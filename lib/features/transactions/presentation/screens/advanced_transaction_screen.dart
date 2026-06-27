import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction.dart';
import '../providers/transaction_providers.dart';

import '../../../../core/services/notification_service.dart';

class AdvancedTransactionScreen extends ConsumerStatefulWidget {
  final String khataUuid;
  const AdvancedTransactionScreen({super.key, required this.khataUuid});

  @override
  ConsumerState<AdvancedTransactionScreen> createState() => _AdvancedTransactionScreenState();
}

class _AdvancedTransactionScreenState extends ConsumerState<AdvancedTransactionScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  TransactionType _selectedType = TransactionType.gave;
  DateTime? _dueDate;
  DateTime? _reminderDate;

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
      ..notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim()
      ..dueDate = _dueDate
      ..reminderDate = _reminderDate
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now()
      ..isDeleted = false;

    await ref.read(transactionsForKhataProvider(widget.khataUuid).notifier).addTransaction(tx);

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
        body: 'Reminder for transaction of PKR ${amount.toStringAsFixed(2)}: ${tx.notes ?? "No notes added."}',
        scheduledDate: _reminderDate!,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction saved successfully!')),
      );
      context.pop(); // Return to Khata detail
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Widget _buildTypeButton(TransactionType type, String label, Color activeColor, IconData icon) {
    final isSelected = _selectedType == type;
    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? activeColor : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction (Advanced)', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 3.2,
              children: [
                _buildTypeButton(TransactionType.gave, 'Gave (Lent)', Colors.green, Icons.arrow_upward_rounded),
                _buildTypeButton(TransactionType.received, 'Received', Colors.red, Icons.arrow_downward_rounded),
                _buildTypeButton(TransactionType.borrowed, 'Borrowed', Colors.redAccent, Icons.south_west_rounded),
                _buildTypeButton(TransactionType.paid, 'Paid (Repaid)', Colors.greenAccent[700]!, Icons.north_east_rounded),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              decoration: InputDecoration(
                prefixText: 'PKR ',
                prefixIcon: const Icon(Icons.currency_exchange, color: Colors.teal, size: 20),
                hintText: '0.00',
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Schedule & Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Theme.of(context).cardColor,
              ),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    leading: const Icon(Icons.calendar_today_rounded, color: Colors.teal, size: 18),
                    title: Text(
                      _dueDate == null ? 'Due Date (Optional)' : 'Due: ${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year} at ${TimeOfDay.fromDateTime(_dueDate!).format(context)}',
                      style: TextStyle(
                        fontSize: 13, 
                        color: _dueDate == null ? Colors.grey[600] : Colors.teal[800], 
                        fontWeight: _dueDate == null ? FontWeight.normal : FontWeight.bold
                      ),
                    ),
                    trailing: _dueDate != null 
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () => setState(() => _dueDate = null),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    onTap: () => _selectDueDate(context),
                  ),
                  const Divider(height: 1, indent: 14, endIndent: 14),
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    leading: const Icon(Icons.notifications_active_outlined, color: Colors.teal, size: 18),
                    title: Text(
                      _reminderDate == null ? 'Reminder Date (Optional)' : 'Remind: ${_reminderDate!.day}/${_reminderDate!.month}/${_reminderDate!.year} at ${TimeOfDay.fromDateTime(_reminderDate!).format(context)}',
                      style: TextStyle(
                        fontSize: 13, 
                        color: _reminderDate == null ? Colors.grey[600] : Colors.teal[800], 
                        fontWeight: _reminderDate == null ? FontWeight.normal : FontWeight.bold
                      ),
                    ),
                    trailing: _reminderDate != null 
                        ? IconButton(
                            icon: const Icon(Icons.close, size: 16, color: Colors.red),
                            onPressed: () => setState(() => _reminderDate = null),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    onTap: () => _selectReminderDate(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Enter specific transaction details...',
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
                onPressed: _save,
                child: const Text('Save Transaction', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
