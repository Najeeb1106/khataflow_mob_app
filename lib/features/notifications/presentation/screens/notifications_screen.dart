import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  void _triggerMockDueAlert(BuildContext context) {
    NotificationService().showNotification(
      id: 101,
      title: 'Payment Due Today ⏰',
      body: 'Ali Khan owes Rs. 10,000. Due by end of day.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mock alert triggered! Check your notifications.')),
    );
  }

  void _triggerMockSummaryAlert(BuildContext context) {
    NotificationService().showNotification(
      id: 102,
      title: 'Daily Summary Report 📊',
      body: 'Total Receivables: Rs. 45,000. 2 accounts overdue.',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mock daily summary triggered! Check notifications.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Alerts', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Alerts Info
          Card(
            color: Colors.teal[50],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Notification Profiles',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow('Due Date Alerts', 'Alerts when repayment timeline is reached.'),
                  _buildProfileRow('Overdue Notices', 'Daily updates for accounts remaining unpaid.'),
                  _buildProfileRow('Daily Summary', 'A quick nightly snapshot of outstanding balances.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Developer Simulator', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Use the buttons below to manually trigger local notification alerts for testing.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.notifications_active),
            label: const Text('Simulate "Due Today" Alert'),
            onPressed: () => _triggerMockDueAlert(context),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.bar_chart),
            label: const Text('Simulate "Daily Summary" Alert'),
            onPressed: () => _triggerMockSummaryAlert(context),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(description, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
