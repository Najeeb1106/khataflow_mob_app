import '../../features/transactions/data/models/transaction.dart';

/// Centralized, single-source-of-truth balance calculator for KhataFlow.
///
/// All balance math MUST go through this class. Do NOT compute balances
/// inline in widgets, build methods, or provider lambdas.
///
/// Sign convention:
///   positive  → money is OWED TO YOU   (receivable / "they owe you")
///   negative  → money YOU OWE TO THEM  (payable    / "you owe them")
///   zero      → settled
class BalanceCalculator {
  const BalanceCalculator._();

  // ──────────────────────────────────────────────────────────────────────
  // Core calculation
  // ──────────────────────────────────────────────────────────────────────

  /// Calculates net balance from a list of [Transaction] objects.
  ///
  /// - [TransactionType.gave]       → +amount  (you lent money)
  /// - [TransactionType.paid]       → +amount  (they repaid you, i.e. debt reduced on their side)
  /// - [TransactionType.adjustment] → +amount  (positive correction)
  /// - [TransactionType.received]   → -amount  (you received payment from them, reducing receivable)
  /// - [TransactionType.borrowed]   → -amount  (you borrowed, increasing payable)
  static double calculate(List<Transaction> transactions) {
    double balance = 0.0;
    for (final tx in transactions) {
      switch (tx.type) {
        case TransactionType.gave:
        case TransactionType.paid:
        case TransactionType.adjustment:
          balance += tx.amount;
        case TransactionType.received:
        case TransactionType.borrowed:
          balance -= tx.amount;
      }
    }
    return balance;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Label helpers (UI display)
  // ──────────────────────────────────────────────────────────────────────

  /// Returns a human-readable status label for a person's net balance.
  /// Used in headers and balance summary cards.
  static String getStatusLabel(double balance) {
    if (balance > 0) return 'They owe you';
    if (balance < 0) return 'You owe them';
    return 'Settled';
  }

  /// Returns a compact prefix string for list tiles.
  /// e.g. "Owes you Rs. " | "You owe Rs. " | "Settled"
  static String getListPrefix(double balance, [String currency = 'Rs.']) {
    if (balance > 0) return 'Owes you $currency ';
    if (balance < 0) return 'You owe $currency ';
    return 'Settled';
  }

  /// Returns the ledger card label for a khata balance.
  /// e.g. "Outstanding Receivable" | "Outstanding Payable" | "Settled"
  static String getLedgerLabel(double balance) {
    if (balance > 0) return 'Outstanding Receivable';
    if (balance < 0) return 'Outstanding Payable';
    return 'Settled';
  }

  /// Returns the display amount string without the prefix symbol.
  /// Returns empty string when balance is zero (Settled).
  static String getDisplayAmount(double balance) {
    if (balance == 0.0) return '';
    return balance.abs().toStringAsFixed(0);
  }

  static String formatPkr(double amount, [String currency = 'Rs.']) {
    final displayCurrency = (currency == 'PKR' || currency == 'Rs.') ? 'Rs.' : currency;
    final value = amount.abs().toStringAsFixed(0);
    if (value.length <= 3) {
      return '$displayCurrency $value';
    }
    final lastThree = value.substring(value.length - 3);
    final rest = value.substring(0, value.length - 3);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = rest.length - 1; i >= 0; i--) {
      buffer.write(rest[i]);
      count++;
      if (count == 2 && i > 0) {
        buffer.write(',');
        count = 0;
      }
    }
    final restFormatted = buffer.toString().split('').reversed.join('');
    final sign = amount < 0 ? '-' : '';
    return '$sign$displayCurrency $restFormatted,$lastThree';
  }

  /// Calculates the due status of a transaction.
  static String getDueStatus(Transaction tx, double khataBalance) {
    if (tx.type == TransactionType.received ||
        tx.type == TransactionType.paid) {
      return '✅ Settled';
    }

    final isReceivable = tx.type == TransactionType.gave || 
        (tx.type == TransactionType.adjustment && tx.amount >= 0);
    final isPayable = tx.type == TransactionType.borrowed || 
        (tx.type == TransactionType.adjustment && tx.amount < 0);
        
    if ((isReceivable && khataBalance <= 0) || (isPayable && khataBalance >= 0)) {
      return '✅ Settled';
    }

    if (tx.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(tx.dueDate!.year, tx.dueDate!.month, tx.dueDate!.day);

    if (due.isBefore(today)) {
      final diff = today.difference(due).inDays;
      return '⚠️ Overdue by $diff day${diff > 1 ? "s" : ""}';
    } else if (due.isAtSameMomentAs(today)) {
      return '🟡 Due Today';
    } else if (due.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return '🔔 Due Tomorrow';
    }
    return '';
  }

  /// Returns the details for a priority status badge.
  static Map<String, dynamic> getDueBadgeDetails(Transaction tx, double khataBalance) {
    if (tx.type == TransactionType.received ||
        tx.type == TransactionType.paid) {
      return {'label': '✅ Settled', 'color': 'green'};
    }

    final isReceivable = tx.type == TransactionType.gave || 
        (tx.type == TransactionType.adjustment && tx.amount >= 0);
    final isPayable = tx.type == TransactionType.borrowed || 
        (tx.type == TransactionType.adjustment && tx.amount < 0);
        
    if ((isReceivable && khataBalance <= 0) || (isPayable && khataBalance >= 0)) {
      return {'label': '✅ Settled', 'color': 'green'};
    }

    if (tx.dueDate == null) {
      return {'label': '⚪ No Due Date', 'color': 'grey'};
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(tx.dueDate!.year, tx.dueDate!.month, tx.dueDate!.day);

    if (due.isBefore(today)) {
      final diff = today.difference(due).inDays;
      return {
        'label': '🔴 Overdue by $diff day${diff > 1 ? "s" : ""}',
        'color': 'red',
      };
    } else if (due.isAtSameMomentAs(today)) {
      return {'label': '🟡 Due Today', 'color': 'orange'};
    } else if (due.isAtSameMomentAs(today.add(const Duration(days: 1)))) {
      return {'label': '🟢 Due Tomorrow', 'color': 'green'};
    } else {
      return {'label': '🔵 Upcoming', 'color': 'blue'};
    }
  }
}
