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
final dashboardSummaryProvider = FutureProvider<DashboardSummary>((ref) async {
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

/// Provides list of transactions grouped by due date status for dashboard widgets.
final dashboardDueStatsProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
      final peopleRepo = ref.watch(personRepositoryProvider);
      final khataRepo = ref.watch(khataRepositoryProvider);
      final txRepo = ref.watch(transactionRepositoryProvider);

      final people = await peopleRepo.getPeople();

      final List<Map<String, dynamic>> overdue = [];
      final List<Map<String, dynamic>> dueToday = [];
      final List<Map<String, dynamic>> dueTomorrow = [];
      final List<Map<String, dynamic>> upcoming = [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      for (final person in people) {
        final khatas = await khataRepo.getKhatasForPerson(person.uuid);
        for (final khata in khatas) {
          final txs = await txRepo.getTransactionsForKhata(khata.uuid);
          final netBalance = BalanceCalculator.calculate(txs);
          if (netBalance == 0) continue; // Skip settled Khatas

          for (final tx in txs) {
            if (tx.dueDate == null) continue;
            // Skip settled/repaid transactions
            if (tx.type == TransactionType.received ||
                tx.type == TransactionType.paid)
              continue;

            final due = DateTime(
              tx.dueDate!.year,
              tx.dueDate!.month,
              tx.dueDate!.day,
            );
            final txInfo = {
              'transaction': tx,
              'personName': person.name,
              'khataTitle': khata.title,
            };

            if (due.isBefore(today)) {
              overdue.add(txInfo);
            } else if (due.isAtSameMomentAs(today)) {
              dueToday.add(txInfo);
            } else if (due.isAtSameMomentAs(tomorrow)) {
              dueTomorrow.add(txInfo);
            } else {
              upcoming.add(txInfo);
            }
          }
        }
      }

      return {
        'overdue': overdue,
        'dueToday': dueToday,
        'dueTomorrow': dueTomorrow,
        'upcoming': upcoming,
      };
    });

/// Represents aggregated net cashflow data for a given month.
class MonthlyInsight {
  final String monthLabel;
  final double netCashflow;
  final double cashIn; // received + paid
  final double cashOut; // gave + borrowed

  const MonthlyInsight({
    required this.monthLabel,
    required this.netCashflow,
    required this.cashIn,
    required this.cashOut,
  });
}

/// Provides monthly net cashflow metrics for the last 4 months.
final dashboardMonthlyInsightsProvider = FutureProvider<List<MonthlyInsight>>((
  ref,
) async {
  final peopleRepo = ref.watch(personRepositoryProvider);
  final khataRepo = ref.watch(khataRepositoryProvider);
  final txRepo = ref.watch(transactionRepositoryProvider);

  final people = await peopleRepo.getPeople();
  final List<Transaction> allTxs = [];

  for (final person in people) {
    final khatas = await khataRepo.getKhatasForPerson(person.uuid);
    for (final khata in khatas) {
      final txs = await txRepo.getTransactionsForKhata(khata.uuid);
      allTxs.addAll(txs);
    }
  }

  final Map<String, List<Transaction>> grouped = {};
  final months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  for (final tx in allTxs) {
    final date = tx.transactionDate ?? tx.createdAt;
    final key = '${months[date.month - 1]} ${date.year}';
    grouped.putIfAbsent(key, () => []).add(tx);
  }

  final now = DateTime.now();
  final List<MonthlyInsight> insights = [];

  for (int i = 0; i < 4; i++) {
    final targetMonth = DateTime(now.year, now.month - i, 1);
    final key = '${months[targetMonth.month - 1]} ${targetMonth.year}';
    final txs = grouped[key] ?? [];

    double cashIn = 0.0;
    double cashOut = 0.0;

    for (final tx in txs) {
      if (tx.type == TransactionType.received ||
          tx.type == TransactionType.paid) {
        cashIn += tx.amount;
      } else if (tx.type == TransactionType.gave ||
          tx.type == TransactionType.borrowed) {
        cashOut += tx.amount;
      }
    }

    insights.add(
      MonthlyInsight(
        monthLabel: key,
        netCashflow: cashIn - cashOut,
        cashIn: cashIn,
        cashOut: cashOut,
      ),
    );
  }

  return insights;
});
