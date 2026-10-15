import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_state.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/map.dart';

class ExerciseSummaryPage extends StatelessWidget {
  const ExerciseSummaryPage({
    super.key,
    required this.result,
    required this.routePoints,
  });

  final ExerciseSaved result;
  final List<LatLng> routePoints;

  String get _pace {
    if (result.distance <= 0) return '--:--';
    final seconds = result.duration.inSeconds / (result.distance / 1000);
    final minutes = seconds ~/ 60;
    final remaining = (seconds % 60).round();
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  String get _activityTitle => switch (result.selectedType) {
    ExerciseType.walk => 'Caminata al aire libre',
    ExerciseType.running => 'Carrera al aire libre',
    ExerciseType.indoorRunning => 'Carrera en interiores',
    ExerciseType.cycling => 'Ciclismo al aire libre',
  };

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          title: Text(_activityTitle),
          backgroundColor: context.colors.background,
          surfaceTintColor: Colors.transparent,
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Ruta'),
              Tab(text: 'Ritmo'),
              Tab(text: 'Gráficos'),
              Tab(text: 'Detalles'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RouteSummary(
              result: result,
              routePoints: routePoints,
              pace: _pace,
            ),
            _PaceSummary(result: result, pace: _pace),
            _ChartsSummary(result: result, routePoints: routePoints),
            _DetailsSummary(result: result, pace: _pace),
          ],
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({
    required this.result,
    required this.routePoints,
    required this.pace,
  });

  final ExerciseSaved result;
  final List<LatLng> routePoints;
  final String pace;

  @override
  Widget build(BuildContext context) {
    final controller = MapController();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SizedBox(
            height: 360,
            child: MapWidget(
              mapController: controller,
              startPoint: routePoints.isEmpty ? null : routePoints.first,
              endPoint: routePoints.isEmpty ? null : routePoints.last,
              initialCenter: routePoints.isEmpty ? null : routePoints.first,
              routePoints: routePoints,
              showCurrentLocation: false,
              mapReady: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  fitRouteToScreen(routePoints, controller);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '${(result.distance / 1000).toStringAsFixed(2)} km',
          style: Theme.of(
            context,
          ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          formatDateWithWord(result.completedAt),
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final metrics = <({String label, String value})>[
              (label: 'Duración', value: formatDuration(result.duration)),
              (label: 'Ritmo promedio', value: '$pace /km'),
              (
                label: 'Total quemadas',
                value: '${result.caloriesBurned.round()} kcal',
              ),
              if (result.steps != null)
                (label: 'Pasos', value: '${result.steps}'),
            ];
            final columns = metrics.length == 4 ? 2 : 3;
            final width =
                (constraints.maxWidth - ((columns - 1) * 16)) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 20,
              children: [
                for (final metric in metrics)
                  SizedBox(
                    width: width,
                    child: _Metric(label: metric.label, value: metric.value),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PaceSummary extends StatelessWidget {
  const _PaceSummary({required this.result, required this.pace});

  final ExerciseSaved result;
  final String pace;

  @override
  Widget build(BuildContext context) {
    final wholeKilometers = (result.distance / 1000).floor();
    final remainder = result.distance / 1000 - wholeKilometers;
    final rows = math.max(wholeKilometers, remainder > 0 ? 1 : 0);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: _Metric(label: 'Ritmo promedio', value: '$pace /km'),
            ),
            Expanded(
              child: _Metric(label: 'Más rápido', value: '$pace /km'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'Ritmo por kilómetro',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        if (rows == 0)
          const Text('La actividad fue demasiado corta para generar parciales.')
        else
          for (var index = 0; index < rows; index++)
            _SplitRow(
              kilometer: index + 1,
              pace: pace,
              fraction: index == rows - 1 && remainder > 0 ? remainder : 1,
            ),
      ],
    );
  }
}

class _SplitRow extends StatelessWidget {
  const _SplitRow({
    required this.kilometer,
    required this.pace,
    required this.fraction,
  });
  final int kilometer;
  final String pace;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 36, child: Text('$kilometer')),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.08, 1),
                minHeight: 40,
                backgroundColor: context.colors.surfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(pace, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ChartsSummary extends StatelessWidget {
  const _ChartsSummary({required this.result, required this.routePoints});
  final ExerciseSaved result;
  final List<LatLng> routePoints;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Progreso de la ruta',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: CustomPaint(
            painter: _ProgressChartPainter(
              color: context.colors.secondary,
              gridColor: context.colors.border,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.favorite_border_rounded),
            title: const Text('Frecuencia cardiaca no disponible'),
            subtitle: const Text(
              'Esta sección aparecerá cuando la sesión incluya lecturas válidas de un sensor cardiaco.',
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsSummary extends StatelessWidget {
  const _DetailsSummary({required this.result, required this.pace});
  final ExerciseSaved result;
  final String pace;

  @override
  Widget build(BuildContext context) {
    final speed = result.duration.inSeconds == 0
        ? 0.0
        : (result.distance / 1000) / (result.duration.inSeconds / 3600);
    final items = <(IconData, String, String)>[
      (Icons.timer_outlined, 'Duración', formatDuration(result.duration)),
      (
        Icons.local_fire_department_outlined,
        'Calorías totales',
        '${result.caloriesBurned.round()} kcal',
      ),
      (Icons.speed_rounded, 'Ritmo promedio', '$pace /km'),
      (
        Icons.directions_run_rounded,
        'Velocidad promedio',
        '${speed.toStringAsFixed(2)} km/h',
      ),
      if (result.steps != null)
        (Icons.directions_walk_rounded, 'Pasos', '${result.steps}'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              '${(result.distance / 1000).toStringAsFixed(2)} km',
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          );
        }
        final item = items[index - 1];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: Icon(item.$1, color: context.colors.secondary),
          title: Text(item.$2),
          trailing: Text(
            item.$3,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: context.colors.textSecondary)),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _ProgressChartPainter extends CustomPainter {
  const _ProgressChartPainter({required this.color, required this.gridColor});
  final Color color;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = gridColor.withValues(alpha: 0.45);
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final path = ui.Path()..moveTo(0, size.height);
    for (var i = 0; i <= 24; i++) {
      final x = size.width * i / 24;
      final progress = i / 24;
      final y = size.height * (1 - progress * 0.82) - math.sin(i * 0.8) * 5;
      path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressChartPainter oldDelegate) =>
      color != oldDelegate.color || gridColor != oldDelegate.gridColor;
}
