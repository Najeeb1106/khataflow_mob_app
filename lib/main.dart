import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/database/isar_service.dart';
import 'core/router/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/purge_service.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'core/services/security_service.dart';
import 'features/auth/presentation/screens/unlock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Isar Local Database
  await IsarService.initialize();

  // Initialize Notification Service
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint("Failed to initialize Notification Service: $e");
  }

  // Run Database Maintenance Auto-Purge Task
  try {
    await PurgeService().runAutoPurge();
  } catch (e) {
    debugPrint("Failed to run Database Auto-Purge: $e");
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialLock() async {
    final hasProfile = await SecurityService.hasProfile();
    if (!hasProfile) {
      goRouter.go('/onboarding');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused) {
      await SecurityService.updateLastActive();
    } else if (state == AppLifecycleState.resumed) {
      if (UnlockScreen.isUnlockVisible) {
        return;
      }
      final lockReq = await SecurityService.isLockRequired();
      if (lockReq) {
        goRouter.go('/unlock');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'KhataFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: CardThemeData(
          color: Colors.grey.shade900,
          elevation: 2,
        ),
      ),
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
