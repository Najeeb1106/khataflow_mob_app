import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/people_providers.dart';
import '../providers/balance_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';
import '../../../../core/utils/avatar_color_helper.dart';
import '../../../../core/utils/phone_normalizer.dart';
import '../../../../core/utils/phone_formatter.dart';

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

  /// Smart search: matches against name (partial) OR phone (partial, normalized).
  bool _matchesPerson(dynamic person) {
    if (_searchQuery.isEmpty) return true;

    // Name match — partial, case-insensitive
    if (person.name.toLowerCase().contains(_searchQuery)) return true;

    // Phone match — compare normalized query against normalized stored phone
    if (person.phone != null) {
      final queryDigits = _searchQuery.replaceAll(RegExp(r'[^\d]'), '');
      if (queryDigits.isEmpty) return false;

      final storedNormalized = PhoneNormalizer.normalize(person.phone);

      // Normalize the query digits by removing country prefixes
      String normalizedQuery = queryDigits;
      if (normalizedQuery.startsWith('92')) {
        normalizedQuery = normalizedQuery.substring(2);
      } else if (normalizedQuery.startsWith('0')) {
        normalizedQuery = normalizedQuery.substring(1);
      }

      // If normalized query is empty (e.g. "+", "92", "0"), it matches any contact with a phone number
      if (normalizedQuery.isEmpty) {
        return true;
      }

      if (storedNormalized.contains(normalizedQuery)) {
        return true;
      }
    }

    return false;
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
              horizontal: AppDesign.space24,
              vertical: AppDesign.space12,
            ),
            child: Semantics(
              label: 'Search people by name or phone number',
              child: TextField(
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search by name or phone number...',
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
                final filtered =
                    people.where((p) => _matchesPerson(p)).toList();

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
                                        'No contacts match "$_searchQuery". Try searching by name or phone number.',
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
                      horizontal: AppDesign.space24,
                      vertical: AppDesign.space12,
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

    // Stable, UUID-seeded avatar color (immutable even after rename)
    final avatarColor = AvatarColorHelper.forUuid(person.uuid);

    return Semantics(
      label: 'Contact: ${person.name}',
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
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
            person.phone != null && person.phone!.isNotEmpty
                ? PhoneFormatter.format(person.phone)
                : 'No phone number',
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
