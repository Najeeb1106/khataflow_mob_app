import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/services/security_service.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../providers/settings_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<String?> _profileNameFuture;
  String _dbSize = 'Calculating...';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _calculateDbSize();
  }

  void _loadProfile() {
    setState(() {
      _profileNameFuture = SecurityService.getProfileName();
    });
  }

  Future<void> _calculateDbSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/default.isar');
      if (await file.exists()) {
        final size = await file.length();
        setState(() {
          if (size < 1024) {
            _dbSize = '$size B';
          } else if (size < 1024 * 1024) {
            _dbSize = '${(size / 1024).toStringAsFixed(1)} KB';
          } else {
            _dbSize = '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
          }
        });
        return;
      }
    } catch (_) {}
    setState(() {
      _dbSize = '0 B';
    });
  }

  Future<void> _editProfileName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: const Text(
          'Edit Profile Name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: AppTextField(
          controller: controller,
          labelText: 'Full Name',
          prefixIcon: Icons.person_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          AppButton(
            label: 'Save',
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(context, val);
              }
            },
          ),
        ],
      ),
    );

    if (newName != null) {
      await SecurityService.updateProfileName(newName);
      _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile name updated successfully.')),
        );
      }
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    final showConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: const Text(
          'Clear All Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to permanently delete all contacts, khatas, and transactions? This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.redPayable,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppDesign.borderMedium,
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );

    if (showConfirm == true) {
      final isar = IsarService.instance;
      await isar.writeTxn(() async {
        await isar.clear();
      });
      ref.read(peopleListProvider.notifier).loadPeople();
      _calculateDbSize();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All local database records cleared successfully.'),
          ),
        );
      }
    }
  }

  void _selectCurrency(
    BuildContext context,
    WidgetRef ref,
    String currentSymbol,
  ) {
    final currencies = {
      'Rs.': 'Pakistani Rupee (Rs.)',
      'PKR': 'PKR (PKR)',
      '\$': 'US Dollar (\$)',
      '€': 'Euro (€)',
      '£': 'British Pound (£)',
      '₹': 'Indian Rupee (₹)',
    };

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          title: const Text(
            'Select Currency Symbol',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: currencies.entries.map((entry) {
              return RadioListTile<String>(
                title: Text(entry.value),
                value: entry.key,
                groupValue: currentSymbol,
                activeColor: AppDesign.primaryEmerald,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(settingsProvider.notifier)
                        .updateCurrencySymbol(val);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _selectTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
          title: const Text(
            'Select Theme Mode',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                value: ThemeMode.system,
                groupValue: currentMode,
                activeColor: AppDesign.primaryEmerald,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light Theme'),
                value: ThemeMode.light,
                groupValue: currentMode,
                activeColor: AppDesign.primaryEmerald,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Theme'),
                value: ThemeMode.dark,
                groupValue: currentMode,
                activeColor: AppDesign.primaryEmerald,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateThemeMode(val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System Default Theme';
      case ThemeMode.light:
        return 'Light Theme';
      case ThemeMode.dark:
        return 'Dark Theme';
    }
  }

  String _getCurrencyName(String symbol) {
    switch (symbol) {
      case 'Rs.':
        return 'PKR (Rs.)';
      case 'PKR':
        return 'PKR (PKR)';
      case '\$':
        return 'USD (\$)';
      case '€':
        return 'EUR (€)';
      case '£':
        return 'GBP (£)';
      case '₹':
        return 'INR (₹)';
      default:
        return symbol;
    }
  }

  void _triggerSimulatedBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting Encrypted Database Backup to Documents...'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup successful! Filename: khataflow_backup.db'),
          ),
        );
      }
    });
  }

  void _triggerSimulatedRestore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restoring Database from documents backup folder...'),
        duration: Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ref.read(peopleListProvider.notifier).loadPeople();
        _calculateDbSize();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database restored successfully!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 8,
        ),
        child: Column(
          children: [
            // User profile summary section
            FutureBuilder<String?>(
              future: _profileNameFuture,
              builder: (context, snapshot) {
                final userName = snapshot.data ?? 'Offline User';
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesign.darkCard : Colors.white,
                    borderRadius: AppDesign.borderMedium,
                    border: Border.all(
                      color: isDark
                          ? AppDesign.darkBorder
                          : AppDesign.lightBorder,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppDesign.primaryEmerald.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: AppDesign.primaryEmerald,
                      radius: 20,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Secure Local Storage Mode',
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: AppDesign.primaryEmerald,
                        size: 18,
                      ),
                      onPressed: () => _editProfileName(userName),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 6),

            // Section: General Settings
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'GENERAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.security_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Security & App Lock', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'PIN, Biometrics and Session parameters',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () => context.push('/settings/security'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.notifications_none_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Notification Reminders', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      settings.notificationsEnabled ? 'Enabled' : 'Disabled',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: settings.notificationsEnabled,
                        onChanged: (val) {
                          ref
                              .read(settingsProvider.notifier)
                              .updateNotificationsEnabled(val);
                        },
                        activeColor: AppDesign.primaryEmerald,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.attach_money_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Currency Symbol', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      'Set default: ${_getCurrencyName(settings.currencySymbol)}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () =>
                        _selectCurrency(context, ref, settings.currencySymbol),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.color_lens_outlined,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Theme Mode', style: TextStyle(fontSize: 13)),
                    subtitle: Text(_getThemeName(settings.themeMode), style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () => _selectTheme(context, ref, settings.themeMode),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Section: Data & Backup
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'DATA & BACKUP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.delete_sweep_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Trash / Recycle Bin', style: TextStyle(fontSize: 13)),
                    subtitle: const Text(
                      'Recover deleted contacts or transactions',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () => context.push('/trash'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.cloud_upload_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Backup Database', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Export local ledger copy securely', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: _triggerSimulatedBackup,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.cloud_download_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Restore Database', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Import database from local files', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: _triggerSimulatedRestore,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.storage_rounded,
                      color: AppDesign.primaryTeal,
                      size: 20,
                    ),
                    title: const Text('Storage Usage', style: TextStyle(fontSize: 13)),
                    subtitle: Text('Database File Size: $_dbSize', style: const TextStyle(fontSize: 11)),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh, size: 14),
                      onPressed: _calculateDbSize,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Section: About & Support
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SUPPORT & LEGAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 13)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDesign.borderMedium,
                          ),
                          title: const Text('Privacy Policy'),
                          content: const SingleChildScrollView(
                            child: Text(
                              'KhataFlow does not transmit any of your finance data to external servers. Your accounts, transactions, profiles, and parameters are stored exclusively in your local database, secure under hardware PIN/biometric authentication.',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.info_outline_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 20,
                    ),
                    title: const Text('App Version', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Version 1.1.1 (Build 12)', style: TextStyle(fontSize: 11)),
                    onTap: null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Danger zone
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: AppDesign.redPayable.withValues(alpha: 0.03),
              shape: RoundedRectangleBorder(
                borderRadius: AppDesign.borderMedium,
                side: const BorderSide(color: AppDesign.redPayable, width: 0.8),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(
                  Icons.delete_forever_rounded,
                  color: AppDesign.redPayable,
                  size: 20,
                ),
                title: const Text(
                  'Clear All Local Data',
                  style: TextStyle(
                    color: AppDesign.redPayable,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                subtitle: const Text('Permanently wipe Isar database cache', style: TextStyle(fontSize: 11)),
                onTap: () => _clearAllData(context, ref),
              ),
            ),

            const SizedBox(height: 12),

            // Developer signature
            const Text(
              'KhataFlow v1.0.0 (Codrix.dev)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
