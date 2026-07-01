import 'package:isar/isar.dart';
import '../../../../core/database/isar_service.dart';
import '../models/transaction.dart';

abstract class TransactionRepository {
  Future<List<Transaction>> getTransactions({bool includeDeleted = false});
  Future<List<Transaction>> getTransactionsForKhata(
    String khataUuid, {
    bool includeDeleted = false,
  });
  Future<Transaction?> getTransaction(String uuid);
  Future<void> saveTransaction(Transaction transaction);
  Future<void> deleteTransaction(String uuid);
  Future<void> permanentlyDeleteTransaction(String uuid);
}

class LocalTransactionRepository implements TransactionRepository {
  final Isar isar = IsarService.instance;

  @override
  Future<List<Transaction>> getTransactions({
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) {
      return isar.transactions.where().findAll();
    } else {
      return isar.transactions.filter().isDeletedEqualTo(false).findAll();
    }
  }

  @override
  Future<List<Transaction>> getTransactionsForKhata(
    String khataUuid, {
    bool includeDeleted = false,
  }) async {
    if (includeDeleted) {
      return isar.transactions.filter().khataUuidEqualTo(khataUuid).findAll();
    } else {
      return isar.transactions
          .filter()
          .khataUuidEqualTo(khataUuid)
          .isDeletedEqualTo(false)
          .findAll();
    }
  }

  @override
  Future<Transaction?> getTransaction(String uuid) async {
    return isar.transactions.filter().uuidEqualTo(uuid).findFirst();
  }

  @override
  Future<void> saveTransaction(Transaction transaction) async {
    transaction.updatedAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.transactions.put(transaction);
    });
  }

  @override
  Future<void> deleteTransaction(String uuid) async {
    final transaction = await getTransaction(uuid);
    if (transaction != null) {
      transaction.isDeleted = true;
      transaction.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.transactions.put(transaction);
      });
    }
  }

  @override
  Future<void> permanentlyDeleteTransaction(String uuid) async {
    final transaction = await getTransaction(uuid);
    if (transaction != null) {
      await isar.writeTxn(() async {
        await isar.transactions.delete(transaction.id);
      });
    }
  }
}
