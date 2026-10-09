import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/info.dart';

enum AnthroStatus { low, normal, high }

class AnthroValueIndicator extends StatelessWidget {
  const AnthroValueIndicator({
    super.key,
    required this.field,
    required this.value,
    required this.range,
    this.lowColor,
    this.highColor,
    // this.normalColor,
    this.pWidth,
  });

  final String field;
  final num value;
  final ({num min, num max}) range;
  final Color? lowColor;
  final Color? highColor;
  // final Color? normalColor;
  final double? pWidth;

  AnthroStatus get _status {
    if (value < range.min) return AnthroStatus.low;
    if (value > range.max) return AnthroStatus.high;
    return AnthroStatus
        .normal; // shouldn't occur if only alert values are passed in
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;

    final status = _status;

    final statusColor = switch (status) {
      AnthroStatus.low => lowColor ?? context.colors.low,
      AnthroStatus.high => highColor ?? context.colors.danger,
      AnthroStatus.normal => colors.success,
    };

    final statusIcon = switch (status) {
      AnthroStatus.low => Icons.arrow_downward,
      AnthroStatus.high => Icons.arrow_upward,
      AnthroStatus.normal => Icons.check,
    };

    return Container(
      width: pWidth ?? double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(spacing.radiusMd),
        border: Border.all(color: statusColor.withAlpha(150)),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomTextWidget(
            label: field,
            fontSize: context.fontsSize.caption,
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          Row(
            children: [
              Icon(statusIcon, size: context.iconSize.sm, color: statusColor),
              SizedBox(width: spacing.xs),
              CustomTextWidget(
                label: value.toStringAsFixed(1),
                fontSize: context.fontsSize.body,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
