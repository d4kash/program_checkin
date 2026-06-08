import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/features/program/data/program_repository.dart';
import 'package:health_checkin/features/program/domain/models.dart';

enum DashboardStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
  retryableFailure,
}

class DashboardState extends Equatable {
  const DashboardState({required this.status, this.snapshot, this.failure});

  const DashboardState.initial() : this(status: DashboardStatus.initial);

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final AppFailure? failure;

  bool get hasUsableData => snapshot != null;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSnapshot? snapshot,
    AppFailure? failure,
    bool clearFailure = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [status, snapshot, failure];
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({required this.repository, required this.observability})
    : super(const DashboardState.initial());

  final ProgramRepository repository;
  final InMemoryObservability observability;

  int _loadGeneration = 0;

  Future<void> load() async {
    final generation = ++_loadGeneration;
    final correlationId = observability.newCorrelationId();
    observability.breadcrumb(
      'dashboard.load.started',
      attributes: {'route_name': 'dashboard', 'correlation_id': correlationId},
    );
    final span = observability.startSpan(
      'dashboard.load',
      correlationId: correlationId,
      attributes: const {'route_name': 'dashboard'},
    );
    if (!state.hasUsableData) {
      emit(state.copyWith(status: DashboardStatus.loading, clearFailure: true));
    }
    final result = await repository.loadDashboard(
      correlationId: correlationId,
      parentSpanId: span.id,
    );
    if (generation != _loadGeneration) return;
    if (result is AppSuccess<DashboardSnapshot?>) {
      final snapshot = result.value;
      if (snapshot == null) {
        observability.finishSpan(
          span,
          status: SpanStatus.ok,
          attributes: const {'status_class': 'empty'},
        );
        emit(const DashboardState(status: DashboardStatus.empty));
      } else {
        observability.log(
          'dashboard_loaded',
          attributes: {
            'route_name': 'dashboard',
            'status_class': '2xx',
            'region': snapshot.user.region,
            'task_status': snapshot.program.taskStatus.name,
            'correlation_id': correlationId,
          },
        );
        observability.finishSpan(
          span,
          status: SpanStatus.ok,
          attributes: const {'status_class': '2xx'},
        );
        emit(
          DashboardState(status: DashboardStatus.loaded, snapshot: snapshot),
        );
      }
    } else if (result is AppFailureResult<DashboardSnapshot?>) {
      final failure = result.failure;
      observability.expectedError(
        'dashboard_load_failed',
        correlationId: correlationId,
        attributes: {
          'failure_code': failure.code.name,
          'retryable': failure.retryable,
          'status_class': failure.statusClass,
        },
      );
      observability.finishSpan(
        span,
        status: SpanStatus.error,
        attributes: {
          'failure_code': failure.code.name,
          'retryable': failure.retryable,
          'status_class': failure.statusClass,
        },
      );
      emit(
        DashboardState(
          status: state.hasUsableData
              ? DashboardStatus.retryableFailure
              : DashboardStatus.error,
          snapshot: state.snapshot,
          failure: failure,
        ),
      );
    }
  }
}
