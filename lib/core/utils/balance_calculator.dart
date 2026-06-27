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

  /// Formats a full amount string for display with specified currency.
  /// e.g. "Rs. 5,000"
  static String formatPkr(double amount, [String currency = 'Rs.']) {
    return '$currency ${amount.abs().toStringAsFixed(0)}';
  }
}
