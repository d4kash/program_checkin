import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:health_checkin/app/localization/app_localizations.dart';
import 'package:health_checkin/app/router.dart';
import 'package:health_checkin/core/formatting/locale_formatters.dart';
import 'package:health_checkin/features/history/presentation/history_cubit.dart';
import 'package:health_checkin/features/program/domain/models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.history),
        actions: [
          IconButton(
            onPressed: () => context.goNamed(AppRoute.dashboard),
            icon: const Icon(Icons.dashboard_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(
          AppRoute.checkIn,
          queryParameters: const {'source': 'history'},
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.checkIn),
      ),
      body: SafeArea(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            switch (state.status) {
              case HistoryStatus.initial:
              case HistoryStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case HistoryStatus.empty:
                return Center(child: Text(strings.emptyDashboard));
              case HistoryStatus.error:
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(state.failure?.safeMessage ?? 'Error'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: context.read<HistoryCubit>().load,
                          child: Text(strings.retry),
                        ),
                      ],
                    ),
                  ),
                );
              case HistoryStatus.loaded:
                return _HistoryList(entries: state.entries);
            }
          },
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.entries});
  final List<CheckInEntry> entries;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          strings.recentProgress,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.trend,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 140,
                  child: _TrendPainterView(entries: entries),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryTile(entry: entry),
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final CheckInEntry entry;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final formatter = LocaleFormatters(
      Localizations.localeOf(context).languageCode,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              child: Text(
                entry.progressValue == null
                    ? '–'
                    : formatter.progress(
                        entry.progressValue,
                        missing: strings.noValue,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatter.date(entry.date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${strings.adherence}: ${strings.adherenceLabel(entry.adherence.wireValue)}',
                  ),
                  Text(
                    '${strings.wellbeing}: ${strings.wellbeingLabel(entry.wellbeing.wireValue)}',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendPainterView extends StatelessWidget {
  const _TrendPainterView({required this.entries});
  final List<CheckInEntry> entries;

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    return CustomPaint(
      painter: _TrendPainter(sorted, Theme.of(context).colorScheme),
      child: const SizedBox.expand(),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.entries, this.scheme);
  final List<CheckInEntry> entries;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    final chart = Rect.fromLTWH(8, 8, size.width - 16, size.height - 16);
    final axisPaint = Paint()
      ..color = scheme.outlineVariant
      ..strokeWidth = 1;
    canvas.drawLine(chart.bottomLeft, chart.bottomRight, axisPaint);
    canvas.drawLine(chart.bottomLeft, chart.topLeft, axisPaint);

    final values = entries
        .where((entry) => entry.progressValue != null)
        .map((entry) => entry.progressValue!)
        .toList();
    if (values.length < 2) return;
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue == minValue ? 1 : maxValue - minValue;
    final points = <Offset>[];
    for (var index = 0; index < entries.length; index++) {
      final value = entries[index].progressValue;
      if (value == null) continue;
      final x = chart.left + (chart.width * index / (entries.length - 1));
      final normalized = (value - minValue) / range;
      final y = chart.bottom - chart.height * normalized;
      points.add(Offset(x, y));
    }
    final linePaint = Paint()
      ..color = scheme.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);
    final dotPaint = Paint()..color = scheme.primary;
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.scheme != scheme;
}
