/// Standardized exception hierarchy for KhataFlow.
///
/// All thrown errors in repositories, services, and providers MUST use one of
/// these typed exceptions rather than generic [Exception] or raw strings.
/// This enables type-safe error handling in the UI layer.
library;

// ─────────────────────────────────────────────────────────────────────────────
// Base
// ─────────────────────────────────────────────────────────────────────────────

/// Base class for all application-level exceptions.
sealed class AppException implements Exception {
  /// Human-readable error message (suitable for display in a SnackBar/dialog).
  final String message;

  /// Optional machine-readable error code for logging and analytics.
  final String? code;

  /// The original exception/error that caused this, if any.
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() =>
      'AppException[$code]: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Concrete Subtypes
// ─────────────────────────────────────────────────────────────────────────────

/// Thrown when a local Isar database operation fails.
final class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.cause});
}

/// Thrown when Firestore sync operations fail.
final class SyncException extends AppException {
  const SyncException(super.message, {super.code, super.cause});
}

/// Thrown when a network request fails or device is offline.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

/// Thrown when user-supplied data fails business-rule validation.
final class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.cause});
}

/// Thrown when a required entity is not found in the database.
final class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.cause});
}

/// Thrown when a user attempts an operation they are not authorized to perform.
final class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

/// Thrown when PDF generation or file export fails.
final class ExportException extends AppException {
  const ExportException(super.message, {super.code, super.cause});
}
