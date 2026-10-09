import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:salud_ulv_app/src/core/models/exercise_summaries.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/helpers/fomaters.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

// class GridDataTile extends StatelessWidget {
//   const GridDataTile({
//     super.key,
//     required this.icon,
//     required this.label,
//     required this.amount,
//     required this.sufix,
//   });

//   final FaIconData icon;
//   final String label;
//   final String sufix;
//   final double amount;

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final spacing = context.spacing;

//     return Material(
//       color: colors.surface,
//       borderRadius: BorderRadius.circular(spacing.radiusLg),
//       child: Padding(
//             padding: EdgeInsets.all(spacing.md),

//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisAlignment: MainAxisAlignment.end,

//               children: [
//                 Row(
//                   children: [
//                     FaIcon(icon, color: colors.primary, size: 20),
//                     SizedBox(width: spacing.sm),
//                     Text(
//                       label,
//                       style: TextStyle(
//                         color: colors.textPrimary,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ],
//                 ),

//                 Text(
//                   '${amount.toStringAsFixed(2)} $sufix',
//                   style: TextStyle(
//                     color: colors.textPrimary,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 15,
//                   ),
//                 ),

//               ],
//             ),
//           ),
//     );
//   }
// }

// class GridDataTile extends StatelessWidget {
//   const GridDataTile({
//     super.key,
//     required this.icon,
//     required this.label,
//     required this.data,
//     required this.sufix,
//   });

//   final FaIconData icon;
//   final String label;
//   final String sufix;
//   final String data;

//   @override
//   Widget build(BuildContext context) {
//     final colors = context.colors;
//     final spacing = context.spacing;

//     return Material(
//       color: colors.surface,
//       borderRadius: BorderRadius.circular(spacing.radiusLg),
//       child: Padding(
//         padding: EdgeInsets.all(spacing.md),
//         child: Column(
//           // crossAxisAlignment: CrossAxisAlignment.start,
//           // mainAxisSize: MainAxisSize.min,
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             Row(
//               children: [
//                 FaIcon(icon, color: colors.primary, size: 20),
//                 SizedBox(width: spacing.sm),
//                 Expanded(
//                   child: Text(
//                     label,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: colors.textPrimary,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 15,
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 4),

//             FittedBox(
//               fit: BoxFit.scaleDown,
//               alignment: Alignment.centerLeft,
//               child: Text(
//                 '$data $sufix',
//                 maxLines: 2,
//                 style: TextStyle(
//                   color: colors.textPrimary,
//                   fontWeight: FontWeight.w600,
//                   fontSize: 15,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class GridDataTile extends StatelessWidget {
  const GridDataTile({
    super.key,
    this.icon,
    required this.label,
    required this.data,
    this.sufix = '',
    this.color,
    this.iconColor,
    this.width = 150,
    this.height = 90,
  });

  final FaIconData? icon;
  final Color? color;
  final Color? iconColor;
  final String label;
  final String sufix;
  final String data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final innerWidth = (width - spacing.md * 2).clamp(0.0, double.infinity);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: innerWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                FaIcon(
                  icon,
                  color: iconColor ?? colors.secondary,
                  size: context.iconSize.lg,
                ),
                SizedBox(width: spacing.md),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$data $sufix',
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: context.fontsSize.title,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w500,
                        fontSize: context.fontsSize.caption,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridDataTileTrasparent extends StatelessWidget {
  const GridDataTileTrasparent({
    super.key,
    this.icon,
    this.label,
    required this.data,
    this.sufix = '',
    this.iconColor,
    this.width = 150,
    this.height = 110,
  });

  final FaIconData? icon;
  final Color? iconColor;
  final String? label;
  final String sufix;
  final String data;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final innerWidth = (width - spacing.md * 2).clamp(0.0, double.infinity);

    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(spacing.radiusLg),
        // border: Border.all(color: Colors.black),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: innerWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                FaIcon(
                  icon,
                  color: iconColor ?? colors.textPrimary,
                  size: context.iconSize.lg,
                ),
                SizedBox(height: spacing.xxs),
              ],

              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: data,
                      style: TextStyle(
                        color: colors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: context.fontsSize.display,
                      ),
                    ),
                    if (sufix.isNotEmpty)
                      TextSpan(
                        text: ' $sufix',
                        style: TextStyle(
                          color: colors.secondary,
                          fontWeight: FontWeight.w500,
                          fontSize: context.fontsSize.caption,
                        ),
                      ),
                  ],
                ),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: spacing.xs),
              CustomTextWidget(
                label: label ?? '',
                color: colors.textPrimary,
                fontSize: context.fontsSize.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricSummaryCard extends StatelessWidget {
  const MetricSummaryCard({
    super.key,
    required this.label,
    required this.metric,
    this.unit,
    this.titleSuffix,
    this.icon,
    this.color,
    this.backgroundColor,
    this.pWidth,
    this.decimals = 1,
    this.totalDecimals = 0,
    this.averageDecimals = 0,
    this.minDecimals = 0,
    this.maxDecimals = 0,
  });

  final String label;
  final MetricSummary metric;
  final String? unit;

  /// Text appended to the title, e.g. "(hoy)" or "· km".
  final String? titleSuffix;

  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final double? pWidth;

  /// Default decimals for every stat.
  final int decimals;

  /// Optional per-stat overrides. If null, [decimals] is used.
  final int? totalDecimals;
  final int? averageDecimals;
  final int? minDecimals;
  final int? maxDecimals;

  String _fmt(double? value, int? override) {
    if (value == null) return '-';
    final u = unit != null ? ' $unit' : '';
    return '${value.toStringAsFixed(override ?? decimals)}$u';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    if (metric.count == 0) {
      return const SizedBox.shrink();
    }

    final title = titleSuffix != null && titleSuffix!.isNotEmpty
        ? '$label $titleSuffix'
        : label;

    return Container(
      width: pWidth ?? double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        border: Border.all(color: colors.border),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: context.iconSize.sm,
                  color: color ?? colors.secondary,
                ),
                SizedBox(width: spacing.xs),
              ],
              CustomTextWidget(
                label: title,
                fontSize: context.fontsSize.caption,
                color: color ?? colors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricStat(
                title: 'Total',
                value: _fmt(metric.sum, totalDecimals),
              ),
              _MetricStat(
                title: 'Prom.',
                value: _fmt(metric.average, averageDecimals),
              ),
              _MetricStat(title: 'Mín.', value: _fmt(metric.min, minDecimals)),
              _MetricStat(title: 'Máx.', value: _fmt(metric.max, maxDecimals)),
            ],
          ),
        ],
      ),
    );
  }
}

class DurationMetricCard extends StatelessWidget {
  const DurationMetricCard({
    super.key,
    required this.label,
    required this.metric,
    this.titleSuffix,
    this.icon,
    this.color,
    this.backgroundColor,
    this.pWidth,
  });

  final String label;
  final MetricSummary metric;

  /// Text appended to the title, e.g. "(hoy)".
  final String? titleSuffix;

  final IconData? icon;
  final Color? color;
  final Color? backgroundColor;
  final double? pWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    if (metric.count == 0) {
      return const SizedBox.shrink();
    }

    final title = titleSuffix != null && titleSuffix!.isNotEmpty
        ? '$label $titleSuffix'
        : label;

    return Container(
      width: pWidth ?? double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors.surface,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        border: Border.all(color: colors.border),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: context.iconSize.sm,
                  color: color ?? colors.secondary,
                ),
                SizedBox(width: spacing.xs),
              ],
              CustomTextWidget(
                label: title,
                fontSize: context.fontsSize.caption,
                color: color ?? colors.secondary,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricStat(
                title: 'Total',
                value: formatDurationFromSeconds(metric.sum),
              ),
              _MetricStat(
                title: 'Prom.',
                value: formatDurationFromSeconds(metric.average),
              ),
              _MetricStat(
                title: 'Mín.',
                value: formatDurationFromSeconds(metric.min),
              ),
              _MetricStat(
                title: 'Máx.',
                value: formatDurationFromSeconds(metric.max),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricStat extends StatelessWidget {
  const _MetricStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: Column(
        children: [
          CustomTextWidget(
            label: value,
            fontSize: context.fontsSize.body,
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          CustomTextWidget(
            label: title,
            fontSize: context.fontsSize.caption,
            color: colors.textSecondary,
            fontWeight: FontWeight.normal,
          ),
        ],
      ),
    );
  }
}
