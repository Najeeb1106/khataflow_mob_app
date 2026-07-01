import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';
import '../../../settings/presentation/providers/settings_providers.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppDesign.darkBg : AppDesign.lightBg,
      appBar: AppBar(
        title: const Text(
          'Reminders & Alerts',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 8,
        ),
        children: [
          // Info description card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppDesign.darkCard : Colors.white,
              borderRadius: AppDesign.borderMedium,
              border: Border.all(
                color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
              ),
              boxShadow: isDark ? AppDesign.premiumShadowDark : AppDesign.premiumShadow,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppDesign.primaryEmerald,
                  size: 20,
                ),
                const SizedBox(width: AppDesign.space12),
                Expanded(
                  child: Text(
                    'Configure when and how you want to be notified about due repayments, daily ledger summaries, and overdue notices.',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Global Notification Switch Card
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: isDark ? AppDesign.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppDesign.borderMedium,
              side: BorderSide(
                color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
              ),
            ),
            elevation: 0,
            child: SwitchListTile(
              dense: true,
              secondary: Icon(
                settings.notificationsEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_rounded,
                color: settings.notificationsEnabled
                    ? AppDesign.primaryEmerald
                    : AppDesign.grayNeutral,
                size: 20,
              ),
              title: const Text(
                'Allow Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                settings.notificationsEnabled
                    ? 'Receive alerts on this device'
                    : 'All notifications are disabled',
                style: const TextStyle(fontSize: 11),
              ),
              activeColor: AppDesign.primaryEmerald,
              value: settings.notificationsEnabled,
              onChanged: (value) {
                AppHaptics.light();
                notifier.updateNotificationsEnabled(value);
                AppSnackbar.show(
                  context,
                  value
                      ? 'Notifications enabled successfully'
                      : 'All notifications disabled',
                  type: AppSnackbarType.success,
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Granular Settings Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              'NOTIFICATION PROFILES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
          ),

          // Granular Switches Card
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: settings.notificationsEnabled ? 1.0 : 0.5,
            child: AbsorbPointer(
              absorbing: !settings.notificationsEnabled,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: isDark ? AppDesign.darkCard : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDesign.borderMedium,
                  side: BorderSide(
                    color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
                  ),
                ),
                elevation: 0,
                child: Column(
                  children: [
                    _buildSettingsSwitch(
                      context: context,
                      icon: Icons.calendar_today_rounded,
                      title: 'Due Date Alerts',
                      description: 'Alerts when repayment timeline is reached.',
                      value: settings.dueDateAlertsEnabled,
                      onChanged: (val) {
                        AppHaptics.light();
                        notifier.updateDueDateAlertsEnabled(val);
                        AppSnackbar.show(
                          context,
                          val ? 'Due Date Alerts enabled' : 'Due Date Alerts disabled',
                          type: AppSnackbarType.success,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsSwitch(
                      context: context,
                      icon: Icons.error_outline_rounded,
                      title: 'Overdue Notices',
                      description: 'Daily updates for accounts remaining unpaid.',
                      value: settings.overdueNoticesEnabled,
                      onChanged: (val) {
                        AppHaptics.light();
                        notifier.updateOverdueNoticesEnabled(val);
                        AppSnackbar.show(
                          context,
                          val ? 'Overdue Notices enabled' : 'Overdue Notices disabled',
                          type: AppSnackbarType.success,
                        );
                      },
                    ),
                    const Divider(height: 1),
                    _buildSettingsSwitch(
                      context: context,
                      icon: Icons.summarize_outlined,
                      title: 'Daily Summary',
                      description: 'A quick nightly snapshot of outstanding balances.',
                      value: settings.dailySummaryEnabled,
                      onChanged: (val) {
                        AppHaptics.light();
                        notifier.updateDailySummaryEnabled(val);
                        AppSnackbar.show(
                          context,
                          val ? 'Daily Summary enabled' : 'Daily Summary disabled',
                          type: AppSnackbarType.success,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Security and Privacy note at the bottom
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
                const SizedBox(width: AppDesign.space4),
                Text(
                  'All settings are stored offline on your device',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSwitch({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      dense: true,
      secondary: Icon(
        icon,
        color: value ? AppDesign.primaryEmerald : AppDesign.grayNeutral,
        size: 20,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      subtitle: Text(
        description,
        style: const TextStyle(fontSize: 11),
      ),
      activeColor: AppDesign.primaryEmerald,
      value: value,
      onChanged: onChanged,
    );
  }
}
