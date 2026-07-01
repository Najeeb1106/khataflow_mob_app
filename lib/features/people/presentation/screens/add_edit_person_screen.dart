import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/person.dart';
import '../providers/people_providers.dart';

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
  Person? _existingPerson;

  @override
  void initState() {
    super.initState();
    if (widget.personUuid != null) {
      _loadPerson();
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final person = _existingPerson ?? Person()
      ..uuid = const Uuid().v4()
      ..createdAt = DateTime.now()
      ..isDeleted = false;

    person.name = _nameController.text.trim();
    person.phone = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
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

  @override
  Widget build(BuildContext context) {
    final title = widget.personUuid == null ? 'Add Person' : 'Edit Person';

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
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Contact Name *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number (Optional)',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
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
                  'Save Contact',
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
