import 'package:cloud_firestore/cloud_firestore.dart';

enum StepStatus {
  locked,
  inProgress,
  completed,
}

class IntegrationStep {
  final String id;
  final String title;
  final String? subtitle;
  final StepStatus status;
  final String phase; // Pour grouper les étapes (ex: "Connexion")
  final DateTime? updatedAt;
  final String? assignedTo;
  final String? notes;
  final String? department;

  IntegrationStep({
    required this.id,
    required this.title,
    this.subtitle,
    this.status = StepStatus.locked,
    this.phase = '',
    this.updatedAt,
    this.assignedTo,
    this.notes,
    this.department,
  });

  factory IntegrationStep.fromMap(Map<String, dynamic> data) {
    return IntegrationStep(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      status: _parseStatus(data['status']),
      phase: data['phase'] ?? '',
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
      'subtitle': subtitle,
      'status': status.name,
      'phase': phase,
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
    String? subtitle,
    StepStatus? status,
    String? phase,
    DateTime? updatedAt,
    String? assignedTo,
    String? notes,
    String? department,
  }) {
    return IntegrationStep(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      status: status ?? this.status,
      phase: phase ?? this.phase,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      notes: notes ?? this.notes,
      department: department ?? this.department,
    );
  }
}
