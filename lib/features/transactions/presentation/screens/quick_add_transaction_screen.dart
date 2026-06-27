import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../../people/data/models/person.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../khata/data/models/khata.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../data/models/transaction.dart';
import '../../presentation/providers/transaction_providers.dart';

class QuickAddTransactionScreen extends ConsumerStatefulWidget {
  const QuickAddTransactionScreen({super.key});

  @override
  ConsumerState<QuickAddTransactionScreen> createState() => _QuickAddTransactionScreenState();
}

class _QuickAddTransactionScreenState extends ConsumerState<QuickAddTransactionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  Khata? _selectedKhata;
  List<Khata> _khatas = [];
  TransactionType _selectedType = TransactionType.gave;
  bool _isLoadingKhatas = false;

  Future<void> _onPersonSelected(Person person) async {
    setState(() {
      _selectedPerson = person;
      _isLoadingKhatas = true;
      _khatas = [];
      _selectedKhata = null;
    });

    final repo = ref.read(khataRepositoryProvider);
    final list = await repo.getKhatasForPerson(person.uuid);
    
    setState(() {
      _khatas = list;
      _isLoadingKhatas = false;
      if (list.length == 1) {
        _selectedKhata = list.first;
      }
    });
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_selectedPerson == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return;
    }
    if (_selectedKhata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Khata')),
      );
      return;
    }
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    final tx = Transaction()
      ..uuid = const Uuid().v4()
      ..khataUuid = _selectedKhata!.uuid
      ..type = _selectedType
      ..amount = amount
      ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim()
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isDeleted = false;

    await ref.read(transactionsForKhataProvider(_selectedKhata!.uuid).notifier).addTransaction(tx);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully!')),
      );
      context.go('/dashboard');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peopleAsync = ref.watch(peopleListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Add Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Contact Label
            const Text('1. Select Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            peopleAsync.when(
              data: (people) {
                return Autocomplete<Person>(
                  displayStringForOption: (option) => option.name,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Person>.empty();
                    }
                    return people.where((p) => p.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: _onPersonSelected,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type contact name...',
                        prefixIcon: const Icon(Icons.person_search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => Text('Error loading contacts: $err'),
            ),
            const SizedBox(height: 20),
            // Select Khata Label
            if (_selectedPerson != null) ...[
              const Text('2. Select Account (Khata)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (_isLoadingKhatas)
                const CircularProgressIndicator()
              else if (_khatas.isEmpty)
                TextButton.icon(
                  onPressed: () => context.push('/people/${_selectedPerson!.uuid}/khata/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Create a Khata first'),
                )
              else
                DropdownButtonFormField<Khata>(
                  initialValue: _selectedKhata,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _khatas.map((k) {
                    return DropdownMenuItem(value: k, child: Text(k.title));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedKhata = val;
                    });
                  },
                ),
              const SizedBox(height: 20),
            ],
            // Amount
            const Text('3. Enter Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'PKR ',
                hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            // Transaction Type (4 large buttons)
            const Text('4. Transaction Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildTypeButton(TransactionType.gave, 'GAVE (Lent)', Colors.green),
                _buildTypeButton(TransactionType.received, 'RECEIVED', Colors.red),
                _buildTypeButton(TransactionType.borrowed, 'BORROWED', Colors.redAccent),
                _buildTypeButton(TransactionType.paid, 'PAID (Repaid)', Colors.greenAccent),
              ],
            ),
            const SizedBox(height: 20),
            // Notes (Optional)
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes / Remarks (Optional)',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, Color activeColor) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.15) : Colors.grey[50],
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
