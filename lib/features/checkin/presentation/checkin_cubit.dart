import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_checkin/core/clock/clock.dart';
import 'package:health_checkin/core/observability/observability.dart';
import 'package:health_checkin/core/result/app_result.dart';
import 'package:health_checkin/features/checkin/data/checkin_draft_store.dart';
import 'package:health_checkin/features/checkin/domain/checkin_models.dart';
import 'package:health_checkin/features/checkin/domain/checkin_validator.dart';
import 'package:health_checkin/features/program/data/program_repository.dart';
import 'package:health_checkin/features/program/domain/models.dart';
import 'package:health_checkin/features/session/data/session_repository.dart';

enum CheckInStep { progress, adherence, wellbeing, support, note, summary }

enum CheckInStatus {
  editing,
  validating,
  supportNeeded,
  submitting,
  submitted,
  retryableFailure,
  error,
  unauthorized,
}

class CheckInState extends Equatable {
  const CheckInState({
    required this.status,
    required this.step,
    required this.draft,
    this.errors = const {},
    this.failure,
    this.submittedEntry,
  });

  const CheckInState.initial(CheckInDraft draft)
    : this(
        status: CheckInStatus.editing,
        step: CheckInStep.progress,
        draft: draft,
      );

  final CheckInStatus status;
  final CheckInStep step;
  final CheckInDraft draft;
  final Map<CheckInField, String> errors;
  final AppFailure? failure;
  final CheckInEntry? submittedEntry;

  CheckInState copyWith({
    CheckInStatus? status,
    CheckInStep? step,
    CheckInDraft? draft,
    Map<CheckInField, String>? errors,
    AppFailure? failure,
    CheckInEntry? submittedEntry,
    bool clearFailure = false,
    bool clearErrors = false,
  }) {
    return CheckInState(
      status: status ?? this.status,
      step: step ?? this.step,
      draft: draft ?? this.draft,
      errors: clearErrors ? const {} : errors ?? this.errors,
      failure: clearFailure ? null : failure ?? this.failure,
      submittedEntry: submittedEntry ?? this.submittedEntry,
    );
  }

  @override
  List<Object?> get props => [
    status,
    step,
    draft,
    errors,
    failure,
    submittedEntry,
  ];
}

class CheckInCubit extends Cubit<CheckInState> {
  CheckInCubit({
    required this.repository,
    required this.sessionRepository,
    required this.draftStore,
    required this.clock,
    required this.observability,
    CheckInValidator validator = const CheckInValidator(),
  }) : _validator = validator,
       super(CheckInState.initial(draftStore.draft));

  final ProgramRepository repository;
  final SessionRepository sessionRepository;
  final CheckInDraftStore draftStore;
  final Clock clock;
  final InMemoryObservability observability;
  final CheckInValidator _validator;

  bool _submitInFlight = false;

  void updateProgress(String value) =>
      _updateDraft(state.draft.copyWith(progressValueText: value));
  void updateAdherence(Adherence value) =>
      _updateDraft(state.draft.copyWith(adherence: value));
  void updateWellbeing(Wellbeing value) =>
      _updateDraft(state.draft.copyWith(wellbeing: value));
  void updateNote(String value) =>
      _updateDraft(state.draft.copyWith(note: value));

  void _updateDraft(CheckInDraft draft) {
    draftStore.save(draft);
    emit(
      state.copyWith(
        draft: draft,
        status: CheckInStatus.editing,
        clearFailure: true,
        clearErrors: true,
      ),
    );
  }

  void next() {
    if (!_validateCurrentStepBeforeNext()) return;

    switch (state.step) {
      case CheckInStep.progress:
        emit(state.copyWith(step: CheckInStep.adherence));
      case CheckInStep.adherence:
        emit(state.copyWith(step: CheckInStep.wellbeing));
      case CheckInStep.wellbeing:
        if (state.draft.wellbeing == Wellbeing.needsSupport) {
          observability.breadcrumb(
            'checkin.support_interstitial',
            attributes: const {'flow_step': 'support'},
          );
          emit(
            state.copyWith(
              step: CheckInStep.support,
              status: CheckInStatus.supportNeeded,
            ),
          );
        } else {
          emit(
            state.copyWith(
              step: CheckInStep.note,
              status: CheckInStatus.editing,
            ),
          );
        }
      case CheckInStep.support:
        emit(
          state.copyWith(step: CheckInStep.note, status: CheckInStatus.editing),
        );
      case CheckInStep.note:
        emit(state.copyWith(step: CheckInStep.summary));
      case CheckInStep.summary:
        break;
    }
  }

  void back() {
    switch (state.step) {
      case CheckInStep.progress:
        break;
      case CheckInStep.adherence:
        emit(state.copyWith(step: CheckInStep.progress));
      case CheckInStep.wellbeing:
        emit(state.copyWith(step: CheckInStep.adherence));
      case CheckInStep.support:
        emit(
          state.copyWith(
            step: CheckInStep.wellbeing,
            status: CheckInStatus.editing,
          ),
        );
      case CheckInStep.note:
        emit(
          state.copyWith(
            step: state.draft.wellbeing == Wellbeing.needsSupport
                ? CheckInStep.support
                : CheckInStep.wellbeing,
          ),
        );
      case CheckInStep.summary:
        emit(state.copyWith(step: CheckInStep.note));
    }
  }

  Future<void> submit() async {
    if (_submitInFlight) return;
    final correlationId = observability.newCorrelationId();
    observability.breadcrumb(
      'checkin.submit.tapped',
      attributes: {'correlation_id': correlationId, 'flow_step': 'summary'},
    );
    observability.metric(
      'checkin.submit_attempts',
      1,
      attributes: {'correlation_id': correlationId},
    );
    observability.recordEvent(
      'checkin_submit_attempted',
      attributes: {'correlation_id': correlationId, 'route_name': 'check-in'},
    );
    final flowSpan = observability.startSpan(
      'checkin.flow',
      correlationId: correlationId,
      attributes: const {'route_name': 'check-in'},
    );
    final submitSpan = observability.startSpan(
      'checkin.submit',
      correlationId: correlationId,
      parentId: flowSpan.id,
    );

    final validation = _validator.validate(state.draft);
    if (!validation.isValid) {
      observability.metric(
        'checkin.validation_failures',
        1,
        attributes: {'correlation_id': correlationId},
      );
      observability.recordEvent(
        'checkin_validated',
        level: LogLevel.warning,
        attributes: {
          'correlation_id': correlationId,
          'status_class': 'validation',
        },
      );
      observability.finishSpan(
        submitSpan,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'validation'},
      );
      observability.finishSpan(
        flowSpan,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'validation'},
      );
      emit(
        state.copyWith(
          status: CheckInStatus.validating,
          errors: validation.errors,
        ),
      );
      return;
    }

    _submitInFlight = true;
    emit(
      state.copyWith(
        status: CheckInStatus.submitting,
        clearErrors: true,
        clearFailure: true,
      ),
    );
    try {
      final submission = state.draft.toSubmission(
        clock: clock,
        programId: 'program_001',
      );
      final startedAt = clock.now();
      final result = await repository.submitCheckIn(
        submission,
        correlationId: correlationId,
        parentSpanId: submitSpan.id,
      );
      final durationMs = clock.now().difference(startedAt).inMilliseconds;
      observability.metric(
        'checkin.submit_duration_ms',
        durationMs,
        attributes: {'correlation_id': correlationId},
      );

      if (result is AppSuccess<CheckInEntry>) {
        draftStore.clear();
        observability.recordEvent(
          'checkin_submitted',
          attributes: {
            'correlation_id': correlationId,
            'status_class': '2xx',
            'adherence': submission.adherence.wireValue,
            'wellbeing': submission.wellbeing.wireValue,
            'has_note': submission.note != null,
          },
        );
        observability.finishSpan(
          submitSpan,
          status: SpanStatus.ok,
          attributes: const {'status_class': '2xx'},
        );
        observability.finishSpan(
          flowSpan,
          status: SpanStatus.ok,
          attributes: const {'status_class': '2xx'},
        );
        emit(
          state.copyWith(
            status: CheckInStatus.submitted,
            submittedEntry: result.value,
          ),
        );
      } else if (result is AppFailureResult<CheckInEntry>) {
        final failure = result.failure;
        if (failure.isUnauthorized) {
          await sessionRepository.clear();
        }
        observability.metric(
          'checkin.submit_failures',
          1,
          attributes: {
            'correlation_id': correlationId,
            'failure_code': failure.code.name,
            'retryable': failure.retryable,
            'status_class': failure.statusClass,
          },
        );
        observability.recordEvent(
          'checkin_failed',
          level: LogLevel.warning,
          attributes: {
            'correlation_id': correlationId,
            'failure_code': failure.code.name,
            'retryable': failure.retryable,
            'status_class': failure.statusClass,
          },
        );
        observability.expectedError(
          'checkin_submit_failed',
          correlationId: correlationId,
          attributes: {
            'failure_code': failure.code.name,
            'retryable': failure.retryable,
            'status_class': failure.statusClass,
          },
        );
        observability.finishSpan(
          submitSpan,
          status: SpanStatus.error,
          attributes: {
            'failure_code': failure.code.name,
            'retryable': failure.retryable,
            'status_class': failure.statusClass,
          },
        );
        observability.finishSpan(
          flowSpan,
          status: SpanStatus.error,
          attributes: {
            'failure_code': failure.code.name,
            'retryable': failure.retryable,
            'status_class': failure.statusClass,
          },
        );
        emit(
          state.copyWith(
            status: failure.isUnauthorized
                ? CheckInStatus.unauthorized
                : failure.retryable
                ? CheckInStatus.retryableFailure
                : CheckInStatus.error,
            failure: failure,
          ),
        );
      }
    } catch (error) {
      observability.captureUnexpected(
        error,
        correlationId: correlationId,
        attributes: const {'route_name': 'check-in'},
      );
      observability.finishSpan(
        submitSpan,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'unknown'},
      );
      observability.finishSpan(
        flowSpan,
        status: SpanStatus.error,
        attributes: const {'failure_code': 'unknown'},
      );
      emit(
        state.copyWith(
          status: CheckInStatus.error,
          failure: const AppFailure(
            code: FailureCode.unknown,
            safeMessage: 'Unexpected submit error.',
            retryable: true,
            statusClass: 'unknown',
          ),
        ),
      );
    } finally {
      _submitInFlight = false;
    }
  }

  bool _validateCurrentStepBeforeNext() {
    final validation = _validator.validate(state.draft);

    final requiredFieldsForStep = switch (state.step) {
      CheckInStep.progress => {CheckInField.progress},
      CheckInStep.adherence => {CheckInField.adherence},
      CheckInStep.wellbeing => {CheckInField.wellbeing},

      // Support screen and note screen do not need required validation.
      CheckInStep.support => <CheckInField>{},
      CheckInStep.note => <CheckInField>{},

      // Summary submit already validates the full draft.
      CheckInStep.summary => <CheckInField>{},
    };

    final stepErrors = Map<CheckInField, String>.fromEntries(
      validation.errors.entries.where(
        (entry) => requiredFieldsForStep.contains(entry.key),
      ),
    );

    if (stepErrors.isNotEmpty) {
      observability.metric(
        'checkin.validation_failures',
        1,
        attributes: const {'status_class': 'validation'},
      );

      emit(
        state.copyWith(status: CheckInStatus.validating, errors: stepErrors),
      );

      return false;
    }

    emit(
      state.copyWith(
        status: CheckInStatus.editing,
        clearErrors: true,
        clearFailure: true,
      ),
    );

    return true;
  }
}
