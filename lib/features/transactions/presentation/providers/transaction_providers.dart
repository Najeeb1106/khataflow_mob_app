import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../people/presentation/providers/balance_providers.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return LocalTransactionRepository();
});

class TransactionListNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  final String _khataUuid;
  final Ref _ref;

  TransactionListNotifier(this._repository, this._khataUuid, this._ref)
    : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = await _repository.getTransactionsForKhata(
        _khataUuid,
      );
      // Sort by date descending
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(transactions);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> _invalidateAll() async {
    Future.microtask(() async {
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(dashboardRecentTransactionsProvider);
      _ref.invalidate(dashboardDueStatsProvider);

      _ref.invalidate(khataBalanceProvider(_khataUuid));

      final khataRepo = _ref.read(khataRepositoryProvider);
      final khata = await khataRepo.getKhata(_khataUuid);
      if (khata != null) {
        final personUuid = khata.personUuid;
        _ref.invalidate(personBalanceProvider(personUuid));
        _ref.invalidate(personFinancialSummaryProvider(personUuid));
        _ref.invalidate(personNextDueProvider(personUuid));
        _ref.invalidate(peopleListProvider);
      }
    });
  }

  Future<void> addTransaction(Transaction transaction) async {
    try {
      await _repository.saveTransaction(transaction);
      await loadTransactions();
      await _invalidateAll();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await _repository.saveTransaction(transaction);
      await loadTransactions();
      await _invalidateAll();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteTransaction(String uuid) async {
    try {
      await _repository.deleteTransaction(uuid);
      await loadTransactions();
      await _invalidateAll();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final transactionsForKhataProvider =
    StateNotifierProvider.family<
      TransactionListNotifier,
      AsyncValue<List<Transaction>>,
      String
    >((ref, khataUuid) {
      final repository = ref.watch(transactionRepositoryProvider);
      return TransactionListNotifier(repository, khataUuid, ref);
    });
