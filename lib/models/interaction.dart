import 'package:cloud_firestore/cloud_firestore.dart';

class Interaction {
  final String id;
  final String visitorId;
  final String type; // 'call', 'whatsapp', 'visit', 'note'
  final String content;
  final DateTime date;
  final String authorId;
  final String authorName;

  Interaction({
    required this.id,
    required this.visitorId,
    required this.type,
    required this.content,
    required this.date,
    required this.authorId,
    required this.authorName,
  });

  factory Interaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Interaction(
      id: doc.id,
      visitorId: data['visitorId'] ?? '',
      type: data['type'] ?? 'note',
      content: data['content'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Inconnu',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'visitorId': visitorId,
      'type': type,
      'content': content,
      'date': Timestamp.fromDate(date),
      'authorId': authorId,
      'authorName': authorName,
    };
  }
}
