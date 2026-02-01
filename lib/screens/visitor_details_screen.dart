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

  @override
  void initState() {
    super.initState();
    _visitor = widget.visitor;
    _tabController = TabController(length: 2, vsync: this);
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: StreamBuilder<List<MessageTemplate>>(
          stream: FirebaseService.getMessageTemplatesStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Erreur de chargement des modèles: ${snapshot.error}'),
              ));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final templates = snapshot.data ?? [];
            final allTemplates = templates;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Choisir un modèle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: allTemplates.length,
                    itemBuilder: (context, index) {
                      final t = allTemplates[index];
                      return ListTile(
                        leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.accentGreen),
                        title: Text(t.title),
                        subtitle: t.content.isNotEmpty 
                            ? Text(t.content, maxLines: 1, overflow: TextOverflow.ellipsis)
                            : const Text('Ouvrir WhatsApp sans message prédéfini'),
                        onTap: () {
                          Navigator.pop(context);
                          _whatsappService.sendTemplateMessage(_visitor, t);
                          FirebaseService.addInteraction(Interaction(
                            id: '',
                            visitorId: _visitor.id,
                            type: 'whatsapp',
                            content: 'WhatsApp: ${t.title}',
                            date: DateTime.now(),
                            authorId: FirebaseService.currentUser?.id ?? 'current_user',
                            authorName: FirebaseService.currentUser?.nom ?? 'Moi',
                          ));
                        },
                      );
                    },
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('MESSAGES DIRECTS', style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey,
                    letterSpacing: 1.1,
                  )),
                ),
                // Quick WhatsApp option
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.accentGreen),
                  title: const Text('Message WhatsApp'),
                  subtitle: const Text('Ouvrir WhatsApp sans modèle'),
                  onTap: () {
                    Navigator.pop(context);
                    _whatsappService.openWhatsApp(_visitor.telephone, "");
                  },
                ),
                // Quick SMS option
                ListTile(
                  leading: const Icon(Icons.sms_outlined, color: Colors.blue),
                  title: const Text('Message SMS'),
                  subtitle: const Text('Envoyer un SMS classique'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendSMS(_visitor.telephone);
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
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
                  decoration: const InputDecoration(
                    hintText: 'Ajouter une note...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      FirebaseService.addInteraction(Interaction(
                        id: '',
                        visitorId: _visitor.id,
                        type: 'note',
                        content: value,
                        date: DateTime.now(),
                        authorId: 'current_user',
                        authorName: 'Moi',
                      ));
                    }
                  },
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
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone, color: AppTheme.primaryColor),
                onPressed: () => _makeCall(_visitor.telephone), 
              ),
              IconButton(
                icon: const Icon(Icons.chat, color: AppTheme.accentGreen),
                onPressed: _showWhatsAppTemplates,
              ),
            ],
          ),
        ],
      ),
    );
  }


}
