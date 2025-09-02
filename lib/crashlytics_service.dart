import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Initialiser Crashlytics
  static void initialize() {
    // Capturer les erreurs Flutter
    FlutterError.onError = (FlutterErrorDetails details) {
      _crashlytics.recordFlutterFatalError(details);
    };

    // Capturer les erreurs asynchrones
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Enregistrer une erreur non fatale
  static Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    await _crashlytics.recordError(
      exception,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );

    if (kDebugMode) {
      print('Crashlytics: Error recorded - $exception');
    }
  }

  // Enregistrer une erreur Flutter
  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterError(details);

    if (kDebugMode) {
      print('Crashlytics: Flutter error recorded - ${details.exception}');
    }
  }

  // Définir l'ID utilisateur
  static Future<void> setUserId(String userId) async {
    await _crashlytics.setUserIdentifier(userId);

    if (kDebugMode) {
      print('Crashlytics: User ID set - $userId');
    }
  }

  // Définir des clés personnalisées
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);

    if (kDebugMode) {
      print('Crashlytics: Custom key set - $key: $value');
    }
  }

  // Définir plusieurs clés personnalisées
  static Future<void> setCustomKeys(Map<String, dynamic> keys) async {
    for (final entry in keys.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value);
    }

    if (kDebugMode) {
      print('Crashlytics: Custom keys set - $keys');
    }
  }

  // Ajouter des logs personnalisés
  static Future<void> log(String message) async {
    await _crashlytics.log(message);

    if (kDebugMode) {
      print('Crashlytics: Log added - $message');
    }
  }

  // Forcer un crash pour les tests (uniquement en debug)
  static Future<void> crash() async {
    if (kDebugMode) {
      _crashlytics.crash();
    }
  }

  // Vérifier si l'application a crashé lors du dernier lancement
  static Future<bool> didCrashOnPreviousExecution() async {
    return await _crashlytics.didCrashOnPreviousExecution();
  }

  // Activer/désactiver la collecte de données
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);

    if (kDebugMode) {
      print('Crashlytics: Collection enabled - $enabled');
    }
  }

  // Méthodes utilitaires pour l'application TodoList
  static Future<void> logTodoAction(String action, String todoId) async {
    await log('Todo action: $action for todo: $todoId');
    await setCustomKey('last_todo_action', action);
    await setCustomKey('last_todo_id', todoId);
  }

  static Future<void> logAuthAction(String action, String? userId) async {
    await log('Auth action: $action for user: $userId');
    await setCustomKey('last_auth_action', action);
    if (userId != null) {
      await setUserId(userId);
    }
  }

  static Future<void> logErrorWithContext(
    String context,
    dynamic error,
    StackTrace? stackTrace,
  ) async {
    await recordError(error, stackTrace, reason: 'Error in context: $context');
    await setCustomKey('error_context', context);
  }
}


