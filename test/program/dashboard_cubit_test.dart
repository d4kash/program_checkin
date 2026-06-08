import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/network/fake_api_client.dart';
import 'package:health_checkin/features/program/presentation/dashboard_cubit.dart';

import '../helpers/test_fixture.dart';

void main() {
  test('stale delayed dashboard load cannot overwrite newer state', () async {
    final harness = TestHarness();
    final cubit = DashboardCubit(
      repository: harness.programRepository,
      observability: harness.observability,
    );
    harness.apiClient.enqueueScenario(
      FakeApiScenario.timeout,
      delay: const Duration(milliseconds: 40),
    );
    final first = cubit.load();
    await Future<void>.delayed(const Duration(milliseconds: 1));
    final second = cubit.load();
    await Future.wait([first, second]);
    expect(cubit.state.status, DashboardStatus.loaded);
    expect(cubit.state.snapshot?.user.firstName, 'Maya');
  });
}
