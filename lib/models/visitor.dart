import 'package:cloud_firestore/cloud_firestore.dart';

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
  final Map<String, DateTime?> integrationSteps;
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
    this.integrationSteps = const {
      'accueil': null,
      'contact': null,
      'groupe_maison': null,
      'bapteme': null,
    },
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
    final steps = data['integrationSteps'] as Map<String, dynamic>? ?? {};
    final integrationSteps = {
      'accueil': (steps['accueil'] as Timestamp?)?.toDate(),
      'contact': (steps['contact'] as Timestamp?)?.toDate(),
      'groupe_maison': (steps['groupe_maison'] as Timestamp?)?.toDate(),
      'bapteme': (steps['bapteme'] as Timestamp?)?.toDate(),
    };

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
      assignedMemberId: assignedMemberId ?? this.assignedMemberId,
    );
  }
}
