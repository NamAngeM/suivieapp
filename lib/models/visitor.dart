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
  final bool baptise;
  final bool souhaiteRejoindreGroupe;
  final int noteExperience;
  final List<String> pointsForts;
  final String? commentaireLibre;
  final String? besoinPrioritaire;
  final bool voeuService;
  final String? domaineSouhaite;
  final DateTime dateEnregistrement;
  final String statut;
  final Map<String, DateTime?> integrationSteps;
  final List<IntegrationStep> integrationPath;
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
    // New fields defaults
    this.baptise = false,
    this.souhaiteRejoindreGroupe = false,
    this.noteExperience = 3, // Default to Satisfied
    this.pointsForts = const [],
    this.commentaireLibre,
    this.besoinPrioritaire,
    this.voeuService = false,
    this.domaineSouhaite,
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
        // ÉTAPE 1: PREMIER CONTACT
        IntegrationStep(
          id: 'step_1_contact',
          title: '1. Premier Contact',
          subtitle: 'Appel ou message de bienvenue (J+1)',
          phase: 'Phase 1: Connexion',
          status: integrationSteps['contact'] != null ? StepStatus.completed : StepStatus.inProgress,
          updatedAt: integrationSteps['contact'],
        ),
        
        // ÉTAPE 2: GROUPE DE MAISON
        IntegrationStep(
          id: 'step_2_groupe',
          title: '2. Groupe de Maison',
          subtitle: 'Invitation à la cellule de quartier',
          phase: 'Phase 1: Connexion',
          status: integrationSteps['groupe_maison'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['groupe_maison'],
        ),

        // ÉTAPE 3: CAFÉ DES NOUVEAUX
        IntegrationStep(
          id: 'step_3_cafe',
          title: '3. Café des Nouveaux',
          subtitle: 'Rencontre avec les responsables',
          phase: 'Phase 2: Approfondissement',
          status: StepStatus.locked,
        ),
        
        // ÉTAPE 4: AFFERMISSEMENT
        IntegrationStep(
          id: 'step_4_afferm',
          title: '4. Classes d\'Affermissement',
          subtitle: 'Enseignement des bases de la foi',
          phase: 'Phase 2: Approfondissement',
          status: integrationSteps['bapteme'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['bapteme'],
        ),

        // ÉTAPE 5: BAPTÊME
        IntegrationStep(
          id: 'step_5_bapteme',
          title: '5. Baptême',
          subtitle: 'Engagement spirituel public',
          phase: 'Phase 3: Spirituelle',
          status: StepStatus.locked,
        ),

        // ÉTAPE 6: DÉCOUVERTE DES DONS
        IntegrationStep(
          id: 'step_6_dons',
          title: '6. Découverte des Dons',
          subtitle: 'Test de talents et orientation',
          phase: 'Phase 3: Spirituelle',
          status: integrationSteps['dons'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['dons'],
        ),
        
        // ÉTAPE 7: SERVICE
        IntegrationStep(
          id: 'step_7_service',
          title: '7. Service & Département',
          subtitle: 'Intégration active dans un ministère',
          phase: 'Phase 4: Engagement',
          status: integrationSteps['service'] != null ? StepStatus.completed : StepStatus.locked,
          updatedAt: integrationSteps['service'],
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
      baptise: data['baptise'] ?? false,
      souhaiteRejoindreGroupe: data['souhaiteRejoindreGroupe'] ?? false,
      noteExperience: data['noteExperience'] ?? 3,
      pointsForts: List<String>.from(data['pointsForts'] ?? []),
      commentaireLibre: data['commentaireLibre'],
      besoinPrioritaire: data['besoinPrioritaire'],
      voeuService: data['voeuService'] ?? false,
      domaineSouhaite: data['domaineSouhaite'],
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
      'baptise': baptise,
      'souhaiteRejoindreGroupe': souhaiteRejoindreGroupe,
      'noteExperience': noteExperience,
      'pointsForts': pointsForts,
      'commentaireLibre': commentaireLibre,
      'besoinPrioritaire': besoinPrioritaire,
      'voeuService': voeuService,
      'domaineSouhaite': domaineSouhaite,
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
    bool? baptise,
    bool? souhaiteRejoindreGroupe,
    int? noteExperience,
    List<String>? pointsForts,
    String? commentaireLibre,
    String? besoinPrioritaire,
    bool? voeuService,
    String? domaineSouhaite,
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
      baptise: baptise ?? this.baptise,
      souhaiteRejoindreGroupe: souhaiteRejoindreGroupe ?? this.souhaiteRejoindreGroupe,
      noteExperience: noteExperience ?? this.noteExperience,
      pointsForts: pointsForts ?? this.pointsForts,
      commentaireLibre: commentaireLibre ?? this.commentaireLibre,
      besoinPrioritaire: besoinPrioritaire ?? this.besoinPrioritaire,
      voeuService: voeuService ?? this.voeuService,
      domaineSouhaite: domaineSouhaite ?? this.domaineSouhaite,
    );
  }
}
