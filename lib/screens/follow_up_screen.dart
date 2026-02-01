import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../models/task.dart';
import '../services/firebase_service.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final url = Uri.parse('https://wa.me/$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _makeCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _markAsDone(FollowUpTask task) async {
    await FirebaseService.updateTaskStatus(task.id, 'termine');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tâche terminée !'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suivi & Rappels',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
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
            
            // Performance Card
            StreamBuilder<List<FollowUpTask>>(
              stream: FirebaseService.getTasksStream(),
              builder: (context, snapshot) {
                final tasks = snapshot.data ?? [];
                final completed = tasks.where((t) => t.statut == 'termine').length;
                final total = tasks.length;
                final percentage = total > 0 ? (completed / total * 100).round() : 0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                          '$completed visiteurs sur $total contactés',
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
                      color: Colors.black.withOpacity(0.05),
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
                  ),
                  _TaskList(
                    statut: 'en_cours',
                    onCall: _makeCall,
                    onWhatsApp: _openWhatsApp,
                    onMarkDone: _markAsDone,
                  ),
                  _TaskList(
                    statut: 'termine',
                    onCall: _makeCall,
                    onWhatsApp: _openWhatsApp,
                    onMarkDone: _markAsDone,
                    showDoneButton: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends StatelessWidget {
  final String statut;
  final Function(String) onCall;
  final Function(String) onWhatsApp;
  final Function(FollowUpTask) onMarkDone;
  final bool showDoneButton;

  const _TaskList({
    required this.statut,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMarkDone,
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
        
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  statut == 'termine' 
                      ? 'Aucune tâche terminée' 
                      : 'Aucune tâche en attente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _TaskCard(
              task: task,
              onCall: () => onCall(task.visitorId),
              onWhatsApp: () => onWhatsApp(task.visitorId),
              onMarkDone: () => onMarkDone(task),
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
  final bool showDoneButton;

  const _TaskCard({
    required this.task,
    required this.onCall,
    required this.onWhatsApp,
    required this.onMarkDone,
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
                  color: AppTheme.getAvatarColor(widget.task.visitorName).withOpacity(0.15),
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
                    Text(
                      widget.task.visitorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Visiteur (Dimanche dernier)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              // Days badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverdue ? AppTheme.accentRed.withOpacity(0.1) : Colors.transparent,
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
    );
  }
}
