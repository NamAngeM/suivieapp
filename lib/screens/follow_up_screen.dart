import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';
import '../models/interaction.dart';

import '../models/visitor.dart';
import '../services/follow_up_service.dart';
import '../widgets/whatsapp_template_sheet.dart';
import 'visitor_details_screen.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _whatsappService = WhatsappService();
  bool _isLoading = false;
  bool _showMyTasksOnly = true;
  Map<String, String> _memberNames = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateAutoTasks();
    _loadMemberNames();
  }

  Future<void> _loadMemberNames() async {
    FirebaseService.getTeamStream().listen((members) {
      if (mounted) {
        setState(() {
          _memberNames = {for (var m in members) m.id: m.nom};
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone, String visitorId) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      FirebaseService.addInteraction(Interaction(
        id: '',
        visitorId: visitorId,
        type: 'call',
        content: 'Appel lancé depuis Suivi',
        date: DateTime.now(),
        authorId: FirebaseService.currentUser?.id ?? 'current_user',
        authorName: FirebaseService.currentUser?.nom ?? 'Moi',
      ));
    }
  }

  Future<void> _markAsDone(FollowUpTask task) async {
    await FirebaseService.updateTaskStatus(task.id, 'termine');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tâche terminée !'),
          backgroundColor: AppTheme.zoeBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _navigateToDetails(String visitorId) async {
    setState(() => _isLoading = true);
    final visitor = await FirebaseService.getVisitor(visitorId);
    setState(() => _isLoading = false);
    
    if (visitor != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => VisitorDetailsScreen(visitor: visitor)),
      );
    }
  }

  Future<void> _openWhatsApp(String phone, String visitorId, String visitorName) async {
    final visitor = await FirebaseService.getVisitor(visitorId);
    if (visitor != null && mounted) {
      WhatsAppTemplateSheet.show(context, visitor);
    } else {
      // Fallback si visiteur non chargé
      await _whatsappService.openWhatsApp(phone, "Bonjour $visitorName, ravis de vous avoir accueilli à ZOE Church !");
    }
  }

  Future<void> _generateAutoTasks() async {
    await FollowUpService.syncAutoTasks();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.transparent, // Gradient
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFF0F4F8)],
          ),
        ),
        child: Stack(
          children: [
            // Watermark
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Icon(
                    Icons.church, // Placeholder
                    size: 300,
                    color: AppTheme.zoeBlue,
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator()),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header Custom
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1B365D).withValues(alpha: 0.1),
                          const Color(0xFFB41E3A).withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Suivi & Rappels',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B365D),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildFilterChip('Mes Tâches', _showMyTasksOnly, () => setState(() => _showMyTasksOnly = true)),
                            const SizedBox(width: 8),
                            _buildFilterChip('Toute l\'Équipe', !_showMyTasksOnly, () => setState(() => _showMyTasksOnly = false)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gérez vos contacts de la semaine.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Performance Card (Needs to be separate or below header?)
                  // The original code had performance card directly after header.
                  // I will keep it outside the header container but make sure there is spacing.
                  const SizedBox(height: 16),
            
            // Performance Card
            StreamBuilder<List<Visitor>>(
              stream: FirebaseService.getVisitorsStream(), // Need visitors for denominator
              builder: (context, snapshotVisitors) {
                final visitors = snapshotVisitors.data ?? [];
                
                return StreamBuilder<List<FollowUpTask>>(
                  stream: FirebaseService.getTasksStream(),
                  builder: (context, snapshotTasks) {
                    final tasks = snapshotTasks.data ?? [];
                    final completed = tasks.where((t) => t.statut == 'termine').length;
                    
                    // Nouveaux visiteurs de la semaine
                    final now = DateTime.now();
                    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                    final newVisitorsThisWeek = visitors.where((v) => 
                        v.dateEnregistrement.isAfter(startOfWeek)).length;
                    
                    // Ratio: Tâches terminées / Nouveaux visiteurs (Cible: 1 appel par visiteur)
                    // Si 0 visiteurs, 100% si des tâches sont faites, ou 0.
                    final totalTarget = newVisitorsThisWeek > 0 ? newVisitorsThisWeek : (completed > 0 ? completed : 1);
                    final percentage = (completed / totalTarget * 100).clamp(0, 100).round();
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Performance Hebdo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$completed suivis sur $newVisitorsThisWeek nouveaux visiteurs',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
            
            const SizedBox(height: 20),
            
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundGrey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
                ),
                indicatorPadding: const EdgeInsets.all(4),
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'À faire'),
                  Tab(text: 'En cours'),
                  Tab(text: 'Terminé'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Task Lists
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TaskList(
                    statut: 'a_faire',
                    onCall: _makeCall,
                    onWhatsApp: _openWhatsApp,
                    onMarkDone: _markAsDone,
                    onDetails: _navigateToDetails,
                    memberNames: _memberNames,
                    showMyTasksOnly: _showMyTasksOnly,
                  ),
                  _TaskList(
                    statut: 'en_cours',
                    onCall: _makeCall,
                    onWhatsApp: _openWhatsApp,
                    onMarkDone: _markAsDone,
                    onDetails: _navigateToDetails,
                    memberNames: _memberNames,
                    showMyTasksOnly: _showMyTasksOnly,
                  ),
                  _TaskList(
                    statut: 'termine',
                    onCall: _makeCall,
                    onWhatsApp: _openWhatsApp,
                    onMarkDone: _markAsDone,
                    onDetails: _navigateToDetails,
                    memberNames: _memberNames,
                    showMyTasksOnly: _showMyTasksOnly,
                    showDoneButton: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
);
}

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.zoeBlue : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.transparent : AppTheme.zoeBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.zoeBlue,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final String statut;
  final Function(String, String) onCall;
  final Function(String, String, String) onWhatsApp;
  final Function(FollowUpTask) onMarkDone;
  final Function(String) onDetails;
  final Map<String, String> memberNames;
  final bool showMyTasksOnly;
  final bool showDoneButton;

  const _TaskList({
    required this.statut,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMarkDone,
    required this.onDetails,
    required this.memberNames,
    required this.showMyTasksOnly,
    this.showDoneButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FollowUpTask>>(
      stream: FirebaseService.getTasksByStatusStream(statut),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final tasks = snapshot.data ?? [];
        var filteredTasks = tasks;

        if (showMyTasksOnly) {
          final currentUserId = FirebaseService.currentUser?.id;
          filteredTasks = tasks.where((t) => t.assignedTo == currentUserId).toList();
        }

        if (filteredTasks.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    showMyTasksOnly ? 'Vous n\'avez aucune tâche ici' : 'Aucune tâche dans cette catégorie',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return _TaskCard(
              task: task,
              onCall: () => onCall(task.visitorPhone, task.visitorId),
              onWhatsApp: () => onWhatsApp(task.visitorPhone, task.visitorId, task.visitorName),
              onMarkDone: () => onMarkDone(task),
              onDetails: () => onDetails(task.visitorId),
              assignedMemberName: task.assignedTo != null ? memberNames[task.assignedTo] : null,
              showDoneButton: showDoneButton,
            );
          },
        );
      },
    );
  }
}

class _TaskCard extends StatefulWidget {
  final FollowUpTask task;
  final VoidCallback onCall;
  final VoidCallback onWhatsApp;
  final VoidCallback onMarkDone;
  final VoidCallback onDetails;
  final String? assignedMemberName;
  final bool showDoneButton;

  const _TaskCard({
    required this.task,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMarkDone,
    required this.onDetails,
    this.assignedMemberName,
    this.showDoneButton = true,
  });

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  final _noteController = TextEditingController();
  bool _isEditingNote = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = widget.task.note ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    await FirebaseService.updateTaskNote(widget.task.id, _noteController.text);
    setState(() => _isEditingNote = false);
  }

  @override
  Widget build(BuildContext context) {
    final joursLabel = widget.task.joursRestantsLabel;
    final isOverdue = widget.task.joursRestants < 0;
    return InkWell(
      onTap: widget.onDetails,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05), // Requested 0.05
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.getAvatarColor(widget.task.visitorName).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.task.visitorName.isNotEmpty 
                        ? widget.task.visitorName[0].toUpperCase() 
                        : '?',
                    style: TextStyle(
                      color: AppTheme.getAvatarColor(widget.task.visitorName),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.task.visitorName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.task.statut == 'termine' 
                                ? AppTheme.zoeBlue 
                                : (isOverdue ? AppTheme.accentRed : AppTheme.accentOrange),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      widget.task.note ?? 'Parcours d\'intégration',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (widget.assignedMemberName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Responsable : ${widget.assignedMemberName}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.zoeBlue.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Days badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue ? AppTheme.accentRed.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  joursLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? AppTheme.accentRed : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Task description
          Text(
            'Tâche : ${widget.task.description}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // Note
          if (_isEditingNote)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter une note...',
                      filled: true,
                      fillColor: AppTheme.backgroundGrey,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: AppTheme.accentGreen),
                  onPressed: _saveNote,
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => setState(() => _isEditingNote = true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.task.note?.isNotEmpty == true 
                      ? widget.task.note! 
                      : 'Ajouter une note...',
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.task.note?.isNotEmpty == true 
                        ? AppTheme.textPrimary 
                        : Colors.grey[400],
                    fontStyle: widget.task.note?.isNotEmpty == true 
                        ? FontStyle.normal 
                        : FontStyle.italic,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              IconButton(
                onPressed: widget.onCall,
                icon: Icon(Icons.phone_outlined, color: Colors.grey[600]),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundGrey,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.onWhatsApp,
                icon: Icon(Icons.message_outlined, color: Colors.grey[600]),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.backgroundGrey,
                ),
              ),
              const Spacer(),
              if (widget.showDoneButton)
                ElevatedButton.icon(
                  onPressed: widget.onMarkDone,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Fait'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
}
