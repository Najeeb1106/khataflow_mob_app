import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/khata.dart';
import '../providers/khata_providers.dart';

class AddEditKhataScreen extends ConsumerStatefulWidget {
  final String personUuid;
  final String? khataUuid;

  const AddEditKhataScreen({
    super.key,
    required this.personUuid,
    this.khataUuid,
  });

  @override
  ConsumerState<AddEditKhataScreen> createState() => _AddEditKhataScreenState();
}

class _AddEditKhataScreenState extends ConsumerState<AddEditKhataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  Khata? _existingKhata;

  @override
  void initState() {
    super.initState();
    if (widget.khataUuid != null) {
      _loadKhata();
    }
  }

  Future<void> _loadKhata() async {
    setState(() => _isLoading = true);
    final repo = ref.read(khataRepositoryProvider);
    final k = await repo.getKhata(widget.khataUuid!);
    if (k != null && mounted) {
      _existingKhata = k;
      _titleController.text = k.title;
      _notesController.text = k.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(khataRepositoryProvider);
      final existingKhatas = await repo.getKhatasForPerson(widget.personUuid);
      
      final proposedTitle = _titleController.text.trim().toLowerCase();
      final isDuplicate = existingKhatas.any((k) {
        // When editing an existing Khata, ignore the current Khata's own UUID
        if (widget.khataUuid != null && k.uuid == widget.khataUuid) {
          return false;
        }
        return k.title.trim().toLowerCase() == proposedTitle;
      });

      if (isDuplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A Khata with this name already exists for this contact.'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        return;
      }
    } catch (_) {
      // Proceed to save if database check fails
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    final khata = _existingKhata ?? Khata()
      ..uuid = const Uuid().v4()
      ..personUuid = widget.personUuid
      ..createdAt = DateTime.now()
      ..isDeleted = false;

    khata.title = _titleController.text.trim();
    khata.notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final notifier = ref.read(
      khatasForPersonProvider(widget.personUuid).notifier,
    );
    if (_existingKhata == null) {
      await notifier.addKhata(khata);
    } else {
      await notifier.updateKhata(khata);
    }

    if (mounted) {
      context.pop(khata);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.khataUuid == null ? 'Create Khata' : 'Edit Khata';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.teal),
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Khata Title (e.g. Shop Items, Personal Loan) *',
                prefixIcon: const Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _save,
                child: const Text(
                  'Save Khata',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
