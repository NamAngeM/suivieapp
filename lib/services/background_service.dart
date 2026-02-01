import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'notification_service.dart';

/// Callback exécuté en arrière-plan par WorkManager
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      // Initialiser Firebase en arrière-plan
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      final notificationService = NotificationService();
      await notificationService.initialize();
      
      switch (taskName) {
        case BackgroundService.taskCheckOverdueTasks:
          await _checkOverdueTasks(notificationService);
          break;
        case BackgroundService.taskCheckJ3Visitors:
          await _checkJ3Visitors(notificationService);
          break;
      }
      
      return true;
    } catch (e) {
      print('Background task error: $e');
      return false;
    }
  });
}

/// Vérifie les tâches en retard
Future<void> _checkOverdueTasks(NotificationService notificationService) async {
  if (!await notificationService.reminderTasksEnabled) return;
  
  final now = DateTime.now();
  final snapshot = await FirebaseFirestore.instance
      .collection('tasks')
      .where('statut', isEqualTo: 'a_faire')
      .where('dateEcheance', isLessThan: Timestamp.fromDate(now))
      .get();
  
  if (snapshot.docs.isNotEmpty) {
    final count = snapshot.docs.length;
    await notificationService.showNotification(
      id: 100,
      title: '⚠️ $count tâche${count > 1 ? 's' : ''} en retard',
      body: 'Vous avez des visiteurs à contacter. Appuyez pour voir la liste.',
      payload: 'overdue_tasks',
    );
  }
}

/// Vérifie les visiteurs à J+3
Future<void> _checkJ3Visitors(NotificationService notificationService) async {
  if (!await notificationService.reminderJ3Enabled) return;
  
  final now = DateTime.now();
  final threeDaysAgo = now.subtract(const Duration(days: 3));
  final fourDaysAgo = now.subtract(const Duration(days: 4));
  
  // Visiteurs enregistrés il y a exactement 3 jours
  final snapshot = await FirebaseFirestore.instance
      .collection('visitors')
      .where('dateEnregistrement', isGreaterThan: Timestamp.fromDate(fourDaysAgo))
      .where('dateEnregistrement', isLessThan: Timestamp.fromDate(threeDaysAgo))
      .where('statut', isEqualTo: 'nouveau')
      .get();
  
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final visitorName = data['nomComplet'] ?? 'Visiteur';
    
    await notificationService.showNotification(
      id: 200 + doc.id.hashCode.abs() % 800,
      title: '📞 Rappel J+3 : $visitorName',
      body: 'Il est temps de contacter ce nouveau membre !',
      payload: 'visitor:${doc.id}',
    );
  }
}

class BackgroundService {
  static const String taskCheckOverdueTasks = 'check_overdue_tasks';
  static const String taskCheckJ3Visitors = 'check_j3_visitors';
  
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }
  
  /// Programme les tâches quotidiennes
  static Future<void> schedulePeriodicTasks() async {
    // Vérification des tâches en retard - chaque jour
    await Workmanager().registerPeriodicTask(
      'daily-overdue-check',
      taskCheckOverdueTasks,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
    
    // Vérification des visiteurs J+3 - chaque jour
    await Workmanager().registerPeriodicTask(
      'daily-j3-check',
      taskCheckJ3Visitors,
      frequency: const Duration(hours: 24),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
  
  /// Annule toutes les tâches en arrière-plan
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
  }
}
