import 'package:flutter/material.dart';
import '../models/visitor.dart';
import '../models/message_template.dart';
import '../models/interaction.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';
import '../config/theme.dart';

class WhatsAppTemplateSheet extends StatelessWidget {
  final Visitor visitor;
  final Function(Interaction)? onInteractionAdded;

  const WhatsAppTemplateSheet({
    super.key,
    required this.visitor,
    this.onInteractionAdded,
  });

  @override
  Widget build(BuildContext context) {
    final whatsappService = WhatsappService();

    return Container(
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
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final t = templates[index];
                    return ListTile(
                      leading: const Icon(Icons.chat_bubble_outline, color: AppTheme.zoeBlue),
                      title: Text(t.title),
                      subtitle: t.content.isNotEmpty 
                          ? Text(t.content, maxLines: 1, overflow: TextOverflow.ellipsis)
                          : const Text('Ouvrir WhatsApp sans message prédéfini'),
                      onTap: () {
                        Navigator.pop(context);
                        whatsappService.sendTemplateMessage(visitor, t);
                        
                        final interaction = Interaction(
                          id: '',
                          visitorId: visitor.id,
                          type: 'whatsapp',
                          content: 'WhatsApp: ${t.title}',
                          date: DateTime.now(),
                          authorId: FirebaseService.currentUser?.id ?? 'current_user',
                          authorName: FirebaseService.currentUser?.nom ?? 'Moi',
                        );
                        
                        FirebaseService.addInteraction(interaction);
                        if (onInteractionAdded != null) onInteractionAdded!(interaction);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add, color: AppTheme.zoeBlue),
                title: const Text('Modifier les modèles'),
                onTap: () {
                  Navigator.pop(context);
                  // Action pour aller vers l'admin ou les templates si nécessaire
                  // Mais ici on reste simple
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Allez dans Admin > Templates pour modifier'))
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  static void show(BuildContext context, Visitor visitor, {Function(Interaction)? onInteractionAdded}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WhatsAppTemplateSheet(
        visitor: visitor,
        onInteractionAdded: onInteractionAdded,
      ),
    );
  }
}
