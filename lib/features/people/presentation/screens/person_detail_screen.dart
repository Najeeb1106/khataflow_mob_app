import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/balance_calculator.dart';
import '../../data/models/person.dart';
import '../providers/people_providers.dart';
import '../providers/balance_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';

class PersonDetailScreen extends ConsumerStatefulWidget {
  final String personUuid;
  const PersonDetailScreen({super.key, required this.personUuid});

  @override
  ConsumerState<PersonDetailScreen> createState() =>
      _PersonDetailScreenState();
}

class _PersonDetailScreenState extends ConsumerState<PersonDetailScreen> {
  Person? _person;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPerson();
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

  Future<void> _onRefresh() async {
    await _loadPerson();
    // Also invalidate balance providers so they recompute
    ref.invalidate(personBalanceProvider(widget.personUuid));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    if (_person == null) {
      return const Scaffold(
          body: Center(child: Text('Contact not found.')));
    }

    final khatasState =
        ref.watch(khatasForPersonProvider(widget.personUuid));

    // ── Net balance for this person across ALL khatas ──────────────────
    // Uses personBalanceProvider — NO FutureBuilder, NO inline DB query.
    final personBalanceAsync =
        ref.watch(personBalanceProvider(widget.personUuid));

    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_person!.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
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
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete contact',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.teal,
        child: Column(
          children: [
            // ── Net Balance Header Card ────────────────────────────────
            personBalanceAsync.when(
              loading: () => const LinearProgressIndicator(
                  minHeight: 3, color: Colors.teal),
              error: (_, __) => const SizedBox(),
              data: (balance) {
                final color = balance > 0
                    ? Colors.green[700]
                    : balance < 0
                        ? Colors.red[700]
                        : Colors.grey[700];
                final statusLabel =
                    BalanceCalculator.getStatusLabel(balance);

                return Semantics(
                  label:
                      '$statusLabel $currency ${balance.abs().toStringAsFixed(0)}',
                  child: Container(
                    width: double.infinity,
                    color: Colors.teal[50],
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 20),
                    child: Column(
                      children: [
                        Text(
                          statusLabel,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Colors.teal,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          BalanceCalculator.formatPkr(balance, currency),
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: color),
                        ),
                        if (_person!.phone != null) ...[
                          const SizedBox(height: 8),
                          Text(_person!.phone!,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Khatas Section ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Accounts / Khatas',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('New Khata'),
                          onPressed: () => context
                              .push('/people/${_person!.uuid}/khata/add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: khatasState.when(
                        data: (khatas) {
                          if (khatas.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Text('📂',
                                      style: TextStyle(fontSize: 40)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Khatas added yet.',
                                    style: TextStyle(
                                        color: Colors.grey[500]),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push(
                                        '/people/${_person!.uuid}/khata/add'),
                                    child: const Text('Create a Khata'),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: khatas.length,
                            itemBuilder: (context, index) {
                              final khata = khatas[index];

                              // ── khataBalanceProvider replaces FutureBuilder ──
                              final khataBalanceAsync = ref.watch(
                                  khataBalanceProvider(khata.uuid));

                              return khataBalanceAsync.when(
                                loading: () => Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  child: const ListTile(
                                    title: LinearProgressIndicator(
                                        minHeight: 2,
                                        color: Colors.teal),
                                  ),
                                ),
                                error: (_, __) => const SizedBox(),
                                data: (bal) {
                                  final isOwed = bal >= 0;
                                  final color = isOwed
                                      ? Colors.green[700]
                                      : Colors.red[700];

                                  return Semantics(
                                    label:
                                        'Khata: ${khata.title}, balance $currency ${bal.abs().toStringAsFixed(0)}',
                                    child: Card(
                                      margin: const EdgeInsets.only(
                                          bottom: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ListTile(
                                        onTap: () => context
                                            .push('/khata/${khata.uuid}'),
                                        title: Text(khata.title,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.bold)),
                                        subtitle: khata.notes != null
                                            ? Text(khata.notes!,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis)
                                            : null,
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$currency ${bal.abs().toStringAsFixed(0)}',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: color),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 14,
                                                color: Colors.grey),
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
                            child: CircularProgressIndicator()),
                        error: (err, _) => Center(
                            child:
                                Text('Error loading accounts: $err')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before soft-deleting the contact.
  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
          'Are you sure you want to delete ${_person!.name}?\n\n'
          'All their khatas and transactions will be moved to Trash '
          'and can be restored within 30 days.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              await ref
                  .read(peopleListProvider.notifier)
                  .deletePerson(_person!.uuid);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                context.pop(); // Close detail screen
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
