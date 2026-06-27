import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return LocalTransactionRepository();
});

class TransactionListNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  final String _khataUuid;
  final Ref _ref;

  TransactionListNotifier(this._repository, this._khataUuid, this._ref) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = await _repository.getTransactionsForKhata(_khataUuid);
      // Sort by date descending
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(transactions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _invalidateDashboard() async {
    _ref.invalidate(dashboardSummaryProvider);
    _ref.invalidate(dashboardRecentTransactionsProvider);
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _repository.saveTransaction(transaction);
      await loadTransactions();
      await _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _repository.saveTransaction(transaction);
      await loadTransactions();
      await _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteTransaction(String uuid) async {
    try {
      await _repository.deleteTransaction(uuid);
      await loadTransactions();
      await _invalidateDashboard();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final transactionsForKhataProvider = StateNotifierProvider.family<TransactionListNotifier, AsyncValue<List<Transaction>>, String>((ref, khataUuid) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionListNotifier(repository, khataUuid, ref);
});
