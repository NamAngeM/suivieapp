/// Constantes centralisées pour l'application Zoe Church Visitors.
/// Ce fichier regroupe toutes les valeurs constantes utilisées dans l'app.

class AppConstants {
  AppConstants._(); // Empêche l'instanciation

  // === DURÉES (Parcours d'intégration) ===
  
  /// Délai par défaut pour la première tâche de suivi (J+2)
  static const int defaultTaskDelayDays = 2;
  
  /// Délai pour le rappel J+3 des nouveaux visiteurs
  static const int j3ReminderDays = 3;
  
  /// Période de synchronisation des tâches automatiques (90 jours)
  static const int taskSyncPeriodDays = 90;
  
  /// Nombre de semaines pour les statistiques
  static const int statsWeekCount = 4;

  // === PRÉFÉRENCES (SharedPreferences keys) ===
  
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyReminderJ3Enabled = 'reminder_j3_enabled';
  static const String keyReminderTasksEnabled = 'reminder_tasks_enabled';
  static const String keyNotificationHour = 'notification_hour';
  
  /// Heure par défaut pour les notifications (9h)
  static const int defaultNotificationHour = 9;

  // === TÂCHES EN ARRIÈRE-PLAN ===
  
  static const String taskCheckOverdueTasks = 'check_overdue_tasks';
  static const String taskCheckJ3Visitors = 'check_j3_visitors';

  // === COLLECTIONS FIRESTORE ===
  
  static const String collectionVisitors = 'visitors';
  static const String collectionTasks = 'tasks';
  static const String collectionTeam = 'team';
  static const String collectionSettings = 'settings';
  static const String collectionTemplates = 'message_templates';
  static const String collectionAuditLogs = 'audit_logs';

  // === STATUTS ===
  
  static const String statusNew = 'nouveau';
  static const String statusInProgress = 'en_cours';
  static const String statusCompleted = 'termine';
  static const String statusTodo = 'a_faire';

  // === NOTIFICATIONS ===
  
  static const String notificationChannelId = 'zoe_church_channel';
  static const String notificationChannelName = 'Zoe Church Notifications';
  static const String notificationChannelDescription = 'Notifications de suivi des visiteurs';
  
  static const String notificationJ3ChannelId = 'zoe_church_j3_channel';
  static const String notificationJ3ChannelName = 'Rappels J+3';
  
  static const String notificationTasksChannelId = 'zoe_church_tasks_channel';
  static const String notificationTasksChannelName = 'Rappels de tâches';

  // === IDs DE NOTIFICATION ===
  
  static const int dailyTaskReminderId = 1000;
  static const int j3ReminderId = 2000;
}
