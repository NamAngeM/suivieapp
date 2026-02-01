import 'package:cloud_firestore/cloud_firestore.dart';

class MessageTemplate {
  final String id;
  final String title;
  final String content;
  final bool isDefault;

  MessageTemplate({
    required this.id,
    required this.title,
    required this.content,
    this.isDefault = false,
  });

  factory MessageTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageTemplate(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'isDefault': isDefault,
    };
  }
}
