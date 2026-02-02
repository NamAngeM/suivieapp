import '../models/task.dart';
import '../models/visitor.dart';
import 'firebase_service.dart';

class FollowUpService {
  /// Génère toutes les tâches automatiques pour un visiteur si elles n'existent pas déjà
  static Future<void> generateTasksForVisitor(Visitor visitor, {String? assignedTo}) async {
    final now = DateTime.now();
    final dateReg = visitor.dateEnregistrement;
    
    // Liste des tâches à générer avec leurs échéances
    final taskDefinitions = [
      // ÉTAPE 1: PREMIER CONTACT
      _TaskDef('📞 1. Premier Contact (Appel/Message)', 1, 'Phase 1'),
      
      // ÉTAPE 2: GROUPE DE MAISON
      _TaskDef('🏠 2. Invitation Groupe de Maison', 3, 'Phase 1'),
      
      // ÉTAPE 3: CAFÉ DES NOUVEAUX
      _TaskDef('☕ 3. Invitation Café des Nouveaux', 7, 'Phase 2'),
      
      // ÉTAPE 4: AFFERMISSEMENT
      _TaskDef('📖 4. Classes d\'Affermissement', 14, 'Phase 2'),
      
      // ÉTAPE 5: BAPTÊME
      _TaskDef('🌊 5. Entretien pour le Baptême', 30, 'Phase 3'),
      
      // ÉTAPE 6: DÉCOUVERTE DES DONS
      _TaskDef('🛠️ 6. Découverte des Dons (Test)', 45, 'Phase 3'),
      
      // ÉTAPE 7: SERVICE
      _TaskDef('🤝 7. Intégration Département', 60, 'Phase 4'),
    ];

    // Récupérer les tâches existantes pour ce visiteur pour éviter les doublons
    final existingTasks = await FirebaseService.getTasksForVisitor(visitor.id);
    if (existingTasks.isNotEmpty) {
      return; 
    }
    
    for (var def in taskDefinitions) {
      final dueDate = dateReg.add(Duration(days: def.delayInDays));
      
      // On ne génère la tâche que si elle est pertinente (pas trop vieille si on vient de migrer)
      // Mais ici on veut surtout que tout apparaisse pour les nouveaux.
      
      await FirebaseService.createFollowUpTask(
        FollowUpTask(
          id: '', 
          visitorId: visitor.id,
          visitorName: visitor.nomComplet,
          visitorPhone: visitor.telephone,
          description: def.description,
          dateEcheance: dueDate,
          statut: 'a_faire',
          note: def.phase, // Stockage de la phase dans la note par défaut
          assignedTo: assignedTo,
        )
      );
    }
  }

  /// Version optimisée qui vérifie l'existence avant de créer pour tous les visiteurs récents
  static Future<void> syncAutoTasks() async {
    final now = DateTime.now();
    // On synchronise pour les visiteurs des 3 derniers mois (portée du parcours)
    final recentVisitors = await FirebaseService.getVisitorsSince(now.subtract(const Duration(days: 90)));
    
    for (var v in recentVisitors) {
      await generateTasksForVisitor(v, assignedTo: v.assignedMemberId);
    }
  }
}

class _TaskDef {
  final String description;
  final int delayInDays;
  final String phase;

  _TaskDef(this.description, this.delayInDays, this.phase);
}
