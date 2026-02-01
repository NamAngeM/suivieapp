import 'package:cloud_firestore/cloud_firestore.dart';
import 'integration_step.dart';

class Visitor {
  final String id;
  final String nomComplet;
  final String sexe;
  final String telephone;
  final String quartier;
  final String statutMatrimonial;
  final String? email;
  final String commentConnu;
  final bool premiereVisite;
  final String? requetePriere;
  final bool souhaiteEtreRecontacte;
  final bool recevoirActualites;
  final DateTime dateEnregistrement;
  final String statut;
  final Map<String, DateTime?> integrationSteps; // Legacy support
  final List<IntegrationStep> integrationPath; // New system
  final String? assignedMemberId;

  Visitor({
    required this.id,
    required this.nomComplet,
    required this.sexe,
    required this.telephone,
    required this.quartier,
    required this.statutMatrimonial,
    this.email,
    required this.commentConnu,
    required this.premiereVisite,
    this.requetePriere,
    required this.souhaiteEtreRecontacte,
    required this.recevoirActualites,
    required this.dateEnregistrement,
    this.statut = 'nouveau',
    this.integrationSteps = const {},
    this.integrationPath = const [],
    this.assignedMemberId,
  });

  String get initials {
    final parts = nomComplet.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  factory Visitor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Legacy steps handling
    final steps = data['integrationSteps'] as Map<String, dynamic>? ?? {};
    final integrationSteps = {
      'accueil': (steps['accueil'] as Timestamp?)?.toDate(),
      'contact': (steps['contact'] as Timestamp?)?.toDate(),
      'groupe_maison': (steps['groupe_maison'] as Timestamp?)?.toDate(),
      'bapteme': (steps['bapteme'] as Timestamp?)?.toDate(),
      'dons': (steps['dons'] as Timestamp?)?.toDate(),
      'service': (steps['service'] as Timestamp?)?.toDate(),
    };

    // New path handling
    List<IntegrationStep> path = [];
    if (data['integrationPath'] != null) {
      path = (data['integrationPath'] as List)
          .map((item) => IntegrationStep.fromMap(item as Map<String, dynamic>))
          .toList();
    } else {
      // Migration: Build path from legacy map if new path is empty
      path = [
        IntegrationStep(
            id: 'accueil', 
            title: 'Accueil', 
            status: integrationSteps['accueil'] != null ? StepStatus.completed : StepStatus.completed, // Toujours complété si visiteur créé
            updatedAt: integrationSteps['accueil'] ?? (data['dateEnregistrement'] as Timestamp?)?.toDate()),
        IntegrationStep(
            id: 'contact', 
            title: 'Premier Contact', 
            status: integrationSteps['contact'] != null ? StepStatus.completed : StepStatus.inProgress, // En cours par défaut
            updatedAt: integrationSteps['contact']),
        IntegrationStep(
            id: 'groupe_maison', 
            title: 'Groupe de Maison', 
            status: integrationSteps['groupe_maison'] != null ? StepStatus.completed : StepStatus.locked,
            updatedAt: integrationSteps['groupe_maison']),
        IntegrationStep(
            id: 'bapteme', 
            title: 'Baptême / Affermissement', 
            status: integrationSteps['bapteme'] != null ? StepStatus.completed : StepStatus.locked,
            updatedAt: integrationSteps['bapteme']),
        IntegrationStep(
            id: 'dons', 
            title: 'Découverte des Dons', 
            status: integrationSteps['dons'] != null ? StepStatus.completed : StepStatus.locked,
            updatedAt: integrationSteps['dons']),
        IntegrationStep(
            id: 'service', 
            title: 'Service / Département', 
            status: integrationSteps['service'] != null ? StepStatus.completed : StepStatus.locked,
            updatedAt: integrationSteps['service']),
      ];
    }

    return Visitor(
      id: doc.id,
      nomComplet: data['nomComplet'] ?? '',
      sexe: data['sexe'] ?? 'Homme',
      telephone: data['telephone'] ?? '',
      quartier: data['quartier'] ?? '',
      statutMatrimonial: data['statutMatrimonial'] ?? 'Célibataire',
      email: data['email'],
      commentConnu: data['commentConnu'] ?? '',
      premiereVisite: data['premiereVisite'] ?? true,
      requetePriere: data['requetePriere'],
      souhaiteEtreRecontacte: data['souhaiteEtreRecontacte'] ?? false,
      recevoirActualites: data['recevoirActualites'] ?? false,
      dateEnregistrement: (data['dateEnregistrement'] as Timestamp?)?.toDate() ?? DateTime.now(),
      statut: data['statut'] ?? 'nouveau',
      integrationSteps: integrationSteps,
      integrationPath: path,
      assignedMemberId: data['assignedMemberId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nomComplet': nomComplet,
      'sexe': sexe,
      'telephone': telephone,
      'quartier': quartier,
      'statutMatrimonial': statutMatrimonial,
      'email': email,
      'commentConnu': commentConnu,
      'premiereVisite': premiereVisite,
      'requetePriere': requetePriere,
      'souhaiteEtreRecontacte': souhaiteEtreRecontacte,
      'recevoirActualites': recevoirActualites,
      'dateEnregistrement': Timestamp.fromDate(dateEnregistrement),
      'statut': statut,
      'integrationSteps': integrationSteps.map((key, value) => MapEntry(key, value != null ? Timestamp.fromDate(value) : null)),
      'integrationPath': integrationPath.map((s) => s.toMap()).toList(),
      'assignedMemberId': assignedMemberId,
    };
  }

  Visitor copyWith({
    String? id,
    String? nomComplet,
    String? sexe,
    String? telephone,
    String? quartier,
    String? statutMatrimonial,
    String? email,
    String? commentConnu,
    bool? premiereVisite,
    String? requetePriere,
    bool? souhaiteEtreRecontacte,
    bool? recevoirActualites,
    DateTime? dateEnregistrement,
    String? statut,
    Map<String, DateTime?>? integrationSteps,
    List<IntegrationStep>? integrationPath,
    String? assignedMemberId,
  }) {
    return Visitor(
      id: id ?? this.id,
      nomComplet: nomComplet ?? this.nomComplet,
      sexe: sexe ?? this.sexe,
      telephone: telephone ?? this.telephone,
      quartier: quartier ?? this.quartier,
      statutMatrimonial: statutMatrimonial ?? this.statutMatrimonial,
      email: email ?? this.email,
      commentConnu: commentConnu ?? this.commentConnu,
      premiereVisite: premiereVisite ?? this.premiereVisite,
      requetePriere: requetePriere ?? this.requetePriere,
      souhaiteEtreRecontacte: souhaiteEtreRecontacte ?? this.souhaiteEtreRecontacte,
      recevoirActualites: recevoirActualites ?? this.recevoirActualites,
      dateEnregistrement: dateEnregistrement ?? this.dateEnregistrement,
      statut: statut ?? this.statut,
      integrationSteps: integrationSteps ?? this.integrationSteps,
      integrationPath: integrationPath ?? this.integrationPath,
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
    );
  }
}
