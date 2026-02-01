import 'package:cloud_firestore/cloud_firestore.dart';

enum StepStatus {
  locked,
  inProgress,
  completed,
}

class IntegrationStep {
  final String id;
  final String title;
  final StepStatus status;
  final DateTime? updatedAt;
  final String? assignedTo; // ID du membre responsable
  final String? notes;
  final String? department; // Pour l'étape finale "Service"

  IntegrationStep({
    required this.id,
    required this.title,
    this.status = StepStatus.locked,
    this.updatedAt,
    this.assignedTo,
    this.notes,
    this.department,
  });

  factory IntegrationStep.fromMap(Map<String, dynamic> data) {
    return IntegrationStep(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      status: _parseStatus(data['status']),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      assignedTo: data['assignedTo'],
      notes: data['notes'],
      department: data['department'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'status': status.name,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'assignedTo': assignedTo,
      'notes': notes,
      'department': department,
    };
  }

  static StepStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed': return StepStatus.completed;
      case 'inProgress': return StepStatus.inProgress;
      default: return StepStatus.locked;
    }
  }

  IntegrationStep copyWith({
    String? title,
    StepStatus? status,
    DateTime? updatedAt,
    String? assignedTo,
    String? notes,
    String? department,
  }) {
    return IntegrationStep(
      id: id,
      title: title ?? this.title,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      department: department ?? this.department,
    );
  }
}
