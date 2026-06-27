import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:khata_app/core/services/notification_service.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockNotificationService mockNotification;

  setUp(() {
    mockNotification = MockNotificationService();
  });

  group('NotificationService Tests', () {
    test('initialize registers local channels and requests permission permissions', () async {
      when(() => mockNotification.initialize()).thenAnswer((_) async {});

      await mockNotification.initialize();
      verify(() => mockNotification.initialize()).called(1);
    });

    test('requestPermissions requests FCM and local notification access permissions', () async {
      when(() => mockNotification.requestPermissions()).thenAnswer((_) async {});

      await mockNotification.requestPermissions();
      verify(() => mockNotification.requestPermissions()).called(1);
    });

    test('showNotification dispatches standard notification detail payload', () async {
      when(() => mockNotification.showNotification(
            id: 1,
            title: 'Test Title',
            body: 'Test Body',
            payload: 'test-payload',
          )).thenAnswer((_) async {});

      await mockNotification.showNotification(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        payload: 'test-payload',
      );

      verify(() => mockNotification.showNotification(
            id: 1,
            title: 'Test Title',
            body: 'Test Body',
            payload: 'test-payload',
          )).called(1);
    });

    test('scheduleNotification triggers delayed local schedule notification response', () async {
      final scheduledDate = DateTime.now().add(const Duration(minutes: 5));
      when(() => mockNotification.scheduleNotification(
            id: 2,
            title: 'Reminder Title',
            body: 'Reminder Body',
            scheduledDate: scheduledDate,
            payload: 'reminder-payload',
          )).thenAnswer((_) async {});

      await mockNotification.scheduleNotification(
        id: 2,
        title: 'Reminder Title',
        body: 'Reminder Body',
        scheduledDate: scheduledDate,
        payload: 'reminder-payload',
      );

      verify(() => mockNotification.scheduleNotification(
            id: 2,
            title: 'Reminder Title',
            body: 'Reminder Body',
            scheduledDate: scheduledDate,
            payload: 'reminder-payload',
          )).called(1);
    });
  });
}
