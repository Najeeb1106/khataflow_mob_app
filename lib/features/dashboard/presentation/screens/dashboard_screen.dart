import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/services/security_service.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
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

  String _getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDate = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDate).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff > 1 && diff < 7) return '$diff days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentAsync = ref.watch(dashboardRecentTransactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dueStatsAsync = ref.watch(dashboardDueStatsProvider);
    final dueStats = dueStatsAsync.valueOrNull;
    int notificationCount = 0;
    if (dueStats != null) {
      notificationCount += (dueStats['overdue']?.length ?? 0);
      notificationCount += (dueStats['dueToday']?.length ?? 0);
      notificationCount += (dueStats['dueTomorrow']?.length ?? 0);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KhataFlow',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: AppDesign.primaryEmerald,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              _getFormattedDate(),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search_rounded,
              color: AppDesign.primaryEmerald,
              size: 24,
            ),
            tooltip: 'Search everything',
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: Badge(
              label: Text(notificationCount.toString()),
              backgroundColor: AppDesign.redPayable,
              isLabelVisible: notificationCount > 0,
              child: Icon(
                Icons.notifications_outlined,
                color: AppDesign.primaryEmerald,
                size: 24,
              ),
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppDesign.primaryEmerald,
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(dashboardRecentTransactionsProvider);
            ref.invalidate(dashboardDueStatsProvider);
            ref.invalidate(dashboardMonthlyInsightsProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.space24,
              vertical: AppDesign.space16,
            ),
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
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),

                summaryAsync.when(
                  data: (summary) {
                    final isPositive = summary.netPosition > 0;
                    final isNegative = summary.netPosition < 0;
                    final total =
                        summary.totalReceivable + summary.totalPayable;
                    final receivableRatio = total > 0
                        ? summary.totalReceivable / total
                        : 0.5;
                    final payableRatio = total > 0
                        ? summary.totalPayable / total
                        : 0.5;

                    return Column(
                      children: [
                        // Premium Gradient position card
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPositive
                                  ? [
                                      const Color(0xFF0F766E),
                                      const Color(0xFF10B981),
                                    ]
                                  : isNegative
                                  ? [
                                      const Color(0xFF7F1D1D),
                                      const Color(0xFFEF4444),
                                    ]
                                  : [
                                      const Color(0xFF1E293B),
                                      const Color(0xFF475569),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: AppDesign.borderLarge,
                            boxShadow: AppDesign.premiumShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: AppDesign.borderLarge,
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
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(
                                    AppDesign.space16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NET POSITION',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$currency ${summary.netPosition.abs().toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              summary.netPosition >= 0
                                                  ? Icons.trending_up_rounded
                                                  : Icons.trending_down_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              summary.netPosition > 0
                                                  ? 'Net Receivable'
                                                  : summary.netPosition < 0
                                                  ? 'Net Payable'
                                                  : 'Settled Balance',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 10),

                        // Two Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(
                                  10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50.withValues(
                                    alpha: isDark ? 0.05 : 0.5,
                                  ),
                                  border: Border.all(
                                    color: Colors.green.shade100.withValues(
                                      alpha: isDark ? 0.1 : 0.6,
                                    ),
                                  ),
                                  borderRadius: AppDesign.borderMedium,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You Will Get',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.green.shade400
                                            : Colors.green.shade800,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$currency ${summary.totalReceivable.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.green.shade300
                                            : Colors.green.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(
                                  10.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50.withValues(
                                    alpha: isDark ? 0.05 : 0.5,
                                  ),
                                  border: Border.all(
                                    color: Colors.red.shade100.withValues(
                                      alpha: isDark ? 0.1 : 0.6,
                                    ),
                                  ),
                                  borderRadius: AppDesign.borderMedium,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You Will Give',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isDark
                                            ? Colors.red.shade400
                                            : Colors.red.shade800,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$currency ${summary.totalPayable.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.red.shade300
                                            : Colors.red.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Cashflow Ratio Progress Bar
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Receivables vs Payables',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  summary.totalReceivable == 0 && summary.totalPayable == 0
                                      ? 'No active balance yet'
                                      : 'Receive ${(receivableRatio * 100).toStringAsFixed(0)}% • Give ${(payableRatio * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade300
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final totalWidth = constraints.maxWidth;
                                final hasActiveBalance = summary.totalReceivable > 0 || summary.totalPayable > 0;
                                final targetGreenWidth = hasActiveBalance ? totalWidth * receivableRatio : 0.0;
                                final backgroundColor = hasActiveBalance 
                                    ? AppDesign.redPayable 
                                    : (isDark ? Colors.grey.shade800 : Colors.grey.shade300);

                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: totalWidth,
                                    height: 8,
                                    color: backgroundColor,
                                    child: Stack(
                                      children: [
                                        if (hasActiveBalance)
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 400),
                                            curve: Curves.easeInOut,
                                            width: targetGreenWidth,
                                            height: 8,
                                            color: AppDesign.primaryEmerald,
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: AppDesign.primaryEmerald,
                      ),
                    ),
                  ),
                  error: (err, _) =>
                      Center(child: Text('Error loading summary: $err')),
                ),

                // Due Statuses Section
                const SizedBox(height: 12),
                const SectionHeader(title: 'Due Statuses'),
                const SizedBox(height: 6),
                ref
                    .watch(dashboardDueStatsProvider)
                    .when(
                      data: (stats) {
                        final overdueTxs = stats['overdue'] ?? [];
                        final dueTodayTxs = stats['dueToday'] ?? [];
                        final dueTomorrowTxs = stats['dueTomorrow'] ?? [];
                        final upcomingTxs = stats['upcoming'] ?? [];

                        // ── Empty state: all dues are zero ───────────────────
                        if (overdueTxs.isEmpty &&
                            dueTodayTxs.isEmpty &&
                            dueTomorrowTxs.isEmpty &&
                            upcomingTxs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppDesign.greenReceivable.withValues(
                                alpha: isDark ? 0.05 : 0.04,
                              ),
                              borderRadius: AppDesign.borderMedium,
                              border: Border.all(
                                color: AppDesign.greenReceivable.withValues(
                                  alpha: isDark ? 0.15 : 0.15,
                                ),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 36),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No dues currently.',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? Colors.green.shade300
                                        : Colors.green.shade800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All accounts are settled or have no upcoming due dates.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final overdueTotal = overdueTxs.fold<double>(
                          0,
                          (sum, item) =>
                              sum + (item['transaction'] as Transaction).amount,
                        );
                        final dueTodayTotal = dueTodayTxs.fold<double>(
                          0,
                          (sum, item) =>
                              sum + (item['transaction'] as Transaction).amount,
                        );
                        final dueTomorrowTotal = dueTomorrowTxs.fold<double>(
                          0,
                          (sum, item) =>
                              sum + (item['transaction'] as Transaction).amount,
                        );
                        final upcomingTotal = upcomingTxs.fold<double>(
                          0,
                          (sum, item) =>
                              sum + (item['transaction'] as Transaction).amount,
                        );

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.6,
                          children: [
                            _buildDueStatusCard(
                              context,
                              title: 'Overdue',
                              count: overdueTxs.length,
                              total: overdueTotal,
                              currency: currency,
                              color: AppDesign.redPayable,
                              icon: Icons.warning_amber_rounded,
                              onTap: () => _showDueTransactionsBottomSheet(
                                context,
                                'Overdue Transactions',
                                overdueTxs,
                                currency,
                              ),
                            ),
                            _buildDueStatusCard(
                              context,
                              title: 'Due Today',
                              count: dueTodayTxs.length,
                              total: dueTodayTotal,
                              currency: currency,
                              color: AppDesign.amberWarning,
                              icon: Icons.today_rounded,
                              onTap: () => _showDueTransactionsBottomSheet(
                                context,
                                'Due Today',
                                dueTodayTxs,
                                currency,
                              ),
                            ),
                            _buildDueStatusCard(
                              context,
                              title: 'Due Tomorrow',
                              count: dueTomorrowTxs.length,
                              total: dueTomorrowTotal,
                              currency: currency,
                              color: Colors.blueAccent,
                              icon: Icons.notifications_active_outlined,
                              onTap: () => _showDueTransactionsBottomSheet(
                                context,
                                'Due Tomorrow',
                                dueTomorrowTxs,
                                currency,
                              ),
                            ),
                            _buildDueStatusCard(
                              context,
                              title: 'Upcoming',
                              count: upcomingTxs.length,
                              total: upcomingTotal,
                              currency: currency,
                              color: AppDesign.grayNeutral,
                              icon: Icons.calendar_month_rounded,
                              onTap: () => _showDueTransactionsBottomSheet(
                                context,
                                'Upcoming Due Transactions',
                                upcomingTxs,
                                currency,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            color: AppDesign.primaryEmerald,
                          ),
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text('Error loading due statuses: $err'),
                      ),
                    ),

                // Cash Flow Trends (Analytics Graph)
                const SizedBox(height: 12),
                const SectionHeader(title: 'Monthly Cash Flow Trends'),
                const SizedBox(height: 6),
                ref
                    .watch(dashboardMonthlyInsightsProvider)
                    .when(
                      data: (insights) {
                        if (insights.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No historical transaction data available to plot.',
                              ),
                            ),
                          );
                        }

                        final reversedInsights = insights.reversed.toList();
                        final maxAmount = reversedInsights.fold<double>(
                          1000,
                          (maxVal, item) =>
                              (item.cashIn > item.cashOut
                                      ? item.cashIn
                                      : item.cashOut) >
                                  maxVal
                              ? (item.cashIn > item.cashOut
                                    ? item.cashIn
                                    : item.cashOut)
                              : maxVal,
                        );

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDesign.borderMedium,
                            side: BorderSide(
                              color: isDark
                                  ? AppDesign.darkBorder
                                  : AppDesign.lightBorder,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 140,
                                  child: BarChart(
                                    BarChartData(
                                      alignment: BarChartAlignment.spaceAround,
                                      maxY: maxAmount * 1.15,
                                      barTouchData: BarTouchData(enabled: true),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            getTitlesWidget:
                                                (double value, TitleMeta meta) {
                                                  final index = value.toInt();
                                                  if (index >= 0 &&
                                                      index <
                                                          reversedInsights
                                                              .length) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            top: 6,
                                                          ),
                                                      child: Text(
                                                        reversedInsights[index]
                                                            .monthLabel
                                                            .split(' ')
                                                            .first,
                                                        style: const TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return const Text('');
                                                },
                                          ),
                                        ),
                                        leftTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        rightTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                        topTitles: const AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: false,
                                          ),
                                        ),
                                      ),
                                      gridData: const FlGridData(show: false),
                                      borderData: FlBorderData(show: false),
                                      barGroups: List.generate(
                                        reversedInsights.length,
                                        (index) {
                                          final insight =
                                              reversedInsights[index];
                                          return BarChartGroupData(
                                            x: index,
                                            barRods: [
                                              BarChartRodData(
                                                toY: insight.cashIn,
                                                color: AppDesign.primaryEmerald,
                                                width: 10,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              BarChartRodData(
                                                toY: insight.cashOut,
                                                color: AppDesign.redPayable,
                                                width: 10,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppDesign.primaryEmerald,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Cash In',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppDesign.redPayable,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Cash Out',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppDesign.primaryEmerald,
                        ),
                      ),
                      error: (e, s) => const SizedBox.shrink(),
                    ),

                // Quick Actions Grid
                const SizedBox(height: 12),
                const SectionHeader(title: 'Quick Actions'),
                const SizedBox(height: 6),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.add_box_rounded,
                      label: 'Quick Add',
                      onTap: () => context.push('/transaction/quick-add'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.people_alt_rounded,
                      label: 'People',
                      onTap: () => context.push('/people'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.analytics_rounded,
                      label: 'Reports',
                      onTap: () => context.push('/reports'),
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () => context.push('/settings'),
                    ),
                  ],
                ),

                // Recent Activity Header
                const SizedBox(height: 12),
                const SectionHeader(title: 'Recent Activity'),
                const SizedBox(height: 6),

                recentAsync.when(
                  data: (recentList) {
                    if (recentList.isEmpty) {
                      return EmptyState(
                        icon: '💸',
                        title: 'No Transactions Yet',
                        subtitle: 'Start by adding your first transaction.',
                        isCompact: true,
                        action: AppButton(
                          label: 'Add Transaction',
                          icon: Icons.add_rounded,
                          isCompact: true,
                          onPressed: () =>
                              context.push('/transaction/quick-add'),
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
                        final isGaveOrPaid =
                            tx.type == TransactionType.gave ||
                            tx.type == TransactionType.paid;
                        final color = isGaveOrPaid
                            ? AppDesign.greenReceivable
                            : AppDesign.redPayable;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: color.withValues(alpha: 0.08),
                              child: Icon(
                                isGaveOrPaid
                                    ? Icons.arrow_outward_rounded
                                    : Icons.call_received_rounded,
                                color: color,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              personName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              '${tx.type.name.toUpperCase()} • ${item['khataTitle']} • ${_getRelativeDateString(tx.transactionDate ?? tx.createdAt)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                            trailing: Text(
                              '$currency ${tx.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                                fontSize: 13,
                              ),
                            ),
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
                  error: (err, _) => Text('Error: $err'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDesign.borderMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppDesign.primaryEmerald.withValues(alpha: 0.04),
            border: Border.all(
              color: AppDesign.primaryEmerald.withValues(alpha: 0.1),
            ),
            borderRadius: AppDesign.borderMedium,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppDesign.primaryEmerald, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey.shade300 : AppDesign.primaryTeal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueStatusCard(
    BuildContext context, {
    required String title,
    required int count,
    required double total,
    required String currency,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
        borderRadius: AppDesign.borderMedium,
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDesign.borderMedium,
        child: Padding(
          padding: const EdgeInsets.all(AppDesign.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currency ${total.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDueTransactionsBottomSheet(
    BuildContext context,
    String title,
    List<Map<String, dynamic>> items,
    String currency,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppDesign.primaryEmerald,
                      letterSpacing: -0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions in this category.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final tx = item['transaction'] as Transaction;
                          final personName = item['personName'] as String;
                          final khataTitle = item['khataTitle'] as String;
                          final isGaveOrPaid =
                              tx.type == TransactionType.gave ||
                              tx.type == TransactionType.paid;
                          final color = isGaveOrPaid
                              ? AppDesign.greenReceivable
                              : AppDesign.redPayable;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              title: Text(
                                personName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${tx.type.name.toUpperCase()} • $khataTitle\nDue: ${tx.dueDate!.day}/${tx.dueDate!.month}/${tx.dueDate!.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.black54,
                                ),
                              ),
                              trailing: Text(
                                '$currency ${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
