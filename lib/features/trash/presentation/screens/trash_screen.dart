import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/database/isar_service.dart';
import '../../../people/data/models/person.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../khata/data/models/khata.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';
import '../../../../core/utils/phone_formatter.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Isar _isar = IsarService.instance;

  List<Person> _deletedPeople = [];
  List<Khata> _deletedKhatas = [];
  List<Transaction> _deletedTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDeletedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeletedItems() async {
    setState(() => _isLoading = true);
    final people = await _isar.persons
        .filter()
        .isDeletedEqualTo(true)
        .findAll();
    final khatas = await _isar.khatas.filter().isDeletedEqualTo(true).findAll();
    final txs = await _isar.transactions
        .filter()
        .isDeletedEqualTo(true)
        .findAll();

    setState(() {
      _deletedPeople = people;
      _deletedKhatas = khatas;
      _deletedTransactions = txs;
      _isLoading = false;
    });
  }

  Future<void> _restorePerson(Person person) async {
    person.isDeleted = false;
    person.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.persons.put(person);
    });
    ref.read(peopleListProvider.notifier).loadPeople();
    _loadDeletedItems();
  }

  Future<void> _restoreKhata(Khata khata) async {
    khata.isDeleted = false;
    khata.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.khatas.put(khata);
    });
    ref.invalidate(khatasForPersonProvider(khata.personUuid));
    _loadDeletedItems();
  }

  Future<void> _restoreTransaction(Transaction tx) async {
    tx.isDeleted = false;
    tx.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.transactions.put(tx);
    });
    ref.invalidate(transactionsForKhataProvider(tx.khataUuid));
    _loadDeletedItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trash Bin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.teal,
          labelColor: Colors.teal,
          tabs: const [
            Tab(text: 'Contacts'),
            Tab(text: 'Khatas'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDeletedPeopleList(),
                _buildDeletedKhatasList(),
                _buildDeletedTransactionsList(),
              ],
            ),
    );
  }

  Widget _buildDeletedPeopleList() {
    if (_deletedPeople.isEmpty) return _buildEmptyState('No deleted contacts.');
    return ListView.builder(
      itemCount: _deletedPeople.length,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.space24,
        vertical: AppDesign.space16,
      ),
      itemBuilder: (context, index) {
        final p = _deletedPeople[index];
        return Card(
          child: ListTile(
            title: Text(p.name),
            subtitle: Text(
              p.phone != null && p.phone!.isNotEmpty
                  ? PhoneFormatter.format(p.phone)
                  : 'No phone',
            ),
            trailing: IconButton(
              icon: const Icon(Icons.restore, color: Colors.teal),
              onPressed: () => _restorePerson(p),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeletedKhatasList() {
    if (_deletedKhatas.isEmpty) return _buildEmptyState('No deleted Khatas.');
    return ListView.builder(
      itemCount: _deletedKhatas.length,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.space24,
        vertical: AppDesign.space16,
      ),
      itemBuilder: (context, index) {
        final k = _deletedKhatas[index];
        return Card(
          child: ListTile(
            title: Text(k.title),
            subtitle: Text(k.notes ?? 'No notes'),
            trailing: IconButton(
              icon: const Icon(Icons.restore, color: Colors.teal),
              onPressed: () => _restoreKhata(k),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeletedTransactionsList() {
    if (_deletedTransactions.isEmpty)
      return _buildEmptyState('No deleted transactions.');
    return ListView.builder(
      itemCount: _deletedTransactions.length,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.space24,
        vertical: AppDesign.space16,
      ),
      itemBuilder: (context, index) {
        final tx = _deletedTransactions[index];
        return Card(
          child: ListTile(
            title: Text('${tx.type.name.toUpperCase()} - PKR ${tx.amount}'),
            subtitle: Text(tx.notes ?? 'No notes'),
            trailing: IconButton(
              icon: const Icon(Icons.restore, color: Colors.teal),
              onPressed: () => _restoreTransaction(tx),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String text) {
    return EmptyState(
      icon: '🗑️',
      title: 'Trash Bin Empty',
      subtitle: text,
    );
  }
}
