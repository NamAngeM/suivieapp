import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:sqflite/sqflite.dart';
// import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'; // REMOVED for build stability
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/visitor.dart';
import 'follow_up_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  Database? _database;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  final _onlineController = StreamController<bool>.broadcast();
  final _pendingCountController = StreamController<int>.broadcast();
  
  Stream<bool> get onlineStream => _onlineController.stream;
  Stream<int> get pendingCountStream => _pendingCountController.stream;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await _initDatabase();
    await _checkConnectivity();
    _startConnectivityListener();
  }

  Future<void> _initDatabase() async {
    if (kIsWeb) {
      // Sur le web, on utilise pas SQLite pour l'instant (Online Only)
      // TODO: Implémenter Hive ou SharedPreferences si besoin d'offline web
      return;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'zoe_church_offline.db');
    
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_visitors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            nom_complet TEXT NOT NULL,
            sexe TEXT NOT NULL,
            telephone TEXT NOT NULL,
            quartier TEXT NOT NULL,
            statut_matrimonial TEXT NOT NULL,
            email TEXT,
            comment_connu TEXT NOT NULL,
            premiere_visite INTEGER NOT NULL,
            requete_priere TEXT,
            souhaite_etre_recontacte INTEGER NOT NULL,
            recevoir_actualites INTEGER NOT NULL,
            date_enregistrement TEXT NOT NULL,
            created_at TEXT NOT NULL,
            baptise INTEGER DEFAULT 0,
            souhaite_rejoindre_groupe INTEGER DEFAULT 0,
            note_experience INTEGER DEFAULT 3,
            points_forts TEXT,
            commentaire_libre TEXT,
            besoin_prioritaire TEXT,
            voeu_service INTEGER DEFAULT 0,
            domaine_souhaite TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN baptise INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN souhaite_rejoindre_groupe INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN note_experience INTEGER DEFAULT 3');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN points_forts TEXT');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN commentaire_libre TEXT');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN besoin_prioritaire TEXT');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN voeu_service INTEGER DEFAULT 0');
          await db.execute('ALTER TABLE pending_visitors ADD COLUMN domaine_souhaite TEXT');
        }
      },
    );
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateOnlineStatus(results);
  }

  void _startConnectivityListener() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateOnlineStatus(results);
    });
  }

  void _updateOnlineStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    _onlineController.add(_isOnline);
    
    // Si on vient de passer en ligne, synchroniser
    if (!wasOnline && _isOnline) {
      syncPendingVisitors();
    }
  }

  /// Sauvegarder un visiteur (en ligne ou hors-ligne)
  Future<String> saveVisitor(Visitor visitor) async {
    if (_isOnline) {
      // En ligne : sauvegarder directement dans Firestore
      try {
        final docRef = await FirebaseFirestore.instance
            .collection('visitors')
            .add(visitor.toFirestore());
        return docRef.id;
      } catch (e) {
        // Si erreur réseau, sauvegarder localement
        await _saveVisitorLocally(visitor);
        return 'pending_${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      // Hors-ligne : sauvegarder localement
      await _saveVisitorLocally(visitor);
      return 'pending_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> _saveVisitorLocally(Visitor visitor) async {
    if (_database == null) return;
    
    await _database!.insert('pending_visitors', {
      'nom_complet': visitor.nomComplet,
      'sexe': visitor.sexe,
      'telephone': visitor.telephone,
      'quartier': visitor.quartier,
      'statut_matrimonial': visitor.statutMatrimonial,
      'email': visitor.email,
      'comment_connu': visitor.commentConnu,
      'premiere_visite': visitor.premiereVisite ? 1 : 0,
      'requete_priere': visitor.requetePriere,
      'souhaite_etre_recontacte': visitor.souhaiteEtreRecontacte ? 1 : 0,
      'recevoir_actualites': visitor.recevoirActualites ? 1 : 0,
      'date_enregistrement': visitor.dateEnregistrement.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'baptise': visitor.baptise ? 1 : 0,
      'souhaite_rejoindre_groupe': visitor.souhaiteRejoindreGroupe ? 1 : 0,
      'note_experience': visitor.noteExperience,
      'points_forts': visitor.pointsForts.join(','),
      'commentaire_libre': visitor.commentaireLibre,
      'besoin_prioritaire': visitor.besoinPrioritaire,
      'voeu_service': visitor.voeuService ? 1 : 0,
      'domaine_souhaite': visitor.domaineSouhaite,
    });
    
    _updatePendingCount();
  }

  /// Obtenir le nombre de visiteurs en attente de synchronisation
  Future<int> getPendingCount() async {
    if (_database == null) return 0;
    try {
      final result = await _database!.rawQuery('SELECT COUNT(*) as count FROM pending_visitors');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updatePendingCount() async {
    final count = await getPendingCount();
    _pendingCountController.add(count);
  }

  /// Synchroniser les visiteurs en attente
  Future<int> syncPendingVisitors() async {
    if (!_isOnline || _database == null) return 0;
    
    final pendingVisitors = await _database!.query('pending_visitors');
    int synced = 0;
    
    for (final row in pendingVisitors) {
      try {
        final visitor = Visitor(
          id: '',
          nomComplet: row['nom_complet'] as String,
          sexe: row['sexe'] as String,
          telephone: row['telephone'] as String,
          quartier: row['quartier'] as String,
          statutMatrimonial: row['statut_matrimonial'] as String,
          email: row['email'] as String?,
          commentConnu: row['comment_connu'] as String,
          premiereVisite: (row['premiere_visite'] as int) == 1,
          requetePriere: row['requete_priere'] as String?,
          souhaiteEtreRecontacte: (row['souhaite_etre_recontacte'] as int) == 1,
          recevoirActualites: (row['recevoir_actualites'] as int) == 1,
          dateEnregistrement: DateTime.parse(row['date_enregistrement'] as String),
          baptise: (row['baptise'] as int? ?? 0) == 1,
          souhaiteRejoindreGroupe: (row['souhaite_rejoindre_groupe'] as int? ?? 0) == 1,
          noteExperience: row['note_experience'] as int? ?? 3,
          pointsForts: (row['points_forts'] as String?)?.split(',').where((e) => e.isNotEmpty).toList() ?? [],
          commentaireLibre: row['commentaire_libre'] as String?,
          besoinPrioritaire: row['besoin_prioritaire'] as String?,
          voeuService: (row['voeu_service'] as int? ?? 0) == 1,
          domaineSouhaite: row['domaine_souhaite'] as String?,
        );
        
        final docRef = await FirebaseFirestore.instance
            .collection('visitors')
            .add(visitor.toFirestore());

        // Générer les tâches de suivi pour ce visiteur maintenant qu'il est synchronisé
        await FollowUpService.generateTasksForVisitor(
          visitor.copyWith(id: docRef.id),
        );
        
        // Supprimer de la base locale après synchronisation réussie
        await _database!.delete(
          'pending_visitors',
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        
        synced++;
      } catch (e) {
        // Erreur de sync, réessayer plus tard
        debugPrint('Erreur sync visiteur: $e');
      }
    }
    
    _updatePendingCount();
    return synced;
  }

  /// Vérifier si un visiteur existe déjà par numéro de téléphone
  Future<Visitor?> findVisitorByPhone(String phone) async {
    if (!_isOnline) return null;
    
    try {
      final normalizedPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final snapshot = await FirebaseFirestore.instance
          .collection('visitors')
          .where('telephone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return Visitor.fromFirestore(snapshot.docs.first);
      }
    } catch (e) {
      print('Erreur recherche visiteur: $e');
    }
    return null;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _onlineController.close();
    _pendingCountController.close();
    _database?.close();
  }
}
