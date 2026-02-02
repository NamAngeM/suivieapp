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
        // PHASE 1: CONNEXION
        IntegrationStep(
          id: 'connexion_appel',
          title: 'Appel de Bienvenue',
          subtitle: 'J+1: Remercier et écouter',
          phase: 'Phase 1: Connexion',
          status: integrationSteps['contact'] != null ? StepStatus.completed : StepStatus.inProgress,
          updatedAt: integrationSteps['contact'],
        ),
        IntegrationStep(
          id: 'connexion_pack',
          title: 'Pack de Bienvenue',
          subtitle: 'Envoi WhatsApp brochure numérique',
          phase: 'Phase 1: Connexion',
          status: StepStatus.locked,
        ),
        IntegrationStep(
          id: 'connexion_adresse',
          title: 'Vérification adresse',
          subtitle: 'Confirmer le quartier pour orientation',
          phase: 'Phase 1: Connexion',
          status: StepStatus.locked,
        ),

        // PHASE 2: APPROFONDISSEMENT
        IntegrationStep(
          id: 'approf_groupe',
          title: 'Groupe de Maison',
          subtitle: 'Mise en contact responsable quartier',
          phase: 'Phase 2: Approfondissement',
          status: integrationSteps['groupe_maison'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['groupe_maison'],
        ),
        IntegrationStep(
          id: 'approf_cafe',
          title: 'Café des Nouveaux',
          subtitle: 'Rencontre informelle avec responsables',
          phase: 'Phase 2: Approfondissement',
          status: StepStatus.locked,
        ),
        IntegrationStep(
          id: 'approf_rappel',
          title: 'Rappel 2ème Dimanche',
          subtitle: 'Message d\'invitation le samedi soir',
          phase: 'Phase 2: Approfondissement',
          status: StepStatus.locked,
        ),

        // PHASE 3: SPIRITUELLE
        IntegrationStep(
          id: 'spirit_affermit',
          title: 'Classes d\'Affermissement',
          subtitle: 'Inscription cycle bases de la foi',
          phase: 'Phase 3: Spirituelle',
          status: integrationSteps['bapteme'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['bapteme'],
        ),
        IntegrationStep(
          id: 'spirit_bapteme',
          title: 'Entretien Baptême',
          subtitle: 'Rendez-vous avec diacre ou pasteur',
          phase: 'Phase 3: Spirituelle',
          status: StepStatus.locked,
        ),
        IntegrationStep(
          id: 'spirit_priere',
          title: 'Suivi Requêtes Prière',
          subtitle: 'Évolution de la situation',
          phase: 'Phase 3: Spirituelle',
          status: StepStatus.locked,
        ),

        // PHASE 4: ENGAGEMENT
        IntegrationStep(
          id: 'engag_dons',
          title: 'Test des Dons',
          subtitle: 'Découverte des talents spirituels',
          phase: 'Phase 4: Engagement',
          status: integrationSteps['dons'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['dons'],
        ),
        IntegrationStep(
          id: 'engag_depts',
          title: 'Présentation Départements',
          subtitle: 'Tour d\'horizon des ministères',
          phase: 'Phase 4: Engagement',
          status: integrationSteps['service'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['service'],
        ),
        IntegrationStep(
          id: 'engag_entrevue',
          title: 'Entrevue d\'Intégration',
          subtitle: 'De Visiteur à Membre',
          phase: 'Phase 4: Engagement',
          status: StepStatus.locked,
        ),
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
