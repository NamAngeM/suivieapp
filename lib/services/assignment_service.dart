import '../models/visitor.dart';
import '../models/team_member.dart';
import '../models/task.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

class AssignmentService {
  final NotificationService _notificationService = NotificationService();

  /// Attribue automatiquement un visiteur à un membre de l'équipe
  Future<String?> assignVisitor(Visitor visitor, {String taskNote = 'Premier appel de bienvenue'}) async {
    // 1. Récupérer les membres disponibles
    final teamStream = FirebaseService.getTeamStream();
    final team = await teamStream.first;
    
    final availableMembers = team.where((m) => m.isAvailable).toList();
    
    if (availableMembers.isEmpty) return null;

    // 2. Trouver le membre avec le moins de tâches actives (Round Robin simple basé sur la charge)
    availableMembers.sort((a, b) => a.activeTasksCount.compareTo(b.activeTasksCount));
    final selectedMember = availableMembers.first;

    // 3. Créer la tâche pour ce membre
    final task = FollowUpTask(
      id: '',
      visitorId: visitor.id,
      visitorName: visitor.nomComplet,
      visitorPhone: visitor.telephone,
      description: 'Télephone',
      dateEcheance: DateTime.now().add(const Duration(days: 2)), // J+2 par défaut
      assignedTo: selectedMember.id,
      note: taskNote,
    );

    await FirebaseService.addTask(task);

    // 4. Mettre à jour le visiteur
    await FirebaseService.updateVisitor(
      visitor.copyWith(assignedMemberId: selectedMember.id)
    );

    // 5. Mettre à jour le compteur du membre
    await FirebaseService.updateTeamMember(
      selectedMember.copyWith(activeTasksCount: selectedMember.activeTasksCount + 1)
    );

    // 6. (Optionnel) Notifier le membre si implémentation de push notification serveur
    // Pour l'instant on utilise les notifs locales, donc ça ne marchera que sur le tel du membre concerné
    // si l'app tourne. Dans une vraie prod, utiliser Cloud Functions + FCM.
    
    print('Visiteur ${visitor.nomComplet} assigné à ${selectedMember.nom}');
    return selectedMember.id;
  }

  /// Affecte manuellement un visiteur à un membre spécifique
  Future<void> manuallyAssignVisitor(Visitor visitor, String memberId) async {
    // 1. Mettre à jour le visiteur
    await FirebaseService.updateVisitor(
      visitor.copyWith(assignedMemberId: memberId)
    );

    // 2. Mettre à jour toutes les tâches "à faire" ou "en cours" du visiteur
    final tasks = await FirebaseService.getTasksForVisitor(visitor.id);
    for (var task in tasks) {
      if (task.statut != 'termine') {
        await FirebaseService.updateTask(task.copyWith(assignedTo: memberId));
      }
    }

    // 3. Log de l'action
    await FirebaseService.logAction(
      action: 'assignment', 
      details: 'Visiteur ${visitor.nomComplet} affecté manuellement à $memberId',
      performedBy: FirebaseService.currentUser?.nom ?? 'System'
    );
  }

  /// Réassigne une tâche spécifique
  Future<void> reassignTask(FollowUpTask task, String newAssigneeId) async {
    await FirebaseService.updateTask(task.copyWith(assignedTo: newAssigneeId));
  }
}
