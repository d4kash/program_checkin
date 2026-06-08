import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/features/checkin/domain/checkin_models.dart';
import 'package:health_checkin/features/program/domain/models.dart';

void main() {
  test('maps typed draft to submission', () {
    final clock = FixedClock(DateTime.utc(2026, 6, 8, 9));
    final draft = CheckInDraft(
      idempotencyKey: 'idemp-1',
      progressValueText: '80,4',
      adherence: Adherence.partial,
      wellbeing: Wellbeing.needsSupport,
      note: 'private note text',
    );
    final submission = draft.toSubmission(
      clock: clock,
      programId: 'program_001',
    );
    expect(submission.idempotencyKey, 'idemp-1');
    expect(submission.progressValue, 80.4);
    expect(submission.adherence, Adherence.partial);
    expect(submission.wellbeing, Wellbeing.needsSupport);
    expect(submission.note, 'private note text');
  });
}
