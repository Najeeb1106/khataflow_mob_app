import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_providers.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class AdvancedTransactionScreen extends ConsumerStatefulWidget {
  final String khataUuid;
  final String? presetType;
  const AdvancedTransactionScreen({
    super.key,
    required this.khataUuid,
    this.presetType,
  });

  @override
  ConsumerState<AdvancedTransactionScreen> createState() =>
      _AdvancedTransactionScreenState();
}

class _AdvancedTransactionScreenState
    extends ConsumerState<AdvancedTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.gave;
  DateTime _transactionDate = DateTime.now();
  DateTime? _dueDate;
  DateTime? _reminderDate;

  @override
  void initState() {
    super.initState();
    if (widget.presetType != null) {
      final match = TransactionType.values.firstWhere(
        (e) => e.name.toLowerCase() == widget.presetType!.toLowerCase(),
        orElse: () => TransactionType.gave,
      );
      setState(() {
        _selectedType = match;
      });
    }
  }

  Future<void> _selectTransactionDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      setState(() {
        _transactionDate = pickedDate;
      });
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _selectReminderDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _reminderDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid positive amount')),
      );
      return;
    }

    final tx = Transaction()
      ..uuid = const Uuid().v4()
      ..khataUuid = widget.khataUuid
      ..type = _selectedType
      ..amount = amount
      ..notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim()
      ..transactionDate = _transactionDate
      ..dueDate = _dueDate
      ..reminderDate = _reminderDate
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isDeleted = false;

    await ref
        .read(transactionsForKhataProvider(widget.khataUuid).notifier)
        .addTransaction(tx);

    // Schedule notifications if dates are set
    if (_dueDate != null) {
      final dueId = tx.uuid.hashCode;
      await NotificationService().scheduleNotification(
        id: dueId,
        title: 'Payment Due Alert',
        body: 'Payment of PKR ${amount.toStringAsFixed(2)} is due now.',
        scheduledDate: _dueDate!,
      );
    }

    if (_reminderDate != null) {
      final remindId = tx.uuid.hashCode + 1;
      await NotificationService().scheduleNotification(
        id: remindId,
        title: 'Transaction Reminder',
        body:
            'Reminder for transaction of PKR ${amount.toStringAsFixed(2)}: ${tx.notes ?? "No notes added."}',
        scheduledDate: _reminderDate!,
      );
    }

    if (mounted) {
      AppHaptics.light();
      AppSnackbar.show(
        context,
        'Transaction saved successfully!',
        type: AppSnackbarType.success,
      );
      context.pop();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildTypeButton(
    TransactionType type,
    String label,
    Color activeColor,
    IconData icon,
  ) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: AppDesign.borderMedium,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: AppDesign.borderMedium,
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? AppDesign.darkBorder : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.grey.shade300 : Colors.grey[800]),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Transaction',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.space16,
            vertical: AppDesign.space12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction Type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.3,
                padding: EdgeInsets.zero,
                children: [
                  _buildTypeButton(
                    TransactionType.gave,
                    'LENT (Gave)',
                    AppDesign.greenReceivable,
                    Icons.arrow_upward_rounded,
                  ),
                  _buildTypeButton(
                    TransactionType.received,
                    'RECEIVED',
                    AppDesign.redPayable,
                    Icons.arrow_downward_rounded,
                  ),
                  _buildTypeButton(
                    TransactionType.borrowed,
                    'BORROWED',
                    AppDesign.amberWarning,
                    Icons.south_west_rounded,
                  ),
                  _buildTypeButton(
                    TransactionType.paid,
                    'REPAID (Paid)',
                    AppDesign.primaryTeal,
                    Icons.north_east_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              const Text(
                'Amount',
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
              const SizedBox(height: 16),

              const Text(
                'Transaction Date (Required)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppDesign.borderMedium,
                  border: Border.all(
                    color: isDark
                        ? AppDesign.darkBorder
                        : AppDesign.lightBorder,
                  ),
                  color: isDark ? AppDesign.darkCard : Colors.white,
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 0,
                  ),
                  leading: Icon(
                    Icons.calendar_today_rounded,
                    color: AppDesign.primaryEmerald,
                    size: 18,
                  ),
                  title: Text(
                    'Date: ${_transactionDate.day}/${_transactionDate.month}/${_transactionDate.year}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    'Change',
                    style: TextStyle(
                      color: AppDesign.primaryEmerald,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _selectTransactionDate(context),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  'The actual day money was exchanged.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Schedule & Alerts (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: AppDesign.borderMedium,
                  border: Border.all(
                    color: isDark
                        ? AppDesign.darkBorder
                        : AppDesign.lightBorder,
                  ),
                  color: isDark ? AppDesign.darkCard : Colors.white,
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      leading: Icon(
                        Icons.event_note_rounded,
                        color: AppDesign.primaryEmerald,
                        size: 18,
                      ),
                      title: Text(
                        _dueDate == null
                            ? 'Due Date (Optional)'
                            : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} at ${TimeOfDay.fromDateTime(_dueDate!).format(context)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _dueDate == null
                              ? Colors.grey
                              : AppDesign.primaryEmerald,
                          fontWeight: _dueDate == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      trailing: _dueDate != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppDesign.redPayable,
                              ),
                              onPressed: () => setState(() => _dueDate = null),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.grey,
                            ),
                      onTap: () => _selectDueDate(context),
                    ),
                    const Divider(height: 1, indent: 14, endIndent: 14),
                    ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 0,
                      ),
                      leading: Icon(
                        Icons.notifications_active_outlined,
                        color: AppDesign.primaryTeal,
                        size: 18,
                      ),
                      title: Text(
                        _reminderDate == null
                            ? 'Reminder Date (Optional)'
                            : 'Remind: ${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year} at ${TimeOfDay.fromDateTime(_reminderDate!).format(context)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _reminderDate == null
                              ? Colors.grey
                              : AppDesign.primaryTeal,
                          fontWeight: _reminderDate == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      trailing: _reminderDate != null
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppDesign.redPayable,
                              ),
                              onPressed: () =>
                                  setState(() => _reminderDate = null),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 12,
                              color: Colors.grey,
                            ),
                      onTap: () => _selectReminderDate(context),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 4),
                child: Text(
                  'Due Date: When repayment is expected.\nReminder: When KhataFlow should notify you.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Notes / Remarks',
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
              const SizedBox(height: 24),

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
}
