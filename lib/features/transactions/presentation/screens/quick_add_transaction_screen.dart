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
  DateTime? _transactionDate;

  Future<void> _selectTransactionDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate ?? DateTime.now(),
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
    if (_transactionDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a transaction date')),
      );
      return;
    }

    // ── Validation: RECEIVED requires a positive receivable balance ─────────
    if (_selectedType == TransactionType.received) {
      final txsState = ref.read(
        transactionsForKhataProvider(_selectedKhata!.uuid),
      );
      final txs = txsState.valueOrNull ?? [];
      double receivable = 0.0;
      for (final tx in txs) {
        if (tx.type == TransactionType.gave) receivable += tx.amount;
        if (tx.type == TransactionType.received) receivable -= tx.amount;
      }
      if (receivable <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no outstanding amount to collect.'),
            backgroundColor: AppDesign.amberWarning,
          ),
        );
        return;
      }
    }

    // ── Validation: REPAYMENT requires a positive borrowed balance ──────────
    if (_selectedType == TransactionType.paid) {
      final txsState = ref.read(
        transactionsForKhataProvider(_selectedKhata!.uuid),
      );
      final txs = txsState.valueOrNull ?? [];
      double borrowed = 0.0;
      for (final tx in txs) {
        if (tx.type == TransactionType.borrowed) borrowed += tx.amount;
        if (tx.type == TransactionType.paid) borrowed -= tx.amount;
      }
      if (borrowed <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no borrowed amount to repay.'),
            backgroundColor: AppDesign.amberWarning,
          ),
        );
        return;
      }
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
      body: SafeArea(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesign.space12,
              vertical: AppDesign.space8,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contact Select
                const Text(
                  '1. Select Contact',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                prefixIcon: Icon(
                                  Icons.person_search_rounded,
                                  color: AppDesign.primaryEmerald,
                                  size: 18,
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
                const SizedBox(height: 10),
  
                // Select Khata
                if (_selectedPerson != null) ...[
                  const Text(
                    '2. Select Account (Khata)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_isLoadingKhatas)
                    const CircularProgressIndicator(
                      color: AppDesign.primaryEmerald,
                    )
                  else if (_khatas.isEmpty)
                    TextButton.icon(
                      onPressed: () async {
                        final personUuid = _selectedPerson!.uuid;
                        // Await navigation result containing the newly created Khata.
                        // This allows immediate UI update without requiring screen reopen.
                        final newKhata = await context.push<Khata>(
                          '/people/$personUuid/khata/add',
                        );
                        
                        if (!mounted) return;

                        // Refresh/invalidate the Riverpod provider for this person's khatas
                        // to ensure the overall application state remains in sync.
                        ref.invalidate(khatasForPersonProvider(personUuid));

                        setState(() {
                          _isLoadingKhatas = true;
                        });

                        try {
                          final repo = ref.read(khataRepositoryProvider);
                          final list = await repo.getKhatasForPerson(personUuid);
                          
                          if (mounted) {
                            setState(() {
                              final Map<String, Khata> uniqueKhatas = {};
                              
                              // Populate with fresh database entries
                              for (final k in list) {
                                if (k.uuid.isNotEmpty) {
                                  uniqueKhatas[k.uuid] = k;
                                }
                              }
                              
                              // If a new Khata was returned, ensure it's in the unique map
                              if (newKhata != null && newKhata.uuid.isNotEmpty) {
                                uniqueKhatas[newKhata.uuid] = newKhata;
                              }
                              
                              // Replace the entire list with the deduplicated elements
                              _khatas = uniqueKhatas.values.toList();
                              
                              // Auto-select the newly created Khata, or fallback to the single item if only one exists
                              if (newKhata != null) {
                                _selectedKhata = _khatas.firstWhere(
                                  (k) => k.uuid == newKhata.uuid,
                                  orElse: () => newKhata,
                                );
                              } else if (_khatas.length == 1) {
                                _selectedKhata = _khatas.first;
                              }
                            });
                          }
                        } catch (_) {
                          // Handle errors silently
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoadingKhatas = false;
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Create a Khata first', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: AppDesign.primaryEmerald,
                        minimumSize: const Size(44, 32),
                      ),
                    )
                  else
                    DropdownButtonFormField<Khata>(
                      value: _selectedKhata,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        return DropdownMenuItem(value: k, child: Text(k.title, style: const TextStyle(fontSize: 14)));
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
                  const SizedBox(height: 10),
                ],
  
                // Amount textfield
                const Text(
                  '3. Enter Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 10),
  
                // Transaction Type Buttons
                const Text(
                  '4. Transaction Type',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.8,
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
                const SizedBox(height: 10),
  
                // Transaction Date Selector
                const Text(
                  '5. Transaction Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _selectTransactionDate(context),
                  borderRadius: AppDesign.borderMedium,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
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
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _transactionDate == null
                              ? 'Select Date (Required)'
                              : '${_transactionDate!.day}/${_transactionDate!.month}/${_transactionDate!.year}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _transactionDate == null ? Colors.redAccent : null,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Change',
                          style: TextStyle(
                            color: AppDesign.primaryEmerald,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),
  
                // Notes Remarks
                const Text(
                  '6. Notes / Remarks (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                AppTextField(
                  controller: _notesController,
                  labelText: 'Notes',
                  hintText: 'Enter specific transaction details...',
                  prefixIcon: Icons.description_rounded,
                ),
                const SizedBox(height: 16),
  
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
