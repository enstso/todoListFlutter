import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer = FirebaseAnalyticsObserver(
    analytics: _analytics,
  );

  static FirebaseAnalyticsObserver get observer => _observer;

  // Événements d'authentification
  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    if (kDebugMode) {
      print('Analytics: User signed up with $method');
    }
  }

  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    if (kDebugMode) {
      print('Analytics: User logged in with $method');
    }
  }

  static Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    if (kDebugMode) {
      print('Analytics: User logged out');
    }
  }

  // Événements des todos
  static Future<void> logTodoCreated() async {
    await _analytics.logEvent(
      name: 'todo_created',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    if (kDebugMode) {
      print('Analytics: Todo created');
    }
  }

  static Future<void> logTodoCompleted() async {
    await _analytics.logEvent(
      name: 'todo_completed',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    if (kDebugMode) {
      print('Analytics: Todo completed');
    }
  }

  static Future<void> logTodoUpdated() async {
    await _analytics.logEvent(
      name: 'todo_updated',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    if (kDebugMode) {
      print('Analytics: Todo updated');
    }
  }

  static Future<void> logTodoDeleted() async {
    await _analytics.logEvent(
      name: 'todo_deleted',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    if (kDebugMode) {
      print('Analytics: Todo deleted');
    }
  }

  static Future<void> logAllTodosDeleted() async {
    await _analytics.logEvent(
      name: 'all_todos_deleted',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    if (kDebugMode) {
      print('Analytics: All todos deleted');
    }
  }

  static Future<void> logCompletedTodosDeleted() async {
    await _analytics.logEvent(
      name: 'completed_todos_deleted',
      parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
    if (kDebugMode) {
      print('Analytics: Completed todos deleted');
    }
  }

  // Événements de navigation
  static Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
    if (kDebugMode) {
      print('Analytics: Screen view - $screenName');
    }
  }

  // Événements d'erreur
  static Future<void> logError(String error, String? stackTrace) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error': error,
        'stack_trace': stackTrace ?? 'No stack trace',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    if (kDebugMode) {
      print('Analytics: Error logged - $error');
    }
  }

  // Événements personnalisés
  static Future<void> logCustomEvent(
    String eventName, {
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: eventName, parameters: parameters);
    if (kDebugMode) {
      print('Analytics: Custom event - $eventName');
    }
  }

  // Définir les propriétés utilisateur
  static Future<void> setUserProperty(String name, String? value) async {
    await _analytics.setUserProperty(name: name, value: value);
    if (kDebugMode) {
      print('Analytics: User property set - $name: $value');
    }
  }

  // Définir l'ID utilisateur
  static Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    if (kDebugMode) {
      print('Analytics: User ID set - $userId');
    }
  }

  // Obtenir l'ID d'instance
  static Future<String?> getAppInstanceId() async {
    return await _analytics.appInstanceId;
  }

  // Réinitialiser les données analytiques
  static Future<void> resetAnalyticsData() async {
    await _analytics.resetAnalyticsData();
    if (kDebugMode) {
      print('Analytics: Data reset');
    }
  }
}
