import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/person.dart';
import '../../presentation/providers/people_providers.dart';
import '../../../khata/data/models/khata.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';

class PeopleTestScreen extends ConsumerStatefulWidget {
  const PeopleTestScreen({super.key});

  @override
  ConsumerState<PeopleTestScreen> createState() => _PeopleTestScreenState();
}

class _PeopleTestScreenState extends ConsumerState<PeopleTestScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddPersonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Person'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name (Required)'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone (Optional)'),
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              final person = Person()
                ..uuid = const Uuid().v4()
                ..name = _nameController.text.trim()
                ..phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim()
                ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim()
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now()
                ..isDeleted = false;

              ref.read(peopleListProvider.notifier).addPerson(person);
              
              _nameController.clear();
              _phoneController.clear();
              _notesController.clear();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peopleState = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KhataFlow Foundation Test'),
        centerTitle: true,
        elevation: 2,
      ),
      body: peopleState.when(
        data: (people) {
          if (people.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No people added yet!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _showAddPersonDialog,
                    child: const Text('Add First Person'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: people.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final person = people[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    person.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(person.phone ?? 'No phone'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          ref.read(peopleListProvider.notifier).deletePerson(person.uuid);
                        },
                      ),
                      const Icon(Icons.keyboard_arrow_down),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (person.notes != null) ...[
                            Text('Notes: ${person.notes}'),
                            const SizedBox(height: 8),
                          ],
                          Text('UUID: ${person.uuid}'),
                          const Divider(),
                          _KhataSection(personUuid: person.uuid),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _KhataSection extends ConsumerWidget {
  final String personUuid;

  const _KhataSection({required this.personUuid});

  void _showAddKhataDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Khata'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Khata Title (e.g. Personal)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              final khata = Khata()
                ..uuid = const Uuid().v4()
                ..personUuid = personUuid
                ..title = titleController.text.trim()
                ..createdAt = DateTime.now()
                ..updatedAt = DateTime.now()
                ..isDeleted = false;

              ref.read(khatasForPersonProvider(personUuid).notifier).addKhata(khata);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final khatasState = ref.watch(khatasForPersonProvider(personUuid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Khatas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton.icon(
              onPressed: () => _showAddKhataDialog(context, ref),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Khata'),
            ),
          ],
        ),
        khatasState.when(
          data: (khatas) {
            if (khatas.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('No khatas under this person', style: TextStyle(color: Colors.grey, fontSize: 12)),
              );
            }
            return Column(
              children: khatas.map((khata) {
                return Card(
                  color: Colors.grey[100],
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    title: Text(khata.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
                      onPressed: () {
                        ref.read(khatasForPersonProvider(personUuid).notifier).deleteKhata(khata.uuid);
                      },
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                        child: _TransactionSection(khataUuid: khata.uuid),
                      )
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text('Error loading khatas: $err'),
        ),
      ],
    );
  }
}

class _TransactionSection extends ConsumerWidget {
  final String khataUuid;

  const _TransactionSection({required this.khataUuid});

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    TransactionType selectedType = TransactionType.gave;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<TransactionType>(
                value: selectedType,
                items: TransactionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedType = val);
                  }
                },
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (PKR)'),
              ),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) return;

                final tx = Transaction()
                  ..uuid = const Uuid().v4()
                  ..khataUuid = khataUuid
                  ..type = selectedType
                  ..amount = amount
                  ..notes = notesController.text.trim().isEmpty ? null : notesController.text.trim()
                  ..createdAt = DateTime.now()
                  ..updatedAt = DateTime.now()
                  ..isDeleted = false;

                ref.read(transactionsForKhataProvider(khataUuid).notifier).addTransaction(tx);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionsForKhataProvider(khataUuid));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            TextButton.icon(
              onPressed: () => _showAddTransactionDialog(context, ref),
              icon: const Icon(Icons.add_circle_outline, size: 14),
              label: const Text('Add Tx', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        transactionsState.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text('No transactions', style: TextStyle(color: Colors.grey, fontSize: 11)),
              );
            }
            return Column(
              children: transactions.map((tx) {
                final color = (tx.type == TransactionType.gave || tx.type == TransactionType.paid)
                    ? Colors.green[700]
                    : Colors.red[700];
                return ListTile(
                  dense: true,
                  title: Text(
                    '${tx.type.name.toUpperCase()} - PKR ${tx.amount}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  subtitle: tx.notes != null ? Text(tx.notes!) : null,
                  trailing: Text(
                    '${tx.createdAt.hour}:${tx.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (err, _) => Text('Error: $err'),
        ),
      ],
    );
  }
}
