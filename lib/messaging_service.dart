import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class MessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;

  // Initialiser le service de messagerie
  static Future<void> initialize() async {
    // Demander la permission pour les notifications
    await _requestPermission();

    // Obtenir le token FCM
    await _getFCMToken();

    // Configurer les gestionnaires de messages
    _setupMessageHandlers();
  }

  // Demander la permission pour les notifications
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('Messaging: Permission status - ${settings.authorizationStatus}');
    }
  }

  // Obtenir le token FCM
  static Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('Messaging: FCM Token - $_fcmToken');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Messaging: Error getting FCM token - $e');
      }
    }
  }

  // Configurer les gestionnaires de messages
  static void _setupMessageHandlers() {
    // Message en arrière-plan
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Message en premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Notification tapée
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Notification tapée quand l'app est fermée
    _handleInitialMessage();
  }

  // Gestionnaire de message en arrière-plan
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    if (kDebugMode) {
      print('Messaging: Background message received - ${message.messageId}');
    }
  }

  // Gestionnaire de message en premier plan
  static void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Messaging: Foreground message received - ${message.messageId}');
    }

    // Afficher une notification locale ou une snackbar
    _showLocalNotification(message);
  }

  // Gestionnaire de notification tapée
  static void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) {
      print('Messaging: Notification tapped - ${message.messageId}');
    }

    // Naviguer vers la page appropriée
    _navigateToPage(message);
  }

  // Gestionnaire de message initial
  static Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  // Afficher une notification locale
  static void _showLocalNotification(RemoteMessage message) {
    // Ici vous pouvez utiliser flutter_local_notifications
    // pour afficher une notification locale
    if (kDebugMode) {
      print('Messaging: Showing local notification - ${message.notification?.title}');
    }
  }

  // Naviguer vers la page appropriée
  static void _navigateToPage(RemoteMessage message) {
    final data = message.data;
    if (kDebugMode) {
      print('Messaging: Navigating to page - $data');
    }

    // Ici vous pouvez implémenter la navigation
    // basée sur les données du message
  }

  // S'abonner à un topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Messaging: Subscribed to topic - $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Messaging: Error subscribing to topic - $e');
      }
    }
  }

  // Se désabonner d'un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Messaging: Unsubscribed from topic - $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Messaging: Error unsubscribing from topic - $e');
      }
    }
  }

  // Obtenir un nouveau token
  static Future<String?> refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (kDebugMode) {
        print('Messaging: Token refreshed - $_fcmToken');
      }
      return _fcmToken;
    } catch (e) {
      if (kDebugMode) {
        print('Messaging: Error refreshing token - $e');
      }
      return null;
    }
  }

  // Supprimer le token
  static Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      if (kDebugMode) {
        print('Messaging: Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Messaging: Error deleting token - $e');
      }
    }
  }

  // Méthodes spécifiques à l'application TodoList
  static Future<void> subscribeToUserTodos(String userId) async {
    await subscribeToTopic('user_$userId');
    await subscribeToTopic('todos');
  }

  static Future<void> unsubscribeFromUserTodos(String userId) async {
    await unsubscribeFromTopic('user_$userId');
    await unsubscribeFromTopic('todos');
  }

  // Envoyer une notification de rappel (nécessite Cloud Functions)
  static Future<void> scheduleTodoReminder(String todoId, DateTime reminderTime) async {
    // Cette fonctionnalité nécessiterait l'implémentation
    // de Cloud Functions pour envoyer des notifications programmées
    if (kDebugMode) {
      print('Messaging: Todo reminder scheduled for $todoId at $reminderTime');
    }
  }
}
