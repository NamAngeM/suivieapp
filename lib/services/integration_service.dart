import '../models/visitor.dart';
import 'firebase_service.dart';

class IntegrationService {
  static const List<String> steps = [
    'accueil',
    'contact',
    'groupe_maison',
    'bapteme',
  ];

  static const Map<String, String> stepLabels = {
    'accueil': 'Accueil',
    'contact': 'Premier Contact',
    'groupe_maison': 'Groupe de Maison',
    'bapteme': 'Baptême',
  };

  /// Valide une étape du parcours d'intégration
  Future<void> validateStep(Visitor visitor, String stepId) async {
    if (!steps.contains(stepId)) return;

    final updatedSteps = Map<String, DateTime?>.from(visitor.integrationSteps);
    updatedSteps[stepId] = DateTime.now();

    final updatedVisitor = visitor.copyWith(
      integrationSteps: updatedSteps,
    );

    await FirebaseService.updateVisitor(updatedVisitor);
  }

  /// Annule la validation d'une étape
  Future<void> unvalidateStep(Visitor visitor, String stepId) async {
    if (!steps.contains(stepId)) return;

    final updatedSteps = Map<String, DateTime?>.from(visitor.integrationSteps);
    updatedSteps[stepId] = null;

    final updatedVisitor = visitor.copyWith(
      integrationSteps: updatedSteps,
    );

    await FirebaseService.updateVisitor(updatedVisitor);
  }

  /// Récupère la progression actuelle (0.0 à 1.0)
  double getProgress(Visitor visitor) {
    int validated = 0;
    for (final step in steps) {
      if (visitor.integrationSteps[step] != null) {
        validated++;
      }
    }
    return validated / steps.length;
  }

  /// Vérifie si l'étape précédente est validée pour autoriser la suivante
  bool canValidateStep(Visitor visitor, String stepId) {
    final index = steps.indexOf(stepId);
    if (index == -1) return false;
    if (index == 0) return true;

    final previousStep = steps[index - 1];
    return visitor.integrationSteps[previousStep] != null;
  }
}
