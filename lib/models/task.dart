import 'package:cloud_firestore/cloud_firestore.dart';

class FollowUpTask {
  final String id;
  final String visitorId;
  final String visitorName;
  final String description;
  final String statut;
  final String? note;
  final DateTime dateEcheance;
  final String? assignedTo;
  final DateTime createdAt;

  FollowUpTask({
    required this.id,
    required this.visitorId,
    required this.visitorName,
    required this.description,
    this.statut = 'a_faire',
    this.note,
    required this.dateEcheance,
    this.assignedTo,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get joursRestants {
    return dateEcheance.difference(DateTime.now()).inDays;
  }

  String get joursRestantsLabel {
    final jours = joursRestants;
    if (jours < 0) {
      return 'J${jours}';
    } else if (jours == 0) {
      return "Aujourd'hui";
    } else {
      return 'J+$jours';
    }
  }

  factory FollowUpTask.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FollowUpTask(
      id: doc.id,
      visitorId: data['visitorId'] ?? '',
      visitorName: data['visitorName'] ?? '',
      description: data['description'] ?? '',
      statut: data['statut'] ?? 'a_faire',
      note: data['note'],
      dateEcheance: (data['dateEcheance'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'visitorId': visitorId,
      'visitorName': visitorName,
      'description': description,
      'statut': statut,
      'note': note,
      'dateEcheance': Timestamp.fromDate(dateEcheance),
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FollowUpTask copyWith({
    String? id,
    String? visitorId,
    String? visitorName,
    String? description,
    String? statut,
    String? note,
    DateTime? dateEcheance,
    String? assignedTo,
  }) {
    return FollowUpTask(
      id: id ?? this.id,
      visitorId: visitorId ?? this.visitorId,
      visitorName: visitorName ?? this.visitorName,
      description: description ?? this.description,
      statut: statut ?? this.statut,
      note: note ?? this.note,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
    );
  }
}
