// lib/src/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notifications - call this in main.dart
  Future<void> initialize() async {
    debugPrint('NotificationService.initialize()');

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    final initialized = await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
            '[NotificationService] Notification tapped: ${response.payload}');
      },
    );

    debugPrint('[NotificationService] Initialization result: $initialized');

    // Request permission for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        debugPrint(
            '[NotificationService] Android permission granted: $granted');
      }
    }

    _isInitialized = true;
    debugPrint('[NotificationService] ✓ Initialized successfully');
  }

  /// Show a missed call notification
  Future<void> showMissedCallNotification(String fromUserName) async {
    debugPrint('╔════════════════════════════════════════╗');
    debugPrint('║  showMissedCallNotification()         ║');
    debugPrint('╚════════════════════════════════════════╝');
    debugPrint('From: $fromUserName');
    debugPrint('Initialized: $_isInitialized');

    if (!_isInitialized) {
      debugPrint('ERROR: NotificationService not initialized!');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'missed_calls', // Channel ID
        'Missed Calls', // Channel name
        channelDescription: 'Notifications for missed calls',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      debugPrint(
          '[NotificationService] Showing notification with ID: $notificationId');

      await _notificationsPlugin.show(
        notificationId,
        'Ubesvaret opkald',
        'Ubesvaret opkald fra $fromUserName',
        notificationDetails,
        payload: 'missed_call:$fromUserName',
      );

      debugPrint('[NotificationService] ✓ Notification shown successfully');
    } catch (e, stackTrace) {
      debugPrint('[NotificationService] ❌ ERROR showing notification:');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Test notification - useful for debugging
  Future<void> showTestNotification() async {
    debugPrint('[NotificationService] Showing test notification...');
    await showMissedCallNotification('Test User');
  }
}
