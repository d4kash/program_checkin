import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/features/checkin/domain/checkin_models.dart';
import 'package:health_checkin/features/program/data/fixture_loader.dart';
import 'package:health_checkin/features/program/domain/models.dart';

abstract class ProgramRepository {
  Future<AppResult<DashboardSnapshot?>> loadDashboard({
    required String correlationId,
    String? parentSpanId,
  });
  Future<AppResult<List<CheckInEntry>>> loadHistory({
    required String correlationId,
    String? parentSpanId,
  });
  Future<AppResult<CheckInEntry>> submitCheckIn(
    CheckInSubmission submission, {
    required String correlationId,
    String? parentSpanId,
  });
}

class FixtureProgramRepository implements ProgramRepository {
  FixtureProgramRepository({
    required this.fixtureLoader,
    required this.apiClient,
    required this.clock,
    required this.observability,
  });

  final FixtureLoader fixtureLoader;
  final FakeApiClient apiClient;
  final Clock clock;
  final InMemoryObservability observability;

  DashboardSnapshot? _dashboard;
  final List<CheckInEntry> _history = [];
  final Map<String, CheckInEntry> _submittedByIdempotencyKey = {};
  bool _loaded = false;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final fixture = await fixtureLoader.load();
    final user = UserProfile.fromJson(fixture['user'] as Map<String, dynamic>);
    final program = Program.fromJson(
      fixture['program'] as Map<String, dynamic>,
    );
    final historyJson = fixture['history'] as List<dynamic>;
    _dashboard = DashboardSnapshot(user: user, program: program);
    _history
      ..clear()
      ..addAll(
        historyJson.map(
          (item) => CheckInEntry.fromJson(item as Map<String, dynamic>),
        ),
      );
    _loaded = true;
  }

  @override
  Future<AppResult<DashboardSnapshot?>> loadDashboard({
    required String correlationId,
    String? parentSpanId,
  }) async {
    final span = observability.startSpan(
      'repository.dashboard_load',
      correlationId: correlationId,
      parentId: parentSpanId,
      attributes: const {'source': 'fixture_repository'},
    );
    try {
      final apiResult = await apiClient.request(endpoint: 'dashboard');
      if (apiResult is AppFailureResult<void>) {
        observability.finishSpan(
          span,
          status: SpanStatus.error,
          attributes: {
            'failure_code': apiResult.failure.code.name,
            'retryable': apiResult.failure.retryable,
            'status_class': apiResult.failure.statusClass,
          },
        );
        return AppFailureResult(apiResult.failure);
      }
      await _ensureLoaded();
      observability.finishSpan(
        span,
        status: SpanStatus.ok,
        attributes: {
          'status_class': '2xx',
          'task_status': _dashboard?.program.taskStatus.name,
          'region': _dashboard?.user.region,
        },
      );
      return AppSuccess(_dashboard);
    } catch (error) {
      observability.captureUnexpected(
        error,
        correlationId: correlationId,
        attributes: const {'source': 'program_repository'},
      );
      observability.finishSpan(
        span,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'unknown'},
      );
      return const AppFailureResult(
        AppFailure(
          code: FailureCode.unknown,
          safeMessage: 'Unexpected dashboard error.',
          retryable: true,
          statusClass: 'unknown',
        ),
      );
    }
  }

  @override
  Future<AppResult<List<CheckInEntry>>> loadHistory({
    required String correlationId,
    String? parentSpanId,
  }) async {
    final span = observability.startSpan(
      'repository.history_load',
      correlationId: correlationId,
      parentId: parentSpanId,
      attributes: const {'source': 'fixture_repository'},
    );
    try {
      final apiResult = await apiClient.request(endpoint: 'history');
      if (apiResult is AppFailureResult<void>) {
        observability.finishSpan(
          span,
          status: SpanStatus.error,
          attributes: {
            'failure_code': apiResult.failure.code.name,
            'retryable': apiResult.failure.retryable,
            'status_class': apiResult.failure.statusClass,
          },
        );
        return AppFailureResult(apiResult.failure);
      }
      await _ensureLoaded();
      final sorted = [..._history]..sort((a, b) => b.date.compareTo(a.date));
      observability.finishSpan(
        span,
        status: SpanStatus.ok,
        attributes: const {'status_class': '2xx'},
      );
      return AppSuccess(sorted);
    } catch (error) {
      observability.captureUnexpected(
        error,
        correlationId: correlationId,
        attributes: const {'source': 'program_repository'},
      );
      observability.finishSpan(
        span,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'unknown'},
      );
      return const AppFailureResult(
        AppFailure(
          code: FailureCode.unknown,
          safeMessage: 'Unexpected history error.',
          retryable: true,
          statusClass: 'unknown',
        ),
      );
    }
  }

  @override
  Future<AppResult<CheckInEntry>> submitCheckIn(
    CheckInSubmission submission, {
    required String correlationId,
    String? parentSpanId,
  }) async {
    final span = observability.startSpan(
      'repository.submit_checkin',
      correlationId: correlationId,
      parentId: parentSpanId,
      attributes: {
        'source': 'fixture_repository',
        'adherence': submission.adherence.wireValue,
        'wellbeing': submission.wellbeing.wireValue,
        'has_note': submission.note != null,
      },
    );
    try {
      final apiResult = await apiClient.request(endpoint: 'submit_checkin');
      if (apiResult is AppFailureResult<void>) {
        observability.finishSpan(
          span,
          status: SpanStatus.error,
          attributes: {
            'failure_code': apiResult.failure.code.name,
            'retryable': apiResult.failure.retryable,
            'status_class': apiResult.failure.statusClass,
          },
        );
        return AppFailureResult(apiResult.failure);
      }
      await _ensureLoaded();
      final existing = _submittedByIdempotencyKey[submission.idempotencyKey];
      if (existing != null) {
        observability.finishSpan(
          span,
          status: SpanStatus.ok,
          attributes: const {'status_class': '2xx'},
        );
        return AppSuccess(existing);
      }
      final entry = CheckInEntry(
        id: 'local_${clock.now().microsecondsSinceEpoch}',
        date: submission.date,
        progressValue: submission.progressValue,
        adherence: submission.adherence,
        wellbeing: submission.wellbeing,
        note: submission.note,
      );
      _submittedByIdempotencyKey[submission.idempotencyKey] = entry;
      _history.add(entry);
      final current = _dashboard;
      if (current != null) {
        _dashboard = DashboardSnapshot(
          user: current.user,
          program: current.program.copyWith(
            taskStatus: TaskStatus.completed,
            nextCheckinDue: current.program.nextCheckinDue.add(
              const Duration(days: 7),
            ),
          ),
        );
      }
      observability.finishSpan(
        span,
        status: SpanStatus.ok,
        attributes: const {'status_class': '2xx'},
      );
      return AppSuccess(entry);
    } catch (error) {
      observability.captureUnexpected(
        error,
        correlationId: correlationId,
        attributes: const {'source': 'program_repository'},
      );
      observability.finishSpan(
        span,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'unknown'},
      );
      return const AppFailureResult(
        AppFailure(
          code: FailureCode.unknown,
          safeMessage: 'Unexpected submit error.',
          retryable: true,
          statusClass: 'unknown',
        ),
      );
    }
  }
}
