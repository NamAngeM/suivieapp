import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/visitor.dart';
import '../models/visitor.dart';
import '../models/interaction.dart';
import '../models/message_template.dart';
import '../services/integration_service.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';

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

  Future<void> _showWhatsAppTemplates() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => StreamBuilder<List<MessageTemplate>>(
        stream: FirebaseService.getMessageTemplatesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final templates = snapshot.data!;
          // Ajouter un template par défaut "Message vide"
          final allTemplates = [
            MessageTemplate(id: 'manual', title: 'Message manuel', content: ''),
            ...templates
          ];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Choisir un modèle', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: allTemplates.length,
                  itemBuilder: (context, index) {
                    final t = allTemplates[index];
                    return ListTile(
                      title: Text(t.title),
                      subtitle: t.content.isNotEmpty 
                          ? Text(t.content, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _whatsappService.sendTemplateMessage(_visitor, t);
                        // Enregistrer l'interaction
                        FirebaseService.addInteraction(Interaction(
                          id: '',
                          visitorId: _visitor.id,
                          type: 'whatsapp',
                          content: 'Template: ${t.title}',
                          date: DateTime.now(),
                          authorId: 'current_user', // TODO: user ID
                          authorName: 'Moi', // TODO: user name
                        ));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleStep(String stepId) async {
    setState(() => _isLoading = true);
    try {
      if (_visitor.integrationSteps[stepId] != null) {
        // Dévalider (si nécessaire, pas forcément accessible à tous)
        // await _integrationService.unvalidateStep(_visitor, stepId); // Pas implémenté pour l'instant
      } else {
        // Valider
        if (_integrationService.canValidateStep(_visitor, stepId)) {
          await _integrationService.validateStep(_visitor, stepId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Veuillez valider les étapes précédentes d\'abord.')),
          );
        }
      }
      
      // Ici idéalement on rechargerait le visiteur depuis Firebase
      // Pour simuler la réactivité immédiate :
      final updatedSteps = Map<String, DateTime?>.from(_visitor.integrationSteps);
      updatedSteps[stepId] = DateTime.now();
      setState(() {
        _visitor = _visitor.copyWith(integrationSteps: updatedSteps);
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                      _buildIntegrationStepper(),
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
                onPressed: () {
                  // Enregistrer l'appel
                  FirebaseService.addInteraction(Interaction(
                    id: '',
                    visitorId: _visitor.id,
                    type: 'call',
                    content: 'Appel téléphonique',
                    date: DateTime.now(),
                    authorId: 'current_user',
                    authorName: 'Moi',
                  ));
                }, 
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

  Widget _buildIntegrationStepper() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: IntegrationService.steps.length,
      itemBuilder: (context, index) {
        final stepId = IntegrationService.steps[index];
        final label = IntegrationService.stepLabels[stepId]!;
        final isValidated = _visitor.integrationSteps[stepId] != null;
        final date = _visitor.integrationSteps[stepId];
        final isLast = index == IntegrationService.steps.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _toggleStep(stepId),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isValidated ? AppTheme.accentGreen : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isValidated ? AppTheme.accentGreen : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: isValidated
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey[300],
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isValidated ? FontWeight.bold : FontWeight.normal,
                        color: isValidated ? AppTheme.textPrimary : Colors.grey[600],
                      ),
                    ),
                    if (isValidated)
                      Text(
                        'Validé le ${DateFormat('dd/MM/yyyy').format(date!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
