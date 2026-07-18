import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
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

  // Load AppSettings from disk
  var initialSettings = await SettingsNotifier.loadInitialSettings();

  // Migrate profileName from secure storage if it exists there but not in AppSettings
  if (initialSettings.profileName == null || initialSettings.profileName!.isEmpty) {
    try {
      final secureName = await SecurityService.getProfileName();
      if (secureName != null && secureName.isNotEmpty) {
        initialSettings = initialSettings.copyWith(
          profileName: secureName,
          isSecuritySetupCompleted: true,
          hasCompletedOnboarding: true,
        );
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/app_settings.json');
        await file.writeAsString(jsonEncode(initialSettings.toJson()));
        debugPrint('[MIGRATION] Migrated profileName from secure storage to AppSettings');
      }
    } catch (e) {
      debugPrint('[MIGRATION] Failed to migrate profileName: $e');
    }
  }

  // Migrate isSecuritySetupCompleted for existing users who already have a profile
  if (!initialSettings.isSecuritySetupCompleted && initialSettings.profileName != null && initialSettings.profileName!.isNotEmpty) {
    initialSettings = initialSettings.copyWith(
      isSecuritySetupCompleted: true,
      hasCompletedOnboarding: true,
    );
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/app_settings.json');
      await file.writeAsString(jsonEncode(initialSettings.toJson()));
      debugPrint('[MIGRATION] Auto-completed isSecuritySetupCompleted for existing user');
    } catch (e) {
      debugPrint('[MIGRATION] Failed to update isSecuritySetupCompleted: $e');
    }
  }

  // Initialize Notification Service
  try {
    await NotificationService().initialize();
    if (kDebugMode) {
      final count = await NotificationService().getPendingNotificationsCount();
      debugPrint("Startup Audit: Pending Notification Count = $count");
    }
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
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => SettingsNotifier(initialSettings)),
      ],
      child: const MyApp(),
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
    final settings = ref.read(settingsProvider);
    if (!settings.hasCompletedOnboarding) {
      goRouter.go('/onboarding');
      return;
    }
    if (!settings.isSecuritySetupCompleted) {
      goRouter.go('/setup-profile');
      return;
    }
    if (settings.profileName == null || settings.profileName!.trim().isEmpty) {
      goRouter.go('/setup-profile');
      return;
    }
    // Continue startup flow (stays on /unlock screen)
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
