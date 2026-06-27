import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/balance_calculator.dart';
import '../providers/people_providers.dart';
import '../providers/balance_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';

class PeopleListScreen extends ConsumerStatefulWidget {
  const PeopleListScreen({super.key});

  @override
  ConsumerState<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends ConsumerState<PeopleListScreen> {
  String _searchQuery = '';

  /// Auto-focus controller so the search bar receives focus on screen open.
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Briefly delay so the navigator animation finishes before focusing.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Pull-to-refresh: invalidate the people list to reload from Isar.
  Future<void> _onRefresh() async {
    await ref.read(peopleListProvider.notifier).loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    final peopleState = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('People', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // ── Search Bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Semantics(
              label: 'Search people by name',
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  // Clear button when there is text
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Clear search',
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
            ),
          ),

          // ── People List ───────────────────────────────────────────────
          Expanded(
            child: peopleState.when(
              data: (people) {
                // Apply search filter
                final filtered = people
                    .where((p) =>
                        p.name.toLowerCase().contains(_searchQuery))
                    .toList();

                if (filtered.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: Colors.teal,
                    child: ListView(
                      // ListView needed so RefreshIndicator can scroll
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('👥',
                                    style: TextStyle(fontSize: 48)),
                                const SizedBox(height: 16),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No contacts yet.\nTap + to add your first contact.'
                                      : 'No contacts match "$_searchQuery".',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.grey[500], fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Colors.teal,
                  child: ListView.builder(
                    itemCount: filtered.length,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemBuilder: (context, index) {
                      final person = filtered[index];
                      return _PersonListItem(person: person);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/people/add'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        tooltip: 'Add new contact',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PersonListItem — NO FutureBuilder, uses personBalanceProvider instead
// ─────────────────────────────────────────────────────────────────────────────
class _PersonListItem extends ConsumerWidget {
  final dynamic person;

  const _PersonListItem({required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the cached, deduplicated balance provider — no inline DB queries.
    final balanceAsync = ref.watch(personBalanceProvider(person.uuid));
    final currency = ref.watch(currencySymbolProvider);

    return Semantics(
      label: 'Contact: ${person.name}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: () => context.push('/people/${person.uuid}'),
          leading: Semantics(
            label: 'Avatar for ${person.name}',
            child: CircleAvatar(
              backgroundColor: Colors.teal[50],
              child: Text(
                person.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ),
          ),
          title: Text(
            person.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(person.phone ?? 'No phone number'),
          trailing: balanceAsync.when(
            // ── Show shimmer/loading state inline ───────────────────────
            loading: () => const SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Colors.teal,
                minHeight: 2,
              ),
            ),
            // ── Error state: show dash instead of crashing ───────────────
            error: (_, __) => Text(
              '—',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            // ── Resolved: show balance label ─────────────────────────────
            data: (balance) {
              final color = balance > 0
                  ? Colors.green[700]
                  : balance < 0
                      ? Colors.red[700]
                      : Colors.grey[600];
              final prefix = BalanceCalculator.getListPrefix(balance, currency);
              final amount = BalanceCalculator.getDisplayAmount(balance);

              return Semantics(
                label: balance == 0.0
                    ? 'Settled'
                    : '$prefix$amount',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      prefix + amount,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
