import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../models/interaction.dart';
import '../models/message_template.dart';
import '../services/integration_service.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';
import '../models/integration_step.dart';
import '../widgets/integration_timeline.dart';
import '../widgets/whatsapp_template_sheet.dart';
import '../services/assignment_service.dart';
import '../models/team_member.dart';

class VisitorDetailsScreen extends StatefulWidget {
  final Visitor visitor;

  const VisitorDetailsScreen({super.key, required this.visitor});

  @override
  State<VisitorDetailsScreen> createState() => _VisitorDetailsScreenState();
}

class _VisitorDetailsScreenState extends State<VisitorDetailsScreen> with SingleTickerProviderStateMixin {
  late Visitor _visitor;
  late TabController _tabController;
  final _integrationService = IntegrationService();
  final _whatsappService = WhatsappService();
  bool _isLoading = false;
  String? _assignedToName;

  @override
  void initState() {
    super.initState();
    _visitor = widget.visitor;
    _tabController = TabController(length: 2, vsync: this);
    _loadAssignedMember();
  }

  Future<void> _loadAssignedMember() async {
    if (_visitor.assignedMemberId != null && _visitor.assignedMemberId!.isNotEmpty) {
      final member = await FirebaseService.getTeamMember(_visitor.assignedMemberId!);
      if (mounted && member != null) {
        setState(() => _assignedToName = member.nom);
      } else if (mounted) {
        setState(() => _assignedToName = null);
      }
    } else if (mounted) {
      setState(() => _assignedToName = null);
    }
  }

  Future<void> _showAssignmentDialog() async {
    final teamStream = FirebaseService.getTeamStream();
    final team = await teamStream.first;
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Affecter un responsable'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: team.length,
            itemBuilder: (context, index) {
              final member = team[index];
              final isCurrent = member.id == _visitor.assignedMemberId;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.zoeBlue.withOpacity(0.1),
                  child: Text(member.initials, style: const TextStyle(color: AppTheme.zoeBlue, fontSize: 12)),
                ),
                title: Text(member.nom),
                subtitle: Text(member.role),
                trailing: isCurrent ? const Icon(Icons.check_circle, color: AppTheme.zoeBlue) : null,
                onTap: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  final assignmentService = AssignmentService();
                  await assignmentService.manuallyAssignVisitor(_visitor, member.id);
                  
                  // Recharger le visiteur et l'UI
                  final updatedVisitor = await FirebaseService.getVisitor(_visitor.id);
                  if (mounted && updatedVisitor != null) {
                    setState(() {
                      _visitor = updatedVisitor;
                      _isLoading = false;
                    });
                    _loadAssignedMember();
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      // Enregistrer l'interaction
      FirebaseService.addInteraction(Interaction(
        id: '',
        visitorId: _visitor.id,
        type: 'call',
        content: 'Appel téléphonique lancé',
        date: DateTime.now(),
        authorId: FirebaseService.currentUser?.id ?? 'current_user',
        authorName: FirebaseService.currentUser?.nom ?? 'Moi',
      ));
    }
  }

  Future<void> _sendSMS(String phone) async {
    final url = Uri.parse('sms:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _showWhatsAppTemplates() async {
    WhatsAppTemplateSheet.show(context, _visitor);
  }

  // _toggleStep removed (replaced by IntegrationTimelineWidget logic)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.white, // Use theme default
      appBar: AppBar(
        title: Text(_visitor.nomComplet),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: const [
              Tab(text: 'Détails & Parcours'),
              Tab(text: 'Historique'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Onglet 1: Détails existants
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 32),
                      const Text(
                        'Parcours d\'Intégration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      IntegrationTimelineWidget(
                        visitor: _visitor,
                        onStatusChanged: (step, status) async {
                          setState(() => _isLoading = true);
                          await _integrationService.updateStepStatus(_visitor, step.id, status);
                          // Force refresh (simplified) because _visitor is state. 
                          // Ideally we should re-fetch or use a Stream for the whole screen.
                          // But for now, let's keep it simple.
                          // We need to update the local _visitor state to reflect changes immediately
                          // Logic to update local _visitor path:
                          final newPath = List<IntegrationStep>.from(_visitor.integrationPath);
                          final idx = newPath.indexWhere((s) => s.id == step.id);
                          if (idx != -1) {
                            newPath[idx] = newPath[idx].copyWith(status: status, updatedAt: DateTime.now());
                            // Handle auto-unlock logic locally for UI responsiveness? 
                            // Or just wait for reload. Let's rely on setState re-render if we updated local object.
                            // However, updateStepStatus returns void and does Firestore update.
                            // We should really start listening to the visitor stream in `initState` or `build`.
                            // But for this patch, let's just assume hot reload or re-entry. 
                            // OR, manually update local state:
                             setState(() {
                               _visitor = _visitor.copyWith(integrationPath: newPath);
                               _isLoading = false;
                             });
                          }
                        },
                      ),
                      // ... reste du contenu
                    ],
                  ),
                ),
                // Onglet 2: Historique
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Interaction>>(
            stream: FirebaseService.getInteractionsStream(_visitor.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final interactions = snapshot.data ?? [];
              
              if (interactions.isEmpty) {
                return const Center(child: Text('Aucune interaction enregistrée'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: interactions.length,
                itemBuilder: (context, index) {
                  final interaction = interactions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInteractionIcon(interaction.type),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${DateFormat('dd/MM HH:mm').format(interaction.date)} - ${interaction.authorName}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                interaction.content,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Zone de saisie rapide (Note)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: const Offset(0, -2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      FirebaseService.addInteraction(Interaction(
                        id: '',
                        visitorId: _visitor.id,
                        type: 'note',
                        content: value,
                        date: DateTime.now(),
                        authorId: FirebaseService.currentUser?.id ?? 'current_user',
                        authorName: FirebaseService.currentUser?.nom ?? 'Moi',
                      ));
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Ajouter une note...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.zoeBlue.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.zoeBlue.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.zoeBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppTheme.primaryColor),
                onPressed: () {
                  // Logique d'envoi similaire à onSubmitted
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionIcon(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'call':
        icon = Icons.phone;
        color = Colors.blue;
        break;
      case 'whatsapp':
        icon = Icons.chat_bubble;
        color = Colors.green;
        break;
      default:
        icon = Icons.note;
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.getAvatarColor(_visitor.nomComplet),
                child: Text(
                  _visitor.initials,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _visitor.quartier,
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _visitor.telephone,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (_assignedToName != null || (FirebaseService.currentUser?.isAdmin ?? false))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: InkWell(
                          onTap: (FirebaseService.currentUser?.isAdmin ?? false) 
                              ? _showAssignmentDialog 
                              : null,
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, size: 14, color: AppTheme.zoeBlue),
                              const SizedBox(width: 4),
                              Text(
                                _assignedToName != null ? 'Assigné à : $_assignedToName' : 'Non assigné',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.zoeBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (FirebaseService.currentUser?.isAdmin ?? false) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 12, color: AppTheme.zoeBlue),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                onPressed: () => _makeCall(_visitor.telephone), 
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: AppTheme.zoeBlue),
                onPressed: _showWhatsAppTemplates,
              ),
            ],
          ),
        ],
      ),
    );
  }


}
