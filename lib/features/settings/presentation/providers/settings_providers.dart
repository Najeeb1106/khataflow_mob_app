import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String currencySymbol;
  final bool notificationsEnabled;
  final bool dueDateAlertsEnabled;
  final bool overdueNoticesEnabled;
  final bool dailySummaryEnabled;
  final bool hasCompletedOnboarding;
  final String? profileName;
  final bool isSecuritySetupCompleted;

  const AppSettings({
    required this.themeMode,
    required this.currencySymbol,
    required this.notificationsEnabled,
    required this.dueDateAlertsEnabled,
    required this.overdueNoticesEnabled,
    required this.dailySummaryEnabled,
    required this.hasCompletedOnboarding,
    this.profileName,
    required this.isSecuritySetupCompleted,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? notificationsEnabled,
    bool? dueDateAlertsEnabled,
    bool? overdueNoticesEnabled,
    bool? dailySummaryEnabled,
    bool? hasCompletedOnboarding,
    String? profileName,
    bool? isSecuritySetupCompleted,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dueDateAlertsEnabled: dueDateAlertsEnabled ?? this.dueDateAlertsEnabled,
      overdueNoticesEnabled: overdueNoticesEnabled ?? this.overdueNoticesEnabled,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      profileName: profileName ?? this.profileName,
      isSecuritySetupCompleted: isSecuritySetupCompleted ?? this.isSecuritySetupCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'currencySymbol': currencySymbol,
    'notificationsEnabled': notificationsEnabled,
    'dueDateAlertsEnabled': dueDateAlertsEnabled,
    'overdueNoticesEnabled': overdueNoticesEnabled,
    'dailySummaryEnabled': dailySummaryEnabled,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'profileName': profileName,
    'isSecuritySetupCompleted': isSecuritySetupCompleted,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    ThemeMode theme = ThemeMode.system;
    if (json['themeMode'] != null) {
      theme = ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      );
    }
    return AppSettings(
      themeMode: theme,
      currencySymbol: json['currencySymbol'] ?? 'Rs.',
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      dueDateAlertsEnabled: json['dueDateAlertsEnabled'] ?? true,
      overdueNoticesEnabled: json['overdueNoticesEnabled'] ?? true,
      dailySummaryEnabled: json['dailySummaryEnabled'] ?? true,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] ?? false,
      profileName: json['profileName'],
      isSecuritySetupCompleted: json['isSecuritySetupCompleted'] ?? false,
    );
  }

  static const defaultSettings = AppSettings(
    themeMode: ThemeMode.system,
    currencySymbol: 'Rs.',
    notificationsEnabled: true,
    dueDateAlertsEnabled: true,
    overdueNoticesEnabled: true,
    dailySummaryEnabled: true,
    hasCompletedOnboarding: false,
    profileName: null,
    isSecuritySetupCompleted: false,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier([AppSettings? initialSettings]) : super(initialSettings ?? AppSettings.defaultSettings) {
    if (initialSettings == null) {
      loadSettings();
    }
  }

  static Future<AppSettings> loadInitialSettings() async {
    String? loadPath;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      loadPath = '${directory.path}/app_settings.json';
      
      final file = File(loadPath);
      final exists = await file.exists();
      
      if (exists) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        return AppSettings.fromJson(json);
      }
    } catch (e) {
      // Fallback/Mock support for testing environments where path_provider is not mocked
      try {
        final directory = Directory.systemTemp;
        loadPath = '${directory.path}/app_settings.json';
        
        final file = File(loadPath);
        final exists = await file.exists();
        
        if (exists) {
          final contents = await file.readAsString();
          final json = jsonDecode(contents) as Map<String, dynamic>;
          return AppSettings.fromJson(json);
        }
      } catch (_) {}
    }
    return AppSettings.defaultSettings;
  }

  Future<File> get _localFile async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/app_settings.json';
      return File(path);
    } catch (e) {
      final directory = Directory.systemTemp;
      final path = '${directory.path}/app_settings.json';
      return File(path);
    }
  }

  Future<void> loadSettings() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final json = jsonDecode(contents) as Map<String, dynamic>;
        state = AppSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  Future<void> updateCurrencySymbol(String currencySymbol) async {
    state = state.copyWith(currencySymbol: currencySymbol);
    await _saveSettings();
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateDueDateAlertsEnabled(bool enabled) async {
    state = state.copyWith(dueDateAlertsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateOverdueNoticesEnabled(bool enabled) async {
    state = state.copyWith(overdueNoticesEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateDailySummaryEnabled(bool enabled) async {
    state = state.copyWith(dailySummaryEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateOnboardingCompleted(bool completed) async {
    state = state.copyWith(hasCompletedOnboarding: completed);
    await _saveSettings();
  }

  Future<void> updateProfileName(String? profileName) async {
    state = state.copyWith(profileName: profileName);
    await _saveSettings();
  }

  Future<void> updateSecuritySetupCompleted(bool completed) async {
    state = state.copyWith(isSecuritySetupCompleted: completed);
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _localFile;
      final jsonStr = jsonEncode(state.toJson());
      await file.writeAsString(jsonStr);
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((
  ref,
) {
  return SettingsNotifier();
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final currencySymbolProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).currencySymbol;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).notificationsEnabled;
});
