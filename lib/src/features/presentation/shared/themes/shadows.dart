import 'package:flutter/material.dart';

@immutable
class AppShadows extends ThemeExtension<AppShadows> {
  const AppShadows({required this.color, required this.magnitude});

  final Color color;
  final double magnitude;

  static const standard = AppShadows(color: Color(0x2935566D), magnitude: 5);

  static const dark = AppShadows(color: Color(0x70302116), magnitude: 4);

  List<BoxShadow> get smBoxShadow => [
    BoxShadow(
      color: color,
      blurRadius: magnitude * 2,
      offset: Offset(0, magnitude * 0.6),
    ),
  ];

  List<BoxShadow> get boxShadow => [
    BoxShadow(
      color: color,
      blurRadius: magnitude * 3,
      offset: Offset(0, magnitude),
    ),
  ];

  List<BoxShadow> get bigBoxShadow => [
    BoxShadow(
      color: color,
      blurRadius: magnitude * 4,
      offset: Offset(0, magnitude * 1.5),
    ),
  ];

  @override
  AppShadows copyWith({Color? color, double? magnitude}) {
    return AppShadows(
      color: color ?? this.color,
      magnitude: magnitude ?? this.magnitude,
    );
  }

  @override
  AppShadows lerp(covariant AppShadows? other, double t) {
    if (other == null) return this;

    return AppShadows(
      color: Color.lerp(color, other.color, t) ?? color,
      magnitude: magnitude + (other.magnitude - magnitude) * t,
    );
  }
}

extension AppShadowsContext on BuildContext {
  AppShadows get shadows {
    return Theme.of(this).extension<AppShadows>() ?? AppShadows.standard;
  }
}
