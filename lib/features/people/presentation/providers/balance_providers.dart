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
final personBalanceProvider = FutureProvider.family<double, String>((
  ref,
  personUuid,
) async {
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
final khataBalanceProvider = FutureProvider.family<double, String>((
  ref,
  khataUuid,
) async {
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

/// Provides the earliest upcoming due date for a single PERSON across all active balances in all their khatas.
final personNextDueProvider = FutureProvider.family<DateTime?, String>((
  ref,
  personUuid,
) async {
  final khataRepo = ref.watch(khataRepositoryProvider);
  final khatas = await khataRepo.getKhatasForPerson(personUuid);

  DateTime? nextDue;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  for (final khata in khatas) {
    final txsAsync = ref.watch(transactionsForKhataProvider(khata.uuid));
    List<Transaction> txs;
    if (txsAsync is AsyncData<List<Transaction>>) {
      txs = txsAsync.value;
    } else {
      final txRepo = ref.read(transactionRepositoryProvider);
      txs = await txRepo.getTransactionsForKhata(khata.uuid);
    }

    final khataBalance = BalanceCalculator.calculate(txs);

    for (final tx in txs) {
      if (tx.dueDate == null) continue;
      // Skip settled transactions
      if (tx.type == TransactionType.received ||
          tx.type == TransactionType.paid)
        continue;

      final isReceivable = tx.type == TransactionType.gave || 
          (tx.type == TransactionType.adjustment && tx.amount >= 0);
      final isPayable = tx.type == TransactionType.borrowed || 
          (tx.type == TransactionType.adjustment && tx.amount < 0);
      if ((isReceivable && khataBalance <= 0) || (isPayable && khataBalance >= 0)) {
        continue;
      }

      final due = DateTime(
        tx.dueDate!.year,
        tx.dueDate!.month,
        tx.dueDate!.day,
      );
      if (due.isAfter(today) || due.isAtSameMomentAs(today)) {
        if (nextDue == null || due.isBefore(nextDue)) {
          nextDue = due;
        }
      }
    }
  }

  return nextDue;
});

/// Aggregate financial summary details for a single contact.
class PersonFinancialSummary {
  final double totalGiven;
  final double totalReceived;
  final double totalBorrowed;
  final double totalPaid;
  final double outstandingReceivable;
  final double outstandingPayable;
  final double netBalance;
  final DateTime? nextDueDate;
  final int transactionCount;

  const PersonFinancialSummary({
    required this.totalGiven,
    required this.totalReceived,
    required this.totalBorrowed,
    required this.totalPaid,
    required this.outstandingReceivable,
    required this.outstandingPayable,
    required this.netBalance,
    required this.transactionCount,
    this.nextDueDate,
  });
}

/// Provides a complete financial summary details for a single PERSON across all khatas.
final personFinancialSummaryProvider =
    FutureProvider.family<PersonFinancialSummary, String>((
      ref,
      personUuid,
    ) async {
      final khataRepo = ref.watch(khataRepositoryProvider);
      final khatas = await khataRepo.getKhatasForPerson(personUuid);

      double totalGiven = 0.0;
      double totalReceived = 0.0;
      double totalBorrowed = 0.0;
      double totalPaid = 0.0;
      double outstandingReceivable = 0.0;
      double outstandingPayable = 0.0;
      double netBalance = 0.0;
      int transactionCount = 0;

      DateTime? nextDue;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final khata in khatas) {
        final txsAsync = ref.watch(transactionsForKhataProvider(khata.uuid));
        List<Transaction> txs;
        if (txsAsync is AsyncData<List<Transaction>>) {
          txs = txsAsync.value;
        } else {
          final txRepo = ref.read(transactionRepositoryProvider);
          txs = await txRepo.getTransactionsForKhata(khata.uuid);
        }
        transactionCount += txs.length;

        final khataBalance = BalanceCalculator.calculate(txs);
        if (khataBalance > 0) {
          outstandingReceivable += khataBalance;
        } else if (khataBalance < 0) {
          outstandingPayable += khataBalance.abs();
        }
        netBalance += khataBalance;

        for (final tx in txs) {
          switch (tx.type) {
            case TransactionType.gave:
              totalGiven += tx.amount;
              break;
            case TransactionType.received:
              totalReceived += tx.amount;
              break;
            case TransactionType.borrowed:
              totalBorrowed += tx.amount;
              break;
            case TransactionType.paid:
              totalPaid += tx.amount;
              break;
            case TransactionType.adjustment:
              if (tx.amount >= 0) {
                totalGiven += tx.amount;
              } else {
                totalReceived += tx.amount.abs();
              }
              break;
          }

          if (tx.dueDate != null &&
              tx.type != TransactionType.received &&
              tx.type != TransactionType.paid) {
            final isReceivable = tx.type == TransactionType.gave || 
                (tx.type == TransactionType.adjustment && tx.amount >= 0);
            final isPayable = tx.type == TransactionType.borrowed || 
                (tx.type == TransactionType.adjustment && tx.amount < 0);
            if ((isReceivable && khataBalance <= 0) || (isPayable && khataBalance >= 0)) {
              continue;
            }

            final due = DateTime(
              tx.dueDate!.year,
              tx.dueDate!.month,
              tx.dueDate!.day,
            );
            if (due.isAfter(today) || due.isAtSameMomentAs(today)) {
              if (nextDue == null || due.isBefore(nextDue)) {
                nextDue = due;
              }
            }
          }
        }
      }

      return PersonFinancialSummary(
        totalGiven: totalGiven,
        totalReceived: totalReceived,
        totalBorrowed: totalBorrowed,
        totalPaid: totalPaid,
        outstandingReceivable: outstandingReceivable,
        outstandingPayable: outstandingPayable,
        netBalance: netBalance,
        transactionCount: transactionCount,
        nextDueDate: nextDue,
      );
    });
