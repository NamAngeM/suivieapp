import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zoe_church_visitors/models/visitor.dart';
import 'package:zoe_church_visitors/core/utils/app_logger.dart';

/// Repository pour la gestion des visiteurs
class VisitorRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _collection => _firestore.collection('visitors');

  /// Ajouter un visiteur
  Future<String> addVisitor(Visitor visitor) async {
    try {
      final docRef = await _collection.add(visitor.toFirestore());
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding visitor', tag: 'VisitorRepository', error: e);
      rethrow;
    }
  }
  
  /// Mettre à jour un visiteur
  Future<void> updateVisitor(Visitor visitor) async {
    try {
      await _collection.doc(visitor.id).update(visitor.toFirestore());
    } catch (e) {
      AppLogger.error('Error updating visitor', tag: 'VisitorRepository', error: e);
      rethrow;
    }
  }
  
  /// Supprimer un visiteur
  Future<void> deleteVisitor(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      AppLogger.error('Error deleting visitor', tag: 'VisitorRepository', error: e);
      rethrow;
    }
  }
  
  /// Stream des visiteurs (limité à 50 pour performance)
  Stream<List<Visitor>> getVisitorsStream() {
    return _collection
        .orderBy('dateEnregistrement', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Visitor.fromFirestore(doc)).toList());
  }
  
  /// Récupérer tous les visiteurs
  Future<List<Visitor>> getVisitors() async {
    try {
      final snapshot = await _collection
          .orderBy('dateEnregistrement', descending: true)
          .get();
      return snapshot.docs.map((doc) => Visitor.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting visitors', tag: 'VisitorRepository', error: e);
      return [];
    }
  }
  
  /// Récupérer un visiteur par ID
  Future<Visitor?> getVisitor(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return Visitor.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting visitor', tag: 'VisitorRepository', error: e);
      return null;
    }
  }

  /// Récupérer les visiteurs depuis une date
  Future<List<Visitor>> getVisitorsSince(DateTime date) async {
    try {
      final snapshot = await _collection
          .where('dateEnregistrement', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
          .get();
      return snapshot.docs.map((doc) => Visitor.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting visitors since date', tag: 'VisitorRepository', error: e);
      return [];
    }
  }
}
