import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_checkin/app/localization/app_localizations.dart';
import 'package:health_checkin/app/router.dart';
import 'package:health_checkin/features/checkin/domain/checkin_validator.dart';
import 'package:health_checkin/features/checkin/presentation/checkin_cubit.dart';
import 'package:health_checkin/features/checkin/presentation/widgets/accessible_choice_card.dart';
import 'package:health_checkin/features/program/domain/models.dart';

class CheckInScreen extends StatelessWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return BlocListener<CheckInCubit, CheckInState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == CheckInStatus.submitted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(strings.submitted)));
          context.goNamed(AppRoute.dashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.checkIn)),
        body: SafeArea(
          child: BlocBuilder<CheckInCubit, CheckInState>(
            builder: (context, state) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  LinearProgressIndicator(value: _stepProgress(state.step)),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: _StepContent(state: state),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FooterControls(state: state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  double _stepProgress(CheckInStep step) {
    switch (step) {
      case CheckInStep.progress:
        return .16;
      case CheckInStep.adherence:
        return .32;
      case CheckInStep.wellbeing:
        return .48;
      case CheckInStep.support:
        return .64;
      case CheckInStep.note:
        return .80;
      case CheckInStep.summary:
        return 1;
    }
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({required this.state});
  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    switch (state.step) {
      case CheckInStep.progress:
        return _ProgressStep(state: state);
      case CheckInStep.adherence:
        return _AdherenceStep(state: state);
      case CheckInStep.wellbeing:
        return _WellbeingStep(state: state);
      case CheckInStep.support:
        return const _SupportStep();
      case CheckInStep.note:
        return _NoteStep(state: state);
      case CheckInStep.summary:
        return _SummaryStep(state: state);
    }
  }
}

class _ProgressStep extends StatefulWidget {
  const _ProgressStep({required this.state});
  final CheckInState state;

  @override
  State<_ProgressStep> createState() => _ProgressStepState();
}

class _ProgressStepState extends State<_ProgressStep> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.state.draft.progressValueText ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: strings.progressStep, subtitle: strings.progressHint),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: strings.progressValue,
            errorText: _errorText(
              context,
              widget.state.errors[CheckInField.progress],
            ),
          ),
          onChanged: context.read<CheckInCubit>().updateProgress,
        ),
      ],
    );
  }
}

class _AdherenceStep extends StatelessWidget {
  const _AdherenceStep({required this.state});
  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final cubit = context.read<CheckInCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: strings.adherenceStep, subtitle: strings.adherence),
        const SizedBox(height: 14),
        AccessibleChoiceCard(
          value: Adherence.completed,
          groupValue: state.draft.adherence,
          label: strings.completed,
          icon: Icons.task_alt_rounded,
          onChanged: cubit.updateAdherence,
        ),
        const SizedBox(height: 10),
        AccessibleChoiceCard(
          value: Adherence.partial,
          groupValue: state.draft.adherence,
          label: strings.partial,
          icon: Icons.adjust_rounded,
          onChanged: cubit.updateAdherence,
        ),
        const SizedBox(height: 10),
        AccessibleChoiceCard(
          value: Adherence.missed,
          groupValue: state.draft.adherence,
          label: strings.missed,
          icon: Icons.event_busy_rounded,
          onChanged: cubit.updateAdherence,
        ),
        if (state.errors.containsKey(CheckInField.adherence))
          _InlineError(text: strings.requiredField),
      ],
    );
  }
}

class _WellbeingStep extends StatelessWidget {
  const _WellbeingStep({required this.state});
  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final cubit = context.read<CheckInCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: strings.wellbeingStep, subtitle: strings.wellbeing),
        const SizedBox(height: 14),
        AccessibleChoiceCard(
          value: Wellbeing.good,
          groupValue: state.draft.wellbeing,
          label: strings.good,
          icon: Icons.sentiment_satisfied_alt_rounded,
          onChanged: cubit.updateWellbeing,
        ),
        const SizedBox(height: 10),
        AccessibleChoiceCard(
          value: Wellbeing.okay,
          groupValue: state.draft.wellbeing,
          label: strings.okay,
          icon: Icons.sentiment_neutral_rounded,
          onChanged: cubit.updateWellbeing,
        ),
        const SizedBox(height: 10),
        AccessibleChoiceCard(
          value: Wellbeing.needsSupport,
          groupValue: state.draft.wellbeing,
          label: strings.needsSupport,
          icon: Icons.volunteer_activism_rounded,
          onChanged: cubit.updateWellbeing,
        ),
        if (state.errors.containsKey(CheckInField.wellbeing))
          _InlineError(text: strings.requiredField),
      ],
    );
  }
}

class _SupportStep extends StatelessWidget {
  const _SupportStep();
  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.health_and_safety_rounded, color: scheme.primary, size: 42),
        const SizedBox(height: 14),
        _StepTitle(title: strings.supportTitle, subtitle: strings.supportBody),
      ],
    );
  }
}

class _NoteStep extends StatefulWidget {
  const _NoteStep({required this.state});
  final CheckInState state;

  @override
  State<_NoteStep> createState() => _NoteStepState();
}

class _NoteStepState extends State<_NoteStep> {
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.draft.note ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: strings.noteStep, subtitle: strings.noteHint),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(labelText: strings.optionalNote),
          onChanged: context.read<CheckInCubit>().updateNote,
        ),
      ],
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({required this.state});
  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final draft = state.draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepTitle(title: strings.summary, subtitle: strings.submit),
        const SizedBox(height: 16),
        _SummaryRow(
          label: strings.progressValue,
          value: draft.progressValueText ?? '',
        ),
        _SummaryRow(
          label: strings.adherence,
          value: draft.adherence == null
              ? '-'
              : strings.adherenceLabel(draft.adherence!.wireValue),
        ),
        _SummaryRow(
          label: strings.wellbeing,
          value: draft.wellbeing == null
              ? '-'
              : strings.wellbeingLabel(draft.wellbeing!.wireValue),
        ),
        _SummaryRow(
          label: strings.optionalNote,
          value: draft.hasNote ? 'Added' : '-',
        ),
        if (state.status == CheckInStatus.retryableFailure)
          _InlineError(text: strings.offlineRetry),
        if (state.status == CheckInStatus.unauthorized)
          _InlineError(text: strings.unauthorized),
      ],
    );
  }
}

class _FooterControls extends StatelessWidget {
  const _FooterControls({required this.state});
  final CheckInState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final cubit = context.read<CheckInCubit>();
    final isSummary = state.step == CheckInStep.summary;
    final isBusy = state.status == CheckInStatus.submitting;
    return Row(
      children: [
        if (state.step != CheckInStep.progress)
          Expanded(
            child: OutlinedButton(
              onPressed: isBusy ? null : cubit.back,
              child: Text(strings.back),
            ),
          ),
        if (state.step != CheckInStep.progress) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isBusy
                ? null
                : isSummary
                ? cubit.submit
                : cubit.next,
            child: Text(
              isBusy
                  ? strings.submitting
                  : isSummary
                  ? strings.submit
                  : strings.continueText,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(subtitle),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String? _errorText(BuildContext context, String? code) {
  if (code == null) return null;
  final strings = AppStrings.of(context);
  if (code == 'required') return strings.requiredField;
  if (code == 'invalid_progress') return strings.invalidProgress;
  return strings.requiredField;
}
