import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../transactions/data/models/transaction.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueStatsAsync = ref.watch(dashboardDueStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppDesign.darkBg : AppDesign.lightBg,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification Settings',
            onPressed: () => context.push('/notifications/settings'),
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        color: AppDesign.primaryEmerald,
        onRefresh: () async {
          ref.invalidate(dashboardDueStatsProvider);
        },
        child: dueStatsAsync.when(
          data: (stats) {
            final List<Map<String, dynamic>> allNotifications = [];

            // Add overdue notifications
            if (stats['overdue'] != null) {
              for (final item in stats['overdue']!) {
                allNotifications.add({
                  ...item,
                  'urgency': 'Overdue ⚠️',
                  'color': AppDesign.redPayable,
                  'icon': Icons.warning_amber_rounded,
                  'message': 'Repayment is overdue since ${_formatDate(item['transaction'].dueDate!)}.',
                });
              }
            }

            // Add due today notifications
            if (stats['dueToday'] != null) {
              for (final item in stats['dueToday']!) {
                allNotifications.add({
                  ...item,
                  'urgency': 'Due Today ⏰',
                  'color': AppDesign.amberWarning,
                  'icon': Icons.today_rounded,
                  'message': 'Repayment is due today.',
                });
              }
            }

            // Add due tomorrow notifications
            if (stats['dueTomorrow'] != null) {
              for (final item in stats['dueTomorrow']!) {
                allNotifications.add({
                  ...item,
                  'urgency': 'Due Tomorrow 🔔',
                  'color': Colors.blueAccent,
                  'icon': Icons.notifications_active_outlined,
                  'message': 'Repayment is due tomorrow.',
                });
              }
            }

            // Sort all by date or keep urgency order (Overdue -> Today -> Tomorrow)
            if (allNotifications.isEmpty) {
              return const EmptyState(
                icon: '🔔',
                title: 'All caught up!',
                subtitle: 'No pending due or overdue notifications at the moment.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDesign.space24,
                vertical: AppDesign.space16,
              ),
              itemCount: allNotifications.length,
              itemBuilder: (context, index) {
                if (index >= allNotifications.length) return const SizedBox.shrink();
                final item = allNotifications[index];
                final tx = item['transaction'] as Transaction;
                final personName = item['personName'] as String;
                final khataTitle = item['khataTitle'] as String;
                final color = item['color'] as Color;
                final icon = item['icon'] as IconData;
                final urgency = item['urgency'] as String;
                final message = item['message'] as String;

                final isOwed = tx.type == TransactionType.gave || tx.type == TransactionType.paid;
                final actionText = isOwed ? 'collect from' : 'pay to';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isDark ? AppDesign.darkCard : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDesign.borderMedium,
                    side: BorderSide(
                      color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          urgency,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'PKR ${tx.amount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Please remember to $actionText $personName ($khataTitle). $message',
                            style: TextStyle(
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                          if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Notes: "${tx.notes}"',
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    onTap: () {
                      context.push('/khata/${tx.khataUuid}');
                    },
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(
              color: AppDesign.primaryEmerald,
            ),
          ),
          error: (err, _) => Center(
            child: Text('Error loading notifications: $err'),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
