import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/team_member.dart';
import '../../core/utils/app_logger.dart';

/// Repository pour la gestion de l'équipe
class TeamRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _collection => _firestore.collection('team');

  /// Récupérer un membre par ID
  Future<TeamMember?> getTeamMember(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return TeamMember.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error getting team member', tag: 'TeamRepository', error: e);
      return null;
    }
  }

  /// Stream de tous les membres
  Stream<List<TeamMember>> getTeamStream() {
    return _collection
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList());
  }
  
  /// Ajouter un membre
  Future<String> addTeamMember(TeamMember member) async {
    try {
      final docRef = await _collection.add(member.toFirestore());
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding team member', tag: 'TeamRepository', error: e);
      rethrow;
    }
  }
  
  /// Mettre à jour un membre
  Future<void> updateTeamMember(TeamMember member) async {
    try {
      await _collection.doc(member.id).update(member.toFirestore());
    } catch (e) {
      AppLogger.error('Error updating team member', tag: 'TeamRepository', error: e);
      rethrow;
    }
  }
  
  /// Supprimer un membre
  Future<void> deleteTeamMember(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      AppLogger.error('Error deleting team member', tag: 'TeamRepository', error: e);
      rethrow;
    }
  }
}
