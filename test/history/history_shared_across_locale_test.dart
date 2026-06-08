import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/features/checkin/domain/checkin_models.dart';
import 'package:health_checkin/features/program/domain/models.dart';
import '../widgets/accessibility_and_locale_test.dart';

void main() {
  test('submitted check-ins are shared across locale changes', () async {
    final dependencies = testDependencies();

    final repository = dependencies.programRepository;

    final first = CheckInSubmission(
      idempotencyKey: 'english-flow-checkin',
      programId: 'program_001',
      date: DateTime.parse('2026-06-08T10:00:00Z'),
      progressValue: 80.4,
      adherence: Adherence.completed,
      wellbeing: Wellbeing.good,
    );

    final second = CheckInSubmission(
      idempotencyKey: 'german-flow-checkin',
      programId: 'program_001',
      date: DateTime.parse('2026-06-08T11:00:00Z'),
      progressValue: 81.2,
      adherence: Adherence.partial,
      wellbeing: Wellbeing.okay,
    );

    await repository.submitCheckIn(first, correlationId: 'corr-en');

    // Simulate locale switch. Locale should not recreate repository.
    await dependencies.plainPreferences.setString('locale_code', 'de');

    await repository.submitCheckIn(second, correlationId: 'corr-de');

    final historyResult = await repository.loadHistory(
      correlationId: 'corr-history',
    );

    final entries = switch (historyResult) {
      AppSuccess<List<CheckInEntry>>(:final value) => value,
      _ => fail('History should load successfully'),
    };

    expect(entries.where((entry) => entry.id.startsWith('local_')).length, 2);

    expect(entries.any((entry) => entry.progressValue == 80.4), isTrue);

    expect(entries.any((entry) => entry.progressValue == 81.2), isTrue);
  });
}
