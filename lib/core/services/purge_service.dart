import 'package:flutter/foundation.dart';
import '../database/isar_service.dart';
import '../../features/people/data/models/person.dart';
import '../../features/khata/data/models/khata.dart';
import '../../features/transactions/data/models/transaction.dart';
import 'package:isar/isar.dart';

class PurgeService {
  static final PurgeService _instance = PurgeService._internal();
  factory PurgeService() => _instance;
  PurgeService._internal();

  final Isar _isar = IsarService.instance;

  Future<void> runAutoPurge() async {
    debugPrint("Database Maintenance: Running 30-day auto-purge...");
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));

    try {
      await _isar.writeTxn(() async {
        // 1. Purge Persons
        final oldPeople = await _isar.persons
            .filter()
            .isDeletedEqualTo(true)
            .updatedAtLessThan(cutoffDate)
            .findAll();
        for (final p in oldPeople) {
          await _isar.persons.delete(p.id);
        }

        // 2. Purge Khatas
        final oldKhatas = await _isar.khatas
            .filter()
            .isDeletedEqualTo(true)
            .updatedAtLessThan(cutoffDate)
            .findAll();
        for (final k in oldKhatas) {
          await _isar.khatas.delete(k.id);
        }

        // 3. Purge Transactions
        final oldTxs = await _isar.transactions
            .filter()
            .isDeletedEqualTo(true)
            .updatedAtLessThan(cutoffDate)
            .findAll();
        for (final tx in oldTxs) {
          await _isar.transactions.delete(tx.id);
        }
      });
      debugPrint("Database Maintenance: Auto-purge completed successfully.");
    } catch (e) {
      debugPrint("Database Maintenance: Auto-purge encountered error: $e");
    }
  }
}
