import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khata_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';

class FakeSettingsNotifier extends SettingsNotifier {
  FakeSettingsNotifier() : super(AppSettings.defaultSettings);

  @override
  Future<void> updateOnboardingCompleted(bool completed) async {
    state = state.copyWith(hasCompletedOnboarding: completed);
  }

  @override
  Future<void> updateProfileName(String? name) async {
    state = state.copyWith(profileName: name);
  }

  @override
  Future<void> updateSecuritySetupCompleted(bool completed) async {
    state = state.copyWith(isSecuritySetupCompleted: completed);
  }
}

void main() {
  group('OnboardingScreen Widget Tests', () {
    testWidgets('renders all pages and transitions on Next click', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/setup-profile',
            builder: (context, state) =>
                const Scaffold(body: Text('Setup Profile Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeSettingsNotifier()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Verify First slide content
      expect(find.text('Track Money with Confidence'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Tap Next button to go to Stay on Top of Due Payments
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Stay on Top of Due Payments'), findsOneWidget);

      // Tap Next button to go to Generate Professional Statements
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Generate Professional Statements'), findsOneWidget);

      // Tap Next button to go to Private and Secure
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Private and Secure'), findsOneWidget);

      // Tap Next button to go to Welcome to KhataFlow
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to KhataFlow'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify navigation to Auth
      expect(find.text('Setup Profile Page'), findsOneWidget);
    });

    testWidgets('Skip button navigates immediately to auth', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const OnboardingScreen(),
          ),
          GoRoute(
            path: '/setup-profile',
            builder: (context, state) =>
                const Scaffold(body: Text('Setup Profile Page')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsProvider.overrideWith((ref) => FakeSettingsNotifier()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.text('Setup Profile Page'), findsOneWidget);
    });
  });
}
