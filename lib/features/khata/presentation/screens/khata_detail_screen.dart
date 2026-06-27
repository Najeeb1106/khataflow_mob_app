import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/balance_calculator.dart';
import '../../data/models/khata.dart';
import '../providers/khata_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/data/models/transaction.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';

class KhataDetailScreen extends ConsumerStatefulWidget {
  final String khataUuid;
  const KhataDetailScreen({super.key, required this.khataUuid});

  @override
  ConsumerState<KhataDetailScreen> createState() =>
      _KhataDetailScreenState();
}

class _KhataDetailScreenState extends ConsumerState<KhataDetailScreen> {
  Khata? _khata;
  bool _isLoading = false;
  String _selectedFilter = 'All';

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
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_khata == null) {
      return const Scaffold(
          body: Center(child: Text('Khata not found.')));
    }

    final txsState =
        ref.watch(transactionsForKhataProvider(widget.khataUuid));

    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_khata!.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined,
                color: Colors.teal),
            tooltip: 'Export PDF statement',
            onPressed: () =>
                context.push('/statement/${_khata!.uuid}'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit khata',
            onPressed: () async {
              await context.push(
                  '/people/${_khata!.personUuid}/khata/${_khata!.uuid}/edit');
              _loadKhata();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete khata',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.teal,
        child: Column(
          children: [
            // ── Balance Summary Card ───────────────────────────────────
            txsState.when(
              data: (txs) {
                // ── Use BalanceCalculator — no more inline switch loop ──
                final bal = BalanceCalculator.calculate(txs);
                final color =
                    bal >= 0 ? Colors.green[700] : Colors.red[700];
                final label = BalanceCalculator.getLedgerLabel(bal);

                return Semantics(
                  label: '$label $currency ${bal.abs().toStringAsFixed(0)}',
                  child: Container(
                    width: double.infinity,
                    color: Colors.teal[50],
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 14,
                                color: Colors.teal,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          BalanceCalculator.formatPkr(bal, currency),
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () =>
                  const LinearProgressIndicator(color: Colors.teal),
              error: (_, __) => const SizedBox(),
            ),

            // ── Filter Chips ─────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  'All',
                  'Gave',
                  'Received',
                  'Borrowed',
                  'Paid'
                ].map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: Colors.teal,
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Transaction List ─────────────────────────────────────
            Expanded(
              child: txsState.when(
                data: (txs) {
                  // Apply filter
                  var filtered = txs;
                  if (_selectedFilter != 'All') {
                    final targetType = TransactionType.values.firstWhere(
                      (e) =>
                          e.name.toLowerCase() ==
                          _selectedFilter.toLowerCase(),
                    );
                    filtered =
                        txs.where((t) => t.type == targetType).toList();
                  }

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('💸',
                              style: TextStyle(fontSize: 40)),
                          const SizedBox(height: 12),
                          Text('No transactions found.',
                              style:
                                  TextStyle(color: Colors.grey[500])),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemBuilder: (context, index) {
                      final tx = filtered[index];
                      final isOwed = tx.type == TransactionType.gave ||
                          tx.type == TransactionType.paid;
                      final txColor =
                          isOwed ? Colors.green[700] : Colors.red[700];

                      // ── Swipe-to-delete gesture ────────────────────
                      return Dismissible(
                        key: Key(tx.uuid),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 22),
                        ),
                        confirmDismiss: (_) async {
                          return await _confirmDeleteTransaction(
                              context, tx);
                        },
                        onDismissed: (_) {
                          ref
                              .read(transactionsForKhataProvider(
                                      widget.khataUuid)
                                  .notifier)
                              .deleteTransaction(tx.uuid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Transaction moved to Trash')),
                          );
                        },
                        child: Semantics(
                          label:
                              '${tx.type.name} $currency ${tx.amount.toStringAsFixed(0)}',
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    txColor?.withValues(alpha: 0.1),
                                child: Icon(
                                  isOwed
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: txColor,
                                ),
                              ),
                              title: Text(
                                '$currency ${tx.amount.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: txColor),
                              ),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${tx.type.name.toUpperCase()} • ${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}'),
                                  if (tx.notes != null)
                                    Text(
                                      tx.notes!,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54),
                                    ),
                                ],
                              ),
                              trailing: Semantics(
                                label: 'Delete transaction',
                                child: IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final confirmed =
                                        await _confirmDeleteTransaction(
                                            context, tx);
                                    if (confirmed) {
                                      ref
                                          .read(
                                              transactionsForKhataProvider(
                                                      widget.khataUuid)
                                                  .notifier)
                                          .deleteTransaction(tx.uuid);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) =>
                    Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
            '/transaction/advanced?khataUuid=${_khata!.uuid}'),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ── Confirmation Dialogs ─────────────────────────────────────────────

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Khata'),
        content: Text(
          'Are you sure you want to delete "${_khata!.title}"?\n\n'
          'All transactions within it will be moved to Trash.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              await ref
                  .read(khatasForPersonProvider(_khata!.personUuid)
                      .notifier)
                  .deleteKhata(_khata!.uuid);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                context.pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDeleteTransaction(
      BuildContext context, Transaction tx) async {
    final currency = ref.read(currencySymbolProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Move this $currency ${tx.amount.toStringAsFixed(0)} ${tx.type.name} '
          'transaction to Trash?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
