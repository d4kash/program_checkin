import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_checkin/app/localization/app_localizations.dart';
import 'package:health_checkin/app/router.dart';
import 'package:health_checkin/core/formatting/locale_formatters.dart';
import 'package:health_checkin/features/program/domain/models.dart';
import 'package:health_checkin/features/program/presentation/dashboard_cubit.dart';
import 'package:health_checkin/features/session/presentation/session_cubit.dart';
import 'package:health_checkin/features/settings/presentation/locale_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.dashboard),
        actions: const [_LocaleToggle(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            switch (state.status) {
              case DashboardStatus.initial:
              case DashboardStatus.loading:
                if (state.snapshot != null) {
                  return _LoadedDashboard(state: state);
                }
                return Center(child: Text(strings.loadingDashboard));
              case DashboardStatus.empty:
                return _CenteredMessage(
                  message: strings.emptyDashboard,
                  onRetry: () => context.read<DashboardCubit>().load(),
                );
              case DashboardStatus.error:
                return _CenteredMessage(
                  message: state.failure?.safeMessage ?? 'Error',
                  onRetry: () => context.read<DashboardCubit>().load(),
                );
              case DashboardStatus.loaded:
              case DashboardStatus.retryableFailure:
                return _LoadedDashboard(state: state);
            }
          },
        ),
      ),
    );
  }
}

class _LoadedDashboard extends StatelessWidget {
  const _LoadedDashboard({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final snapshot = state.snapshot!;
    final formatter = LocaleFormatters(
      Localizations.localeOf(context).languageCode,
    );
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: () => context.read<DashboardCubit>().load(),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (state.status == DashboardStatus.retryableFailure)
            _InfoBanner(
              icon: Icons.cloud_off_rounded,
              message: strings.dashboardRefreshFailed,
            ),
          Text(
            '${strings.hello}, ${snapshot.user.firstName}',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${strings.region}: ${snapshot.user.region}')),
              BlocBuilder<SessionCubit, SessionState>(
                builder: (context, session) => Chip(
                  avatar: Icon(
                    session.status == SessionStatus.unauthenticated
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    size: 18,
                  ),
                  label: Text(
                    session.status == SessionStatus.unauthenticated
                        ? strings.sessionExpired
                        : strings.sessionSafe,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.auto_graph_rounded,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          snapshot.program.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ProgramFact(
                    label: strings.currentWeek,
                    value: formatter.number(snapshot.program.currentWeek),
                  ),
                  const SizedBox(height: 10),
                  _ProgramFact(
                    label: strings.nextDue,
                    value: formatter.date(snapshot.program.nextCheckinDue),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          _PendingTaskCard(program: snapshot.program),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => context.goNamed(AppRoute.history),
            icon: const Icon(Icons.history_rounded),
            label: Text(strings.viewHistory),
          ),
        ],
      ),
    );
  }
}

class _ProgramFact extends StatelessWidget {
  const _ProgramFact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final shouldStack = constraints.maxWidth < 320 || textScale >= 1.4;

        if (shouldStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, softWrap: true),
              const SizedBox(height: 4),
              Text(value, style: valueStyle, softWrap: true),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(label, softWrap: true)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                softWrap: true,
                style: valueStyle,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingTaskCard extends StatelessWidget {
  const _PendingTaskCard({required this.program});
  final Program program;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final pending = program.taskStatus == TaskStatus.pending;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: pending ? scheme.primary : scheme.secondaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: pending
            ? () => context.goNamed(
                AppRoute.checkIn,
                queryParameters: const {'source': 'dashboard'},
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Icon(
                pending ? Icons.assignment_rounded : Icons.task_alt_rounded,
                color: pending ? scheme.onPrimary : scheme.onSecondaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  pending ? strings.pendingTask : strings.submitted,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: pending
                        ? scheme.onPrimary
                        : scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (pending)
                Icon(Icons.arrow_forward_rounded, color: scheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline_rounded, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ),
      ),
    );
  }
}

class _LocaleToggle extends StatelessWidget {
  const _LocaleToggle();

  @override
  Widget build(BuildContext context) {
    final current = Localizations.localeOf(context).languageCode;
    return SegmentedButton<String>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: 'en', label: Text('EN')),
        ButtonSegment(value: 'de', label: Text('DE')),
      ],
      selected: {current == 'de' ? 'de' : 'en'},
      onSelectionChanged: (selected) =>
          context.read<LocaleCubit>().setLocale(Locale(selected.first)),
    );
  }
}
