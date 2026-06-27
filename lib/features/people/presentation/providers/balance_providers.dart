import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../../core/utils/balance_calculator.dart';

import '../../../transactions/data/models/transaction.dart';

/// Provides the net balance for a single PERSON across all their khatas.
///
/// Returns an [AsyncValue<double>] where:
///   positive  → person owes YOU  (receivable)
///   negative  → YOU owe person  (payable)
///   zero      → settled
///
/// This replaces every inline FutureBuilder that computed per-person balance.
/// The provider is keyed by [personUuid] so Riverpod caches it per person.
final personBalanceProvider =
    FutureProvider.family<double, String>((ref, personUuid) async {
  final khataRepo = ref.watch(khataRepositoryProvider);
  final khatas = await khataRepo.getKhatasForPerson(personUuid);

  double totalBalance = 0.0;
  for (final khata in khatas) {
    final txsAsync = ref.watch(transactionsForKhataProvider(khata.uuid));
    List<Transaction> txs;
    if (txsAsync is AsyncData<List<Transaction>>) {
      txs = txsAsync.value;
    } else {
      final txRepo = ref.read(transactionRepositoryProvider);
      txs = await txRepo.getTransactionsForKhata(khata.uuid);
    }
    totalBalance += BalanceCalculator.calculate(txs);
  }

  return totalBalance;
});

/// Provides the net balance for a single KHATA from its transactions.
///
/// This replaces every inline FutureBuilder that computed per-khata balance
/// inside ListView.builder rows in [PersonDetailScreen].
final khataBalanceProvider =
    FutureProvider.family<double, String>((ref, khataUuid) async {
  final txsAsync = ref.watch(transactionsForKhataProvider(khataUuid));
  List<Transaction> txs;
  if (txsAsync is AsyncData<List<Transaction>>) {
    txs = txsAsync.value;
  } else {
    final txRepo = ref.read(transactionRepositoryProvider);
    txs = await txRepo.getTransactionsForKhata(khataUuid);
  }
  return BalanceCalculator.calculate(txs);
});
