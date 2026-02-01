import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogEntry {
  final String id;
  final String action; // ex: 'delete_visitor', 'update_role'
  final String details;
  final String performedBy; // user ID or name
  final DateTime timestamp;

  AuditLogEntry({
    required this.id,
    required this.action,
    required this.details,
    required this.performedBy,
    required this.timestamp,
  });

  factory AuditLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogEntry(
      id: doc.id,
      action: data['action'] ?? '',
      details: data['details'] ?? '',
      performedBy: data['performedBy'] ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'details': details,
      'performedBy': performedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
