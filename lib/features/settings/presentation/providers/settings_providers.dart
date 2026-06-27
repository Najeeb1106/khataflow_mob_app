import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class AppSettings {
  final ThemeMode themeMode;
  final String currencySymbol;
  final bool notificationsEnabled;

  const AppSettings({
    required this.themeMode,
    required this.currencySymbol,
    required this.notificationsEnabled,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'currencySymbol': currencySymbol,
    'notificationsEnabled': notificationsEnabled,
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
    );
  }

  static const defaultSettings = AppSettings(
    themeMode: ThemeMode.system,
    currencySymbol: 'Rs.',
    notificationsEnabled: true,
  );
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings.defaultSettings) {
    loadSettings();
  }

  Future<File> get _localFile async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return File('${directory.path}/app_settings.json');
    } catch (_) {
      // Fallback/Mock support for testing environments where path_provider is not mocked
      final directory = Directory.systemTemp;
      return File('${directory.path}/app_settings.json');
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

  Future<void> _saveSettings() async {
    try {
      final file = await _localFile;
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
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
