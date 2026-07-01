import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../people/data/models/person.dart';
import '../../../khata/data/models/khata.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import 'package:khata_app/features/settings/presentation/providers/settings_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  List<Person> _matchingPeople = [];
  List<Map<String, dynamic>> _matchingKhatas = []; // {khata, personName}
  List<Map<String, dynamic>> _matchingTransactions =
      []; // {tx, khataTitle, personName}
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query == _query) return;
    setState(() {
      _query = query;
      _isSearching = true;
    });
    _performSearch();
  }

  Future<void> _performSearch() async {
    if (_query.isEmpty) {
      setState(() {
        _matchingPeople = [];
        _matchingKhatas = [];
        _matchingTransactions = [];
        _isSearching = false;
      });
      return;
    }

    final peopleRepo = ref.read(personRepositoryProvider);
    final khataRepo = ref.read(khataRepositoryProvider);
    final txRepo = ref.read(transactionRepositoryProvider);

    final allPeople = await peopleRepo.getPeople();
    final List<Person> peopleResults = [];
    final List<Map<String, dynamic>> khataResults = [];
    final List<Map<String, dynamic>> txResults = [];

    for (final person in allPeople) {
      final matchesName = person.name.toLowerCase().contains(_query);
      final matchesPhone =
          person.phone?.toLowerCase().contains(_query) ?? false;
      if (matchesName || matchesPhone) {
        peopleResults.add(person);
      }

      final khatas = await khataRepo.getKhatasForPerson(person.uuid);
      for (final khata in khatas) {
        final matchesKhata = khata.title.toLowerCase().contains(_query);
        if (matchesKhata) {
          khataResults.add({'khata': khata, 'personName': person.name});
        }

        final txs = await txRepo.getTransactionsForKhata(khata.uuid);
        for (final tx in txs) {
          final matchesAmount = tx.amount.toStringAsFixed(0).contains(_query);
          final matchesNotes =
              tx.notes?.toLowerCase().contains(_query) ?? false;

          final txDate = tx.transactionDate ?? tx.createdAt;
          final dateStr = '${txDate.day}/${txDate.month}/${txDate.year}';
          final matchesDate = dateStr.contains(_query);
          final matchesKhataTitle = khata.title.toLowerCase().contains(_query);

          if (matchesAmount ||
              matchesNotes ||
              matchesDate ||
              matchesKhataTitle) {
            txResults.add({
              'transaction': tx,
              'khataTitle': khata.title,
              'personName': person.name,
            });
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _matchingPeople = peopleResults;
        _matchingKhatas = khataResults;
        _matchingTransactions = txResults;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search contacts, amounts, notes, dates...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
          ),
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_rounded),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: _isSearching
          ? const Center(
              child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
            )
          : _query.isEmpty
          ? _buildSearchPlaceholder()
          : _matchingPeople.isEmpty &&
                _matchingKhatas.isEmpty &&
                _matchingTransactions.isEmpty
          ? _buildNoResults()
          : ListView(
              padding: const EdgeInsets.all(AppDesign.space16),
              children: [
                if (_matchingPeople.isNotEmpty) ...[
                  const SectionHeader(title: 'Contacts'),
                  const SizedBox(height: 8),
                  ..._matchingPeople.map(
                    (person) => _buildPersonTile(person, isDark),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_matchingKhatas.isNotEmpty) ...[
                  const SectionHeader(title: 'Accounts (Khatas)'),
                  const SizedBox(height: 8),
                  ..._matchingKhatas.map(
                    (item) => _buildKhataTile(item, isDark),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_matchingTransactions.isNotEmpty) ...[
                  const SectionHeader(title: 'Transactions'),
                  const SizedBox(height: 8),
                  ..._matchingTransactions.map(
                    (item) => _buildTransactionTile(item, currency, isDark),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSearchPlaceholder() {
    return const EmptyState(
      icon: '🔍',
      title: 'Search anything in KhataFlow',
      subtitle:
          'Find contacts, accounts, transaction amounts, notes or specific dates instantly.',
    );
  }

  Widget _buildNoResults() {
    return EmptyState(
      icon: '📭',
      title: 'No results found',
      subtitle:
          'We couldn\'t find any records matching "$_query". Try checking the spelling.',
    );
  }

  Widget _buildPersonTile(Person person, bool isDark) {
    // Generate simple deterministic color for avatar
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: avatarColor.withValues(alpha: 0.1),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          person.phone ?? 'No phone number',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        onTap: () => context.push('/people/${person.uuid}'),
      ),
    );
  }

  Widget _buildKhataTile(Map<String, dynamic> item, bool isDark) {
    final khata = item['khata'] as Khata;
    final personName = item['personName'] as String;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.blue,
          ),
        ),
        title: Text(
          khata.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Contact: $personName',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        onTap: () => context.push('/khata/${khata.uuid}'),
      ),
    );
  }

  Widget _buildTransactionTile(
    Map<String, dynamic> item,
    String currency,
    bool isDark,
  ) {
    final tx = item['transaction'] as Transaction;
    final khataTitle = item['khataTitle'] as String;
    final personName = item['personName'] as String;
    final isGaveOrPaid =
        tx.type == TransactionType.gave || tx.type == TransactionType.paid;
    final txColor = isGaveOrPaid
        ? AppDesign.greenReceivable
        : AppDesign.redPayable;

    final txDate = tx.transactionDate ?? tx.createdAt;
    final dateStr = '${txDate.day}/${txDate.month}/${txDate.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: txColor.withValues(alpha: 0.08),
          child: Icon(
            isGaveOrPaid
                ? Icons.arrow_outward_rounded
                : Icons.call_received_rounded,
            color: txColor,
            size: 20,
          ),
        ),
        title: Text(
          '$currency ${tx.amount.toStringAsFixed(0)}',
          style: TextStyle(fontWeight: FontWeight.bold, color: txColor),
        ),
        subtitle: Text(
          '${tx.type.name.toUpperCase()} • $personName • $khataTitle\nDate: $dateStr • Notes: ${tx.notes ?? "-"}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade400 : Colors.black54,
          ),
        ),
        onTap: () => context.push('/khata/${tx.khataUuid}'),
      ),
    );
  }
}
