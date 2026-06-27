import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/dashboard_providers.dart';
import '../../../../core/presentation/widgets/offline_banner.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/services/security_service.dart';
import '../../../transactions/data/models/transaction.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(dashboardRecentTransactionsProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'KhataFlow',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.teal),
            ),
            Text(
              _getFormattedDate(),
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: OfflineBanner(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(dashboardRecentTransactionsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome text
                FutureBuilder<String?>(
                  future: SecurityService.getProfileName(),
                  builder: (context, snapshot) {
                    final userName = snapshot.data ?? 'User';
                    return Text(
                      '${_getGreeting()}, $userName 👋',
                      style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w600),
                    );
                  },
                ),
                const SizedBox(height: 12),

                summaryAsync.when(
                  data: (summary) {
                    final netPrefix = summary.netPosition >= 0 ? '$currency ' : '-$currency ';

                    // Math for ratio bar
                    final total = summary.totalReceivable + summary.totalPayable;
                    final receivableRatio = total > 0 ? summary.totalReceivable / total : 0.5;
                    final payableRatio = total > 0 ? summary.totalPayable / total : 0.5;

                    return Column(
                      children: [
                        // Premium Gradient position card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: summary.netPosition >= 0
                                  ? [Colors.teal.shade800, Colors.green.shade600]
                                  : [Colors.blueGrey.shade800, Colors.red.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (summary.netPosition >= 0 ? Colors.teal : Colors.red).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -40,
                                  top: -40,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.08),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NET POSITION',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withValues(alpha: 0.85),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$netPrefix${summary.netPosition.abs().toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              summary.netPosition >= 0 ? Icons.trending_up : Icons.trending_down,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              summary.netPosition >= 0 ? 'You are owed money overall' : 'You owe money overall',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Two Mini Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50.withValues(alpha: 0.5),
                                  border: Border.all(color: Colors.green.shade100),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('You Will Get', style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$currency ${summary.totalReceivable.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50.withValues(alpha: 0.5),
                                  border: Border.all(color: Colors.red.shade100),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('You Will Give', style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$currency ${summary.totalPayable.toStringAsFixed(0)}',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Cashflow Ratio Progress Bar
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Receivables Ratio',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '${(receivableRatio * 100).toStringAsFixed(0)}% vs ${(payableRatio * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                height: 8,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: (receivableRatio * 100).toInt(),
                                      child: Container(color: Colors.green.shade400),
                                    ),
                                    Expanded(
                                      flex: (payableRatio * 100).toInt(),
                                      child: Container(color: Colors.red.shade400),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      ],
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (err, _) => Center(child: Text('Error loading summary: $err')),
                ),

                // Quick Actions Grid
                const SizedBox(height: 28),
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.add_box_outlined,
                      label: 'Quick Add',
                      onTap: () => context.push('/transaction/quick-add'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.assignment_outlined,
                      label: 'Reports',
                      onTap: () => context.push('/reports'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.delete_sweep_outlined,
                      label: 'Trash',
                      onTap: () => context.push('/trash'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),

                // Recent Activity Header
                const SizedBox(height: 28),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                recentAsync.when(
                  data: (recentList) {
                    if (recentList.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Column(
                            children: [
                              const Text('💸', style: TextStyle(fontSize: 40)),
                              const SizedBox(height: 8),
                              Text('No transactions recorded yet.', style: TextStyle(color: Colors.grey[500])),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentList.length,
                      itemBuilder: (context, index) {
                        final item = recentList[index];
                        final tx = item['transaction'] as Transaction;
                        final personName = item['personName'] as String;
                        final isGaveOrPaid = tx.type == TransactionType.gave || tx.type == TransactionType.paid;
                        final color = isGaveOrPaid ? Colors.green[700] : Colors.red[700];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.grey.shade100),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color?.withValues(alpha: 0.08),
                              child: Icon(
                                isGaveOrPaid ? Icons.arrow_outward : Icons.call_received,
                                color: color,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              personName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              '${tx.type.name.toUpperCase()} • ${item['khataTitle']}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            trailing: Text(
                              '$currency ${tx.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: color,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.withValues(alpha: 0.04),
          border: Border.all(color: Colors.teal.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.teal, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.teal),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
