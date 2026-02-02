import '../models/visitor.dart';
import '../models/integration_step.dart';
import 'firebase_service.dart';

class IntegrationService {
  // Les IDs sont maintenant gérés dans le modèle (classe IntegrationStep)

  /// Met à jour le statut d'une étape
  Future<void> updateStepStatus(Visitor visitor, String stepId, StepStatus newStatus) async {
    final List<IntegrationStep> currentPath = List.from(visitor.integrationPath);
    final index = currentPath.indexWhere((s) => s.id == stepId);
    
    if (index == -1) return; // Étape non trouvée

    // Mise à jour de l'étape
    currentPath[index] = currentPath[index].copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );

    // Logique de déverrouillage automatique
    if (newStatus == StepStatus.completed) {
      if (index + 1 < currentPath.length) {
        // Unlock next step if it was locked
        if (currentPath[index + 1].status == StepStatus.locked) {
          currentPath[index + 1] = currentPath[index + 1].copyWith(
            status: StepStatus.inProgress,
          );
        }
      }
    }

    final updatedVisitor = visitor.copyWith(
      integrationPath: currentPath,
      // Backward compatibility (optional but safe)
      integrationSteps: _mapFromPath(currentPath),
    );

    await FirebaseService.updateVisitor(updatedVisitor);
  }

  /// Helper pour maintenir la compatibilité avec l'ancien système de Map
  Map<String, DateTime?> _mapFromPath(List<IntegrationStep> path) {
    final Map<String, DateTime?> map = {};
    for (var step in path) {
      if (step.status == StepStatus.completed) {
        map[step.id] = step.updatedAt;
      } else {
        map[step.id] = null;
      }
    }
    return map;
  }

  // Legacy (Keep for compatibility signatures just in case, or deprecated)
  static const List<String> steps = [
    'accueil', 'contact', 'groupe_maison', 'bapteme', 'dons', 'service'
  ];
  
  static const Map<String, String> stepLabels = {
    'connexion_appel': 'Appel de Bienvenue',
    'connexion_pack': 'Pack de Bienvenue',
    'connexion_adresse': 'Vérification Adresse',
    'approf_groupe': 'Groupe de Maison',
    'approf_cafe': 'Café des Nouveaux',
    'approf_rappel': 'Rappel Dimanche',
    'spirit_affermit': 'Affermissement',
    'spirit_bapteme': 'Entretien Baptême',
    'spirit_priere': 'Suivi Prière',
    'engag_dons': 'Test des Dons',
    'engag_depts': 'Départements',
    'engag_entrevue': 'Intégration Membre',
  };

  bool canValidateStep(Visitor visitor, String stepId) {
    final index = visitor.integrationPath.indexWhere((s) => s.id == stepId);
    if (index <= 0) return true;
    // Check previous
    return visitor.integrationPath[index - 1].status == StepStatus.completed;
  }
}
