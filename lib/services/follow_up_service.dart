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
      // PHASE 1: CONNEXION
      _TaskDef('📞 Appel de Bienvenue (J+1)', 1, 'Phase 1'),
      _TaskDef('📱 Envoi du Pack de Bienvenue (WhatsApp)', 1, 'Phase 1'),
      _TaskDef('✅ Vérification de l\'adresse (Quartier)', 1, 'Phase 1'),
      
      // PHASE 2: APPROFONDISSEMENT
      _TaskDef('🏠 Invitation au Groupe de Maison', 3, 'Phase 2'),
      _TaskDef('☕ Invitation au "Café des Nouveaux"', 7, 'Phase 2'),
      _TaskDef('📅 Rappel pour le 2ème Dimanche', 6, 'Phase 2'), // Samedi suivant
      
      // PHASE 3: SPIRITUELLE
      _TaskDef('📖 Inscription classes d\'Affermissement', 21, 'Phase 3'),
      _TaskDef('🌊 Entretien pour le Baptême', 25, 'Phase 3'),
      _TaskDef('🙏 Suivi des Requêtes de Prière', 28, 'Phase 3'),
      
      // PHASE 4: ENGAGEMENT
      _TaskDef('🛠️ Test des Dons Spirituels', 60, 'Phase 4'),
      _TaskDef('🤝 Présentation des Départements', 70, 'Phase 4'),
      _TaskDef('🎖️ Entrevue d\'Intégration (Membre)', 90, 'Phase 4'),
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
