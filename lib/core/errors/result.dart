import 'app_exception.dart';

/// A discriminated union type for operation results.
///
/// Use [Result<T>] as the return type of repository methods and services
/// instead of throwing exceptions. This makes error paths explicit and
/// forces callers to handle both success and failure branches.
///
/// ```dart
/// // Repository usage
/// Future<Result<Person>> getPerson(String uuid) async {
///   try {
///     final p = await _isar.persons.filter().uuidEqualTo(uuid).findFirst();
///     if (p == null) return Failure(NotFoundException('Person not found'));
///     return Success(p);
///   } catch (e) {
///     return Failure(DatabaseException('Failed to load person', cause: e));
///   }
/// }
///
/// // UI usage
/// final result = await repo.getPerson(uuid);
/// switch (result) {
///   case Success(:final data): setState(() => _person = data);
///   case Failure(:final exception): showError(exception.message);
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Represents a successful operation with a [data] payload.
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed operation with a typed [AppException].
final class Failure<T> extends Result<T> {
  final AppException exception;
  const Failure(this.exception);

  @override
  String toString() => 'Failure(${exception.message})';
}

// ─────────────────────────────────────────────────────────────────────────────
// Extension helpers
// ─────────────────────────────────────────────────────────────────────────────

extension ResultExtension<T> on Result<T> {
  /// Returns `true` if this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Returns `true` if this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// Returns the data payload, or `null` if this is a [Failure].
  T? get dataOrNull => switch (this) {
        Success(:final data) => data,
        Failure() => null,
      };

  /// Returns the exception, or `null` if this is a [Success].
  AppException? get exceptionOrNull => switch (this) {
        Success() => null,
        Failure(:final exception) => exception,
      };

  /// Maps the success value, leaving failures unchanged.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
        Success(:final data) => Success(transform(data)),
        Failure(:final exception) => Failure(exception),
      };

  /// Runs [onSuccess] or [onFailure] depending on this result.
  void fold({
    required void Function(T data) onSuccess,
    required void Function(AppException exception) onFailure,
  }) {
    switch (this) {
      case Success(:final data):
        onSuccess(data);
      case Failure(:final exception):
        onFailure(exception);
    }
  }
}
