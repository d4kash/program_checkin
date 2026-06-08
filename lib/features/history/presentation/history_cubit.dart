import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/features/program/data/program_repository.dart';
import 'package:health_checkin/features/program/domain/models.dart';

enum HistoryStatus { initial, loading, loaded, empty, error }

class HistoryState extends Equatable {
  const HistoryState({
    required this.status,
    this.entries = const [],
    this.failure,
  });

  const HistoryState.initial() : this(status: HistoryStatus.initial);

  final HistoryStatus status;
  final List<CheckInEntry> entries;
  final AppFailure? failure;

  @override
  List<Object?> get props => [status, entries, failure];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required this.repository, required this.observability})
    : super(const HistoryState.initial());

  final ProgramRepository repository;
  final InMemoryObservability observability;

  Future<void> load() async {
    final correlationId = observability.newCorrelationId();
    final span = observability.startSpan(
      'history.refresh',
      correlationId: correlationId,
      attributes: const {'route_name': 'history'},
    );
    emit(const HistoryState(status: HistoryStatus.loading));
    final result = await repository.loadHistory(
      correlationId: correlationId,
      parentSpanId: span.id,
    );
    if (result is AppSuccess<List<CheckInEntry>>) {
      observability.finishSpan(
        span,
        status: SpanStatus.ok,
        attributes: const {'status_class': '2xx'},
      );
      emit(
        HistoryState(
          status: result.value.isEmpty
              ? HistoryStatus.empty
              : HistoryStatus.loaded,
          entries: result.value,
        ),
      );
    } else if (result is AppFailureResult<List<CheckInEntry>>) {
      observability.finishSpan(
        span,
        status: SpanStatus.error,
        attributes: {
          'failure_code': result.failure.code.name,
          'retryable': result.failure.retryable,
          'status_class': result.failure.statusClass,
        },
      );
      emit(HistoryState(status: HistoryStatus.error, failure: result.failure));
    }
  }
}
