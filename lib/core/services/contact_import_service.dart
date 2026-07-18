import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../features/people/data/models/person.dart';
import '../utils/phone_normalizer.dart';

/// Service that encapsulates all device contact import logic:
/// permission requests, native contact picking, and duplicate detection.
///
/// All methods are static — this class has no instance state.
class ContactImportService {
  ContactImportService._();

  /// Requests READ_CONTACTS permission from the user.
  ///
  /// Returns `true` if granted or limited, `false` if denied.
  static Future<bool> requestPermission(BuildContext context) async {
    final currentStatus = await FlutterContacts.permissions.check(PermissionType.read);
    if (currentStatus == PermissionStatus.permanentlyDenied ||
        currentStatus == PermissionStatus.restricted) {
      if (context.mounted) {
        final openSettings = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              'Permission Required',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Contact permission is required to import contacts. Please enable it from your device settings.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Open Settings', style: TextStyle(color: Color(0xFF0F766E))),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          await FlutterContacts.permissions.openSettings();
        }
      }
      return false;
    }

    final status = await FlutterContacts.permissions.request(PermissionType.read);
    return status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  /// Opens the native device contacts list and returns the selected contact's
  /// data as `{name: String, phones: List<String>}`.
  ///
  /// Returns `null` if:
  ///  - Permission denied
  ///  - User cancelled the picker
  ///  - Contact has no name
  static Future<Map<String, dynamic>?> pickContact(BuildContext context) async {
    final granted = await requestPermission(context);
    if (!granted) return null;

    final contact = await FlutterContacts.native.showPicker(
      properties: {ContactProperty.phone},
    );
    if (contact == null) return null;

    final name = (contact.displayName ?? '').trim();
    if (name.isEmpty) return null;

    final phones = contact.phones
        .map((p) => p.number.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    return {'name': name, 'phones': phones};
  }

  /// Detects whether an existing contact in [people] duplicates the given
  /// [phone] or [name].
  ///
  /// Detection priority:
  ///   1. Normalized phone number match (if phone is non-empty)
  ///   2. Case-insensitive trimmed name match
  ///
  /// Returns the matching [Person] or `null` if no duplicate is found.
  static Person? findDuplicate({
    required List<Person> people,
    required String name,
    String? phone,
    String? excludeUuid,
  }) {
    final normalizedInput = PhoneNormalizer.normalize(phone);

    // Pass 1: Phone number match (highest priority)
    if (normalizedInput.isNotEmpty) {
      for (final person in people) {
        if (excludeUuid != null && person.uuid == excludeUuid) continue;
        if (person.phone != null &&
            PhoneNormalizer.normalize(person.phone) == normalizedInput) {
          return person;
        }
      }
    }

    // Pass 2: Exact name match (case-insensitive, trimmed)
    final lowerName = name.trim().toLowerCase();
    if (lowerName.isNotEmpty) {
      for (final person in people) {
        if (excludeUuid != null && person.uuid == excludeUuid) continue;
        if (person.name.trim().toLowerCase() == lowerName) {
          return person;
        }
      }
    }

    return null;
  }

  /// Shows a phone number picker dialog when the selected contact has
  /// multiple phone numbers. Returns the chosen number, or `null` if
  /// the user dismissed the dialog.
  static Future<String?> pickPhoneNumber(
    BuildContext context,
    List<String> phones,
  ) async {
    if (phones.isEmpty) return null;
    if (phones.length == 1) return phones.first;

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Select Phone Number',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This contact has multiple phone numbers. Choose one to import:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...phones.map(
              (phone) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.phone_rounded, size: 18),
                title: Text(phone, style: const TextStyle(fontSize: 14)),
                onTap: () => Navigator.pop(ctx, phone),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  /// Shows the "duplicate contact" dialog and returns the user's choice:
  ///  - `true`  → user chose "Open Existing Contact"
  ///  - `false` → user chose "Cancel Import"
  static Future<bool> showDuplicateDialog(
    BuildContext context,
    Person existingPerson,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        icon: const Icon(
          Icons.person_search_rounded,
          color: Color(0xFFF59E0B),
          size: 40,
        ),
        title: const Text(
          'This contact already exists.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          '"${existingPerson.name}" is already in your contacts list.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel Import'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Open Existing Contact'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

