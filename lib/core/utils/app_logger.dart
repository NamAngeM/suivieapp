import 'package:flutter/foundation.dart';

/// Service de logging centralisé pour l'application.
/// En mode debug: affiche les logs dans la console.
/// En mode release: logs silencieux (prêt pour integration avec Crashlytics/Sentry).
class AppLogger {
  static const String _tag = 'ZoeChurch';

  /// Log d'information générale
  static void info(String message, {String? tag}) {
    _log('INFO', tag ?? _tag, message);
  }

  /// Log d'erreur
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log('ERROR', tag ?? _tag, message);
    if (error != null) {
      _log('ERROR', tag ?? _tag, 'Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
    // TODO: En production, envoyer à Crashlytics/Sentry
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Log de warning
  static void warning(String message, {String? tag}) {
    _log('WARN', tag ?? _tag, message);
  }

  /// Log de debug (uniquement en mode debug)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log('DEBUG', tag ?? _tag, message);
    }
  }

  static void _log(String level, String tag, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String().substring(11, 19);
      debugPrint('[$timestamp][$level][$tag] $message');
    }
  }
}
