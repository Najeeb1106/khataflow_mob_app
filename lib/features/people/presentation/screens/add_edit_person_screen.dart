import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/person.dart';
import '../providers/people_providers.dart';
import '../../../../core/services/contact_import_service.dart';
import '../../../../core/utils/avatar_color_helper.dart';
import '../../../../core/utils/phone_normalizer.dart';
import '../../../../core/presentation/design_system.dart';
import '../../../../core/presentation/widgets/shared_widgets.dart';

class AddEditPersonScreen extends ConsumerStatefulWidget {
  final String? personUuid;
  const AddEditPersonScreen({super.key, this.personUuid});

  @override
  ConsumerState<AddEditPersonScreen> createState() =>
      _AddEditPersonScreenState();
}

class _AddEditPersonScreenState extends ConsumerState<AddEditPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isImporting = false;
  Person? _existingPerson;

  bool get _isAddMode => widget.personUuid == null;

  @override
  void initState() {
    super.initState();
    if (!_isAddMode) {
      _loadPerson();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPerson() async {
    setState(() => _isLoading = true);
    final repo = ref.read(personRepositoryProvider);
    final p = await repo.getPerson(widget.personUuid!);
    if (p != null && mounted) {
      _existingPerson = p;
      _nameController.text = p.name;
      _phoneController.text = p.phone ?? '';
      _notesController.text = p.notes ?? '';
    }
    setState(() => _isLoading = false);
  }

  // ── Contact Import ──────────────────────────────────────────────────────

  Future<void> _importFromContacts() async {
    setState(() => _isImporting = true);
    try {
      final result = await ContactImportService.pickContact(context);
      if (result == null || !mounted) {
        setState(() => _isImporting = false);
        return;
      }

      final name = result['name'] as String;
      final phones = result['phones'] as List<String>;

      // Check if contact has no phone numbers
      if (phones.isEmpty) {
        setState(() => _isImporting = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: AppDesign.borderMedium),
              title: const Text('Import Failed', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text("This contact doesn't have a phone number."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK', style: TextStyle(color: AppDesign.primaryEmerald)),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Phone number selection (if contact has multiple numbers)
      String? selectedPhone;
      if (phones.isNotEmpty && mounted) {
        selectedPhone =
            await ContactImportService.pickPhoneNumber(context, phones);
        // null here means the user tapped Cancel on the phone picker
        if (phones.length > 1 && selectedPhone == null) {
          setState(() => _isImporting = false);
          return;
        }
        selectedPhone ??= phones.isNotEmpty ? phones.first : null;
      }

      if (!mounted) {
        setState(() => _isImporting = false);
        return;
      }

      // Duplicate detection against existing contacts
      final allPeople =
          ref.read(peopleListProvider).valueOrNull ?? <Person>[];
      final duplicate = ContactImportService.findDuplicate(
        people: allPeople,
        name: name,
        phone: selectedPhone,
        excludeUuid: widget.personUuid,
      );

      if (duplicate != null && mounted) {
        setState(() => _isImporting = false);
        final openExisting = await ContactImportService.showDuplicateDialog(
          context,
          duplicate,
        );
        if (openExisting && mounted) {
          context.push('/people/${duplicate.uuid}');
        }
        return;
      }

      // No duplicate — pre-fill the form
      setState(() {
        _nameController.text = name;
        _phoneController.text = selectedPhone ?? '';
        _isImporting = false;
      });

      if (mounted) {
        AppSnackbar.show(
          context,
          'Contact imported. You can edit before saving.',
          type: AppSnackbarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        AppSnackbar.show(
          context,
          'Could not access contacts: $e',
          type: AppSnackbarType.error,
        );
      }
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();

    // Run duplicate detection on manual save as well
    final allPeople = ref.read(peopleListProvider).valueOrNull ?? <Person>[];
    final duplicate = ContactImportService.findDuplicate(
      people: allPeople,
      name: name,
      phone: phone,
      excludeUuid: widget.personUuid,
    );

    if (duplicate != null && mounted) {
      final openExisting = await ContactImportService.showDuplicateDialog(
        context,
        duplicate,
      );
      if (openExisting && mounted) {
        context.push('/people/${duplicate.uuid}');
      }
      return;
    }

    final person = _existingPerson ?? Person()
      ..uuid = const Uuid().v4()
      ..createdAt = DateTime.now()
      ..isDeleted = false;

    person.name = name;
    // Normalize phone numbers before saving to the database
    person.phone = phone != null ? PhoneNormalizer.normalize(phone) : null;
    person.notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_existingPerson == null) {
      await ref.read(peopleListProvider.notifier).addPerson(person);
    } else {
      await ref.read(peopleListProvider.notifier).updatePerson(person);
    }

    if (mounted) {
      context.pop();
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final title = _isAddMode ? 'Add Person' : 'Edit Person';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(
          child: CircularProgressIndicator(color: AppDesign.primaryEmerald),
        ),
      );
    }

    // Stable avatar preview for edit mode
    final avatarColor = _existingPerson != null
        ? AvatarColorHelper.forUuid(_existingPerson!.uuid)
        : AppDesign.primaryEmerald;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Import button only in Add mode
          if (_isAddMode)
            _isImporting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppDesign.primaryEmerald,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.contacts_rounded),
                    tooltip: 'Import from Contacts',
                    onPressed: _importFromContacts,
                  ),
          IconButton(
            icon: const Icon(Icons.check_rounded, color: AppDesign.primaryEmerald),
            tooltip: 'Save contact',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDesign.space24),
          children: [
            // ── Import prompt card (Add mode only) ─────────────────────
            if (_isAddMode) ...[
              InkWell(
                onTap: _isImporting ? null : _importFromContacts,
                borderRadius: AppDesign.borderMedium,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.space16,
                    vertical: AppDesign.space16,
                  ),
                  decoration: BoxDecoration(
                    color: AppDesign.primaryEmerald.withValues(
                      alpha: isDark ? 0.08 : 0.05,
                    ),
                    borderRadius: AppDesign.borderMedium,
                    border: Border.all(
                      color: AppDesign.primaryEmerald.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppDesign.primaryEmerald.withValues(
                            alpha: 0.12,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.contacts_rounded,
                          color: AppDesign.primaryEmerald,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Import from Phone Contacts',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : AppDesign.primaryTeal,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to pick a contact and auto-fill the form.',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppDesign.primaryEmerald.withValues(alpha: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'or fill manually',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // ── Avatar preview (Edit mode) ─────────────────────────────
            if (!_isAddMode) ...[
              Center(
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: avatarColor.withValues(alpha: 0.12),
                  child: Text(
                    (_existingPerson?.name.isNotEmpty == true)
                        ? _existingPerson!.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: avatarColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ── Name Field ─────────────────────────────────────────────
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Contact Name *',
                prefixIcon: const Icon(Icons.person_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppDesign.borderMedium,
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a contact name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Phone Field ────────────────────────────────────────────
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: const Icon(Icons.phone_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppDesign.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Notes Field ────────────────────────────────────────────
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                prefixIcon: const Icon(Icons.notes_rounded),
                border: OutlineInputBorder(
                  borderRadius: AppDesign.borderMedium,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Button ────────────────────────────────────────────
            AppButton(
              label: _isAddMode ? 'Save Contact' : 'Update Contact',
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
