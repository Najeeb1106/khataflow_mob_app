import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/khata.dart';
import '../providers/khata_providers.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

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
        if (widget.khataUuid != null && k.uuid == widget.khataUuid) {
          return false;
        }
        return k.title.trim().toLowerCase() == proposedTitle;
      });

      if (isDuplicate) {
        if (mounted) {
          AppSnackbar.show(
            context,
            'A Khata with this name already exists for this contact.',
            type: AppSnackbarType.error,
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
        body: const Center(
          child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppDesign.primaryEmerald),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDesign.space24,
            vertical: AppDesign.space24,
          ),
          children: [
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Khata Title (e.g. Shop Items, Personal Loan) *',
                prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppDesign.borderMedium,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDesign.space24),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppDesign.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: AppDesign.space32),
            AppButton(
              label: widget.khataUuid == null ? 'Save Khata' : 'Update Khata',
              onPressed: _save,
              isFullWidth: true,
              backgroundColor: AppDesign.primaryEmerald,
            ),
          ],
        ),
      ),
    );
  }
}
