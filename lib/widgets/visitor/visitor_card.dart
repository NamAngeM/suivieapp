import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/visitor.dart';

/// Card displaying visitor information with progress indicator
class VisitorCard extends StatelessWidget {
  final Visitor visitor;
  final String? assignedMemberName;
  final VoidCallback onWhatsApp;
  final VoidCallback onSMS;
  final VoidCallback onCall;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VisitorCard({
    super.key,
    required this.visitor,
    this.assignedMemberName,
    required this.onWhatsApp,
    required this.onSMS,
    required this.onCall,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMM.', 'fr_FR').format(visitor.dateEnregistrement);
    final avatarColor = AppTheme.getAvatarColor(visitor.nomComplet);
    
    // Calculate progress
    final totalSteps = visitor.integrationPath.length;
    final completedSteps = visitor.integrationPath.where((s) => s.status.name == 'completed').length;
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Progress Indicator
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54, 
                    height: 54,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade100,
                      color: AppTheme.zoeBlue,
                      strokeWidth: 3,
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: avatarColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        visitor.initials,
                        style: TextStyle(
                          color: avatarColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            visitor.nomComplet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: visitor.statut == 'nouveau' 
                                ? AppTheme.zoeBlue 
                                : AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${visitor.quartier} · $dateFormatted',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    if (assignedMemberName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 12, color: AppTheme.zoeBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Assigné à : $assignedMemberName',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.zoeBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Menu Options
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20, color: AppTheme.zoeBlue),
                        SizedBox(width: 12),
                        Text('Modifier'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'WhatsApp',
                color: AppTheme.zoeBlue,
                onTap: onWhatsApp,
              ),
              ActionButton(
                icon: Icons.sms_outlined,
                label: 'SMS',
                color: Colors.blue,
                onTap: onSMS,
              ),
              ActionButton(
                icon: Icons.phone_outlined,
                label: 'Appel',
                color: AppTheme.textSecondary,
                onTap: onCall,
              ),
              ActionButton(
                icon: Icons.info_outline,
                label: 'Détails',
                color: AppTheme.textSecondary,
                onTap: onDetails,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Action button for visitor card
class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
