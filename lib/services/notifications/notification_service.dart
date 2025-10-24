import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // Timezone setup
    try {
      tz.initializeTimeZones();
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (e) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);

    // Request permissions on Android 13+
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    // Android 13+ runtime permission handled by plugin upon showing first notification if not granted.
    _initialized = true;
  }

  Future<void> scheduleReminder({
    required String taskId,
    required DateTime when,
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();

    // Only schedule for future moments
    if (when.isBefore(DateTime.now())) return;

    final int notifId = _notificationIdForTask(taskId);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'todo_reminders',
      'Rappels des tâches',
      channelDescription: 'Notifications programmées pour les rappels de tâches',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    final NotificationDetails details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final tz.TZDateTime tzWhen = tz.TZDateTime.from(when, tz.local);

    // Cancel any existing schedule for this task first to avoid duplicates
    await _plugin.cancel(notifId);

    await _plugin.zonedSchedule(
      notifId,
      title,
      body,
      tzWhen,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: taskId,
    );
  }

  Future<void> cancelReminder(String taskId) async {
    if (!_initialized) await init();
    final int notifId = _notificationIdForTask(taskId);
    await _plugin.cancel(notifId);
  }

  int _notificationIdForTask(String taskId) {
    // Deterministic 32-bit FNV-1a hash for stable IDs
    const int fnvPrime = 16777619;
    int hash = 2166136261;
    for (int i = 0; i < taskId.length; i++) {
      hash ^= taskId.codeUnitAt(i);
      hash = (hash * fnvPrime) & 0xFFFFFFFF;
    }
    // Map to signed 31-bit int range for plugin
    return hash & 0x7FFFFFFF;
  }
}
