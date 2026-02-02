import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/integration_step.dart';
import '../models/visitor.dart';
import '../config/theme.dart';
import '../services/firebase_service.dart';

class IntegrationTimelineWidget extends StatelessWidget {
  final Visitor visitor;
  final Function(IntegrationStep, StepStatus) onStatusChanged;

  const IntegrationTimelineWidget({
    super.key,
    required this.visitor,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressBar(context),
        const SizedBox(height: 24),
        _buildGroupedTimeline(context),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context) {
    final completedCount = visitor.integrationPath.where((s) => s.status == StepStatus.completed).length;
    final total = visitor.integrationPath.length;
    final progress = total > 0 ? completedCount / total : 0.0;
    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression Intégration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getProgressLabel(percentage),
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedTimeline(BuildContext context) {
    final groupedSteps = <String, List<IntegrationStep>>{};
    for (var step in visitor.integrationPath) {
      final phase = step.phase.isEmpty ? 'Général' : step.phase;
      groupedSteps.putIfAbsent(phase, () => []).add(step);
    }

    return Column(
      children: groupedSteps.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.zoeBlue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.zoeBlue,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            ...entry.value.asMap().entries.map((stepEntry) {
              final step = stepEntry.value;
              final isLastInPhase = stepEntry.key == entry.value.length - 1;
              final isLastInTotal = step.id == visitor.integrationPath.last.id;
              return _buildStepItem(context, step, isLastInTotal);
            }).toList(),
          ],
        );
      }).toList(),
    );
  }

  String _getProgressLabel(int percentage) {
    if (percentage == 100) return 'Membre Actif & Engagé ! 🎉';
    if (percentage >= 80) return 'Presque arrivé !';
    if (percentage >= 50) return 'En bonne voie...';
    return 'Début du parcours';
  }

  Widget _buildStepItem(BuildContext context, IntegrationStep step, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              GestureDetector(
                onTap: step.status != StepStatus.locked 
                    ? () => _showStatusSheet(context, step)
                    : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getStatusColor(step.status),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getStatusBorderColor(step.status),
                      width: 2,
                    ),
                    boxShadow: step.status == StepStatus.inProgress
                        ? [BoxShadow(color: AppTheme.zoeBlue.withOpacity(0.3), blurRadius: 8)]
                        : null,
                  ),
                  child: Center(
                    child: _getStatusIcon(step.status),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0, top: 4),
              child: InkWell(
                onTap: step.status != StepStatus.locked 
                    ? () => _showStatusSheet(context, step)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: step.status == StepStatus.locked 
                            ? Colors.grey 
                            : AppTheme.textPrimary,
                      ),
                    ),
                    if (step.subtitle != null)
                      Text(
                        step.subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    _buildStatusBadge(step),
                    if (step.updatedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          step.status == StepStatus.completed 
                              ? 'Validé le ${DateFormat('dd/MM/yyyy').format(step.updatedAt!)}'
                              : 'Mis à jour le ${DateFormat('dd/MM/yyyy').format(step.updatedAt!)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    if (step.notes != null && step.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            step.notes!,
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusSheet(BuildContext context, IntegrationStep step) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier l\'étape : ${step.title}', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppTheme.zoeBlue),
              title: const Text('Marquer comme terminé'),
              onTap: () {
                Navigator.pop(context);
                onStatusChanged(step, StepStatus.completed);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: AppTheme.accentOrange),
              title: const Text('Marquer en cours'),
              onTap: () {
                Navigator.pop(context);
                onStatusChanged(step, StepStatus.inProgress);
              },
            ),
            if (step.id != 'accueil') // On ne verrouille pas l'accueil
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.grey),
                title: const Text('Verrouiller / Réinitialiser'),
                onTap: () {
                  Navigator.pop(context);
                  onStatusChanged(step, StepStatus.locked);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(IntegrationStep step) {
    String label;
    Color color;
    switch (step.status) {
      case StepStatus.completed:
        label = 'Complété';
        color = AppTheme.zoeBlue;
        break;
      case StepStatus.inProgress:
        label = 'En cours';
        color = AppTheme.accentOrange;
        break;
      case StepStatus.locked:
        label = 'À venir';
        color = Colors.grey;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(StepStatus status) {
    switch (status) {
      case StepStatus.completed: return AppTheme.zoeBlue;
      case StepStatus.inProgress: return Colors.white;
      case StepStatus.locked: return Colors.grey.shade200;
    }
  }

  Color _getStatusBorderColor(StepStatus status) {
    switch (status) {
      case StepStatus.completed: return AppTheme.zoeBlue;
      case StepStatus.inProgress: return AppTheme.accentOrange;
      case StepStatus.locked: return Colors.grey.shade400;
    }
  }

  Widget _getStatusIcon(StepStatus status) {
    switch (status) {
      case StepStatus.completed: 
        return const Icon(Icons.check, color: Colors.white, size: 20);
      case StepStatus.inProgress:
        return Icon(Icons.timelapse, color: AppTheme.accentOrange, size: 20); // Animé ?
      case StepStatus.locked:
        return Icon(Icons.lock_outline, color: Colors.grey.shade500, size: 18);
    }
  }
}
