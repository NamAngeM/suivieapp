import 'package:flutter/material.dart';
import '../models/message_template.dart';
import '../services/firebase_service.dart';
import '../config/theme.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  void _showEditDialog(BuildContext context, MessageTemplate? template) {
    final titleController = TextEditingController(text: template?.title ?? '');
    final contentController = TextEditingController(text: template?.content ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template == null ? 'Nouveau Template' : 'Modifier Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Bienvenue',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Bonjour [Prénom], ...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Variables disponibles: [Prénom], [Nom], [Date]',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || contentController.text.isEmpty) return;

              final newTemplate = MessageTemplate(
                id: template?.id ?? '',
                title: titleController.text.trim(),
                content: contentController.text.trim(),
                isDefault: template?.isDefault ?? false,
              );

              if (template == null) {
                await FirebaseService.addMessageTemplate(newTemplate);
              } else {
                await FirebaseService.updateMessageTemplate(newTemplate);
              }

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates WhatsApp'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<MessageTemplate>>(
        stream: FirebaseService.getMessageTemplatesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final templates = snapshot.data ?? [];

          if (templates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.message_outlined, size: 60, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   Text(
                     'Aucun modèle de message',
                     style: TextStyle(color: Colors.grey[500]),
                   ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () => _showEditDialog(context, null),
                     icon: const Icon(Icons.add),
                     label: const Text('Créer un modèle'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.primaryColor,
                       foregroundColor: Colors.white,
                     ),
                   ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Card(
                elevation: 0,
                color: AppTheme.backgroundGrey,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(
                    template.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    template.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.grey),
                        onPressed: () => _showEditDialog(context, template),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Supprimer ?'),
                              content: const Text('Cette action est irréversible.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirm == true) {
                            await FirebaseService.deleteMessageTemplate(template.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, null),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
