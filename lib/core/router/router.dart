import 'package:go_router/go_router.dart';
import '../presentation/screens/main_navigation_wrapper.dart';
import '../../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../../features/auth/presentation/screens/local_auth_setup_screen.dart';
import '../../../features/auth/presentation/screens/unlock_screen.dart';
import '../../../features/settings/presentation/screens/security_settings_screen.dart';
import '../../../features/people/presentation/screens/add_edit_person_screen.dart';
import '../../../features/people/presentation/screens/person_detail_screen.dart';
import '../../../features/khata/presentation/screens/add_edit_khata_screen.dart';
import '../../../features/khata/presentation/screens/khata_detail_screen.dart';
import '../../../features/transactions/presentation/screens/quick_add_transaction_screen.dart';
import '../../../features/transactions/presentation/screens/advanced_transaction_screen.dart';
import '../../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../../features/reports/presentation/screens/statement_preview_screen.dart';
import '../../../features/trash/presentation/screens/trash_screen.dart';
import '../../../features/settings/presentation/screens/backup_restore_screen.dart';

import '../../../features/dashboard/presentation/screens/global_search_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/unlock', // Check lock requirement at start
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/setup-profile',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'];
        return LocalAuthSetupScreen(mode: mode);
      },
    ),
    GoRoute(path: '/unlock', builder: (context, state) => const UnlockScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const MainNavigationWrapper(initialTab: 0),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const GlobalSearchScreen(),
    ),
    GoRoute(
      path: '/people',
      builder: (context, state) => const MainNavigationWrapper(initialTab: 1),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const MainNavigationWrapper(initialTab: 2),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const MainNavigationWrapper(initialTab: 3),
    ),
    GoRoute(
      path: '/people/add',
      builder: (context, state) => const AddEditPersonScreen(),
    ),
    GoRoute(
      path: '/people/:uuid',
      builder: (context, state) =>
          PersonDetailScreen(personUuid: state.pathParameters['uuid']!),
    ),
    GoRoute(
      path: '/people/:uuid/edit',
      builder: (context, state) =>
          AddEditPersonScreen(personUuid: state.pathParameters['uuid']),
    ),
    GoRoute(
      path: '/people/:uuid/khata/add',
      builder: (context, state) =>
          AddEditKhataScreen(personUuid: state.pathParameters['uuid']!),
    ),
    GoRoute(
      path: '/people/:personUuid/khata/:khataUuid/edit',
      builder: (context, state) => AddEditKhataScreen(
        personUuid: state.pathParameters['personUuid']!,
        khataUuid: state.pathParameters['khataUuid'],
      ),
    ),
    GoRoute(
      path: '/khata/:uuid',
      builder: (context, state) =>
          KhataDetailScreen(khataUuid: state.pathParameters['uuid']!),
    ),
    GoRoute(
      path: '/transaction/quick-add',
      builder: (context, state) => const QuickAddTransactionScreen(),
    ),
    GoRoute(
      path: '/transaction/advanced',
      builder: (context, state) => AdvancedTransactionScreen(
        khataUuid: state.uri.queryParameters['khataUuid'] ?? '',
        presetType: state.uri.queryParameters['type'],
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/notifications/settings',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/statement/:khataUuid',
      builder: (context, state) =>
          StatementPreviewScreen(khataUuid: state.pathParameters['khataUuid']!),
    ),
    GoRoute(path: '/trash', builder: (context, state) => const TrashScreen()),
    GoRoute(
      path: '/settings/security',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/backup',
      builder: (context, state) => const BackupRestoreScreen(),
    ),
  ],
);
