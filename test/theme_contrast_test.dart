import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/color_palettes.dart';

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = foreground == lighter ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

void _expectReadable(Color foreground, Color background, String role) {
  expect(
    _contrastRatio(foreground, background),
    greaterThanOrEqualTo(4.5),
    reason: '$role must meet WCAG AA contrast for normal text',
  );
}

void main() {
  test('reference palette matches the supplied brand colors', () {
    expect(AppColors.copper, const Color(0xFFCE8F5A));
    expect(AppColors.sand, const Color(0xFFEFD199));
    expect(AppColors.seafoam, const Color(0xFF80C8BC));
    expect(AppColors.turquoise, const Color(0xFF5EC0CA));
    expect(AppColors.coastalBlue, const Color(0xFF6287A2));
  });

  for (final entry in {
    'light': AppColors.light,
    'dark': AppColors.dark,
  }.entries) {
    test('${entry.key} theme keeps text and action pairs readable', () {
      final colors = entry.value;

      _expectReadable(
        colors.textPrimary,
        colors.background,
        '${entry.key} text/background',
      );
      _expectReadable(
        colors.textPrimary,
        colors.surface,
        '${entry.key} text/surface',
      );
      _expectReadable(
        colors.textSecondary,
        colors.surface,
        '${entry.key} secondary text/surface',
      );
      _expectReadable(
        colors.onPrimary,
        colors.primary,
        '${entry.key} primary action',
      );
      _expectReadable(
        colors.onSecondary,
        colors.secondary,
        '${entry.key} secondary action',
      );
      _expectReadable(
        colors.onTertiary,
        colors.tertiary,
        '${entry.key} tertiary action',
      );
      _expectReadable(
        colors.onPrimaryContainer,
        colors.primaryContainer,
        '${entry.key} primary container',
      );
      _expectReadable(
        colors.onSecondaryContainer,
        colors.secondaryContainer,
        '${entry.key} secondary container',
      );
      _expectReadable(
        colors.onTertiaryContainer,
        colors.tertiaryContainer,
        '${entry.key} tertiary container',
      );
      _expectReadable(
        colors.onSuccess,
        colors.success,
        '${entry.key} success state',
      );
      _expectReadable(
        colors.onWarning,
        colors.warning,
        '${entry.key} warning state',
      );
      _expectReadable(
        colors.onDanger,
        colors.danger,
        '${entry.key} danger state',
      );
    });
  }

  test('bottom navigation states remain readable in both themes', () {
    _expectReadable(
      AppColors.light.onPrimaryContainer,
      AppColors.light.primaryContainer,
      'light selected navigation item',
    );
    _expectReadable(
      AppColors.light.onTertiary,
      AppColors.light.tertiary,
      'light unselected navigation item',
    );
    _expectReadable(
      AppColors.dark.textPrimary,
      AppColors.dark.onTertiary,
      'dark selected navigation item',
    );
    _expectReadable(
      AppColors.dark.onTertiary,
      AppColors.dark.tertiary,
      'dark unselected navigation item',
    );
  });
}
