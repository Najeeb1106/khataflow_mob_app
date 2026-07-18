import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/khata/data/models/khata.dart';
import '../../features/people/data/models/person.dart';
import '../../features/transactions/data/models/transaction.dart';
import '../database/isar_service.dart';

// ---------------------------------------------------------------------------
// Backup format version — increment when the schema changes.
// ---------------------------------------------------------------------------
const int _kBackupVersion = 1;

// ---------------------------------------------------------------------------
// BackupPreview — lightweight summary shown before a restore is confirmed.
// ---------------------------------------------------------------------------
class BackupPreview {
  final int backupVersion;
  final DateTime createdAt;
  final String appVersion;
  final int peopleCount;
  final int khataCount;
  final int transactionCount;
  final DateTime? earliestTransaction;
  final DateTime? latestTransaction;

  /// The full parsed JSON payload — passed to [BackupService.restoreBackup]
  /// so we do not re-parse the file a second time.
  final Map<String, dynamic> rawData;

  const BackupPreview({
    required this.backupVersion,
    required this.createdAt,
    required this.appVersion,
    required this.peopleCount,
    required this.khataCount,
    required this.transactionCount,
    this.earliestTransaction,
    this.latestTransaction,
    required this.rawData,
  });
}

// ---------------------------------------------------------------------------
// BackupService
// ---------------------------------------------------------------------------
class BackupService {
  BackupService._();

  // -------------------------------------------------------------------------
  // Export
  // -------------------------------------------------------------------------

  /// Reads all Isar records and `app_settings.json`, writes a versioned
  /// backup JSON to [getApplicationDocumentsDirectory], then opens the OS
  /// share sheet so the user can save it wherever they want.
  ///
  /// Returns the path of the created backup file, or throws on error.
  static Future<String> exportBackup() async {
    final isar = IsarService.instance;

    // 1. Read all records (including soft-deleted so Trash survives).
    final people = await isar.persons.where().findAll();
    final khatas = await isar.khatas.where().findAll();
    final transactions = await isar.transactions.where().findAll();

    // 2. Read settings file (best-effort — missing file → empty map).
    Map<String, dynamic> settingsJson = {};
    try {
      final dir = await getApplicationDocumentsDirectory();
      final settingsFile = File('${dir.path}/app_settings.json');
      if (await settingsFile.exists()) {
        settingsJson =
            jsonDecode(await settingsFile.readAsString()) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[BackupService] Could not read settings: $e');
    }

    // 3. Read package info for appVersion.
    String appVersion = 'unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    // 4. Build versioned backup envelope.
    final backup = {
      'backupVersion': _kBackupVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': appVersion,
      'data': {
        'settings': _sanitiseSettings(settingsJson),
        'people': people.map(_personToJson).toList(),
        'khatas': khatas.map(_khataToJson).toList(),
        'transactions': transactions.map(_transactionToJson).toList(),
      },
    };

    // 5. Write file.
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .substring(0, 19);
    final filePath = '${dir.path}/khataflow_backup_$timestamp.json';
    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(backup),
    );

    // 6. Share so the user can save it outside the app sandbox.
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/json')],
      subject: 'KhataFlow Backup – $timestamp',
    );

    return filePath;
  }

  // -------------------------------------------------------------------------
  // Parse / Preview (no DB writes)
  // -------------------------------------------------------------------------

  /// Parses a backup file and returns a [BackupPreview] without writing
  /// anything to the database. Throws [FormatException] if the file is
  /// invalid, missing required keys, or has an unsupported version.
  static Future<BackupPreview> parseBackupPreview(File file) async {
    final raw = await file.readAsString();
    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Backup file is not valid JSON: $e');
    }

    // Version gate — we only know how to restore version 1 right now.
    final version = parsed['backupVersion'];
    if (version == null || version is! int) {
      throw const FormatException(
          'Missing or invalid backupVersion field. This may not be a KhataFlow backup.');
    }
    if (version > _kBackupVersion) {
      throw FormatException(
          'Backup version $version is newer than the app supports (max $_kBackupVersion). '
          'Please update the app to restore this backup.');
    }

    // Dates.
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(parsed['createdAt'] as String? ?? '');
    } catch (_) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    final appVersion = parsed['appVersion'] as String? ?? 'unknown';

    final data = parsed['data'] as Map<String, dynamic>? ?? {};
    final peopleList = data['people'] as List<dynamic>? ?? [];
    final khataList = data['khatas'] as List<dynamic>? ?? [];
    final txList = data['transactions'] as List<dynamic>? ?? [];

    // Date range of transactions.
    DateTime? earliest;
    DateTime? latest;
    for (final tx in txList) {
      final txMap = tx as Map<String, dynamic>;
      final dateStr = txMap['transactionDate'] as String? ??
          txMap['createdAt'] as String? ??
          '';
      try {
        final d = DateTime.parse(dateStr);
        if (earliest == null || d.isBefore(earliest)) earliest = d;
        if (latest == null || d.isAfter(latest)) latest = d;
      } catch (_) {}
    }

    return BackupPreview(
      backupVersion: version,
      createdAt: createdAt,
      appVersion: appVersion,
      peopleCount: peopleList.length,
      khataCount: khataList.length,
      transactionCount: txList.length,
      earliestTransaction: earliest,
      latestTransaction: latest,
      rawData: parsed,
    );
  }

  // -------------------------------------------------------------------------
  // Restore (writes to DB)
  // -------------------------------------------------------------------------

  /// Atomically clears all Isar collections and restores data from [preview].
  /// Also overwrites `app_settings.json` with the backed-up settings.
  ///
  /// Throws on any write error — callers should handle and show UI feedback.
  static Future<void> restoreBackup(BackupPreview preview) async {
    final isar = IsarService.instance;
    final data = preview.rawData['data'] as Map<String, dynamic>? ?? {};

    final peopleList = data['people'] as List<dynamic>? ?? [];
    final khataList = data['khatas'] as List<dynamic>? ?? [];
    final txList = data['transactions'] as List<dynamic>? ?? [];

    // Build Isar objects before the write transaction.
    final people = peopleList.map((e) => _personFromJson(e as Map<String, dynamic>)).toList();
    final khatas = khataList.map((e) => _khataFromJson(e as Map<String, dynamic>)).toList();
    final transactions = txList.map((e) => _transactionFromJson(e as Map<String, dynamic>)).toList();

    // Single atomic write: clear → restore.
    await isar.writeTxn(() async {
      await isar.clear();
      if (people.isNotEmpty) await isar.persons.putAll(people);
      if (khatas.isNotEmpty) await isar.khatas.putAll(khatas);
      if (transactions.isNotEmpty) await isar.transactions.putAll(transactions);
    });

    // Restore settings file.
    try {
      final settingsMap = data['settings'] as Map<String, dynamic>?;
      if (settingsMap != null) {
        final dir = await getApplicationDocumentsDirectory();
        final settingsFile = File('${dir.path}/app_settings.json');
        await settingsFile.writeAsString(jsonEncode(settingsMap));
      }
    } catch (e) {
      debugPrint('[BackupService] Could not restore settings file: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Serialisation helpers
  // -------------------------------------------------------------------------

  /// Strips security-sensitive keys that must never leave the device.
  static Map<String, dynamic> _sanitiseSettings(Map<String, dynamic> raw) {
    final copy = Map<String, dynamic>.from(raw);
    // Security credentials — device-specific or secret; never backed up.
    const excludedKeys = [
      'database_encryption_key',
      'hashed_pin',
      'fingerprint_enabled',
      'app_lock_enabled',
      'session_timeout_seconds',
      'recovery_question',
      'hashed_recovery_answer',
      'last_active_timestamp',
      'failed_recovery_attempts',
      'recovery_lockout_until_timestamp',
      'device_unique_id',
    ];
    for (final key in excludedKeys) {
      copy.remove(key);
    }
    return copy;
  }

  static Map<String, dynamic> _personToJson(Person p) => {
        'uuid': p.uuid,
        'name': p.name,
        'phone': p.phone,
        'notes': p.notes,
        'createdAt': p.createdAt.toUtc().toIso8601String(),
        'updatedAt': p.updatedAt.toUtc().toIso8601String(),
        'isDeleted': p.isDeleted,
      };

  static Person _personFromJson(Map<String, dynamic> m) {
    final p = Person()
      ..uuid = m['uuid'] as String
      ..name = m['name'] as String
      ..phone = m['phone'] as String?
      ..notes = m['notes'] as String?
      ..createdAt = _parseDate(m['createdAt'])
      ..updatedAt = _parseDate(m['updatedAt'])
      ..isDeleted = m['isDeleted'] as bool? ?? false;
    return p;
  }

  static Map<String, dynamic> _khataToJson(Khata k) => {
        'uuid': k.uuid,
        'personUuid': k.personUuid,
        'title': k.title,
        'notes': k.notes,
        'createdAt': k.createdAt.toUtc().toIso8601String(),
        'updatedAt': k.updatedAt.toUtc().toIso8601String(),
        'isDeleted': k.isDeleted,
      };

  static Khata _khataFromJson(Map<String, dynamic> m) {
    final k = Khata()
      ..uuid = m['uuid'] as String
      ..personUuid = m['personUuid'] as String
      ..title = m['title'] as String
      ..notes = m['notes'] as String?
      ..createdAt = _parseDate(m['createdAt'])
      ..updatedAt = _parseDate(m['updatedAt'])
      ..isDeleted = m['isDeleted'] as bool? ?? false;
    return k;
  }

  static Map<String, dynamic> _transactionToJson(Transaction t) => {
        'uuid': t.uuid,
        'khataUuid': t.khataUuid,
        'type': t.type.name,
        'amount': t.amount,
        'notes': t.notes,
        'dueDate': t.dueDate?.toUtc().toIso8601String(),
        'reminderDate': t.reminderDate?.toUtc().toIso8601String(),
        'transactionDate': t.transactionDate?.toUtc().toIso8601String(),
        'photoUrl': t.photoUrl,
        'createdAt': t.createdAt.toUtc().toIso8601String(),
        'updatedAt': t.updatedAt.toUtc().toIso8601String(),
        'isDeleted': t.isDeleted,
      };

  static Transaction _transactionFromJson(Map<String, dynamic> m) {
    final t = Transaction()
      ..uuid = m['uuid'] as String
      ..khataUuid = m['khataUuid'] as String
      ..type = TransactionType.values.firstWhere(
        (e) => e.name == (m['type'] as String? ?? 'gave'),
        orElse: () => TransactionType.gave,
      )
      ..amount = (m['amount'] as num).toDouble()
      ..notes = m['notes'] as String?
      ..dueDate = _parseDateOpt(m['dueDate'])
      ..reminderDate = _parseDateOpt(m['reminderDate'])
      ..transactionDate = _parseDateOpt(m['transactionDate'])
      ..photoUrl = m['photoUrl'] as String?
      ..createdAt = _parseDate(m['createdAt'])
      ..updatedAt = _parseDate(m['updatedAt'])
      ..isDeleted = m['isDeleted'] as bool? ?? false;
    return t;
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {}
    }
    return DateTime.now();
  }

  static DateTime? _parseDateOpt(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {}
    }
    return null;
  }
}
