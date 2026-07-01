import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/people_providers.dart';
import '../providers/balance_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class PeopleListScreen extends ConsumerStatefulWidget {
  const PeopleListScreen({super.key});

  @override
  ConsumerState<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends ConsumerState<PeopleListScreen> {
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(peopleListProvider.notifier).loadPeople();
  }

  @override
  Widget build(BuildContext context) {
    final peopleState = ref.watch(peopleListProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'People',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.space16,
              vertical: AppDesign.space8,
            ),
            child: Semantics(
              label: 'Search people by name',
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search people...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppDesign.primaryEmerald,
                  ),
                  filled: true,
                  fillColor: isDark ? AppDesign.darkCard : Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: AppDesign.borderMedium,
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
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

          // People List
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
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: _searchQuery.isEmpty
                                ? EmptyState(
                                    icon: '👥',
                                    title: 'No contacts yet',
                                    subtitle:
                                        'Tap the button below to add your first customer or vendor contact.',
                                    action: AppButton(
                                      label: 'Add Contact',
                                      icon: Icons.person_add_rounded,
                                      onPressed: () =>
                                          context.push('/people/add'),
                                    ),
                                  )
                                : EmptyState(
                                    icon: '👥',
                                    title: 'No search results',
                                    subtitle:
                                        'No contacts match the search query "$_searchQuery".',
                                  ),
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
                      horizontal: AppDesign.space16,
                      vertical: AppDesign.space8,
                    ),
                    itemBuilder: (context, index) {
                      final person = filtered[index];
                      return _PersonListItem(person: person);
                    },
                  ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/people/add'),
        backgroundColor: AppDesign.primaryEmerald,
        foregroundColor: Colors.white,
        tooltip: 'Add new contact',
        child: const Icon(Icons.person_add_rounded),
      ),
    );
  }
}

class _PersonListItem extends ConsumerWidget {
  final dynamic person;

  const _PersonListItem({required this.person});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(personBalanceProvider(person.uuid));
    final currency = ref.watch(currencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Generate dynamic colored avatar background
    final colors = [
      Colors.teal,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.orange,
    ];
    final colorIndex =
        person.name.codeUnits.fold<int>(
          0,
          (int prev, int element) => prev + element,
        ) %
        colors.length;
    final avatarColor = colors[colorIndex];

    return Semantics(
      label: 'Contact: ${person.name}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          onTap: () => context.push('/people/${person.uuid}'),
          leading: CircleAvatar(
            backgroundColor: avatarColor.withValues(alpha: 0.1),
            child: Text(
              person.name.substring(0, 1).toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: avatarColor),
            ),
          ),
          title: Text(
            person.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            person.phone ?? 'No phone number',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          trailing: balanceAsync.when(
            loading: () => const SizedBox(
              width: 50,
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppDesign.primaryEmerald,
                minHeight: 2,
              ),
            ),
            error: (_, __) => Text(
              '—',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
            data: (balance) {
              if (balance > 0) {
                return StatusBadge(
                  label: 'Receivable: $currency ${balance.toStringAsFixed(0)}',
                  color: AppDesign.greenReceivable,
                );
              } else if (balance < 0) {
                return StatusBadge(
                  label:
                      'Payable: $currency ${balance.abs().toStringAsFixed(0)}',
                  color: AppDesign.redPayable,
                );
              } else {
                return const StatusBadge(
                  label: 'Settled',
                  color: AppDesign.grayNeutral,
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
