import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/features/session/data/session_repository.dart';
import 'package:health_checkin/features/session/domain/session_models.dart';

enum SessionStatus { loading, authenticated, refreshing, unauthenticated }

class SessionState extends Equatable {
  const SessionState({required this.status, this.expiresAt});

  const SessionState.loading() : this(status: SessionStatus.loading);
  const SessionState.unauthenticated()
    : this(status: SessionStatus.unauthenticated);
  const SessionState.authenticated(DateTime expiresAt)
    : this(status: SessionStatus.authenticated, expiresAt: expiresAt);
  const SessionState.refreshing(DateTime? expiresAt)
    : this(status: SessionStatus.refreshing, expiresAt: expiresAt);

  final SessionStatus status;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [status, expiresAt];
}

class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._repository) : super(const SessionState.loading());

  final SessionRepository _repository;

  Future<void> restore() async {
    final tokens = await _repository.restore();
    if (tokens == null) {
      emit(const SessionState.unauthenticated());
    } else {
      emit(SessionState.authenticated(tokens.expiresAt));
    }
  }

  Future<void> refresh(String correlationId) async {
    emit(SessionState.refreshing(state.expiresAt));
    final result = await _repository.refresh(correlationId: correlationId);
    if (result is AppSuccess<SessionTokens>) {
      emit(SessionState.authenticated(result.value.expiresAt));
    } else {
      emit(const SessionState.unauthenticated());
    }
  }

  Future<void> clear() async {
    await _repository.clear();
    emit(const SessionState.unauthenticated());
  }
}
