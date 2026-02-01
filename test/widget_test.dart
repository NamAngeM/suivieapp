// Test basique pour l'application Zoe Church Visitors

import 'package:flutter_test/flutter_test.dart';
import 'package:zoe_church_visitors/models/visitor.dart';

void main() {
  group('Visitor Model Tests', () {
    test('Visitor initials are generated correctly', () {
      final visitor = Visitor(
        id: '1',
        nomComplet: 'Jean Dupont',
        sexe: 'Homme',
        telephone: '+225 07 08 45 12',
        quartier: 'Cocody',
        statutMatrimonial: 'Célibataire',
        commentConnu: 'Réseaux Sociaux',
        premiereVisite: true,
        souhaiteEtreRecontacte: true,
        recevoirActualites: true,
        dateEnregistrement: DateTime.now(),
      );

      expect(visitor.initials, 'JD');
    });

    test('Visitor single name initial', () {
      final visitor = Visitor(
        id: '2',
        nomComplet: 'Marie',
        sexe: 'Femme',
        telephone: '+225 07 08 45 12',
        quartier: 'Yopougon',
        statutMatrimonial: 'Mariée',
        commentConnu: 'Ami/Famille',
        premiereVisite: false,
        souhaiteEtreRecontacte: false,
        recevoirActualites: true,
        dateEnregistrement: DateTime.now(),
      );

      expect(visitor.initials, 'M');
    });

    test('Visitor toFirestore returns correct map', () {
      final now = DateTime.now();
      final visitor = Visitor(
        id: '3',
        nomComplet: 'Test User',
        sexe: 'Homme',
        telephone: '+225 00 00 00 00',
        quartier: 'Marcory',
        statutMatrimonial: 'Fiancé',
        commentConnu: 'Passant',
        premiereVisite: true,
        souhaiteEtreRecontacte: true,
        recevoirActualites: false,
        dateEnregistrement: now,
      );

      final map = visitor.toFirestore();
      
      expect(map['nomComplet'], 'Test User');
      expect(map['sexe'], 'Homme');
      expect(map['quartier'], 'Marcory');
      expect(map['premiereVisite'], true);
    });
  });
}
