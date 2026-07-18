import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/balance_calculator.dart';
import '../../data/models/khata.dart';
import '../providers/khata_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/data/models/transaction.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class KhataDetailScreen extends ConsumerStatefulWidget {
  final String khataUuid;
  const KhataDetailScreen({super.key, required this.khataUuid});

  @override
  ConsumerState<KhataDetailScreen> createState() => _KhataDetailScreenState();
}

class _KhataDetailScreenState extends ConsumerState<KhataDetailScreen> {
  Khata? _khata;
  bool _isLoading = false;
  String _selectedFilter = 'All';
  String _selectedSort = 'Due Date';

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
  void initState() {
    super.initState();
    _loadKhata();
  }

  Future<void> _loadKhata() async {
    setState(() => _isLoading = true);
    final repo = ref.read(khataRepositoryProvider);
    final k = await repo.getKhata(widget.khataUuid);
    if (k != null && mounted) setState(() => _khata = k);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _onRefresh() async {
    await _loadKhata();
    ref.invalidate(transactionsForKhataProvider(widget.khataUuid));
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

    if (_khata == null) {
      return const Scaffold(body: Center(child: Text('Khata not found.')));
    }

    final txsState = ref.watch(transactionsForKhataProvider(widget.khataUuid));
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _khata!.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.picture_as_pdf_outlined,
              color: AppDesign.primaryEmerald,
            ),
            tooltip: 'Export PDF statement',
            onPressed: () => context.push('/statement/${_khata!.uuid}'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit khata',
            onPressed: () async {
              await context.push(
                '/people/${_khata!.personUuid}/khata/${_khata!.uuid}/edit',
              );
              _loadKhata();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppDesign.redPayable,
            ),
            tooltip: 'Delete khata',
            onPressed: () => _confirmDelete(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppDesign.primaryEmerald,
          child: Column(
            children: [
              // Balance Summary Card
              txsState.when(
                data: (txs) {
                  final bal = BalanceCalculator.calculate(txs);
                  final color = bal >= 0
                      ? AppDesign.greenReceivable
                      : AppDesign.redPayable;
                  final label = BalanceCalculator.getLedgerLabel(bal);
  
                  double totalGiven = 0.0;
                  double totalReceived = 0.0;
                  double totalBorrowed = 0.0;
                  double totalPaid = 0.0;
  
                  for (final tx in txs) {
                    if (tx.type == TransactionType.gave) totalGiven += tx.amount;
                    if (tx.type == TransactionType.received)
                      totalReceived += tx.amount;
                    if (tx.type == TransactionType.borrowed)
                      totalBorrowed += tx.amount;
                    if (tx.type == TransactionType.paid) totalPaid += tx.amount;
                  }
  
                  Widget progressWidget = const SizedBox();
                  if (bal == 0.0) {
                    progressWidget = const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: StatusBadge(
                        label: 'Fully Settled',
                        color: AppDesign.greenReceivable,
                      ),
                    );
                  } else if (bal > 0) {
                    final totalRecovered = totalReceived;
                    final totalTarget = totalGiven;
                    final pct = totalTarget > 0
                        ? (totalRecovered / totalTarget).clamp(0.0, 1.0)
                        : 0.0;
                    progressWidget = _buildProgressSection(
                      'Loan Recovery Progress',
                      'Recovered',
                      BalanceCalculator.formatPkr(totalRecovered, currency),
                      BalanceCalculator.formatPkr(totalTarget, currency),
                      pct,
                      AppDesign.greenReceivable,
                    );
                  } else {
                    final totalRepaid = totalPaid;
                    final totalTarget = totalBorrowed;
                    final pct = totalTarget > 0
                        ? (totalRepaid / totalTarget).clamp(0.0, 1.0)
                        : 0.0;
                    progressWidget = _buildProgressSection(
                      'Debt Repayment Progress',
                      'Repaid',
                      BalanceCalculator.formatPkr(totalRepaid, currency),
                      BalanceCalculator.formatPkr(totalTarget, currency),
                      pct,
                      AppDesign.redPayable,
                    );
                  }
  
                  return Semantics(
                    label: '$label $currency ${bal.abs().toStringAsFixed(0)}',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppDesign.darkCard
                            : AppDesign.primaryEmerald.withValues(alpha: 0.04),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? AppDesign.darkBorder
                                : AppDesign.lightBorder,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : AppDesign.primaryTeal,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            BalanceCalculator.formatPkr(bal, currency),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: -1,
                            ),
                          ),
                          progressWidget,
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(
                  color: AppDesign.primaryEmerald,
                ),
                error: (_, __) => const SizedBox(),
              ),
  
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.space24,
                  vertical: AppDesign.space8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                    PopupMenuButton<String>(
                      initialValue: _selectedSort,
                      onSelected: (String val) {
                        setState(() {
                          _selectedSort = val;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppDesign.primaryEmerald.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: AppDesign.primaryEmerald.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_rounded,
                              color: AppDesign.primaryEmerald,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _selectedSort,
                              style: TextStyle(
                                color: AppDesign.primaryEmerald,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: AppDesign.primaryEmerald,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (BuildContext context) {
                        return [
                          'Transaction Date',
                          'Due Date',
                          'Amount',
                          'Latest',
                          'Oldest',
                        ].map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(
                              choice,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: _selectedSort == choice
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: _selectedSort == choice
                                    ? AppDesign.primaryEmerald
                                    : null,
                              ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ],
                ),
              ),
  
              // Transaction List
              Expanded(
                child: txsState.when(
                  data: (txs) {
                    final bal = BalanceCalculator.calculate(txs);
                    // Apply filter
                    var filtered = List<Transaction>.from(txs);
                    if (_selectedFilter != 'All') {
                      if (_selectedFilter == 'Given') {
                        filtered = filtered
                            .where((t) => t.type == TransactionType.gave)
                            .toList();
                      } else if (_selectedFilter == 'Received') {
                        filtered = filtered
                            .where((t) => t.type == TransactionType.received)
                            .toList();
                      } else if (_selectedFilter == 'Borrowed') {
                        filtered = filtered
                            .where((t) => t.type == TransactionType.borrowed)
                            .toList();
                      } else if (_selectedFilter == 'Paid') {
                        filtered = filtered
                            .where((t) => t.type == TransactionType.paid)
                            .toList();
                      } else if (_selectedFilter == 'Due Today') {
                        final today = DateTime.now();
                        filtered = filtered.where((t) {
                          if (t.dueDate == null) return false;
                          return t.dueDate!.year == today.year &&
                              t.dueDate!.month == today.month &&
                              t.dueDate!.day == today.day;
                        }).toList();
                      } else if (_selectedFilter == 'Overdue') {
                        final today = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        );
                        filtered = filtered.where((t) {
                          if (t.dueDate == null) return false;
                          if (t.type == TransactionType.received ||
                              t.type == TransactionType.paid)
                            return false;
                          final isReceivable = t.type == TransactionType.gave || 
                              (t.type == TransactionType.adjustment && t.amount >= 0);
                          final isPayable = t.type == TransactionType.borrowed || 
                              (t.type == TransactionType.adjustment && t.amount < 0);
                          if ((isReceivable && bal <= 0) || (isPayable && bal >= 0)) {
                            return false;
                          }
                          final due = DateTime(
                            t.dueDate!.year,
                            t.dueDate!.month,
                            t.dueDate!.day,
                          );
                          return due.isBefore(today);
                        }).toList();
                      } else if (_selectedFilter == 'Upcoming') {
                        final today = DateTime(
                          DateTime.now().year,
                          DateTime.now().month,
                          DateTime.now().day,
                        );
                        filtered = filtered.where((t) {
                          if (t.dueDate == null) return false;
                          if (t.type == TransactionType.received ||
                              t.type == TransactionType.paid)
                            return false;
                          final isReceivable = t.type == TransactionType.gave || 
                              (t.type == TransactionType.adjustment && t.amount >= 0);
                          final isPayable = t.type == TransactionType.borrowed || 
                              (t.type == TransactionType.adjustment && t.amount < 0);
                          if ((isReceivable && bal <= 0) || (isPayable && bal >= 0)) {
                            return false;
                          }
                          final due = DateTime(
                            t.dueDate!.year,
                            t.dueDate!.month,
                            t.dueDate!.day,
                          );
                          return due.isAfter(today) ||
                              due.isAtSameMomentAs(today);
                        }).toList();
                      }
                    }
  
                    // Apply sorting
                    if (_selectedSort == 'Transaction Date') {
                      filtered.sort(
                        (a, b) => (b.transactionDate ?? b.createdAt).compareTo(
                          a.transactionDate ?? a.createdAt,
                        ),
                      );
                    } else if (_selectedSort == 'Due Date') {
                      filtered.sort((a, b) {
                        final aIsSettled =
                            a.type == TransactionType.received ||
                            a.type == TransactionType.paid;
                        final bIsSettled =
                            b.type == TransactionType.received ||
                            b.type == TransactionType.paid;
                        if (!aIsSettled && !bIsSettled) {
                          if (a.dueDate == null && b.dueDate == null)
                            return (b.transactionDate ?? b.createdAt).compareTo(
                              a.transactionDate ?? a.createdAt,
                            );
                          if (a.dueDate == null) return 1;
                          if (b.dueDate == null) return -1;
                          return a.dueDate!.compareTo(b.dueDate!);
                        }
                        if (aIsSettled && bIsSettled) {
                          return (b.transactionDate ?? b.createdAt).compareTo(
                            a.transactionDate ?? a.createdAt,
                          );
                        }
                        return aIsSettled ? 1 : -1;
                      });
                    } else if (_selectedSort == 'Amount') {
                      filtered.sort((a, b) => b.amount.compareTo(a.amount));
                    } else if (_selectedSort == 'Latest') {
                      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                    } else if (_selectedSort == 'Oldest') {
                      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                    }
  
                    if (filtered.isEmpty) {
                      return const EmptyState(
                        icon: '💸',
                        title: 'No transactions found',
                        subtitle:
                            'Try changing the selected filters or add a new transaction.',
                      );
                    }
  
                    return ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesign.space24,
                        vertical: AppDesign.space8,
                      ),
                      itemBuilder: (context, index) {
                        final tx = filtered[index];
                        final isOwed =
                            tx.type == TransactionType.gave ||
                            tx.type == TransactionType.paid;
                        final txColor = isOwed
                            ? AppDesign.greenReceivable
                            : AppDesign.redPayable;
  
                        final badgeDetails = BalanceCalculator.getDueBadgeDetails(
                          tx,
                          bal,
                        );
                        final badgeLabel = badgeDetails['label'] as String;
                        final badgeColorName = badgeDetails['color'] as String;
                        final badgeColor = badgeColorName == 'red'
                            ? AppDesign.redPayable
                            : (badgeColorName == 'orange'
                                  ? AppDesign.amberWarning
                                  : (badgeColorName == 'green'
                                        ? AppDesign.greenReceivable
                                        : (badgeColorName == 'blue'
                                              ? Colors.blue
                                              : AppDesign.grayNeutral)));
  
                        return Dismissible(
                          key: Key(tx.uuid),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: AppDesign.primaryEmerald,
                              borderRadius: AppDesign.borderMedium,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          secondaryBackground: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: AppDesign.redPayable,
                              borderRadius: AppDesign.borderMedium,
                            ),
                            child: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              return await _confirmDeleteTransaction(context, tx);
                            } else {
                              _showEditTransactionDialog(context, tx);
                              return false;
                            }
                          },
                          onDismissed: (_) {
                            final deletedTx = tx;
                            ref
                                .read(
                                  transactionsForKhataProvider(
                                    widget.khataUuid,
                                  ).notifier,
                                )
                                .deleteTransaction(tx.uuid);
                            AppSnackbar.show(
                              context,
                              'Transaction moved to Trash',
                              type: AppSnackbarType.success,
                              actionLabel: 'UNDO',
                              onActionPressed: () async {
                                deletedTx.isDeleted = false;
                                await ref
                                    .read(
                                      transactionsForKhataProvider(
                                        widget.khataUuid,
                                      ).notifier,
                                    )
                                    .addTransaction(deletedTx);
                              },
                            );
                          },
                          child: GestureDetector(
                            onLongPress: () => _showLongPressMenu(context, tx),
                            child: Stack(
                              children: [
                                // Timeline vertical line
                                Positioned(
                                  top: 0,
                                  bottom: 0,
                                  left: 20,
                                  child: Container(
                                    width: 2,
                                    color: AppDesign.primaryTeal.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                // Timeline node dot
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: txColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: txColor.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Transaction Card details
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 36,
                                    right: 8,
                                    bottom: 4,
                                  ),
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                BalanceCalculator.formatPkr(
                                                  tx.amount,
                                                  currency,
                                                ),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: txColor,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                tx.type.name.toUpperCase(),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: txColor,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Date:',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${(tx.transactionDate ?? tx.createdAt).day} ${_getMonthName(tx.transactionDate ?? tx.createdAt)} ${(tx.transactionDate ?? tx.createdAt).year}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (tx.dueDate != null)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    const Text(
                                                      'Due:',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${tx.dueDate!.day} ${_getMonthName(tx.dueDate!)} ${tx.dueDate!.year}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              StatusBadge(
                                                label: badgeLabel,
                                                color: badgeColor,
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 16,
                                                ),
                                                tooltip: 'Delete',
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () async {
                                                  final confirmed =
                                                      await _confirmDeleteTransaction(
                                                        context,
                                                        tx,
                                                      );
                                                  if (confirmed) {
                                                    final deletedTx = tx;
                                                    ref
                                                        .read(
                                                          transactionsForKhataProvider(
                                                            widget.khataUuid,
                                                          ).notifier,
                                                        )
                                                        .deleteTransaction(
                                                          tx.uuid,
                                                        );
                                                    if (!context.mounted) return;
                                                    AppSnackbar.show(
                                                      context,
                                                      'Transaction moved to Trash',
                                                      type: AppSnackbarType.success,
                                                      actionLabel: 'UNDO',
                                                      onActionPressed: () async {
                                                        deletedTx.isDeleted = false;
                                                        await ref
                                                            .read(
                                                              transactionsForKhataProvider(
                                                                widget.khataUuid,
                                                              ).notifier,
                                                            )
                                                            .addTransaction(
                                                              deletedTx,
                                                            );
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          if (tx.notes != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              tx.notes!,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark
                                                    ? Colors.grey.shade400
                                                    : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/transaction/advanced?khataUuid=${_khata!.uuid}'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Transaction'),
        backgroundColor: AppDesign.primaryEmerald,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    AppHaptics.vibrate();
    showDialog(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        icon: Icons.delete_forever_rounded,
        iconColor: AppDesign.redPayable,
        title: 'Delete Khata',
        description:
            'Are you sure you want to delete "${_khata!.title}"?\n\nAll transactions within it will be moved to Trash.',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        onConfirm: () async {
          await ref
              .read(khatasForPersonProvider(_khata!.personUuid).notifier)
              .deleteKhata(_khata!.uuid);
          if (context.mounted) {
            context.pop();
          }
        },
      ),
    );
  }

  Future<bool> _confirmDeleteTransaction(
    BuildContext context,
    Transaction tx,
  ) async {
    final currency = ref.read(currencySymbolProvider);
    AppHaptics.vibrate();
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (ctx) => AppConfirmationDialog(
        icon: Icons.delete_sweep_rounded,
        iconColor: AppDesign.redPayable,
        title: 'Delete Transaction',
        description:
            'Move this $currency ${tx.amount.toStringAsFixed(0)} ${tx.type.name} transaction to Trash?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        onConfirm: () {
          confirmed = true;
        },
      ),
    );
    return confirmed;
  }

  Widget _buildProgressSection(
    String title,
    String actionLabel,
    String currentFormatted,
    String targetFormatted,
    double percent,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '${(percent * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$actionLabel $currentFormatted / $targetFormatted',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(BuildContext context, Transaction tx) {
    final amountController = TextEditingController(
      text: tx.amount.toStringAsFixed(0),
    );
    final notesController = TextEditingController(text: tx.notes ?? '');

    // Mutable state managed inside StatefulBuilder
    DateTime? editTransactionDate = tx.transactionDate;
    DateTime? editDueDate = tx.dueDate;
    DateTime? editReminderDate = tx.reminderDate;

    final bool supportsDueDates = tx.type == TransactionType.gave ||
        tx.type == TransactionType.borrowed;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
            title: const Text(
              'Edit Transaction',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Read-only type indicator
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: AppDesign.borderSmall,
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, size: 14, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(
                          'Type: ${tx.type.name.toUpperCase()} (cannot be changed)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Amount
                  AppTextField(
                    controller: amountController,
                    labelText: 'Amount',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.money_rounded,
                  ),
                  const SizedBox(height: 10),

                  // Transaction Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: editTransactionDate ?? DateTime.now(),
                        firstDate: DateTime.now()
                            .subtract(const Duration(days: 365 * 10)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setDialogState(() => editTransactionDate = picked);
                      }
                    },
                    borderRadius: AppDesign.borderSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppDesign.lightBorder),
                        borderRadius: AppDesign.borderSmall,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppDesign.primaryEmerald,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              editTransactionDate != null
                                  ? 'Date: ${editTransactionDate!.day}/${editTransactionDate!.month}/${editTransactionDate!.year}'
                                  : 'Transaction Date (tap to set)',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          const Icon(Icons.edit_rounded,
                              size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  // Due Date & Reminder (only for GAVE / BORROWED)
                  if (supportsDueDates) ...[
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: editDueDate ?? DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          if (!dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(
                              editDueDate ?? DateTime.now(),
                            ),
                          );
                          if (time != null) {
                            setDialogState(() => editDueDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  time.hour,
                                  time.minute,
                                ));
                          }
                        }
                      },
                      borderRadius: AppDesign.borderSmall,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppDesign.lightBorder),
                          borderRadius: AppDesign.borderSmall,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              size: 16,
                              color: AppDesign.primaryEmerald,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                editDueDate != null
                                    ? 'Due: ${editDueDate!.day}/${editDueDate!.month}/${editDueDate!.year}'
                                    : 'Due Date (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: editDueDate != null
                                      ? AppDesign.primaryEmerald
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            if (editDueDate != null)
                              GestureDetector(
                                onTap: () =>
                                    setDialogState(() => editDueDate = null),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: AppDesign.redPayable),
                              )
                            else
                              const Icon(Icons.edit_rounded,
                                  size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: editReminderDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          if (!dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: TimeOfDay.fromDateTime(
                              editReminderDate ?? DateTime.now(),
                            ),
                          );
                          if (time != null) {
                            setDialogState(() => editReminderDate = DateTime(
                                  picked.year,
                                  picked.month,
                                  picked.day,
                                  time.hour,
                                  time.minute,
                                ));
                          }
                        }
                      },
                      borderRadius: AppDesign.borderSmall,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppDesign.lightBorder),
                          borderRadius: AppDesign.borderSmall,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: AppDesign.primaryTeal,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                editReminderDate != null
                                    ? 'Remind: ${editReminderDate!.day}/${editReminderDate!.month}/${editReminderDate!.year}'
                                    : 'Reminder Date (Optional)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: editReminderDate != null
                                      ? AppDesign.primaryTeal
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            if (editReminderDate != null)
                              GestureDetector(
                                onTap: () =>
                                    setDialogState(() => editReminderDate = null),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: AppDesign.redPayable),
                              )
                            else
                              const Icon(Icons.edit_rounded,
                                  size: 14, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  // Notes
                  AppTextField(
                    controller: notesController,
                    labelText: 'Notes',
                    prefixIcon: Icons.notes_rounded,
                  ),

                  const SizedBox(height: 8),
                  // Immutability hint
                  const Text(
                    'To change the type, delete this transaction and create a new one.',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              AppButton(
                onPressed: () async {
                  final newAmount =
                      double.tryParse(amountController.text) ?? tx.amount;
                  final newNotes = notesController.text.trim();

                  final updated = Transaction()
                    ..id = tx.id
                    ..uuid = tx.uuid
                    ..khataUuid = tx.khataUuid
                    ..type = tx.type
                    ..amount = newAmount
                    ..notes = newNotes.isEmpty ? null : newNotes
                    ..transactionDate = editTransactionDate ?? tx.transactionDate
                    // Preserve due dates only for types that support them
                    ..dueDate = supportsDueDates ? editDueDate : null
                    ..reminderDate = supportsDueDates ? editReminderDate : null
                    ..createdAt = tx.createdAt
                    ..updatedAt = DateTime.now()
                    ..isDeleted = tx.isDeleted;

                  await ref
                      .read(
                        transactionsForKhataProvider(widget.khataUuid).notifier,
                      )
                      .updateTransaction(updated);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction updated!')),
                    );
                  }
                },
                label: 'Save',
              ),
            ],
          );
        },
      ),
    );
  }

  void _showLongPressMenu(BuildContext context, Transaction tx) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.copy_rounded, color: AppDesign.primaryEmerald),
            title: const Text('Duplicate Transaction'),
            onTap: () async {
              Navigator.pop(context);
              final duplicate = Transaction()
                ..uuid = const Uuid().v4()
                ..khataUuid = tx.khataUuid
                ..type = tx.type
                ..amount = tx.amount
                ..notes = tx.notes != null ? '${tx.notes} (Copy)' : 'Copy'
                ..transactionDate = tx.transactionDate
                ..dueDate = tx.dueDate
                ..reminderDate = tx.reminderDate
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now()
                ..isDeleted = false;
              await ref
                  .read(transactionsForKhataProvider(widget.khataUuid).notifier)
                  .addTransaction(duplicate);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction duplicated!')),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.share_rounded, color: AppDesign.primaryEmerald),
            title: const Text('Share Receipt'),
            onTap: () {
              Navigator.pop(context);
              Share.share(
                'Receipt from KhataFlow:\nContact Name: ${_khata!.title}\nType: ${tx.type.name.toUpperCase()}\nAmount: Rs. ${tx.amount.toStringAsFixed(0)}\nDate: ${tx.transactionDate?.day ?? tx.createdAt.day} ${_getMonthName(tx.transactionDate ?? tx.createdAt)}\nNotes: ${tx.notes ?? "-"}',
              );
            },
          ),
        ],
      ),
    );
  }
}
