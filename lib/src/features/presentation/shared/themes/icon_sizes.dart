import 'package:flutter/material.dart';

@immutable
class AppIconSizes extends ThemeExtension<AppIconSizes> {
  const AppIconSizes({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
    required this.mega,
  });

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;
  final double mega;

  static const standard = AppIconSizes(
    xs: 10,
    sm: 15,
    md: 20,
    lg: 25,
    xl: 30,
    xxl: 75,
    mega: 150,
  );

  @override
  AppIconSizes copyWith({
    double? xs,
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xxl,
    double? mega,
  }) {
    return AppIconSizes(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xxl: xxl ?? this.xxl,
      mega: mega ?? this.mega,
    );
  }

  @override
  AppIconSizes lerp(covariant AppIconSizes? other, double t) {
    if (other == null) return this;

    return AppIconSizes(
      xs: _lerp(xs, other.xs, t),
      sm: _lerp(sm, other.sm, t),
      md: _lerp(md, other.md, t),
      lg: _lerp(lg, other.lg, t),
      xl: _lerp(xl, other.xl, t),
      xxl: _lerp(xxl, other.xxl, t),
      mega: _lerp(mega, other.mega, t),
    );
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

extension AppIconSizesContext on BuildContext {
  AppIconSizes get iconSize {
    return Theme.of(this).extension<AppIconSizes>() ?? AppIconSizes.standard;
  }
}
