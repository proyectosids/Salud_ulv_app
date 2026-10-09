import 'package:flutter/material.dart';

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
  });

  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  static const standard = AppSpacing(
    xxs: 2,
    xs: 4,
    sm: 8,
    md: 16,
    lg: 24,
    xl: 32,
    xxl: 48,
    radiusSm: 4,
    radiusMd: 8,
    radiusLg: 16,
  );

  @override
  AppSpacing copyWith({
    double? xxs,
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
  }) {
    return AppSpacing(
      xxs: xxs ?? this.xxs,
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
    );
  }

  @override
  AppSpacing lerp(covariant AppSpacing? other, double t) {
    if (other == null) return this;

    return AppSpacing(
      xxs: _lerpD(xxs, other.xxs, t),
      xs: _lerpD(xs, other.xs, t),
      sm: _lerpD(sm, other.sm, t),
      md: _lerpD(md, other.md, t),
      lg: _lerpD(lg, other.lg, t),
      xl: _lerpD(xl, other.xl, t),
      xxl: _lerpD(xxl, other.xxl, t),
      radiusSm: _lerpD(radiusSm, other.radiusSm, t),
      radiusMd: _lerpD(radiusMd, other.radiusMd, t),
      radiusLg: _lerpD(radiusLg, other.radiusLg, t),
    );
  }

  static double _lerpD(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

/// Allows access to AppSpacing through BuildContext.
///
/// Example:
/// context.spacing.md
/// context.spacing.lg
/// context.spacing.radiusMd
extension AppSpacingContext on BuildContext {
  AppSpacing get spacing {
    return Theme.of(this).extension<AppSpacing>() ?? AppSpacing.standard;
  }
}
