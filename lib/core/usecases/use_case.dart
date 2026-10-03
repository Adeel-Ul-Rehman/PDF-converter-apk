// ignore_for_file: one_member_abstracts
import 'package:flux_convert/core/error/failures.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// UseCase — Base Interfaces for Domain Use Cases
///
/// All use cases must implement [UseCase] or [NoParamsUseCase]. Each use case
/// represents exactly one business operation and communicates failure through
/// a typed [Failure] returned in a [Result].
/// ─────────────────────────────────────────────────────────────────────────────
abstract interface class UseCase<ReturnType, Params> {
  Future<Result<ReturnType>> call(Params params);
}

/// A use case that takes no parameters.
abstract interface class NoParamsUseCase<ReturnType> {
  Future<Result<ReturnType>> call();
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Result — Lightweight Success / Failure Wrapper
///
/// A minimal discriminated union to avoid adding functional programming packages.
/// ─────────────────────────────────────────────────────────────────────────────
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  /// Returns the success value, or throws if this is a [FailureResult].
  T get value => (this as Success<T>).data;

  /// Returns the failure, or throws if this is a [Success].
  Failure get failure => (this as FailureResult<T>).failure;
}

/// Represents a successful operation with data of type [T].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;
}

/// Represents a failed operation with a typed [Failure].
final class FailureResult<T> extends Result<T> {
  const FailureResult(this.failure);

  @override
  final Failure failure;
}
