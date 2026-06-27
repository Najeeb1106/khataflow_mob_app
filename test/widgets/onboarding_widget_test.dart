import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khata_app/features/onboarding/presentation/screens/onboarding_screen.dart';

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders all pages and transitions on Next click', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/setup-profile',
            builder: (context, state) => const Scaffold(body: Text('Setup Profile Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Verify First slide content
      expect(find.text('No More Paper Ledgers'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify Second slide content
      expect(find.text('Intelligent Reminders'), findsOneWidget);

      // Tap Next button again
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify Third slide content
      expect(find.text('Instant Statements & Share'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Verify navigation to Auth
      expect(find.text('Setup Profile Page'), findsOneWidget);
    });

    testWidgets('Skip button navigates immediately to auth', (WidgetTester tester) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/setup-profile',
            builder: (context, state) => const Scaffold(body: Text('Setup Profile Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.text('Setup Profile Page'), findsOneWidget);
    });
  });
}
