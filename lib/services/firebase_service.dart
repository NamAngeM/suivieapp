import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/visitor.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import '../models/interaction.dart';
import '../models/message_template.dart';
import '../models/audit_log_entry.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collections
  static CollectionReference get visitorsCollection => _firestore.collection('visitors');
  static CollectionReference get tasksCollection => _firestore.collection('tasks');
  static CollectionReference get teamCollection => _firestore.collection('team');
  static CollectionReference get settingsCollection => _firestore.collection('settings');
  static CollectionReference get templatesCollection => _firestore.collection('message_templates');
  static CollectionReference get auditCollection => _firestore.collection('audit_logs');

  // === AUTH ===
  static TeamMember? _currentUser;
  static TeamMember? get currentUser => _currentUser;

  static Future<bool> loginWithCode(String code) async {
    try {
      // Authentification sécurisée via Firebase Auth
      // Le "Code" est utilisé comme mot de passe pour le compte générique staff@zoe.church
      // Assurez-vous d'avoir créé cet utilisateur dans la console Firebase > Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'staff@zoe.church', // Email codé en dur pour simplifier l'accès par code unique
        password: code
      );
      
      // On définit un utilisateur générique pour la session
      // Idéalement, on pourrait récupérer le profil spécifique via une collection séparée si nécessaire
      _currentUser = TeamMember(
        id: 'staff_generic',
        nom: 'Staff Zoe',
        role: 'Bénévole',
        email: 'staff@zoe.church', // Required field
        accessCode: '****'
      );
      
      await logAction(action: 'login', details: 'Connexion Staff', performedBy: 'Staff Zoe');
      return true;
    } on FirebaseAuthException catch (e) {
      print('Auth Error: ${e.code}');
      return false;
    } catch (e) {
      print('Error logging in: $e');
      return false;
    }
  }
  
  static Future<void> logout() async {
    if (_currentUser != null) {
      await logAction(action: 'logout', details: 'Déconnexion de ${_currentUser!.nom}', performedBy: _currentUser!.nom);
    }
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
  }
  
  // Sous-collection interaction accessible via document visitor
  
  // === VISITORS ===
  
  static Future<String> addVisitor(Visitor visitor) async {
    final docRef = await visitorsCollection.add(visitor.toFirestore());
    return docRef.id;
  }
  
  static Future<void> updateVisitor(Visitor visitor) async {
    await visitorsCollection.doc(visitor.id).update(visitor.toFirestore());
  }
  
  static Future<void> deleteVisitor(String id) async {
    await visitorsCollection.doc(id).delete();
  }
  
  static Stream<List<Visitor>> getVisitorsStream() {
    return visitorsCollection
        .orderBy('dateEnregistrement', descending: true)
        .limit(50) // Performance: Limiter aux 50 derniers pour la liste principale
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Visitor.fromFirestore(doc)).toList());
  }
  
  static Future<List<Visitor>> getVisitors() async {
    final snapshot = await visitorsCollection
        .orderBy('dateEnregistrement', descending: true)
        .get();
    return snapshot.docs.map((doc) => Visitor.fromFirestore(doc)).toList();
  }
  
  static Future<Visitor?> getVisitor(String id) async {
    final doc = await visitorsCollection.doc(id).get();
    if (doc.exists) {
      return Visitor.fromFirestore(doc);
    }
    return null;
  }
  
  // === TASKS ===
  
  static Future<String> addTask(FollowUpTask task) async {
    final docRef = await tasksCollection.add(task.toFirestore());
    return docRef.id;
  }
  
  static Future<void> updateTask(FollowUpTask task) async {
    await tasksCollection.doc(task.id).update(task.toFirestore());
  }
  
  static Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await tasksCollection.doc(taskId).update({'statut': newStatus});
  }
  
  static Future<void> updateTaskNote(String taskId, String note) async {
    await tasksCollection.doc(taskId).update({'note': note});
  }
  
  static Stream<List<FollowUpTask>> getTasksStream() {
    return tasksCollection
        .orderBy('dateEcheance')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => FollowUpTask.fromFirestore(doc)).toList());
  }
  
  static Stream<List<FollowUpTask>> getTasksByStatusStream(String statut) {
    return tasksCollection
        .where('statut', isEqualTo: statut)
        .orderBy('dateEcheance')
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => FollowUpTask.fromFirestore(doc)).toList());
  }
  
  // === TEAM ===
  
  static Stream<List<TeamMember>> getTeamStream() {
    return teamCollection
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => TeamMember.fromFirestore(doc)).toList());
  }
  
  static Future<void> addTeamMember(TeamMember member) async {
    await teamCollection.add(member.toFirestore());
  }
  
  static Future<void> updateTeamMember(TeamMember member) async {
    await teamCollection.doc(member.id).update(member.toFirestore());
  }
  
  static Future<void> deleteTeamMember(String id) async {
    await teamCollection.doc(id).delete();
  }
  
  // === SETTINGS ===
  
  static Future<String?> getAutoMessage() async {
    final doc = await settingsCollection.doc('general').get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)['messageAutomatique'];
    }
    return null;
  }
  
  static Future<void> updateAutoMessage(String message) async {
    await settingsCollection.doc('general').set(
      {'messageAutomatique': message},
      SetOptions(merge: true),
    );
  }

  static Future<void> saveGoal(String key, int value) async {
    await settingsCollection.doc('goals').set(
      {key: value},
      SetOptions(merge: true),
    );
  }

  static Future<int> getGoal(String key) async {
    final doc = await settingsCollection.doc('goals').get();
    if (doc.exists) {
      return (doc.data() as Map<String, dynamic>)[key] ?? 0;
    }
    return 0;
    return 0;
  }

  // === INTERACTIONS ===

  static Future<void> addInteraction(Interaction interaction) async {
    await visitorsCollection
        .doc(interaction.visitorId)
        .collection('interactions')
        .add(interaction.toFirestore());
  }

  static Stream<List<Interaction>> getInteractionsStream(String visitorId) {
    return visitorsCollection
        .doc(visitorId)
        .collection('interactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => Interaction.fromFirestore(doc)).toList());
  }

  // === MESSAGE TEMPLATES ===

  static Future<void> addMessageTemplate(MessageTemplate template) async {
    await templatesCollection.add(template.toFirestore());
  }

  static Future<void> updateMessageTemplate(MessageTemplate template) async {
    await templatesCollection.doc(template.id).update(template.toFirestore());
  }

  static Future<void> deleteMessageTemplate(String id) async {
    await templatesCollection.doc(id).delete();
  }

  static Stream<List<MessageTemplate>> getMessageTemplatesStream() {
    return templatesCollection
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MessageTemplate.fromFirestore(doc)).toList());
  }

  // === AUDIT LOG ===

  static Future<void> logAction({
    required String action,
    required String details,
    String performedBy = 'System', // TODO: user actuel
  }) async {
    final entry = AuditLogEntry(
      id: '',
      action: action,
      details: details,
      performedBy: performedBy,
      timestamp: DateTime.now(),
    );
    await auditCollection.add(entry.toFirestore());
  }
  
  static Stream<List<AuditLogEntry>> getAuditLogsStream() {
    return auditCollection
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => AuditLogEntry.fromFirestore(doc)).toList());
  }
  
  // === STATISTICS ===
  
  static Future<Map<String, dynamic>> getStatistics() async {
    final visitors = await getVisitors();
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    
    // Visiteurs ce mois
    final visitorsThisMonth = visitors.where(
      (v) => v.dateEnregistrement.isAfter(thisMonth)
    ).length;
    
    // Taux de rétention (visiteurs contactés / total)
    final contacted = visitors.where((v) => v.statut != 'nouveau').length;
    final retentionRate = visitors.isNotEmpty 
        ? (contacted / visitors.length * 100).round() 
        : 0;
    
    // Demandes de prière
    final prayerRequests = visitors.where(
      (v) => v.requetePriere != null && v.requetePriere!.isNotEmpty
    ).length;
    
    // Sources d'invitation
    final sourceMap = <String, int>{};
    for (final v in visitors) {
      sourceMap[v.commentConnu] = (sourceMap[v.commentConnu] ?? 0) + 1;
    }
    
    // Répartition par quartier
    final quartierMap = <String, int>{};
    for (final v in visitors) {
      quartierMap[v.quartier] = (quartierMap[v.quartier] ?? 0) + 1;
    }
    
    // Croissance par semaine (12 dernières semaines)
    final weeklyGrowth = <int>[];
    for (int i = 11; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: 7 * i + now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final count = visitors.where(
        (v) => v.dateEnregistrement.isAfter(weekStart) && 
               v.dateEnregistrement.isBefore(weekEnd)
      ).length;
      weeklyGrowth.add(count);
    }
    
    return {
      'totalVisitors': visitors.length,
      'visitorsThisMonth': visitorsThisMonth,
      'retentionRate': retentionRate,
      'prayerRequests': prayerRequests,
      'sourceDistribution': sourceMap,
      'quartierDistribution': quartierMap,
      'weeklyGrowth': weeklyGrowth,
    };
  }

  static Future<Map<String, dynamic>> getDetailedStatistics(DateTime start, DateTime end) async {
    final visitors = await getVisitors();
    
    // Filtrer par période
    final periodVisitors = visitors.where((v) => 
      v.dateEnregistrement.isAfter(start) && 
      v.dateEnregistrement.isBefore(end.add(const Duration(days: 1))) // Inclure le jour de fin
    ).toList();
    
    // Comparaison (période précédente)
    final duration = end.difference(start);
    final previousStart = start.subtract(duration);
    final previousEnd = start.subtract(const Duration(days: 1));
    
    final previousVisitors = visitors.where((v) => 
      v.dateEnregistrement.isAfter(previousStart) && 
      v.dateEnregistrement.isBefore(previousEnd.add(const Duration(days: 1)))
    ).toList();
    
    // Calculs
    final totalVisitors = periodVisitors.length;
    final previousTotal = previousVisitors.length;
    final growth = previousTotal > 0 
        ? ((totalVisitors - previousTotal) / previousTotal * 100).round()
        : 100;

    // Contactés
    final contacted = periodVisitors.where((v) => v.statut != 'nouveau').length;
    final retentionRate = totalVisitors > 0 
        ? (contacted / totalVisitors * 100).round() 
        : 0;

    return {
      'visitors': periodVisitors,
      'totalVisitors': totalVisitors,
      'previousTotal': previousTotal,
      'growth': growth,
      'retentionRate': retentionRate,
      'prayerRequests': periodVisitors.where((v) => v.requetePriere != null && v.requetePriere!.isNotEmpty).length,
      'visitorsTopMonth': periodVisitors.length, // Pour compatibilité PDF
    };
  }
}
