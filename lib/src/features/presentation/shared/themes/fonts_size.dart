import 'package:flutter/material.dart';

@immutable
class AppFonts extends ThemeExtension<AppFonts> {
  const AppFonts({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.caption,
    required this.details,
  });

  final double display;
  final double headline;
  final double title;
  final double body;
  final double caption;
  final double details;

  static const standard = AppFonts(
    display: 32,
    headline: 24,
    title: 20,
    body: 16,
    caption: 12,
    details: 10,
  );

  @override
  AppFonts copyWith({
    double? display,
    double? headline,
    double? title,
    double? body,
    double? caption,
    double? details,
  }) {
    return AppFonts(
      display: display ?? this.display,
      headline: headline ?? this.headline,
      title: title ?? this.title,
      body: body ?? this.body,
      caption: caption ?? this.caption,
      details: details ?? this.details,
    );
  }

  @override
  AppFonts lerp(covariant AppFonts? other, double t) {
    if (other == null) return this;

    return AppFonts(
      display: _lerp(display, other.display, t),
      headline: _lerp(headline, other.headline, t),
      title: _lerp(title, other.title, t),
      body: _lerp(body, other.body, t),
      caption: _lerp(caption, other.caption, t),
      details: _lerp(details, other.details, t),
    );
  }

  static double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

extension AppFontsContext on BuildContext {
  AppFonts get fontsSize {
    return Theme.of(this).extension<AppFonts>() ?? AppFonts.standard;
  }
}
