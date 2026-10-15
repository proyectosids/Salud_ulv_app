// ─────────────────────────────────────────────────────────
// Modelo para stats dinámicos
// ─────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_state.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/data_tiles.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';

class ExerciseStat {
  final IconData icon;
  final String label;
  final String value;

  const ExerciseStat({
    required this.icon,
    required this.label,
    required this.value,
  });
}

// ─────────────────────────────────────────────────────────
// _StatCard
// ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 125,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(context.spacing.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Solo se muestra el círculo del icono si icon no es null.
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: colors.secondary),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.fontsSize.caption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: context.fontsSize.caption - 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Tarjeta de info: recibe TODO por parámetro, sin BlocBuilder
// ─────────────────────────────────────────────────────────

Widget exerciseInfoCard(
  BuildContext context, {
  required String title,
  required IconData icon,
  required String
  statusLabel, // 'Pausado' / 'En progreso' / 'Listo para comenzar'
  required bool isTracking, // controla el puntito verde
  required String time, // ya formateado, ej '02:15'
  required List<ExerciseStat> stats,
}) {
  final colors = context.colors;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: colors.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(24),
      boxShadow: context.shadows.boxShadow,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(color: colors.textPrimary, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isTracking)
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.success,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.success.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        Text(
          time,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),

        if (stats.isNotEmpty) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final stat in stats)
                _StatCard(
                  icon: stat.icon,
                  label: stat.label,
                  value: stat.value,
                ),
            ],
          ),
        ],
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────
// Controles: también reciben el "modo" por parámetro
// ─────────────────────────────────────────────────────────

enum ExerciseControlsMode { initial, tracking, paused }

Widget exerciseControls(
  BuildContext context, {
  required ExerciseControlsMode mode,
  required VoidCallback onStart,
  required VoidCallback onPause,
  required VoidCallback onResume,
  required VoidCallback onDiscard,
  required VoidCallback onSave,
}) {
  return Container(
    padding: EdgeInsets.symmetric(vertical: context.spacing.md),
    decoration: BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      // boxShadow: context.shadows.boxShadow,
    ),
    child: switch (mode) {
      ExerciseControlsMode.initial => Center(
        // child: circleButton(
        //   icon: Icons.play_arrow_rounded,
        //   background: colors.onPrimary,
        //   foreground: colors.onSecondary,
        //   onPressed: onStart,
        //   // size: 80
        // ),
        child: TrackActionButton(
          onPressed: onStart,
          icon: Icons.play_arrow_rounded,
          width: 150,
        ),
      ),
      ExerciseControlsMode.tracking => Center(
        // child: circleButton(
        //   icon: Icons.pause_rounded,
        //   background: colors.onPrimary,
        //   foreground: colors.onSecondary,
        //   onPressed: onPause,
        //   size: 90,
        // ),
        child: TrackActionButton(
          icon: Icons.pause_rounded,
          onPressed: onPause,
          width: 150,
        ),
      ),
      ExerciseControlsMode.paused => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // GestureDetector(
          //   onLongPress: onDiscard,
          //   child: circleButton(
          //     icon: Icons.delete_rounded,
          //     background: colors.danger,
          //     foreground: colors.background,
          //     size: 55,
          //     iconSize: context.iconSize.md,
          //     onPressed: () {},
          //   ),
          // ),
          // // SlideToConfirm(icon: Icons.delete_rounded, onConfirmed: onDiscard),

          // SizedBox(width: context.spacing.md),
          // circleButton(
          //   icon: Icons.play_arrow_rounded,
          //   background: colors.onPrimary,
          //   foreground: colors.onSecondary,
          //   onPressed: onResume,
          // ),
          // SizedBox(width: context.spacing.md),
          // circleButton(
          //   icon: Icons.check_rounded,
          //   background: colors.success,
          //   foreground: colors.background,
          //   size: 55,
          //   iconSize: context.iconSize.md,
          //   onPressed: onSave,
          // ),
          TrackActionButton(
            onPressed: onResume,
            icon: Icons.play_arrow_rounded,
            width: 150,
          ),
          SizedBox(height: context.spacing.md),

          Row(
            mainAxisAlignment: .center,
            mainAxisSize: .max,
            crossAxisAlignment: .center,
            children: [
              SlideToConfirm(onConfirmed: onDiscard, width: 100),
              SizedBox(width: context.spacing.sm),
              TrackActionButton(
                onPressed: onSave,
                icon: Icons.save,
                width: 100,
              ),
            ],
          ),
        ],
      ),
    },
  );
}

class TrackActionButton extends StatelessWidget {
  const TrackActionButton({
    super.key,
    this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.foregroundColor,
    this.height = 56,
    this.width = 100,
  });

  final String? label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? foregroundColor;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bg = color ?? colors.secondary;
    final fg = foregroundColor ?? colors.foregroundFor(bg);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: onPressed == null ? bg.withValues(alpha: 0.4) : bg,
        borderRadius: BorderRadius.circular(height / 2),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(height / 2),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: .center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fg, size: context.iconSize.lg),
                // const SizedBox(width: 8),
              ],
              Flexible(
                child: CustomTextWidget(
                  label: label ?? '',
                  color: fg,
                  fontSize: context.fontsSize.details,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    this.label,
    required this.onConfirmed,
    this.icon = Icons.close_rounded,
    this.color,
    this.height = 50,
    this.threshold = 0.85, // how far to slide (0-1) to count as confirmed
    this.width,
  });

  final String? label;
  final VoidCallback onConfirmed;
  final IconData icon;
  final Color? color;
  final double height;
  final double threshold;
  final double? width;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dx = 0;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = widget.color ?? colors.warning;
    final width = widget.width ?? double.infinity;

    return LayoutBuilder(
      builder: (context, constraints) {
        const pad = 4.0;
        final thumb = widget.height - pad * 2;
        final maxDx = (constraints.maxWidth - thumb - pad * 2).clamp(
          1.0,
          width,
        );
        final progress = (_dx / maxDx).clamp(0.0, 1.0);

        void onEnd() {
          if (progress >= widget.threshold) {
            HapticFeedback.mediumImpact();
            setState(() {
              _dragging = false;
              _dx = maxDx;
            });
            widget.onConfirmed();
            // Reset in case the widget stays on screen
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) setState(() => _dx = 0);
            });
          } else {
            setState(() {
              _dragging = false;
              _dx = 0; // snap back
            });
          }
        }

        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: colors.danger),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Fill that follows the thumb
              AnimatedContainer(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                width: _dx + thumb + pad * 2,
                decoration: BoxDecoration(
                  color: colors.danger.withAlpha(200),
                  borderRadius: BorderRadius.circular(widget.height / 2),
                ),
              ),

              // Label fades as you slide
              Center(
                child: Opacity(
                  opacity: 1 - progress,
                  child: Padding(
                    padding: EdgeInsets.only(left: thumb),
                    child: Text(
                      widget.label ?? '',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Thumb
              AnimatedPositioned(
                duration: _dragging
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                left: pad + _dx,
                child: GestureDetector(
                  onHorizontalDragStart: (_) =>
                      setState(() => _dragging = true),
                  onHorizontalDragUpdate: (d) => setState(
                    () => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx),
                  ),
                  onHorizontalDragEnd: (_) => onEnd(),
                  onHorizontalDragCancel: onEnd,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.icon, color: colors.onWarning),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ExerciseTypeSelector extends StatelessWidget {
  const ExerciseTypeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final ExerciseType selected;
  final ValueChanged<ExerciseType> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        padding: EdgeInsets.all(context.spacing.xs),
        decoration: BoxDecoration(
          color: colors.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(context.spacing.radiusLg),
        ),
        child: Row(
          children: [
            for (final type in ExerciseType.values)
              Expanded(
                child: _TypeItem(
                  type: type,
                  isSelected: type == selected,
                  onTap: enabled ? () => onSelected(type) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeItem extends StatelessWidget {
  const _TypeItem({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final ExerciseType type;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(context.spacing.radiusLg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: context.iconSize.md,
              color: isSelected ? colors.onSecondary : colors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: TextStyle(
                fontSize: context.fontsSize.details,
                fontWeight: FontWeight.w600,
                color: isSelected ? colors.onSecondary : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingSheetContent extends StatelessWidget {
  const TrackingSheetContent({super.key});

  // ───────── Formateadores ─────────

  String _formatSpeedKmh(double? speedMs) {
    if (speedMs == null || !speedMs.isFinite || speedMs < 0) return '--';
    return (speedMs * 3.6).toStringAsFixed(1);
  }

  /// Ritmo en min/km a partir de la velocidad en m/s. "--:--" si casi no hay movimiento.
  String _formatPace(double? speedMs) {
    if (speedMs == null || !speedMs.isFinite || speedMs < 0.5) return '--:--';
    final secPerKm = 1000 / speedMs;
    var minutes = secPerKm ~/ 60;
    var seconds = (secPerKm % 60).round();
    if (seconds == 60) {
      minutes += 1;
      seconds = 0;
    }
    // Ritmos absurdos (> 60 min/km) se consideran sin movimiento.
    if (minutes >= 60) return '--:--';
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Estadísticas secundarias según el tipo de actividad.
  /// La distancia va siempre primero, y luego las propias del deporte.
  List<_TileData> _statsFor(ExerciseTrackingState state) {
    final active = state is ActiveExerciseState ? state : null;

    final hasDistance = active?.distance != null && active!.distance! > 0;
    final distance = hasDistance
        ? (active.distance! / 1000).toStringAsFixed(2)
        : '--';

    final distanceTile = _TileData(
      label: 'Distancia',
      data: distance,
      sufix: hasDistance ? 'km' : '',
    );

    switch (state.selectedType) {
      case ExerciseType.walk:
        return [
          distanceTile,
          _TileData(
            label: 'Pasos',
            data: active?.steps != null ? '${active!.steps}' : '--',
          ),
        ];

      case ExerciseType.running:
      case ExerciseType.indoorRunning:
        final pace = _formatPace(active?.speed);
        return [
          distanceTile,
          _TileData(
            label: 'Ritmo',
            data: pace,
            sufix: pace == '--:--' ? '' : 'min/km',
          ),
        ];

      case ExerciseType.cycling:
        final speed = _formatSpeedKmh(active?.speed);
        return [
          distanceTile,
          _TileData(
            label: 'Velocidad',
            data: speed,
            sufix: speed == '--' ? '' : 'km/h',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final colors = context.colors;
    final bloc = context.read<ExerciseTrackingBloc>();

    return BlocBuilder<ExerciseTrackingBloc, ExerciseTrackingState>(
      builder: (context, state) {
        final hasData = state is ActiveExerciseState;
        final isPaused = state is ExercisePaused;
        final isTracking = state is TrackingExercise;

        final time = hasData ? formatDuration(state.timeElapsed) : '--:--';

        final status = isPaused
            ? 'Pausado'
            : isTracking
            ? 'En progreso'
            : 'Listo para comenzar';

        final stats = _statsFor(state);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- PEEK: timer + main button ----------
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextWidget(
                        label: time,
                        fontSize: context.fontsSize.display,
                        fontWeight: FontWeight.w800,
                      ),
                      CustomTextWidget(
                        label: '${state.selectedType.label} · $status',
                        fontSize: context.fontsSize.caption,
                      ),
                    ],
                  ),
                ),
                if (isTracking)
                  TrackActionButton(
                    icon: Icons.pause_rounded,
                    color: colors.warning,
                    onPressed: () => bloc.add(PauseExerciseEvent()),
                  )
                else if (isPaused)
                  TrackActionButton(
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => bloc.add(ResumeExerciseEvent()),
                  )
                else
                  TrackActionButton(
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => bloc.add(StartExerciseEvent()),
                  ),
              ],
            ),

            SizedBox(height: spacing.md),

            // ---------- EXPANDED: stats dinámicos ----------
            Row(
              children: [
                for (final tile in stats)
                  Expanded(
                    child: GridDataTileTrasparent(
                      data: tile.data,
                      sufix: tile.sufix,
                      label: tile.label,
                    ),
                  ),
              ],
            ),

            // ---------- EXPANDED: save / discard (only when paused) ----------
            if (isPaused) ...[
              SizedBox(height: spacing.md),
              Row(
                children: [
                  Expanded(
                    child: SlideToConfirm(
                      label: 'Desliza para descartar',
                      onConfirmed: () => bloc.add(DiscardExerciseEvent()),
                    ),
                  ),
                  SizedBox(width: spacing.md),
                  TrackActionButton(
                    icon: Icons.save,
                    color: colors.success,
                    onPressed: () => bloc.add(SaveExerciseEvent()),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TileData {
  final String label;
  final String data;
  final String sufix;
  const _TileData({required this.label, required this.data, this.sufix = ''});
}
