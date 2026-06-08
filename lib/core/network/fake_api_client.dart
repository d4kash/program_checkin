import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/result/app_result.dart';

enum FakeApiScenario {
  success,
  timeout,
  offline,
  malformedJson,
  unauthorized,
  rateLimited,
  unexpectedException,
}

class FakeApiClient {
  FakeApiClient({required this.clock});

  final Clock clock;
  final List<FakeApiScenario> _scenarioQueue = [];
  final List<Duration> _delayQueue = [];

  void enqueueScenario(
    FakeApiScenario scenario, {
    Duration delay = Duration.zero,
  }) {
    _scenarioQueue.add(scenario);
    _delayQueue.add(delay);
  }

  Future<AppResult<void>> request({required String endpoint}) async {
    final scenario = _scenarioQueue.isEmpty
        ? FakeApiScenario.success
        : _scenarioQueue.removeAt(0);
    final delay = _delayQueue.isEmpty ? Duration.zero : _delayQueue.removeAt(0);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    switch (scenario) {
      case FakeApiScenario.success:
        return const AppSuccess(null);
      case FakeApiScenario.timeout:
        return const AppFailureResult(
          AppFailure(
            code: FailureCode.timeout,
            safeMessage: 'Request timed out.',
            retryable: true,
            statusClass: 'timeout',
          ),
        );
      case FakeApiScenario.offline:
        return const AppFailureResult(
          AppFailure(
            code: FailureCode.offline,
            safeMessage: 'Device appears offline.',
            retryable: true,
            statusClass: 'network',
          ),
        );
      case FakeApiScenario.malformedJson:
        return const AppFailureResult(
          AppFailure(
            code: FailureCode.malformedJson,
            safeMessage: 'Response could not be decoded.',
            retryable: false,
            statusClass: 'bad_response',
          ),
        );
      case FakeApiScenario.unauthorized:
        return const AppFailureResult(
          AppFailure(
            code: FailureCode.unauthorized,
            safeMessage: 'Unauthorized.',
            retryable: false,
            statusClass: '4xx',
          ),
        );
      case FakeApiScenario.rateLimited:
        return const AppFailureResult(
          AppFailure(
            code: FailureCode.rateLimited,
            safeMessage: 'Rate limited.',
            retryable: true,
            statusClass: '429',
          ),
        );
      case FakeApiScenario.unexpectedException:
        throw StateError('Unexpected fake client failure.');
    }
  }
}
