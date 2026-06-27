import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );

    // 2. Request Permissions
    await requestPermissions();

    _initialized = true;
    debugPrint("Notification Service Initialized.");
  }

  Future<void> requestPermissions() async {
    try {
      // Local Notification permission for Android 13+
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint("Notification permissions request skipped: $e");
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'khataflow_main_channel',
      'KhataFlow Alerts',
      channelDescription: 'Main notification channel for due dates and credit updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Basic fallback simulation for platform specific delay if scheduler is not fully initialized.
    // In production, timezone-based scheduling requires 'timezone' package initialization.
    // To keep it 100% stable, we expose this method and trigger standard delayed timers for demo purposes.
    final duration = scheduledDate.difference(DateTime.now());
    if (duration.isNegative) return;

    Future.delayed(duration, () {
      showNotification(id: id, title: title, body: body, payload: payload);
    });
    
    debugPrint("Notification scheduled in ${duration.inSeconds} seconds.");
  }
}
