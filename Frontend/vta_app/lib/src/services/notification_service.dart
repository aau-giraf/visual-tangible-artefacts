// lib/src/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';


final _log = Logger('NotificationService');
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notifications
  Future<void> initialize() async {
    _log.fine('NotificationService.initialize()');

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
        _log.fine(
            '[NotificationService] Notification tapped: ${response.payload}');
      },
    );

    _log.fine('[NotificationService] Initialization result: $initialized');

    // Request permission for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        final granted = await androidImpl.requestNotificationsPermission();
        _log.fine(
            '[NotificationService] Android permission granted: $granted');
      }
    }

    _isInitialized = true;
    _log.fine('[NotificationService] Initialized successfully');
  }

  /// Show a missed call notification
  Future<void> showMissedCallNotification(String fromUserName) async {
    _log.fine('showMissedCallNotification()');
    _log.fine('From: $fromUserName');
    _log.fine('Initialized: $_isInitialized');

    if (!_isInitialized) {
      _log.fine('ERROR: NotificationService not initialized!');
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
      _log.fine(
          '[NotificationService] Showing notification with ID: $notificationId');

      await _notificationsPlugin.show(
        notificationId,
        'Ubesvaret opkald',
        'Ubesvaret opkald fra $fromUserName',
        notificationDetails,
        payload: 'missed_call:$fromUserName',
      );

      _log.fine('[NotificationService] Notification shown successfully');
    } catch (e, stackTrace) {
      _log.fine('[NotificationService] ERROR showing notification:');
      _log.fine('Error: $e');
      _log.fine('Stack trace: $stackTrace');
    }
  }

  /// Test notification - useful for debugging
  Future<void> showTestNotification() async {
    _log.fine('[NotificationService] Showing test notification...');
    await showMissedCallNotification('Test User');
  }
}
