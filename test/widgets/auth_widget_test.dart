import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khata_app/features/auth/presentation/screens/local_auth_setup_screen.dart';

void main() {
  group('LocalAuthSetupScreen Widget Tests', () {
    testWidgets('renders Create Profile step correctly', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/setup-profile',
        routes: [
          GoRoute(
            path: '/setup-profile',
            builder: (context, state) => const LocalAuthSetupScreen(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Verify page text
      expect(find.text('KhataFlow'), findsOneWidget);
      expect(find.text('Create Profile'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });
  });
}
