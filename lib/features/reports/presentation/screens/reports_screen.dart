import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../people/presentation/providers/balance_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';
import '../providers/reports_providers.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedCategory =
      'Ledger'; // Ledger, Outstanding, Due, CashFlow, ExportHistory
  String _searchQuery = '';
  String _historySearchQuery = '';
  String _historySortOrder = 'Newest'; // Newest, Oldest
  final Set<String> _expandedPersonUuids = {};

  Future<void> _onRefresh() async {
    await ref.read(peopleListProvider.notifier).loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports & Statements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Categories Header Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryTab('Ledger', Icons.menu_book_rounded),
                _buildCategoryTab('Outstanding', Icons.account_balance_rounded),
                _buildCategoryTab('Due Alert', Icons.warning_amber_rounded),
                _buildCategoryTab('Cash Flow', Icons.trending_up_rounded),
                _buildCategoryTab('Export History', Icons.history_rounded),
              ],
            ),
          ),

          const Divider(height: 1),

          // Main content based on selection
          Expanded(child: _buildReportContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          color: isSelected ? Colors.white : AppDesign.primaryEmerald,
          size: 14,
        ),
        label: Text(category, style: const TextStyle(fontSize: 11)),
        selected: isSelected,
        selectedColor: AppDesign.primaryEmerald,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedCategory = category;
            });
          }
        },
      ),
    );
  }

  Widget _buildReportContent(bool isDark) {
    switch (_selectedCategory) {
      case 'Outstanding':
        return _buildOutstandingReport(isDark);
      case 'Due Alert':
        return _buildDueReport(isDark);
      case 'Cash Flow':
        return _buildCashFlowReport(isDark);
      case 'Export History':
        return _buildExportHistoryReport(isDark);
      case 'Ledger':
      default:
        return _buildLedgerReport(isDark);
    }
  }

  // 1. Ledger Report (Original listing)
  Widget _buildLedgerReport(bool isDark) {
    final peopleState = ref.watch(peopleListProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search contacts...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppDesign.primaryEmerald,
              ),
              filled: true,
              fillColor: isDark ? AppDesign.darkCard : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: AppDesign.borderMedium,
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: peopleState.when(
            data: (people) {
              final filtered = people
                  .where((p) => p.name.toLowerCase().contains(_searchQuery))
                  .toList();

              if (filtered.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AppDesign.primaryEmerald,
                  child: ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: const EmptyState(
                          icon: '📊',
                          title: 'No contacts found',
                          subtitle:
                              'Add contacts first to generate statement PDFs.',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppDesign.primaryEmerald,
                child: ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  itemBuilder: (context, index) {
                    final person = filtered[index];
                    final isExpanded = _expandedPersonUuids.contains(
                      person.uuid,
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppDesign.primaryEmerald
                                  .withValues(alpha: 0.1),
                              child: Text(
                                person.name.substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppDesign.primaryEmerald,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              person.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              person.phone ?? 'No phone number',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppDesign.primaryEmerald,
                              size: 18,
                            ),
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedPersonUuids.remove(person.uuid);
                                } else {
                                  _expandedPersonUuids.add(person.uuid);
                                }
                              });
                            },
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            _PersonKhatasView(
                              personUuid: person.uuid,
                              personName: person.name,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
            ),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  // 2. Outstanding Report
  Widget _buildOutstandingReport(bool isDark) {
    final peopleState = ref.watch(peopleListProvider);
    final currency = ref.watch(currencySymbolProvider);

    return peopleState.when(
      data: (people) {
        if (people.isEmpty) {
          return const EmptyState(
            icon: '🏦',
            title: 'No accounts',
            subtitle: 'No ledger accounts registered yet.',
          );
        }

        return ListView.builder(
          itemCount: people.length,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          itemBuilder: (context, index) {
            final person = people[index];
            final balanceAsync = ref.watch(personBalanceProvider(person.uuid));

            return balanceAsync.when(
              loading: () => const LinearProgressIndicator(
                color: AppDesign.primaryEmerald,
              ),
              error: (_, __) => const SizedBox(),
              data: (bal) {
                if (bal == 0.0) return const SizedBox.shrink(); // settled
                final isReceivable = bal > 0;
                final badgeColor = isReceivable
                    ? AppDesign.greenReceivable
                    : AppDesign.redPayable;

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    title: Text(
                      person.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: Text(
                      isReceivable
                          ? 'Outstanding Receivable'
                          : 'Outstanding Payable',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: StatusBadge(
                      label: '$currency ${bal.abs().toStringAsFixed(0)}',
                      color: badgeColor,
                    ),
                    onTap: () => context.push('/people/${person.uuid}'),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  // 3. Due Report
  Widget _buildDueReport(bool isDark) {
    final peopleState = ref.watch(peopleListProvider);

    return peopleState.when(
      data: (people) {
        final List<Widget> items = [];
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        return Consumer(
          builder: (context, ref, child) {
            for (final person in people) {
              final summaryAsync = ref.watch(
                personFinancialSummaryProvider(person.uuid),
              );
              summaryAsync.whenData((summary) {
                if (summary.nextDueDate != null) {
                  final due = summary.nextDueDate!;
                  final isOverdue = due.isBefore(today);

                  items.add(
                    Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              (isOverdue
                                      ? AppDesign.redPayable
                                      : AppDesign.amberWarning)
                                  .withValues(alpha: 0.1),
                          child: Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.today_rounded,
                            color: isOverdue
                                ? AppDesign.redPayable
                                : AppDesign.amberWarning,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          person.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Due: ${due.day}/${due.month}/${due.year}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: StatusBadge(
                          label: isOverdue ? 'Overdue' : 'Due Soon',
                          color: isOverdue
                              ? AppDesign.redPayable
                              : AppDesign.amberWarning,
                        ),
                        onTap: () => context.push('/people/${person.uuid}'),
                      ),
                    ),
                  );
                }
              });
            }

            if (items.isEmpty) {
              return const EmptyState(
                icon: '🔔',
                title: 'No upcoming dues',
                subtitle:
                    'All active transactions have been settled or have no due dates.',
              );
            }

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: items,
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
      ),
      error: (e, s) => const SizedBox(),
    );
  }

  // 4. Cash Flow Summary
  Widget _buildCashFlowReport(bool isDark) {
    final currency = ref.watch(currencySymbolProvider);
    final insightsAsync = ref.watch(dashboardMonthlyInsightsProvider);

    return insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) {
          return const EmptyState(
            icon: '📈',
            title: 'No cash flow data',
            subtitle: 'Writings transactions will plot trends here.',
          );
        }

        return ListView.builder(
          itemCount: insights.length,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          itemBuilder: (context, index) {
            final ins = insights[index];
            final isPositive = ins.netCashflow >= 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ins.monthLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        StatusBadge(
                          label:
                              'Net: $currency ${ins.netCashflow.toStringAsFixed(0)}',
                          color: isPositive
                              ? AppDesign.greenReceivable
                              : AppDesign.redPayable,
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CASH IN (Collected)',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$currency ${ins.cashIn.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppDesign.greenReceivable,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'CASH OUT (Lent)',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$currency ${ins.cashOut.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppDesign.redPayable,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
      ),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  // 5. Export History Report Category
  Widget _buildExportHistoryReport(bool isDark) {
    final history = ref.watch(reportHistoryProvider);

    // Calculate summaries
    final totalReports = history.length;
    final lastExportDateStr = history.isNotEmpty
        ? '${history.first.exportedAt.day}/${history.first.exportedAt.month}/${history.first.exportedAt.year} ${history.first.exportedAt.hour.toString().padLeft(2, '0')}:${history.first.exportedAt.minute.toString().padLeft(2, '0')}'
        : 'Never';

    // Apply Search
    var filteredHistory = List<ReportExportLog>.from(history);
    if (_historySearchQuery.isNotEmpty) {
      filteredHistory = filteredHistory
          .where(
            (log) =>
                log.personName.toLowerCase().contains(_historySearchQuery) ||
                log.khataTitle.toLowerCase().contains(_historySearchQuery),
          )
          .toList();
    }

    // Apply Sort
    if (_historySortOrder == 'Newest') {
      filteredHistory.sort((a, b) => b.exportedAt.compareTo(a.exportedAt));
    } else {
      filteredHistory.sort((a, b) => a.exportedAt.compareTo(b.exportedAt));
    }

    return Column(
      children: [
        // Summary Header Cards
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppDesign.darkCard : Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL EXPORTS',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$totalReports Statement${totalReports == 1 ? "" : "s"}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'LAST EXPORT DATE',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lastExportDateStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: AppDesign.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Search and Sort controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search exported history...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppDesign.primaryEmerald,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: isDark ? AppDesign.darkCard : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: AppDesign.borderMedium,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _historySearchQuery = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _historySortOrder,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.sort_rounded,
                  color: AppDesign.primaryEmerald,
                  size: 18,
                ),
                style: const TextStyle(
                  color: AppDesign.primaryEmerald,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                items: ['Newest', 'Oldest'].map((sort) {
                  return DropdownMenuItem(value: sort, child: Text(sort));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _historySortOrder = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),

        // History logs listing
        Expanded(
          child: filteredHistory.isEmpty
              ? const EmptyState(
                  icon: '📭',
                  title: 'No export records',
                  subtitle:
                      'Statement exports and sharing records will appear here.',
                )
              : ListView.builder(
                  itemCount: filteredHistory.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  itemBuilder: (context, index) {
                    final log = filteredHistory[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                        title: Text(
                          log.khataTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          'Contact: ${log.personName}\nFormat: ${log.format}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Text(
                          '${log.exportedAt.day}/${log.exportedAt.month} ${log.exportedAt.hour.toString().padLeft(2, '0')}:${log.exportedAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PersonKhatasView extends ConsumerWidget {
  final String personUuid;
  final String personName;

  const _PersonKhatasView({required this.personUuid, required this.personName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khatasState = ref.watch(khatasForPersonProvider(personUuid));

    return khatasState.when(
      data: (khatas) {
        if (khatas.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'No accounts / Khatas created for this contact.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: khatas.length,
          itemBuilder: (context, index) {
            final khata = khatas[index];
            return Column(
              children: [
                if (index > 0) const Divider(height: 1, indent: 16),
                ListTile(
                  dense: true,
                  title: Text(
                    khata.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    khata.notes ?? 'No remarks',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () {
                      ref
                          .read(reportHistoryProvider.notifier)
                          .logExport(
                            khataTitle: khata.title,
                            personName: personName,
                          );
                      context.push('/statement/${khata.uuid}');
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                    label: const Text('View Statement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppDesign.primaryEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppDesign.primaryEmerald,
            ),
          ),
        ),
      ),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
