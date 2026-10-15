import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/cycling_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/running_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/get_all_exercise.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/anthropometrics/anthro_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/exercise/cycling/cycling_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/exercise/running/running_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/records/exercise/walk/walk_records_page.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/graphs.dart';

enum _ActivityKind { all, walk, running, cycling }

enum _ProgressPeriod { week, month, year, total }

extension on _ActivityKind {
  String get label => switch (this) {
    _ActivityKind.all => 'Todas',
    _ActivityKind.walk => 'Caminata',
    _ActivityKind.running => 'Carrera',
    _ActivityKind.cycling => 'Ciclismo',
  };

  IconData get icon => switch (this) {
    _ActivityKind.all => Icons.auto_graph_rounded,
    _ActivityKind.walk => Icons.directions_walk_rounded,
    _ActivityKind.running => Icons.directions_run_rounded,
    _ActivityKind.cycling => Icons.directions_bike_rounded,
  };

  Color color(BuildContext context) => switch (this) {
    _ActivityKind.all => context.colors.secondary,
    _ActivityKind.walk => context.colors.primary,
    _ActivityKind.running => context.colors.tertiary,
    _ActivityKind.cycling => context.colors.success,
  };
}

extension on _ProgressPeriod {
  String get label => switch (this) {
    _ProgressPeriod.week => 'Semana',
    _ProgressPeriod.month => 'Mes',
    _ProgressPeriod.year => 'Año',
    _ProgressPeriod.total => 'Total',
  };
}

class _ActivityEntry {
  const _ActivityEntry({required this.kind, required this.activity});

  final _ActivityKind kind;
  final IAerobics activity;

  DateTime get date => activity.registeredAt ?? DateTime(1970);
  Duration get duration => activity.duration ?? Duration.zero;
  double get distanceKm => (activity.distance ?? 0) / 1000;
  double get calories => activity.caloriesBurned ?? 0;
  double get pace => activity.avgPace ?? 0;
}

class _ProgressSnapshot {
  const _ProgressSnapshot(this.entries);

  final List<_ActivityEntry> entries;
}

class MainProgressPage extends StatefulWidget {
  const MainProgressPage({super.key});

  @override
  State<MainProgressPage> createState() => _MainProgressPageState();
}

class _MainProgressPageState extends State<MainProgressPage> {
  late Future<_ProgressSnapshot> _snapshot;
  _ActivityKind _filter = _ActivityKind.all;

  @override
  void initState() {
    super.initState();
    _snapshot = _loadProgress();
  }

  Future<_ProgressSnapshot> _loadProgress() async {
    final session = CurrentUserSession();
    final results = await Future.wait<List<IPhysicalActivity>?>([
      GetAllExerciseUseCase(WalkRepo(), session).execute(),
      GetAllExerciseUseCase(RunningRepo(), session).execute(),
      GetAllExerciseUseCase(CyclingRepo(), session).execute(),
    ]);

    final entries = <_ActivityEntry>[
      ...(results[0] ?? const <IPhysicalActivity>[]).whereType<Walk>().map(
        (activity) =>
            _ActivityEntry(kind: _ActivityKind.walk, activity: activity),
      ),
      ...(results[1] ?? const <IPhysicalActivity>[]).whereType<Running>().map(
        (activity) =>
            _ActivityEntry(kind: _ActivityKind.running, activity: activity),
      ),
      ...(results[2] ?? const <IPhysicalActivity>[]).whereType<Cycling>().map(
        (activity) =>
            _ActivityEntry(kind: _ActivityKind.cycling, activity: activity),
      ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return _ProgressSnapshot(entries);
  }

  Future<void> _refresh() async {
    setState(() => _snapshot = _loadProgress());
    await _snapshot;
  }

  void _openStatistics(List<_ActivityEntry> entries) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _ActivityStatisticsPage(entries: entries, initialKind: _filter),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<_ProgressSnapshot>(
          future: _snapshot,
          builder: (context, state) {
            if (state.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.hasError) return _ProgressError(onRetry: _refresh);

            final allEntries = state.data?.entries ?? const <_ActivityEntry>[];
            final visibleEntries = _filter == _ActivityKind.all
                ? allEntries
                : allEntries.where((entry) => entry.kind == _filter).toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProgressHeader(
                      onStatistics: () => _openStatistics(allEntries),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _ActivityFilterBar(
                      value: _filter,
                      onChanged: (value) => setState(() => _filter = value),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _OverviewStrip(entries: visibleEntries),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.spacing.md,
                        context.spacing.lg,
                        context.spacing.md,
                        context.spacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Registro de actividades',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _openStatistics(allEntries),
                            icon: const Icon(Icons.bar_chart_rounded),
                            label: const Text('Estadísticas'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (visibleEntries.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyActivities())
                  else
                    ..._buildMonthSections(visibleEntries),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.spacing.md,
                        context.spacing.lg,
                        context.spacing.md,
                        context.spacing.xxl,
                      ),
                      child: _BodyMeasurementsCard(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AnthroRecordsPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildMonthSections(List<_ActivityEntry> entries) {
    final groups = <DateTime, List<_ActivityEntry>>{};
    for (final entry in entries) {
      final key = DateTime(entry.date.year, entry.date.month);
      groups.putIfAbsent(key, () => <_ActivityEntry>[]).add(entry);
    }
    return groups.entries
        .map(
          (group) => SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                context.spacing.md,
                context.spacing.sm,
                context.spacing.md,
                context.spacing.md,
              ),
              child: _MonthActivitySection(
                month: group.key,
                entries: group.value,
                onOpen: _openActivity,
              ),
            ),
          ),
        )
        .toList();
  }

  void _openActivity(_ActivityEntry entry) {
    final page = switch (entry.kind) {
      _ActivityKind.walk => WalkRecordsPage(
        initialActivityId: entry.activity.activityID,
      ),
      _ActivityKind.running => RunningRecordsPage(
        initialActivityId: entry.activity.activityID,
      ),
      _ActivityKind.cycling => CyclingRecordsPage(
        initialActivityId: entry.activity.activityID,
      ),
      _ActivityKind.all => const SizedBox.shrink(),
    };
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.onStatistics});
  final VoidCallback onStatistics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.md,
        context.spacing.sm,
        context.spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu historial de movimiento, en un solo lugar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onStatistics,
            tooltip: 'Ver estadísticas',
            icon: const Icon(Icons.query_stats_rounded),
          ),
        ],
      ),
    );
  }
}

class _ActivityFilterBar extends StatelessWidget {
  const _ActivityFilterBar({required this.value, required this.onChanged});
  final _ActivityKind value;
  final ValueChanged<_ActivityKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: _ActivityKind.values.length,
        separatorBuilder: (_, _) => SizedBox(width: context.spacing.sm),
        itemBuilder: (context, index) {
          final kind = _ActivityKind.values[index];
          return ChoiceChip(
            selected: kind == value,
            onSelected: (_) => onChanged(kind),
            avatar: Icon(kind.icon, size: 18),
            label: Text(kind.label),
          );
        },
      ),
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  const _OverviewStrip({required this.entries});
  final List<_ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final distance = entries.fold<double>(
      0,
      (sum, item) => sum + item.distanceKm,
    );
    final duration = entries.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );
    final calories = entries.fold<double>(
      0,
      (sum, item) => sum + item.calories,
    );
    return Container(
      margin: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.sm,
        context.spacing.md,
        0,
      ),
      padding: EdgeInsets.all(context.spacing.md),
      decoration: BoxDecoration(
        color: context.colors.secondaryContainer,
        borderRadius: BorderRadius.circular(context.spacing.radiusLg),
      ),
      child: Row(
        children: [
          _SummaryValue(
            value: _formatDurationCompact(duration),
            label: 'tiempo',
          ),
          _VerticalDivider(color: context.colors.onSecondaryContainer),
          _SummaryValue(value: entries.length.toString(), label: 'sesiones'),
          _VerticalDivider(color: context.colors.onSecondaryContainer),
          _SummaryValue(value: distance.toStringAsFixed(1), label: 'km'),
          _VerticalDivider(color: context.colors.onSecondaryContainer),
          _SummaryValue(value: calories.round().toString(), label: 'kcal'),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.fade,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: color.withValues(alpha: .16));
}

class _MonthActivitySection extends StatelessWidget {
  const _MonthActivitySection({
    required this.month,
    required this.entries,
    required this.onOpen,
  });
  final DateTime month;
  final List<_ActivityEntry> entries;
  final ValueChanged<_ActivityEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final distance = entries.fold<double>(
      0,
      (sum, item) => sum + item.distanceKm,
    );
    final duration = entries.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );
    final calories = entries.fold<double>(
      0,
      (sum, item) => sum + item.calories,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.md,
              context.spacing.md,
              context.spacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthName(month.month).toUpperCase()} DE ${month.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  '${distance.toStringAsFixed(2)} km  •  ${_formatDurationCompact(duration)}  •  ${entries.length} ${entries.length == 1 ? 'sesión' : 'sesiones'}  •  ${calories.round()} kcal',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var index = 0; index < entries.length; index++) ...[
            _ActivityRow(
              entry: entries[index],
              onTap: () => onOpen(entries[index]),
            ),
            if (index != entries.length - 1)
              Divider(height: 1, indent: 76, endIndent: context.spacing.md),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.onTap});
  final _ActivityEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = entry.kind.color(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(context.spacing.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(
                entry.kind.icon,
                color: context.colors.foregroundFor(color),
              ),
            ),
            SizedBox(width: context.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.kind.label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Text(
                        _formatDate(entry.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: _InlineMetric(
                          value: '${entry.distanceKm.toStringAsFixed(2)} km',
                          emphasized: true,
                        ),
                      ),
                      Expanded(
                        child: _InlineMetric(
                          value: _formatClock(entry.duration),
                        ),
                      ),
                      Expanded(
                        child: _InlineMetric(
                          value: entry.pace > 0
                              ? '${_formatPace(entry.pace)} /km'
                              : '${entry.calories.round()} kcal',
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: context.spacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.value,
    this.emphasized = false,
    this.alignEnd = false,
  });
  final String value;
  final bool emphasized;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: emphasized
          ? Theme.of(context).textTheme.titleMedium
          : Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
    );
  }
}

class _BodyMeasurementsCard extends StatelessWidget {
  const _BodyMeasurementsCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(
          horizontal: context.spacing.md,
          vertical: context.spacing.sm,
        ),
        leading: CircleAvatar(
          backgroundColor: context.colors.tertiaryContainer,
          foregroundColor: context.colors.onTertiaryContainer,
          child: const Icon(Icons.accessibility_new_rounded),
        ),
        title: const Text('Medidas corporales'),
        subtitle: const Text('Peso, estatura y composición corporal'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _EmptyActivities extends StatelessWidget {
  const _EmptyActivities();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(context.spacing.lg),
      child: Column(
        children: [
          Icon(
            Icons.route_rounded,
            size: 54,
            color: context.colors.textSecondary,
          ),
          SizedBox(height: context.spacing.sm),
          Text(
            'Aún no hay actividades',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Cuando termines una sesión, aparecerá aquí con su distancia, tiempo y ritmo.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressError extends StatelessWidget {
  const _ProgressError({required this.onRetry});
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_problem_rounded,
              size: 48,
              color: context.colors.danger,
            ),
            SizedBox(height: context.spacing.md),
            Text(
              'No pudimos cargar tu progreso',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: context.spacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityStatisticsPage extends StatefulWidget {
  const _ActivityStatisticsPage({
    required this.entries,
    required this.initialKind,
  });
  final List<_ActivityEntry> entries;
  final _ActivityKind initialKind;

  @override
  State<_ActivityStatisticsPage> createState() =>
      _ActivityStatisticsPageState();
}

class _ActivityStatisticsPageState extends State<_ActivityStatisticsPage> {
  late _ActivityKind _kind;
  _ProgressPeriod _period = _ProgressPeriod.week;
  DateTime _anchor = DateTime.now();

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    if (widget.entries.isNotEmpty) _anchor = widget.entries.first.date;
  }

  List<_ActivityEntry> get _kindEntries => _kind == _ActivityKind.all
      ? widget.entries
      : widget.entries.where((entry) => entry.kind == _kind).toList();

  List<_ActivityEntry> get _visibleEntries => _kindEntries
      .where((entry) => _isInPeriod(entry.date, _period, _anchor))
      .toList();

  void _movePeriod(int direction) {
    if (_period == _ProgressPeriod.total) return;
    setState(() {
      _anchor = switch (_period) {
        _ProgressPeriod.week => _anchor.add(Duration(days: 7 * direction)),
        _ProgressPeriod.month => DateTime(
          _anchor.year,
          _anchor.month + direction,
          1,
        ),
        _ProgressPeriod.year => DateTime(_anchor.year + direction, 1, 1),
        _ProgressPeriod.total => _anchor,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries;
    final duration = entries.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );
    final calories = entries.fold<double>(
      0,
      (sum, item) => sum + item.calories,
    );
    final distance = entries.fold<double>(
      0,
      (sum, item) => sum + item.distanceKm,
    );
    final series = _chartSeries(entries, _period, _anchor);
    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<_ActivityKind>(
            value: _kind,
            borderRadius: BorderRadius.circular(context.spacing.radiusLg),
            items: _ActivityKind.values
                .map(
                  (kind) => DropdownMenuItem(
                    value: kind,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(kind.icon, size: 19, color: kind.color(context)),
                        const SizedBox(width: 8),
                        Text(kind.label),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (kind) {
              if (kind != null) setState(() => _kind = kind);
            },
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: context.spacing.xxl),
        children: [
          _PeriodTabs(
            value: _period,
            onChanged: (period) => setState(() => _period = period),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
            child: Row(
              children: [
                IconButton(
                  onPressed: _period == _ProgressPeriod.total
                      ? null
                      : () => _movePeriod(-1),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    _periodTitle(_period, _anchor, _kindEntries),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: _period == _ProgressPeriod.total
                      ? null
                      : () => _movePeriod(1),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.lg,
              context.spacing.md,
              context.spacing.lg,
              0,
            ),
            child: Column(
              children: [
                Text(
                  'Duración',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDurationLarge(duration),
                  style: Theme.of(context).textTheme.displayLarge,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.lg,
              context.spacing.md,
              0,
            ),
            child: CustomDataChart(
              values: series.values,
              times: series.labels,
              type: ChartType.bar,
              height: 230,
              grid: true,
              fill: true,
              maxPoints: 16,
              maxLabels: 12,
              tooltipLabelBuilder: (value, time) =>
                  '$time: ${_formatMinutes(value.toDouble())}',
            ),
          ),
          Padding(
            padding: EdgeInsets.all(context.spacing.md),
            child: _StatisticsMetrics(
              duration: duration,
              sessions: entries.length,
              distance: distance,
              calories: calories,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.spacing.md,
              context.spacing.sm,
              context.spacing.md,
              context.spacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Desglose',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  _periodTitle(_period, _anchor, _kindEntries),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.md),
            child: _ActivityBreakdown(entries: entries),
          ),
        ],
      ),
    );
  }
}

class _PeriodTabs extends StatelessWidget {
  const _PeriodTabs({required this.value, required this.onChanged});
  final _ProgressPeriod value;
  final ValueChanged<_ProgressPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.spacing.md,
        context.spacing.md,
        context.spacing.md,
        context.spacing.sm,
      ),
      child: SegmentedButton<_ProgressPeriod>(
        segments: _ProgressPeriod.values
            .map(
              (period) =>
                  ButtonSegment(value: period, label: Text(period.label)),
            )
            .toList(),
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _StatisticsMetrics extends StatelessWidget {
  const _StatisticsMetrics({
    required this.duration,
    required this.sessions,
    required this.distance,
    required this.calories,
  });
  final Duration duration;
  final int sessions;
  final double distance;
  final double calories;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        label: 'Duración',
        value: _formatDurationHours(duration),
        color: context.colors.secondary,
      ),
      (
        label: 'Sesiones',
        value: sessions.toString(),
        color: context.colors.surfaceMuted,
      ),
      (
        label: 'Distancia',
        value: '${distance.toStringAsFixed(1)} km',
        color: context.colors.surfaceMuted,
      ),
      (
        label: 'Calorías',
        value: '${calories.round()} kcal',
        color: context.colors.surfaceMuted,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - context.spacing.sm) / 2;
        return Wrap(
          spacing: context.spacing.sm,
          runSpacing: context.spacing.sm,
          children: [
            for (final metric in metrics)
              Container(
                width: width,
                padding: EdgeInsets.all(context.spacing.md),
                decoration: BoxDecoration(
                  color: metric.color,
                  borderRadius: BorderRadius.circular(context.spacing.radiusLg),
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: .65),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.value,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ActivityBreakdown extends StatelessWidget {
  const _ActivityBreakdown({required this.entries});
  final List<_ActivityEntry> entries;

  @override
  Widget build(BuildContext context) {
    final totalSeconds = entries.fold<int>(
      0,
      (sum, item) => sum + item.duration.inSeconds,
    );
    final rows = <({_ActivityKind kind, Duration duration, int sessions})>[];
    for (final kind in _ActivityKind.values.where(
      (kind) => kind != _ActivityKind.all,
    )) {
      final matches = entries.where((entry) => entry.kind == kind).toList();
      if (matches.isEmpty) continue;
      rows.add((
        kind: kind,
        duration: matches.fold<Duration>(
          Duration.zero,
          (sum, item) => sum + item.duration,
        ),
        sessions: matches.length,
      ));
    }
    if (rows.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(context.spacing.lg),
          child: const Center(child: Text('No hay actividad en este periodo')),
        ),
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            Builder(
              builder: (context) {
                final row = rows[index];
                final percentage = totalSeconds == 0
                    ? 0.0
                    : row.duration.inSeconds / totalSeconds;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: row.kind.color(context),
                    foregroundColor: context.colors.foregroundFor(
                      row.kind.color(context),
                    ),
                    child: Icon(row.kind.icon),
                  ),
                  title: Text(row.kind.label),
                  subtitle: Text(
                    '${row.sessions} ${row.sessions == 1 ? 'sesión' : 'sesiones'}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatDurationHours(row.duration),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
            if (index != rows.length - 1)
              Divider(height: 1, indent: 72, endIndent: context.spacing.md),
          ],
        ],
      ),
    );
  }
}

({List<num> values, List<String> labels}) _chartSeries(
  List<_ActivityEntry> entries,
  _ProgressPeriod period,
  DateTime anchor,
) {
  late int bucketCount;
  late int Function(DateTime date) bucketFor;
  late String Function(int index) labelFor;
  switch (period) {
    case _ProgressPeriod.week:
      final start = _startOfWeek(anchor);
      bucketCount = 7;
      bucketFor = (date) => _dateOnly(date).difference(start).inDays;
      labelFor = (index) =>
          const ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][index];
      break;
    case _ProgressPeriod.month:
      bucketCount = DateTime(anchor.year, anchor.month + 1, 0).day;
      bucketFor = (date) => date.day - 1;
      labelFor = (index) => '${index + 1}';
      break;
    case _ProgressPeriod.year:
      bucketCount = 12;
      bucketFor = (date) => date.month - 1;
      labelFor = (index) => _monthName(index + 1).substring(0, 3);
      break;
    case _ProgressPeriod.total:
      final dates = entries.map((entry) => entry.date.year);
      final firstYear = dates.isEmpty ? anchor.year : dates.reduce(math.min);
      final lastYear = dates.isEmpty ? anchor.year : dates.reduce(math.max);
      bucketCount = lastYear - firstYear + 1;
      bucketFor = (date) => date.year - firstYear;
      labelFor = (index) => '${firstYear + index}';
      break;
  }
  final values = List<num>.filled(bucketCount, 0);
  for (final entry in entries) {
    final bucket = bucketFor(entry.date);
    if (bucket >= 0 && bucket < values.length) {
      values[bucket] += entry.duration.inSeconds / 60;
    }
  }
  return (values: values, labels: List<String>.generate(bucketCount, labelFor));
}

bool _isInPeriod(DateTime date, _ProgressPeriod period, DateTime anchor) =>
    switch (period) {
      _ProgressPeriod.week =>
        !date.isBefore(_startOfWeek(anchor)) &&
            date.isBefore(_startOfWeek(anchor).add(const Duration(days: 7))),
      _ProgressPeriod.month =>
        date.year == anchor.year && date.month == anchor.month,
      _ProgressPeriod.year => date.year == anchor.year,
      _ProgressPeriod.total => true,
    };

DateTime _startOfWeek(DateTime date) =>
    _dateOnly(date).subtract(Duration(days: date.weekday - 1));
DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _periodTitle(
  _ProgressPeriod period,
  DateTime anchor,
  List<_ActivityEntry> entries,
) => switch (period) {
  _ProgressPeriod.week =>
    '${_startOfWeek(anchor).day}–${_startOfWeek(anchor).add(const Duration(days: 6)).day} de ${_monthName(_startOfWeek(anchor).add(const Duration(days: 6)).month).toLowerCase()}',
  _ProgressPeriod.month => '${_monthName(anchor.month)} ${anchor.year}',
  _ProgressPeriod.year => '${anchor.year}',
  _ProgressPeriod.total =>
    entries.isEmpty
        ? 'Todo el historial'
        : '${entries.map((entry) => entry.date.year).reduce(math.min)}–${entries.map((entry) => entry.date.year).reduce(math.max)}',
};

String _monthName(int month) => const [
  'Enero',
  'Febrero',
  'Marzo',
  'Abril',
  'Mayo',
  'Junio',
  'Julio',
  'Agosto',
  'Septiembre',
  'Octubre',
  'Noviembre',
  'Diciembre',
][month - 1];

String _formatDate(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.day} ${_monthName(date.month).substring(0, 3).toLowerCase()} · $hour:$minute';
}

String _formatClock(Duration value) {
  final hours = value.inHours.toString().padLeft(2, '0');
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatDurationCompact(Duration value) {
  if (value.inHours > 0) {
    final decimalHours = value.inMinutes / 60;
    return '${decimalHours.toStringAsFixed(decimalHours >= 10 ? 0 : 1)} h';
  }
  return '${value.inMinutes} min';
}

String _formatDurationHours(Duration value) {
  final hours = value.inMinutes / 60;
  return '${hours.toStringAsFixed(hours >= 10 ? 1 : 2)} h';
}

String _formatDurationLarge(Duration value) => value.inMinutes >= 60
    ? _formatDurationHours(value)
    : '${value.inMinutes} min';
String _formatMinutes(double minutes) => minutes >= 60
    ? '${(minutes / 60).toStringAsFixed(1)} h'
    : '${minutes.round()} min';

String _formatPace(double pace) {
  final minutes = pace.floor();
  final seconds = ((pace - minutes) * 60).round().clamp(0, 59);
  return "$minutes'${seconds.toString().padLeft(2, '0')}\"";
}
