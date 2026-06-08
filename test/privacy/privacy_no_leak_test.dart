import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/features/checkin/presentation/checkin_cubit.dart';
import 'package:health_checkin/features/program/domain/models.dart';

import '../helpers/test_fixture.dart';

void main() {
  test(
    'observability and plain storage do not leak fake sensitive fixture values',
    () async {
      final harness = TestHarness();
      final cubit = CheckInCubit(
        repository: harness.programRepository,
        sessionRepository: harness.sessionRepository,
        draftStore: harness.draftStore,
        clock: harness.clock,
        observability: harness.observability,
      );
      cubit.updateProgress('80.4');
      cubit.updateAdherence(Adherence.completed);
      cubit.updateWellbeing(Wellbeing.good);
      cubit.updateNote('private note text');
      await cubit.submit();

      final serialized =
          '${harness.observability.serializedForPrivacyAudit()} ${await harness.plainPreferences.dumpForTests()}';
      const forbidden = [
        'private note text',
        '80.4',
        'demo_user_123',
        'Maya',
        'maya@example.org',
        '+10000000000',
        'fake_access_token',
        'fake_refresh_token',
        'authorization',
        'request_body',
        'response_body',
        '/tmp/',
        '?user=',
      ];
      for (final value in forbidden) {
        expect(
          serialized.contains(value),
          isFalse,
          reason: 'Leaked sensitive value: $value',
        );
      }
    },
  );

  test('safe attributes remove sensitive keys and values', () {
  final safe = SafeAttributes.build({
    'route_name': 'check-in',
    'status_class': 'failure',
    'region': 'Region A',
    'adherence': 'completed',
    'wellbeing': 'good',

    // Must be removed
    'email': 'maya@example.org',
    'phone': '+10000000000',
    'token': 'fake_access_token',
    'authorization': 'Bearer fake_access_token',
    'request_body': {'progressValue': '80,4'},
    'response_body': {'id': 'demo_user_123'},
    'file_path': 'C:/Users/example/secret.txt',
    'url': 'https://example.org/checkin?user=demo_user_123',
  });

  expect(safe['route_name'], 'check-in');
  expect(safe['status_class'], 'failure');
  expect(safe['region'], 'Region A');

  expect(safe.containsKey('email'), isFalse);
  expect(safe.containsKey('phone'), isFalse);
  expect(safe.containsKey('token'), isFalse);
  expect(safe.containsKey('authorization'), isFalse);
  expect(safe.containsKey('request_body'), isFalse);
  expect(safe.containsKey('response_body'), isFalse);
  expect(safe.containsKey('file_path'), isFalse);
  expect(safe.containsKey('url'), isFalse);
});

}
