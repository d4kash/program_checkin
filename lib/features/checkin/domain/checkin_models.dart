import 'package:equatable/equatable.dart';
import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/formatting/progress_value_parser.dart';
import 'package:health_checkin/features/program/domain/models.dart';
import 'package:uuid/uuid.dart';

class CheckInDraft extends Equatable {
  CheckInDraft({
    String? idempotencyKey,
    this.progressValueText,
    this.adherence,
    this.wellbeing,
    this.note,
  }) : idempotencyKey = idempotencyKey ?? const Uuid().v4();

  final String idempotencyKey;
  final String? progressValueText;
  final Adherence? adherence;
  final Wellbeing? wellbeing;
  final String? note;

  bool get hasNote => note != null && note!.trim().isNotEmpty;

  CheckInDraft copyWith({
    String? progressValueText,
    Adherence? adherence,
    Wellbeing? wellbeing,
    String? note,
    bool clearNote = false,
  }) {
    return CheckInDraft(
      idempotencyKey: idempotencyKey,
      progressValueText: progressValueText ?? this.progressValueText,
      adherence: adherence ?? this.adherence,
      wellbeing: wellbeing ?? this.wellbeing,
      note: clearNote ? null : note ?? this.note,
    );
  }

  CheckInSubmission toSubmission({
    required Clock clock,
    required String programId,
  }) {
    return CheckInSubmission(
      idempotencyKey: idempotencyKey,
      programId: programId,
      date: clock.now(),
      progressValue: ProgressValueParser.tryParse(progressValueText),
      adherence: adherence!,
      wellbeing: wellbeing!,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
    );
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    progressValueText,
    adherence,
    wellbeing,
    note,
  ];
}

class CheckInSubmission extends Equatable {
  const CheckInSubmission({
    required this.idempotencyKey,
    required this.programId,
    required this.date,
    required this.progressValue,
    required this.adherence,
    required this.wellbeing,
    this.note,
  });

  final String idempotencyKey;
  final String programId;
  final DateTime date;
  final double? progressValue;
  final Adherence adherence;
  final Wellbeing wellbeing;
  final String? note;

  Map<String, Object?> toSafePayloadShapeOnly() {
    return {
      'has_progress_value': progressValue != null,
      'adherence': adherence.wireValue,
      'wellbeing': wellbeing.wireValue,
      'has_note': note != null,
      'idempotency_key_present': idempotencyKey.isNotEmpty,
    };
  }

  @override
  List<Object?> get props => [
    idempotencyKey,
    programId,
    date,
    progressValue,
    adherence,
    wellbeing,
    note,
  ];
}
