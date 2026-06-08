import 'package:health_checkin/core/formatting/progress_value_parser.dart';
import 'package:health_checkin/features/checkin/domain/checkin_models.dart';

enum CheckInField { progress, adherence, wellbeing }

class CheckInValidationResult {
  const CheckInValidationResult({required this.isValid, required this.errors});

  final bool isValid;
  final Map<CheckInField, String> errors;
}

class CheckInValidator {
  const CheckInValidator();

  CheckInValidationResult validate(CheckInDraft draft) {
    final errors = <CheckInField, String>{};

    final rawProgress = draft.progressValueText;
    final progress = ProgressValueParser.tryParse(rawProgress);

    if (rawProgress == null || rawProgress.toString().trim().isEmpty) {
      errors[CheckInField.progress] = 'Progress value is required.';
    } else if (progress == null) {
      errors[CheckInField.progress] =
          'Enter a valid number, for example 80, 80.4, or 80,4.';
    } else if (progress < 0 || progress > 100) {
      errors[CheckInField.progress] =
          'Progress value must be between 0 and 100.';
    }

    if (draft.adherence == null) {
      errors[CheckInField.adherence] = 'Please select adherence.';
    }

    if (draft.wellbeing == null) {
      errors[CheckInField.wellbeing] = 'Please select wellbeing.';
    }

    return CheckInValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
