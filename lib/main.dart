import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/database/isar_service.dart';
import 'core/router/router.dart';
import 'core/services/notification_service.dart';
import 'core/services/purge_service.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'core/services/security_service.dart';
import 'features/auth/presentation/screens/unlock_screen.dart';
import 'core/presentation/design_system.dart';

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

  runApp(const ProviderScope(child: MyApp()));
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
          seedColor: AppDesign.primaryEmerald,
          primary: AppDesign.primaryEmerald,
          brightness: Brightness.light,
          surface: AppDesign.lightBg,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppDesign.lightBg,
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        cardTheme: CardThemeData(
          color: AppDesign.lightCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppDesign.borderMedium,
            side: const BorderSide(color: AppDesign.lightBorder, width: 1),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppDesign.primaryEmerald,
          primary: AppDesign.primaryEmerald,
          brightness: Brightness.dark,
          surface: AppDesign.darkBg,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppDesign.darkBg,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: AppDesign.darkCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppDesign.borderMedium,
            side: const BorderSide(color: AppDesign.darkBorder, width: 1),
          ),
        ),
      ),
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
