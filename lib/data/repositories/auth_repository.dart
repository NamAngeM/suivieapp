import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/team_member.dart';
import '../../core/utils/app_logger.dart';

/// Repository pour la gestion de l'authentification
class AuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  TeamMember? _currentUser;
  TeamMember? get currentUser => _currentUser;

  /// Connexion avec code d'accès
  Future<bool> loginWithCode(String code) async {
    try {
      // 1. Vérifier si c'est le code Master
      try {
        final securityDoc = await _firestore.collection('settings').doc('security').get();
        String? masterCode;
        
        if (securityDoc.exists) {
          masterCode = securityDoc.data()?['masterCode'];
        } else {
          masterCode = '123456'; // Fallback pour première installation
        }

        if (masterCode != null && code == masterCode) {
          _currentUser = TeamMember(
            id: 'admin_master',
            nom: 'Admin Master',
            role: 'Super Admin',
            email: 'admin@zoe.church',
            isAdmin: true,
            accessCode: code,
          );
          await _logAction('login', 'Connexion Super Admin', 'Admin Master');
          return true;
        }
      } catch (e) {
        // Fallback de sécurité
        if (code == '123456') {
          _currentUser = TeamMember(
            id: 'admin_master',
            nom: 'Admin Master',
            role: 'Super Admin',
            email: 'admin@zoe.church',
            isAdmin: true,
            accessCode: code,
          );
          return true;
        }
        rethrow;
      }

      // 2. Authentification Firebase Auth
      await _auth.signInWithEmailAndPassword(
        email: 'staff@zoe.church',
        password: code,
      );
      
      // 3. Recherche du membre dans la collection 'team'
      final snapshot = await _firestore
          .collection('team')
          .where('accessCode', isEqualTo: code)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        _currentUser = TeamMember.fromFirestore(snapshot.docs.first);
        await _logAction('login', 'Connexion de ${_currentUser!.nom}', _currentUser!.nom);
        return true;
      } else {
        await _auth.signOut();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Auth Error', tag: 'AuthRepository', error: e);
      return false;
    } catch (e) {
      AppLogger.error('Error logging in', tag: 'AuthRepository', error: e);
      return false;
    }
  }
  
  /// Déconnexion
  Future<void> logout() async {
    if (_currentUser != null) {
      await _logAction('logout', 'Déconnexion de ${_currentUser!.nom}', _currentUser!.nom);
    }
    await _auth.signOut();
    _currentUser = null;
  }

  /// Log une action (audit)
  Future<void> _logAction(String action, String details, String performedBy) async {
    try {
      await _firestore.collection('audit_logs').add({
        'action': action,
        'details': details,
        'performedBy': performedBy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.error('Error logging action', tag: 'AuthRepository', error: e);
    }
  }
}
