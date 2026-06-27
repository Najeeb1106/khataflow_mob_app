import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../people/presentation/providers/people_providers.dart';
import '../../../khata/presentation/providers/khata_providers.dart';
import '../../../transactions/presentation/providers/transaction_providers.dart';
import '../../../transactions/data/models/transaction.dart';
import '../../../../core/utils/balance_calculator.dart';

/// Aggregated financial summary for the Dashboard screen.
class DashboardSummary {
  final double totalReceivable;
  final double totalPayable;
  final double netPosition;

  const DashboardSummary({
    required this.totalReceivable,
    required this.totalPayable,
    required this.netPosition,
  });
}

/// Computes receivable / payable totals across ALL contacts and khatas.
///
/// Uses [BalanceCalculator.calculate] as the single source of truth
/// for balance math — no more duplicated inline loops.
final dashboardSummaryProvider =
    FutureProvider<DashboardSummary>((ref) async {
  final peopleRepo = ref.watch(personRepositoryProvider);
  final khataRepo = ref.watch(khataRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  final people = await peopleRepo.getPeople();
  double totalReceivable = 0.0;
  double totalPayable = 0.0;

  for (final person in people) {
    final khatas = await khataRepo.getKhatasForPerson(person.uuid);
    for (final khata in khatas) {
      final txs = await txRepo.getTransactionsForKhata(khata.uuid);

      // ── Single call to centralized calculator ─────────────────────
      final balance = BalanceCalculator.calculate(txs);

      if (balance > 0) {
        totalReceivable += balance;
      } else if (balance < 0) {
        totalPayable += balance.abs();
      }
    }
  }

  return DashboardSummary(
    totalReceivable: totalReceivable,
    totalPayable: totalPayable,
    netPosition: totalReceivable - totalPayable,
  );
});

/// Loads the 5 most recent transactions across all people/khatas
/// for display in the Dashboard's "Recent Activity" section.
final dashboardRecentTransactionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final peopleRepo = ref.watch(personRepositoryProvider);
  final khataRepo = ref.watch(khataRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  final people = await peopleRepo.getPeople();
  final List<Map<String, dynamic>> allTxs = [];

  for (final person in people) {
    final khatas = await khataRepo.getKhatasForPerson(person.uuid);
    for (final khata in khatas) {
      final txs = await txRepo.getTransactionsForKhata(khata.uuid);
      for (final tx in txs) {
        allTxs.add({
          'transaction': tx,
          'personName': person.name,
          'khataTitle': khata.title,
        });
      }
    }
  }

  // Sort by createdAt descending
  allTxs.sort((a, b) {
    final txA = a['transaction'] as Transaction;
    final txB = b['transaction'] as Transaction;
    return txB.createdAt.compareTo(txA.createdAt);
  });

  // Return last 5 entries
  return allTxs.take(5).toList();
});
