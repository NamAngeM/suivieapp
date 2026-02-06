import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task.dart';
import '../../core/utils/app_logger.dart';

/// Repository pour la gestion des tâches de suivi
class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _collection => _firestore.collection('tasks');

  /// Ajouter une tâche
  Future<String> addTask(FollowUpTask task) async {
    try {
      final docRef = await _collection.add(task.toFirestore());
      return docRef.id;
    } catch (e) {
      AppLogger.error('Error adding task', tag: 'TaskRepository', error: e);
      rethrow;
    }
  }
  
  /// Mettre à jour une tâche
  Future<void> updateTask(FollowUpTask task) async {
    try {
      await _collection.doc(task.id).update(task.toFirestore());
    } catch (e) {
      AppLogger.error('Error updating task', tag: 'TaskRepository', error: e);
      rethrow;
    }
  }
  
  /// Mettre à jour uniquement le statut d'une tâche
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _collection.doc(taskId).update({'statut': newStatus});
    } catch (e) {
      AppLogger.error('Error updating task status', tag: 'TaskRepository', error: e);
      rethrow;
    }
  }
  
  /// Mettre à jour la note d'une tâche
  Future<void> updateTaskNote(String taskId, String note) async {
    try {
      await _collection.doc(taskId).update({'note': note});
    } catch (e) {
      AppLogger.error('Error updating task note', tag: 'TaskRepository', error: e);
      rethrow;
    }
  }
  
  /// Récupérer les tâches pour un visiteur
  Future<List<FollowUpTask>> getTasksForVisitor(String visitorId) async {
    try {
      final snapshot = await _collection
          .where('visitorId', isEqualTo: visitorId)
          .get();
      return snapshot.docs.map((doc) => FollowUpTask.fromFirestore(doc)).toList();
    } catch (e) {
      AppLogger.error('Error getting tasks for visitor', tag: 'TaskRepository', error: e);
      return [];
    }
  }

  /// Stream de toutes les tâches
  Stream<List<FollowUpTask>> getTasksStream() {
    return _collection
        .orderBy('dateEcheance')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => FollowUpTask.fromFirestore(doc)).toList());
  }
  
  /// Stream des tâches par statut
  Stream<List<FollowUpTask>> getTasksByStatusStream(String statut) {
    return _collection
        .where('statut', isEqualTo: statut)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => FollowUpTask.fromFirestore(doc)).toList());
  }

  /// Créer une tâche de suivi (vérifie si elle existe déjà)
  Future<void> createFollowUpTask(FollowUpTask task) async {
    try {
      // Vérifier si une tâche identique existe déjà
      final existing = await _collection
          .where('visitorId', isEqualTo: task.visitorId)
          .where('description', isEqualTo: task.description)
          .get();
      
      if (existing.docs.isEmpty) {
        await addTask(task);
      }
    } catch (e) {
      AppLogger.error('Error creating follow-up task', tag: 'TaskRepository', error: e);
      rethrow;
    }
  }
}
