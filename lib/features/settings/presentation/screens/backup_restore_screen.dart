import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/design_system.dart';
import '../../../../core/services/backup_service.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../providers/settings_providers.dart';

// ---------------------------------------------------------------------------
// BackupRestoreScreen
// ---------------------------------------------------------------------------
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() =>
      _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _exporting = false;
  bool _importing = false;

  // -------------------------------------------------------------------------
  // Export
  // -------------------------------------------------------------------------
  Future<void> _doExport() async {
    setState(() => _exporting = true);
    try {
      await BackupService.exportBackup();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup exported — save the file to a safe location.'),
            backgroundColor: AppDesign.primaryTeal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppDesign.redPayable,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // -------------------------------------------------------------------------
  // Import → Preview → Confirm → Restore
  // -------------------------------------------------------------------------
  Future<void> _doImport() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select KhataFlow Backup File',
      );

      if (result == null || result.files.single.path == null) {
        // User cancelled.
        return;
      }

      final file = File(result.files.single.path!);

      BackupPreview preview;
      try {
        preview = await BackupService.parseBackupPreview(file);
      } on FormatException catch (e) {
        if (mounted) {
          _showError('Invalid backup file', e.message);
        }
        return;
      }

      if (mounted) {
        await _showRestorePreviewDialog(preview);
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not open file', e.toString());
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // -------------------------------------------------------------------------
  // Restore Preview Dialog
  // -------------------------------------------------------------------------
  Future<void> _showRestorePreviewDialog(BackupPreview preview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RestorePreviewDialog(preview: preview),
    );

    if (confirmed == true && mounted) {
      await _executeRestore(preview);
    }
  }

  Future<void> _executeRestore(BackupPreview preview) async {
    // Safety confirmation — warn that current data will be replaced.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: const Text(
          'Confirm Restore',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Restoring this backup will replace your current local data. '
          'This action cannot be undone.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppDesign.primaryTeal,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: AppDesign.borderMedium,
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // Show progress, then restore.
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Restoring backup…'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      await BackupService.restoreBackup(preview);

      // Invalidate providers so UI reflects restored data.
      ref.read(peopleListProvider.notifier).loadPeople();
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(dashboardRecentTransactionsProvider);
      ref.read(settingsProvider.notifier).loadSettings();

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Backup restored successfully. Please verify your data.',
            ),
            backgroundColor: AppDesign.primaryTeal,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog.
        _showError('Restore failed', e.toString());
      }
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
        title: Text(title,
            style: const TextStyle(
                color: AppDesign.redPayable, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Data & Backup',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDesign.space24,
          vertical: AppDesign.space16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info banner ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppDesign.primaryTeal.withValues(alpha: 0.08),
                borderRadius: AppDesign.borderMedium,
                border: Border.all(
                  color: AppDesign.primaryTeal.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppDesign.primaryTeal, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Backups are stored locally as JSON files. '
                      'Save them to a safe location (e.g. cloud storage, email) '
                      'to recover your data after a device change.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: Export ────────────────────────────────────────
            _SectionHeader(label: 'EXPORT', isDark: isDark),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppDesign.primaryEmerald
                                .withValues(alpha: 0.12),
                            borderRadius: AppDesign.borderSmall,
                          ),
                          child: const Icon(
                            Icons.upload_rounded,
                            color: AppDesign.primaryEmerald,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Exports all contacts, khatas, transactions '
                                'and settings into a single JSON file.',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppDesign.primaryEmerald,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDesign.borderMedium,
                          ),
                        ),
                        onPressed: _exporting ? null : _doExport,
                        icon: _exporting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          _exporting ? 'Preparing…' : 'Export Backup',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Section: Restore ───────────────────────────────────────
            _SectionHeader(label: 'RESTORE', isDark: isDark),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppDesign.amberWarning
                                .withValues(alpha: 0.12),
                            borderRadius: AppDesign.borderSmall,
                          ),
                          child: const Icon(
                            Icons.restore_rounded,
                            color: AppDesign.amberWarning,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Restore Backup',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Select a previously exported .json file. '
                                'You will see a preview before any data is changed.',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppDesign.amberWarning,
                          side: const BorderSide(
                              color: AppDesign.amberWarning),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDesign.borderMedium,
                          ),
                        ),
                        onPressed: _importing ? null : _doImport,
                        icon: _importing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppDesign.amberWarning,
                                ),
                              )
                            : const Icon(Icons.folder_open_rounded,
                                size: 18),
                        label: Text(
                          _importing
                              ? 'Reading file…'
                              : 'Select Backup File',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Restore Preview Dialog
// ---------------------------------------------------------------------------
class _RestorePreviewDialog extends StatelessWidget {
  final BackupPreview preview;

  const _RestorePreviewDialog({required this.preview});

  @override
  Widget build(BuildContext context) {
    String txDateRange = 'No transactions';
    if (preview.earliestTransaction != null &&
        preview.latestTransaction != null) {
      if (preview.earliestTransaction == preview.latestTransaction) {
        txDateRange = _fmtDate(preview.earliestTransaction!);
      } else {
        txDateRange =
            '${_fmtDate(preview.earliestTransaction!)} → '
            '${_fmtDate(preview.latestTransaction!)}';
      }
    }

    final createdAtLocal = preview.createdAt.toLocal();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
      title: Row(
        children: [
          const Icon(Icons.restore_rounded,
              color: AppDesign.primaryTeal, size: 22),
          const SizedBox(width: 8),
          const Text(
            'Restore Preview',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following data will be restored:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _PreviewRow(
              icon: Icons.calendar_today_rounded,
              label: 'Backup date',
              value: _fmtDateTime(createdAtLocal),
            ),
            _PreviewRow(
              icon: Icons.info_outline_rounded,
              label: 'App version',
              value: preview.appVersion,
            ),
            const Divider(height: 20),
            _PreviewRow(
              icon: Icons.people_alt_rounded,
              label: 'Contacts',
              value: '${preview.peopleCount}',
              highlight: true,
            ),
            _PreviewRow(
              icon: Icons.book_rounded,
              label: 'Khatas',
              value: '${preview.khataCount}',
              highlight: true,
            ),
            _PreviewRow(
              icon: Icons.receipt_long_rounded,
              label: 'Transactions',
              value: '${preview.transactionCount}',
              highlight: true,
            ),
            _PreviewRow(
              icon: Icons.date_range_rounded,
              label: 'Date range',
              value: txDateRange,
            ),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppDesign.amberWarning.withValues(alpha: 0.1),
                borderRadius: AppDesign.borderSmall,
                border: Border.all(
                  color: AppDesign.amberWarning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppDesign.amberWarning, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Restoring this backup will replace your current local data.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppDesign.amberWarning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppDesign.primaryTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppDesign.borderMedium,
            ),
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Restore Data'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date formatting helpers (no intl dep needed)
// ---------------------------------------------------------------------------
String _twoDigit(int n) => n.toString().padLeft(2, '0');

String _fmtDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${_twoDigit(d.day)} ${months[d.month - 1]} ${d.year}';
}

String _fmtDateTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final period = d.hour < 12 ? 'AM' : 'PM';
  return '${_fmtDate(d)}, ${_twoDigit(hour)}:${_twoDigit(d.minute)} $period';
}

// ---------------------------------------------------------------------------
// Small helpers
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 10,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _PreviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: highlight
                  ? AppDesign.primaryEmerald
                  : Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  highlight ? FontWeight.bold : FontWeight.normal,
              color: highlight ? AppDesign.primaryEmerald : null,
            ),
          ),
        ],
      ),
    );
  }
}
