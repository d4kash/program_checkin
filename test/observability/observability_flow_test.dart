import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/features/checkin/presentation/checkin_cubit.dart';
import 'package:health_checkin/features/program/domain/models.dart';

import '../helpers/test_fixture.dart';

CheckInCubit buildCubit(TestHarness harness) => CheckInCubit(
  repository: harness.programRepository,
  sessionRepository: harness.sessionRepository,
  draftStore: harness.draftStore,
  clock: harness.clock,
  observability: harness.observability,
);

void fillValid(CheckInCubit cubit) {
  cubit.updateProgress('80');
  cubit.updateAdherence(Adherence.completed);
  cubit.updateWellbeing(Wellbeing.good);
}

void main() {
  test(
    'successful submit span lifecycle is recorded with safe attributes',
    () async {
      final harness = TestHarness();
      final cubit = buildCubit(harness);
      fillValid(cubit);
      await cubit.submit();
      final submitSpan = harness.observability.spans.firstWhere(
        (span) => span.name == 'checkin.submit',
      );
      final repoSpan = harness.observability.spans.firstWhere(
        (span) => span.name == 'repository.submit_checkin',
      );
      expect(submitSpan.status, SpanStatus.ok);
      expect(submitSpan.durationMs, isNotNull);
      expect(repoSpan.parentId, submitSpan.id);
      expect(submitSpan.attributes.containsKey('progress_value'), isFalse);
    },
  );

  test(
    'failed submit shares correlation ID across observability records',
    () async {
      final harness = TestHarness();
      harness.apiClient.enqueueScenario(FakeApiScenario.offline);
      final cubit = buildCubit(harness);
      fillValid(cubit);
      await cubit.submit();
      final log = harness.observability.logs.firstWhere(
        (item) => item.eventName == 'checkin_failed',
      );
      final correlationId = log.attributes['correlation_id'];
      expect(
        harness.observability.breadcrumbs.any(
          (item) => item.attributes['correlation_id'] == correlationId,
        ),
        isTrue,
      );
      expect(
        harness.observability.spans.any(
          (item) => item.correlationId == correlationId,
        ),
        isTrue,
      );
      expect(
        harness.observability.metrics.any(
          (item) => item.attributes['correlation_id'] == correlationId,
        ),
        isTrue,
      );
      expect(
        harness.observability.errors.any(
          (item) => item.correlationId == correlationId,
        ),
        isTrue,
      );
    },
  );

  test(
    'expected repository failure is not crash, unexpected exception is captured once',
    () async {
      final expectedHarness = TestHarness();
      expectedHarness.apiClient.enqueueScenario(FakeApiScenario.offline);
      final expectedCubit = buildCubit(expectedHarness);
      fillValid(expectedCubit);
      await expectedCubit.submit();
      expect(expectedHarness.observability.crashes, isEmpty);
      expect(expectedHarness.observability.errors, isNotEmpty);

      final unexpectedHarness = TestHarness();
      unexpectedHarness.apiClient.enqueueScenario(
        FakeApiScenario.unexpectedException,
      );
      final unexpectedCubit = buildCubit(unexpectedHarness);
      fillValid(unexpectedCubit);
      await unexpectedCubit.submit();
      expect(unexpectedHarness.observability.crashes.length, 1);
    },
  );
}
