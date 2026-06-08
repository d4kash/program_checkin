import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
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
  cubit.updateProgress('80,4');
  cubit.updateAdherence(Adherence.completed);
  cubit.updateWellbeing(Wellbeing.good);
  cubit.updateNote('private note text');
}

void main() {
  blocTest<CheckInCubit, CheckInState>(
    'successful submission emits submitted',
    build: () => buildCubit(TestHarness()),
    act: (cubit) async {
      fillValid(cubit);
      await cubit.submit();
    },
    verify: (cubit) => expect(cubit.state.status, CheckInStatus.submitted),
  );

  blocTest<CheckInCubit, CheckInState>(
    'invalid input emits validating state',
    build: () => buildCubit(TestHarness()),
    act: (cubit) => cubit.submit(),
    verify: (cubit) => expect(cubit.state.status, CheckInStatus.validating),
  );

  blocTest<CheckInCubit, CheckInState>(
    'timeout failure preserves draft and is retryable',
    build: () {
      final harness = TestHarness();
      harness.apiClient.enqueueScenario(FakeApiScenario.timeout);
      return buildCubit(harness);
    },
    act: (cubit) async {
      fillValid(cubit);
      await cubit.submit();
    },
    verify: (cubit) {
      expect(cubit.state.status, CheckInStatus.retryableFailure);
      expect(cubit.state.draft.progressValueText, '80,4');
    },
  );

  test('401 unauthorized clears secure session state', () async {
    final harness = TestHarness();
    await harness.sessionRepository.restore();
    harness.apiClient.enqueueScenario(FakeApiScenario.unauthorized);
    final cubit = buildCubit(harness);
    fillValid(cubit);
    await cubit.submit();
    expect(cubit.state.status, CheckInStatus.unauthorized);
    expect(await harness.secureStore.dumpForTests(), isEmpty);
  });

  test('double-tap submit saves one check-in', () async {
    final harness = TestHarness();
    harness.apiClient.enqueueScenario(
      FakeApiScenario.success,
      delay: const Duration(milliseconds: 20),
    );
    final cubit = buildCubit(harness);
    fillValid(cubit);
    await Future.wait([cubit.submit(), cubit.submit()]);
    final history = await harness.programRepository.loadHistory(
      correlationId: 'test',
      parentSpanId: null,
    );
    final entries = history.when(
      success: (value) => value,
      failure: (_) => throw StateError('failed'),
    );
    expect(entries.where((entry) => entry.id.startsWith('local_')).length, 1);
  });
}
