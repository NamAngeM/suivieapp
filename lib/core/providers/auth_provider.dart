import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/team_member.dart';
import '../../services/firebase_service.dart';
import '../utils/app_logger.dart';

/// État d'authentification
class AuthState {
  final TeamMember? currentUser;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  AuthState copyWith({
    TeamMember? currentUser,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier pour la gestion de l'état d'authentification
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final user = FirebaseService.currentUser;
    if (user != null) {
      state = AuthState(
        currentUser: user,
        isAuthenticated: true,
      );
    }
  }

  /// Connexion avec un code d'accès
  Future<bool> login(String accessCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final success = await FirebaseService.loginWithCode(accessCode);
      
      if (success) {
        state = AuthState(
          currentUser: FirebaseService.currentUser,
          isAuthenticated: true,
          isLoading: false,
        );
        AppLogger.info('Connexion réussie', tag: 'Auth');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Code d\'accès invalide',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error('Erreur de connexion', tag: 'Auth', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur de connexion: $e',
      );
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await FirebaseService.logout();
      state = const AuthState();
      AppLogger.info('Déconnexion réussie', tag: 'Auth');
    } catch (e) {
      AppLogger.error('Erreur de déconnexion', tag: 'Auth', error: e);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Réinitialiser le message d'erreur
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider global pour l'authentification
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// Provider pour accéder rapidement à l'utilisateur courant
final currentUserProvider = Provider<TeamMember?>((ref) {
  return ref.watch(authProvider).currentUser;
});

/// Provider pour vérifier si l'utilisateur est admin
final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdmin ?? false;
});
