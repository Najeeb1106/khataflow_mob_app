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
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class QuickAddTransactionScreen extends ConsumerStatefulWidget {
  const QuickAddTransactionScreen({super.key});

  @override
  ConsumerState<QuickAddTransactionScreen> createState() =>
      _QuickAddTransactionScreenState();
}

class _QuickAddTransactionScreenState
    extends ConsumerState<QuickAddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Person? _selectedPerson;
  Khata? _selectedKhata;
  List<Khata> _khatas = [];
  TransactionType _selectedType = TransactionType.gave;
  bool _isLoadingKhatas = false;
  DateTime _transactionDate = DateTime.now();

  Future<void> _selectTransactionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _transactionDate = picked;
      });
    }
  }

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (_selectedPerson == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a contact')));
      return;
    }
    if (_selectedKhata == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Khata account')),
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
      ..notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim()
      ..transactionDate = _transactionDate
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isDeleted = false;

    await ref
        .read(transactionsForKhataProvider(_selectedKhata!.uuid).notifier)
        .addTransaction(tx);

    if (mounted) {
      AppHaptics.light();
      AppSnackbar.show(
        context,
        'Transaction saved successfully!',
        type: AppSnackbarType.success,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quick Add Transaction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesign.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Select
              const Text(
                '1. Select Contact',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              peopleAsync.when(
                data: (people) {
                  return Autocomplete<Person>(
                    displayStringForOption: (option) => option.name,
                    optionsBuilder: (textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<Person>.empty();
                      }
                      return people.where(
                        (p) => p.name.toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        ),
                      );
                    },
                    onSelected: _onPersonSelected,
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              hintText: 'Type contact name...',
                              prefixIcon: Icon(
                                Icons.person_search_rounded,
                                color: AppDesign.primaryEmerald,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppDesign.darkCard
                                  : Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: AppDesign.borderMedium,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppDesign.borderMedium,
                                borderSide: BorderSide(
                                  color: isDark
                                      ? AppDesign.darkBorder
                                      : AppDesign.lightBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppDesign.borderMedium,
                                borderSide: const BorderSide(
                                  color: AppDesign.primaryEmerald,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (_selectedPerson == null) {
                                return 'Required: Please select a valid contact';
                              }
                              return null;
                            },
                          );
                        },
                  );
                },
                loading: () => const LinearProgressIndicator(
                  color: AppDesign.primaryEmerald,
                ),
                error: (err, _) => Text('Error loading contacts: $err'),
              ),
              const SizedBox(height: 20),

              // Select Khata
              if (_selectedPerson != null) ...[
                const Text(
                  '2. Select Account (Khata)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isLoadingKhatas)
                  const CircularProgressIndicator(
                    color: AppDesign.primaryEmerald,
                  )
                else if (_khatas.isEmpty)
                  TextButton.icon(
                    onPressed: () => context.push(
                      '/people/${_selectedPerson!.uuid}/khata/add',
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create a Khata first'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppDesign.primaryEmerald,
                    ),
                  )
                else
                  DropdownButtonFormField<Khata>(
                    value: _selectedKhata,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? AppDesign.darkCard
                          : Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: AppDesign.borderMedium,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppDesign.borderMedium,
                        borderSide: BorderSide(
                          color: isDark
                              ? AppDesign.darkBorder
                              : AppDesign.lightBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppDesign.borderMedium,
                        borderSide: const BorderSide(
                          color: AppDesign.primaryEmerald,
                          width: 2,
                        ),
                      ),
                    ),
                    items: _khatas.map((k) {
                      return DropdownMenuItem(value: k, child: Text(k.title));
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedKhata = val;
                      });
                    },
                    validator: (val) => val == null
                        ? 'Required: Please select a Khata account'
                        : null,
                  ),
                const SizedBox(height: 20),
              ],

              // Amount textfield
              const Text(
                '3. Enter Amount',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _amountController,
                labelText: 'Amount',
                hintText: '0.00',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Required: Please enter amount';
                  final num = double.tryParse(val.trim());
                  if (num == null || num <= 0)
                    return 'Required: Please enter a valid positive number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Transaction Type Buttons
              const Text(
                '4. Transaction Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.3,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildTypeButton(
                    TransactionType.gave,
                    'GAVE (Lent)',
                    AppDesign.greenReceivable,
                  ),
                  _buildTypeButton(
                    TransactionType.received,
                    'RECEIVED',
                    AppDesign.redPayable,
                  ),
                  _buildTypeButton(
                    TransactionType.borrowed,
                    'BORROWED',
                    AppDesign.amberWarning,
                  ),
                  _buildTypeButton(
                    TransactionType.paid,
                    'REPAID (Paid)',
                    AppDesign.primaryTeal,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction Date Selector
              const Text(
                '5. Transaction Date',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTransactionDate(context),
                borderRadius: AppDesign.borderMedium,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppDesign.darkCard : Colors.white,
                    border: Border.all(
                      color: isDark
                          ? AppDesign.darkBorder
                          : AppDesign.lightBorder,
                    ),
                    borderRadius: AppDesign.borderMedium,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppDesign.primaryEmerald,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${_transactionDate.day}/${_transactionDate.month}/${_transactionDate.year}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Change',
                        style: TextStyle(
                          color: AppDesign.primaryEmerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  'The actual day money was exchanged.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),

              // Notes Remarks
              const Text(
                '6. Notes / Remarks (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              AppTextField(
                controller: _notesController,
                labelText: 'Notes',
                hintText: 'Enter specific transaction details...',
                prefixIcon: Icons.description_rounded,
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Save Transaction',
                onPressed: _save,
                isFullWidth: true,
                backgroundColor: AppDesign.primaryEmerald,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    TransactionType type,
    String label,
    Color activeColor,
  ) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: AppDesign.borderMedium,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : (isDark ? AppDesign.darkCard : Colors.grey[50]),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppDesign.darkBorder : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: AppDesign.borderMedium,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? activeColor
                : (isDark ? Colors.grey.shade300 : Colors.black87),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
