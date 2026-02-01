import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/team_member.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
import '../widgets/sync_indicator.dart';
import 'qr_display_screen.dart';
import 'templates_screen.dart';
import 'audit_log_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _messageController = TextEditingController();
  bool _isLoadingMessage = true;
  bool _isSaving = false;
  DateTime? _lastSync;
  
  // Notification settings
  final _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _reminderJ3Enabled = true;
  bool _reminderTasksEnabled = true;
  int _notificationHour = 9;

  @override
  void initState() {
    super.initState();
    _loadAutoMessage();
    _loadNotificationSettings();
    _lastSync = DateTime.now();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoMessage() async {
    try {
      final message = await FirebaseService.getAutoMessage();
      _messageController.text = message ?? 
          "Bonjour [Prénom], c'est une joie de vous avoir accueilli ce dimanche ! N'hésitez pas à nous solliciter si vous avez des questions. Soyez béni(e) !";
    } finally {
      setState(() => _isLoadingMessage = false);
    }
  }

  Future<void> _saveMessage() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseService.updateAutoMessage(_messageController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message enregistré !'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _loadNotificationSettings() async {
    _notificationsEnabled = await _notificationService.notificationsEnabled;
    _reminderJ3Enabled = await _notificationService.reminderJ3Enabled;
    _reminderTasksEnabled = await _notificationService.reminderTasksEnabled;
    _notificationHour = await _notificationService.notificationHour;
    if (mounted) setState(() {});
  }

  void _showAddMemberDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final emailController = TextEditingController();
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un membre'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(
                labelText: 'Rôle (Admin, Éditeur, Membre)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: 'Code d\'accès',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    final code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
                    codeController.text = code;
                  },
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && codeController.text.isNotEmpty) {
                final member = TeamMember(
                  id: '',
                  nom: nameController.text,
                  role: roleController.text.isEmpty ? 'membre' : roleController.text,
                  email: emailController.text,
                  isAdmin: roleController.text.toLowerCase() == 'admin',
                  accessCode: codeController.text,
                );
                await FirebaseService.addTeamMember(member);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFF0F4F8)],
          ),
        ),
        child: Stack(
          children: [
            // Watermark
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: 0.03,
                  child: Icon(
                    Icons.church,
                    size: 300,
                    color: AppTheme.zoeBlue,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                   // Header Custom
                   Container(
                     width: double.infinity,
                     padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         colors: [
                           const Color(0xFF1B365D).withOpacity(0.1),
                           const Color(0xFFB41E3A).withOpacity(0.1),
                         ],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: const BorderRadius.only(
                         bottomLeft: Radius.circular(24),
                         bottomRight: Radius.circular(24),
                       ),
                     ),
                     child: const Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'CONFIGURATION',
                           style: TextStyle(
                             fontSize: 11,
                             fontWeight: FontWeight.w600,
                             color: Color(0xFF52606D),
                             letterSpacing: 1.2,
                           ),
                         ),
                         const SizedBox(height: 6),
                         Text(
                           'Administration',
                           style: TextStyle(
                             fontSize: 28,
                             fontWeight: FontWeight.bold,
                             color: Color(0xFF1B365D),
                           ),
                         ),
                       ],
                     ),
                   ),
                   
                   Expanded(
                     child: ListView(
                       padding: const EdgeInsets.all(20),
                       children: [
                         Text(
                           'Gérez l\'équipe et les paramètres système.',
                           style: TextStyle(
                             fontSize: 15,
                             color: Colors.grey[600],
                           ),
                         ),
                         const SizedBox(height: 32),
            
                        // QR Code Section
                        const Text(
                          'QR Code Visiteurs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const QrDisplayScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Afficher le QR Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'À afficher à l\'entrée de l\'église pour que les visiteurs s\'enregistrent.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Communication Section
                        const Text(
                          'Communication',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          child: ListTile(
                            leading: const Icon(Icons.message_outlined, color: AppTheme.primaryColor),
                            title: const Text('Templates WhatsApp'),
                            subtitle: const Text('Gérer les modèles de messages'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const TemplatesScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsCard(
                          child: ListTile(
                            leading: const Icon(Icons.security, color: AppTheme.accentOrange),
                            title: const Text('Journal d\'Audit'),
                            subtitle: const Text('Voir l\'historique des actions'),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AuditLogScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Synchronisation Status
                        const SyncIndicator(),
                        const SizedBox(height: 32),
                        
                        // Team Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Membres de l\'équipe',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: _showAddMemberDialog,
                              child: const Text('Ajouter'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Team List
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: StreamBuilder<List<TeamMember>>(
                            stream: FirebaseService.getTeamStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              
                              final members = snapshot.data ?? [];
                              
                              if (members.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Text(
                                      'Aucun membre',
                                      style: TextStyle(color: Colors.grey[400]),
                                    ),
                                  ),
                                );
                              }
                              
                              return Column(
                                children: members.map((member) {
                                  return _TeamMemberTile(member: member);
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Auto Message Section
                        const Text(
                          'Message Automatique',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isLoadingMessage
                              ? const Center(child: CircularProgressIndicator())
                              : TextField(
                                  controller: _messageController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: 'Message d\'accueil automatique...',
                                    filled: true,
                                    fillColor: AppTheme.backgroundGrey,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveMessage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Enregistrer les modifications',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Sync Status
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Synchronisation Firebase',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _lastSync != null
                                      ? 'Dernière synchro : il y a ${DateTime.now().difference(_lastSync!).inMinutes} min'
                                      : 'Synchronisé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                setState(() => _lastSync = DateTime.now());
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Synchronisation effectuée')),
                                );
                              },
                              icon: Icon(Icons.refresh, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Notification Settings Section
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildNotificationSwitch(
                                'Activer les notifications',
                                'Recevoir toutes les notifications',
                                Icons.notifications_outlined,
                                _notificationsEnabled,
                                (value) async {
                                  await _notificationService.setNotificationsEnabled(value);
                                  setState(() => _notificationsEnabled = value);
                                },
                              ),
                              const Divider(height: 24),
                              _buildNotificationSwitch(
                                'Rappel J+3',
                                'Notification 3 jours après inscription',
                                Icons.calendar_today_outlined,
                                _reminderJ3Enabled,
                                (value) async {
                                  await _notificationService.setReminderJ3Enabled(value);
                                  setState(() => _reminderJ3Enabled = value);
                                },
                              ),
                              const Divider(height: 24),
                              _buildNotificationSwitch(
                                'Rappel tâches',
                                'Notification quotidienne tâches en retard',
                                Icons.task_alt_outlined,
                                _reminderTasksEnabled,
                                (value) async {
                                  await _notificationService.setReminderTasksEnabled(value);
                                  setState(() => _reminderTasksEnabled = value);
                                },
                              ),
                              const Divider(height: 24),
                              Row(
                                children: [
                                  Icon(Icons.access_time, color: Colors.grey[400], size: 24),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Heure de notification',
                                          style: TextStyle(fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          'Notifications quotidiennes à ${_notificationHour}h00',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  DropdownButton<int>(
                                    value: _notificationHour,
                                    items: List.generate(24, (i) => i).map((hour) {
                                      return DropdownMenuItem(
                                        value: hour,
                                        child: Text('${hour}h'),
                                      );
                                    }).toList(),
                                    onChanged: (value) async {
                                      if (value != null) {
                                        await _notificationService.setNotificationHour(value);
                                        setState(() => _notificationHour = value);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                       ],
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNotificationSwitch(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentGreen,
        ),
      ],
    );
  }
  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  final TeamMember member;

  const _TeamMemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.getAvatarColor(member.nom).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                member.initials,
                style: TextStyle(
                  color: AppTheme.getAvatarColor(member.nom),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.nom,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  member.role,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Disponibilité & Charge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Switch(
                value: member.isAvailable,
                onChanged: (val) {
                  FirebaseService.updateTeamMember(member.copyWith(isAvailable: val));
                  FirebaseService.logAction(
                    action: 'update_availability',
                    details: 'Membre: ${member.nom}, Dispo: $val',
                  );
                },
                activeColor: AppTheme.accentGreen,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${member.activeTasksCount} tâches',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
