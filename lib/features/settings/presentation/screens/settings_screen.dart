import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/isar_service.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/security_service.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late Future<String?> _profileNameFuture;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileNameFuture = SecurityService.getProfileName();
    });
  }

  Future<void> _editProfileName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(context, val);
              }
            },
            child: const Text('Save'),
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
        title: const Text('Clear All Data'),
        content: const Text('Are you sure you want to permanently delete all contacts, khatas, and transactions? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All local database records cleared successfully.')),
        );
      }
    }
  }

  void _selectCurrency(BuildContext context, WidgetRef ref, String currentSymbol) {
    final currencies = {
      'PKR': 'PKR (PKR)',
      '\$': 'USD (\$)',
      '€': 'EUR (€)',
      '£': 'GBP (£)',
      '₹': 'INR (₹)',
    };

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency Symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies.entries.map((entry) {
            return RadioListTile<String>(
              title: Text(entry.value),
              value: entry.key,
              groupValue: currentSymbol,
              activeColor: Colors.teal,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).updateCurrencySymbol(val);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectTheme(BuildContext context, WidgetRef ref, ThemeMode currentMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              activeColor: Colors.teal,
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
              activeColor: Colors.teal,
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
              activeColor: Colors.teal,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).updateThemeMode(val);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
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

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // User profile summary section
          FutureBuilder<String?>(
            future: _profileNameFuture,
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Offline User';
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  radius: 24,
                  child: Icon(Icons.person, size: 28),
                ),
                title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                subtitle: const Text('Running Secure Local Storage Mode'),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.teal),
                  onPressed: () => _editProfileName(userName),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.teal),
            title: const Text('Security & App Lock'),
            subtitle: const Text('PIN, Biometrics and Session parameters'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push('/settings/security'),
          ),
          const Divider(),

          // App configurations
          ListTile(
            leading: const Icon(Icons.notifications_none, color: Colors.teal),
            title: const Text('Notification Reminders'),
            subtitle: Text(settings.notificationsEnabled ? 'Enabled' : 'Disabled'),
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).updateNotificationsEnabled(val);
              },
              activeThumbColor: Colors.teal,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money, color: Colors.teal),
            title: const Text('Currency Symbol'),
            subtitle: Text('Set default: ${_getCurrencyName(settings.currencySymbol)}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _selectCurrency(context, ref, settings.currencySymbol),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined, color: Colors.teal),
            title: const Text('Theme Mode'),
            subtitle: Text(_getThemeName(settings.themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => _selectTheme(context, ref, settings.themeMode),
          ),
          const Divider(),
          // Danger zone
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Local Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Permanently wipe Isar database cache'),
            onTap: () => _clearAllData(context, ref),
          ),
          const Divider(),
          // Version details
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'KhataFlow v1.0.0 (Codrix.dev)',
              style: TextStyle(color: Colors.grey, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          )
        ],
      ),
    );
  }
}
