import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint("Local Timezone Initialized: $timeZoneName");
    } catch (e) {
      debugPrint("Could not set local location: $e. Defaulting to UTC.");
      tz.setLocalLocation(tz.UTC);
    }

    // 2. Initialize Local Notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification clicked: ${details.payload}");
      },
    );

    // 3. Request Permissions
    await requestPermissions();

    _initialized = true;
    debugPrint("Notification Service Initialized.");
  }

  Future<void> requestPermissions() async {
    try {
      // Local Notification permission for Android 13+
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
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
      channelDescription:
          'Main notification channel for due dates and credit updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final scheduledTZDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
    
    // Check if scheduled time is in the past
    if (scheduledTZDateTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint("Cannot schedule notification in the past (ID: $id): $scheduledTZDateTime");
      debugPrint("debug: notificationScheduledSuccessfully = false");
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'khataflow_main_channel',
      'KhataFlow Alerts',
      channelDescription:
          'Main notification channel for due dates and credit updates',
      importance: Importance.max,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    bool notificationScheduledSuccessfully = false;

    try {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTZDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      notificationScheduledSuccessfully = true;
      debugPrint("Notification scheduled natively (Exact Mode) (ID: $id) at $scheduledTZDateTime (Local Zone: ${tz.local.name})");
    } catch (e) {
      debugPrint("Exact alarm scheduling failed (ID: $id), activating fallback: $e");
      try {
        await _localNotifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTZDateTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        notificationScheduledSuccessfully = true;
        debugPrint("Notification scheduled natively (Approximate Mode Fallback) (ID: $id) at $scheduledTZDateTime (Local Zone: ${tz.local.name})");
      } catch (fallbackError) {
        debugPrint("Notification scheduling failed completely (ID: $id): $fallbackError");
      }
    }

    debugPrint("debug: notificationScheduledSuccessfully = $notificationScheduledSuccessfully");
    final count = await getPendingNotificationsCount();
    debugPrint("Current pending notification count after scheduling: $count");
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  Future<int> getPendingNotificationsCount() async {
    final pending = await getPendingNotifications();
    return pending.length;
  }

  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    debugPrint("Notification canceled (ID: $id)");
  }

  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
    debugPrint("All notifications canceled");
  }

  Future<void> scheduleTestNotification() async {
    final scheduledDate = DateTime.now().add(const Duration(seconds: 30));
    await scheduleNotification(
      id: 99999,
      title: "Test Notification",
      body: "This is a test notification scheduled 30 seconds ago.",
      scheduledDate: scheduledDate,
    );
  }
}
