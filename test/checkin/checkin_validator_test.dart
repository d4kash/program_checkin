import 'package:flutter_test/flutter_test.dart';
import 'package:health_checkin/features/checkin/domain/checkin_models.dart';
import 'package:health_checkin/features/checkin/domain/checkin_validator.dart';
import 'package:health_checkin/features/program/domain/models.dart';

void main() {
  test('validates required check-in fields', () {
    const validator = CheckInValidator();
    final invalid = validator.validate(CheckInDraft());
    expect(invalid.isValid, isFalse);
    expect(
      invalid.errors.keys,
      containsAll([
        CheckInField.progress,
        CheckInField.adherence,
        CheckInField.wellbeing,
      ]),
    );

    final valid = validator.validate(
      CheckInDraft(
        progressValueText: '80,4',
        adherence: Adherence.completed,
        wellbeing: Wellbeing.good,
      ),
    );
    expect(valid.isValid, isTrue);
  });
}
