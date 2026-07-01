import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khata_app/features/settings/presentation/screens/settings_screen.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    testWidgets('renders profile and setting rows correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: SettingsScreen())),
      );

      // Verify layout rows exist
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Offline User'), findsOneWidget);
      expect(find.text('Notification Reminders'), findsOneWidget);
      expect(find.text('Currency Symbol'), findsOneWidget);
      expect(find.text('Clear All Local Data'), findsOneWidget);
      expect(find.text('KhataFlow v1.0.0 (Codrix.dev)'), findsOneWidget);
    });
  });
}
