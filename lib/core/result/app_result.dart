import 'package:equatable/equatable.dart';

enum FailureCode {
  timeout,
  offline,
  malformedJson,
  unauthorized,
  rateLimited,
  validation,
  notFound,
  unknown,
}

class AppFailure extends Equatable {
  const AppFailure({
    required this.code,
    required this.safeMessage,
    required this.retryable,
    this.statusClass = 'unknown',
  });

  final FailureCode code;
  final String safeMessage;
  final bool retryable;
  final String statusClass;

  bool get isUnauthorized => code == FailureCode.unauthorized;

  @override
  List<Object?> get props => [code, safeMessage, retryable, statusClass];
}

sealed class AppResult<T> extends Equatable {
  const AppResult();

  bool get isSuccess => this is AppSuccess<T>;
  bool get isFailure => this is AppFailureResult<T>;

  R when<R>({
    required R Function(T value) success,
    required R Function(AppFailure failure) failure,
  }) {
    final current = this;
    if (current is AppSuccess<T>) {
      return success(current.value);
    }
    return failure((current as AppFailureResult<T>).failure);
  }
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class AppFailureResult<T> extends AppResult<T> {
  const AppFailureResult(this.failure);

  final AppFailure failure;

  @override
  List<Object?> get props => [failure];
}
