import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/balance_calculator.dart';
import '../../data/models/person.dart';
import '../providers/people_providers.dart';
import '../providers/balance_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final String personUuid;
  const PersonDetailScreen({super.key, required this.personUuid});

  @override
  ConsumerState<PersonDetailScreen> createState() => _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  Person? _person;
  bool _isLoading = false;
  DateTime? _lastTransactionDate;
  double _averageTransactionSize = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPerson();
    _loadStats();
  }

  Future<void> _loadPerson() async {
    setState(() => _isLoading = true);
    final repo = ref.read(personRepositoryProvider);
    final p = await repo.getPerson(widget.personUuid);
    if (p != null && mounted) {
      setState(() => _person = p);
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadStats() async {
    final khataRepo = ref.read(khataRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);
    final khatas = await khataRepo.getKhatasForPerson(widget.personUuid);

    double totalAmount = 0.0;
    int count = 0;
    DateTime? lastDate;

    for (final khata in khatas) {
      final txs = await txRepo.getTransactionsForKhata(khata.uuid);
      for (final tx in txs) {
        totalAmount += tx.amount;
        count++;
        final txDate = tx.transactionDate ?? tx.createdAt;
        if (lastDate == null || txDate.isAfter(lastDate)) {
          lastDate = txDate;
        }
      }
    }

    if (mounted) {
      setState(() {
        _lastTransactionDate = lastDate;
        _averageTransactionSize = count > 0 ? totalAmount / count : 0.0;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadPerson();
    await _loadStats();
    ref.invalidate(personBalanceProvider(widget.personUuid));
    ref.invalidate(personFinancialSummaryProvider(widget.personUuid));
  }

  String _getMonthName(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
        ),
      );
    }

    if (_person == null) {
      return const Scaffold(body: Center(child: Text('Contact not found.')));
    }

    final khatasState = ref.watch(khatasForPersonProvider(widget.personUuid));
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _person!.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit contact',
            onPressed: () async {
              await context.push('/people/${_person!.uuid}/edit');
              _loadPerson();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppDesign.redPayable,
            ),
            tooltip: 'Delete contact',
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppDesign.primaryEmerald,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Net Balance Header Card
              ref
                  .watch(personFinancialSummaryProvider(widget.personUuid))
                  .when(
                    loading: () => const LinearProgressIndicator(
                      minHeight: 3,
                      color: AppDesign.primaryEmerald,
                    ),
                    error: (err, _) => Center(child: Text('Error: $err')),
                    data: (summary) {
                      final isPositive = summary.netBalance > 0;
                      final isNegative = summary.netBalance < 0;
                      final netColor = isPositive
                          ? AppDesign.greenReceivable
                          : isNegative
                          ? AppDesign.redPayable
                          : AppDesign.grayNeutral;
                      final statusLabel = BalanceCalculator.getStatusLabel(
                        summary.netBalance,
                      );
  
                      return Semantics(
                        label:
                            'Financial Summary for ${_person!.name}, balance is ${BalanceCalculator.formatPkr(summary.netBalance, currency)}',
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppDesign.space16,
                            vertical: AppDesign.space12,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppDesign.space20),
                            child: Column(
                              children: [
                                Text(
                                  statusLabel.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : AppDesign.primaryTeal,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  BalanceCalculator.formatPkr(
                                    summary.netBalance,
                                    currency,
                                  ),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: netColor,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
  
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        'Total Lent',
                                        BalanceCalculator.formatPkr(
                                          summary.totalGiven,
                                          currency,
                                        ),
                                        AppDesign.greenReceivable,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        'Total Received',
                                        BalanceCalculator.formatPkr(
                                          summary.totalReceived,
                                          currency,
                                        ),
                                        AppDesign.redPayable,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildSummaryItem(
                                        'Total Borrowed',
                                        BalanceCalculator.formatPkr(
                                          summary.totalBorrowed,
                                          currency,
                                        ),
                                        AppDesign.amberWarning,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildSummaryItem(
                                        'Total Repaid',
                                        BalanceCalculator.formatPkr(
                                          summary.totalPaid,
                                          currency,
                                        ),
                                        AppDesign.primaryTeal,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
  
              // Metadata summary card (Customer Since, Avg Transaction, Last Tx)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppDesign.space16),
                padding: const EdgeInsets.all(AppDesign.space16),
                decoration: BoxDecoration(
                  color: isDark ? AppDesign.darkCard : Colors.white,
                  borderRadius: AppDesign.borderMedium,
                  border: Border.all(
                    color: isDark ? AppDesign.darkBorder : AppDesign.lightBorder,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetaLabel('Contact Created'),
                        _buildMetaValue(
                          '${_getMonthName(_person!.createdAt)} ${_person!.createdAt.year}',
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetaLabel('Last Transaction'),
                        _buildMetaValue(
                          _lastTransactionDate != null
                              ? '${_lastTransactionDate!.day} ${_getMonthName(_lastTransactionDate!)} ${_lastTransactionDate!.year}'
                              : 'No transactions',
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMetaLabel('Average Transaction'),
                        _buildMetaValue(
                          '$currency ${_averageTransactionSize.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
  
              const SizedBox(height: AppDesign.space12),
  
              // Quick Actions Row
              khatasState.when(
                data: (khatas) => _buildQuickActionsSection(context, khatas),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
  
              // Khatas Section
              Padding(
                padding: const EdgeInsets.all(AppDesign.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Accounts / Khatas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('New Khata'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppDesign.primaryEmerald,
                            minimumSize: const Size(48, 48), // tap target size
                          ),
                          onPressed: () => context.push(
                            '/people/${_person!.uuid}/khata/add',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDesign.space8),
                    khatasState.when(
                      data: (khatas) {
                        if (khatas.isEmpty) {
                          return EmptyState(
                            icon: '📂',
                            title: 'No accounts added',
                            subtitle:
                                'Create a Khata to log transactions for this contact.',
                            action: AppButton(
                              label: 'Create a Khata',
                              icon: Icons.add_rounded,
                              onPressed: () => context.push(
                                '/people/${_person!.uuid}/khata/add',
                              ),
                            ),
                          );
                        }
  
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: khatas.length,
                          itemBuilder: (context, index) {
                            final khata = khatas[index];
                            final khataBalanceAsync = ref.watch(
                              khataBalanceProvider(khata.uuid),
                            );
  
                            return khataBalanceAsync.when(
                              loading: () => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: const ListTile(
                                  title: LinearProgressIndicator(
                                    minHeight: 2,
                                    color: AppDesign.primaryEmerald,
                                  ),
                                ),
                              ),
                              error: (_, __) => const SizedBox(),
                              data: (bal) {
                                final isOwed = bal >= 0;
                                final color = isOwed
                                    ? AppDesign.greenReceivable
                                    : AppDesign.redPayable;
  
                                return Semantics(
                                  label:
                                      'Khata: ${khata.title}, balance $currency ${bal.abs().toStringAsFixed(0)}',
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      dense: true,
                                      onTap: () => context.push(
                                        '/khata/${khata.uuid}',
                                      ),
                                      title: Text(
                                        khata.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: khata.notes != null
                                          ? Text(
                                              khata.notes!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$currency ${bal.abs().toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppDesign.primaryEmerald,
                        ),
                      ),
                      error: (err, _) =>
                          Center(child: Text('Error loading accounts: $err')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaLabel(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMetaValue(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    );
  }

  void _confirmDelete(BuildContext context) {
    final khatas =
        ref.read(khatasForPersonProvider(widget.personUuid)).value ?? [];
    final summary = ref
        .read(personFinancialSummaryProvider(widget.personUuid))
        .value;

    final khataCount = khatas.length;
    final txCount = summary?.transactionCount ?? 0;
    final outstanding = summary?.netBalance ?? 0.0;
    final currency = ref.read(currencySymbolProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: const Text('Delete Contact Safely?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete ${_person!.name}?\nThis contact has linked data:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('• Accounts (Khatas): $khataCount'),
            Text('• Transactions: $txCount'),
            Text(
              '• Net Outstanding Balance: ${BalanceCalculator.formatPkr(outstanding, currency)}',
            ),
            const SizedBox(height: 16),
            const Text(
              'All linked khatas and transactions will be moved to Trash and can be restored within 30 days.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () async {
              await ref
                  .read(peopleListProvider.notifier)
                  .deletePerson(_person!.uuid);
              if (context.mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _onQuickActionTapped(
    BuildContext context,
    String type,
    List<dynamic> khatas,
  ) {
    if (khatas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please create a Khata account for this contact first.',
          ),
        ),
      );
      return;
    }

    if (khatas.length == 1) {
      final khata = khatas.first;
      context.push('/transaction/advanced?khataUuid=${khata.uuid}&type=$type');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: const Text('Select Account (Khata)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: khatas.map((khata) {
            return ListTile(
              title: Text(khata.title),
              onTap: () {
                Navigator.pop(context);
                context.push(
                  '/transaction/advanced?khataUuid=${khata.uuid}&type=$type',
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, List<dynamic> khatas) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.space16,
        vertical: AppDesign.space8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionButtonCard(
                context,
                label: 'Lent',
                color: AppDesign.greenReceivable,
                icon: Icons.arrow_upward_rounded,
                onTap: () => _onQuickActionTapped(context, 'gave', khatas),
              ),
              _buildActionButtonCard(
                context,
                label: 'Received',
                color: AppDesign.redPayable,
                icon: Icons.arrow_downward_rounded,
                onTap: () => _onQuickActionTapped(context, 'received', khatas),
              ),
              _buildActionButtonCard(
                context,
                label: 'Borrowed',
                color: AppDesign.amberWarning,
                icon: Icons.call_received_rounded,
                onTap: () => _onQuickActionTapped(context, 'borrowed', khatas),
              ),
              _buildActionButtonCard(
                context,
                label: 'Repaid',
                color: AppDesign.primaryTeal,
                icon: Icons.call_made_rounded,
                onTap: () => _onQuickActionTapped(context, 'paid', khatas),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonCard(
    BuildContext context, {
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppDesign.borderMedium,
          side: BorderSide(color: color.withValues(alpha: 0.15)),
        ),
        color: color.withValues(alpha: 0.04),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDesign.borderMedium,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
