import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

class RecordListPaginator extends StatelessWidget {
  const RecordListPaginator({
    super.key,
    required this.title,
    required this.subtitle,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final String subtitle;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: hasPrevious ? onPrevious : null,
          icon: Icon(
            Icons.chevron_left_rounded,
            color: hasPrevious
                ? colors.textPrimary
                : colors.textSecondary.withValues(alpha: 0.45),
          ),
        ),

        Column(
          children: [
            CustomTextWidget(
              label: title,
              fontWeight: FontWeight.w700,
              fontSize: context.fontsSize.title,
            ),
            CustomTextWidget(
              label: subtitle,
              fontSize: context.fontsSize.caption,
              color: colors.textSecondary,
            ),
          ],
        ),

        IconButton(
          onPressed: hasNext ? onNext : null,
          icon: Icon(
            Icons.chevron_right_rounded,
            color: hasNext
                ? colors.textPrimary
                : colors.textSecondary.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    this.onTap,
    this.color,
  });

  final IAerobics activity;
  final VoidCallback? onTap;
  final Color? color;

  // ───────── Configuración por tipo ─────────

  FaIconData get _icon => switch (activity) {
    Walk() => FontAwesomeIcons.personWalking,
    Running() => FontAwesomeIcons.personRunning,
    Cycling() => FontAwesomeIcons.personBiking,
    _ => FontAwesomeIcons.dumbbell,
  };

  String get _label => switch (activity) {
    Walk() => 'Caminata',
    Running() => 'Carrera',
    Cycling() => 'Ciclismo',
    _ => 'Actividad',
  };

  /// Estadísticas específicas del tipo, después de distancia y duración.
  List<_StatData> get _extraStats {
    final a = activity;
    return switch (a) {
      Walk() => [
        _StatData(FontAwesomeIcons.shoePrints, '${a.steps ?? 0} pasos'),
      ],
      Running() => [
        _StatData(FontAwesomeIcons.gaugeHigh, _formatPace(a.avgPace)),
      ],
      Cycling() => [
        _StatData(
          FontAwesomeIcons.gaugeHigh,
          '${((a.avgSpeed ?? 0) * 3.6).toStringAsFixed(1)} km/h',
        ),
      ],
      _ => const [],
    };
  }

  /// avgPace está en min/km (ej. 5.5 -> 5:30 /km).
  String _formatPace(double? pace) {
    if (pace == null || pace <= 0) return '--:-- /km';
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    // Evita "5:60" cuando el redondeo sube a 60.
    final m = seconds == 60 ? minutes + 1 : minutes;
    final s = seconds == 60 ? 0 : seconds;
    return '$m:${s.toString().padLeft(2, '0')} /km';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final textTheme = Theme.of(context).textTheme;

    final stats = <_StatData>[
      _StatData(
        FontAwesomeIcons.rulerHorizontal,
        '${((activity.distance ?? 0) / 1000).toStringAsFixed(2)} km',
      ),
      _StatData(
        FontAwesomeIcons.stopwatch,
        formatDuration(activity.duration ?? Duration.zero),
      ),
      ..._extraStats,
    ];

    return Material(
      color: color ?? colors.surface,
      borderRadius: BorderRadius.circular(spacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(spacing.radiusLg),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(spacing.sm),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  _icon,
                  color: colors.secondary,
                  size: context.iconSize.md,
                ),
              ),
              SizedBox(width: spacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label,
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatDateWithWord(activity.registeredAt!),
                      style: textTheme.titleSmall?.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Wrap(
                      spacing: spacing.md,
                      runSpacing: spacing.xs,
                      children: [
                        for (final s in stats)
                          _Stat(icon: s.icon, text: s.text),
                      ],
                    ),
                  ],
                ),
              ),

              if (onTap != null)
                Icon(Icons.chevron_right, color: Theme.of(context).hintColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatData {
  final FaIconData icon;
  final String text;
  const _StatData(this.icon, this.text);
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.text});

  final FaIconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final hint = Theme.of(context).hintColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(icon, size: 14, color: context.colors.secondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: hint),
        ),
      ],
    );
  }
}
