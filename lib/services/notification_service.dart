import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  // Clés de préférences
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyReminderJ3Enabled = 'reminder_j3_enabled';
  static const String _keyReminderTasksEnabled = 'reminder_tasks_enabled';
  static const String _keyNotificationHour = 'notification_hour';
  
  // IDs de notifications
  static const int _dailyTaskReminderId = 1000;
  static const int _j3ReminderId = 2000;

  Future<void> initialize() async {
    // Initialiser les timezones
    tz_data.initializeTimeZones();
    
    // Configuration Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Demander les permissions sur Android 13+
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      // await android.requestExactAlarmsPermission(); // Désactivé pour éviter le blocage sur Android 12+ (Utilisation du mode inexact)
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification
    // Peut naviguer vers un écran spécifique selon le payload
    print('Notification tapped: ${response.payload}');
  }

  // === Préférences ===
  
  Future<bool> get notificationsEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }
  
  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
    if (!value) {
      await cancelAllNotifications();
    }
  }
  
  Future<bool> get reminderJ3Enabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderJ3Enabled) ?? true;
  }
  
  Future<void> setReminderJ3Enabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderJ3Enabled, value);
  }
  
  Future<bool> get reminderTasksEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReminderTasksEnabled) ?? true;
  }
  
  Future<void> setReminderTasksEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminderTasksEnabled, value);
  }
  
  Future<int> get notificationHour async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyNotificationHour) ?? 9; // 9h par défaut
  }
  
  Future<void> setNotificationHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNotificationHour, hour);
  }

  // === Notifications immédiates ===
  
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!await notificationsEnabled) return;
    
    const androidDetails = AndroidNotificationDetails(
      'zoe_church_channel',
      'Zoe Church Notifications',
      channelDescription: 'Notifications de suivi des visiteurs',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(id, title, body, details, payload: payload);
  }

  // === Notifications programmées ===
  
  /// Programmer un rappel J+3 pour un nouveau visiteur
  Future<void> scheduleJ3Reminder({
    required String visitorId,
    required String visitorName,
    required DateTime registrationDate,
  }) async {
    if (!await notificationsEnabled || !await reminderJ3Enabled) return;
    
    final hour = await notificationHour;
    final scheduledDate = registrationDate.add(const Duration(days: 3));
    final notificationTime = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      0,
    );
    
    // Ne pas programmer si la date est déjà passée
    if (notificationTime.isBefore(DateTime.now())) return;
    
    const androidDetails = AndroidNotificationDetails(
      'zoe_church_j3_channel',
      'Rappels J+3',
      channelDescription: 'Rappels pour contacter les nouveaux visiteurs',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    await _notifications.zonedSchedule(
      _j3ReminderId + visitorId.hashCode.abs() % 1000,
      '📞 Rappel : Contacter $visitorName',
      'Il est temps de recontacter ce visiteur enregistré il y a 3 jours !',
      tz.TZDateTime.from(notificationTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'visitor:$visitorId',
    );
  }

  /// Programmer un rappel quotidien pour les tâches en retard
  Future<void> scheduleDailyTaskReminder() async {
    if (!await notificationsEnabled || !await reminderTasksEnabled) return;
    
    final hour = await notificationHour;
    
    const androidDetails = AndroidNotificationDetails(
      'zoe_church_tasks_channel',
      'Rappels de tâches',
      channelDescription: 'Rappels quotidiens pour les tâches de suivi',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const details = NotificationDetails(android: androidDetails);
    
    // Programmer pour chaque jour à l'heure définie
    await _notifications.zonedSchedule(
      _dailyTaskReminderId,
      '📋 Tâches de suivi',
      'Vous avez des tâches de suivi à compléter aujourd\'hui.',
      _nextInstanceOfTime(hour, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'tasks',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // === Gestion des notifications ===
  
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  Future<void> cancelJ3Reminder(String visitorId) async {
    await _notifications.cancel(_j3ReminderId + visitorId.hashCode.abs() % 1000);
  }
  
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
  
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
