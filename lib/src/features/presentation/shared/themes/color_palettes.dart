import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.onWarning,
    required this.low,
    required this.onLow,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.border,
  });

  // Reference palette supplied for the Salud ULV visual identity.
  static const copper = Color(0xFFCE8F5A);
  static const sand = Color(0xFFEFD199);
  static const seafoam = Color(0xFF80C8BC);
  static const turquoise = Color(0xFF5EC0CA);
  static const coastalBlue = Color(0xFF6287A2);

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color onWarning;
  final Color low;
  final Color onLow;
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color onDangerContainer;
  final Color border;

  /// Returns the intended readable foreground for a semantic background.
  Color foregroundFor(Color color) {
    if (color == primary) return onPrimary;
    if (color == primaryContainer) return onPrimaryContainer;
    if (color == secondary) return onSecondary;
    if (color == secondaryContainer) return onSecondaryContainer;
    if (color == tertiary) return onTertiary;
    if (color == tertiaryContainer) return onTertiaryContainer;
    if (color == success) return onSuccess;
    if (color == warning) return onWarning;
    if (color == low) return onLow;
    if (color == danger) return onDanger;
    if (color == dangerContainer) return onDangerContainer;
    if (color == surface || color == surfaceMuted || color == background) {
      return textPrimary;
    }
    return textPrimary;
  }

  /// Coastal daylight: warm neutral surfaces with restrained ocean accents.
  static const light = AppColors(
    background: Color(0xFFF7F4EF),
    surface: Color(0xFFFFFCF8),
    surfaceMuted: Color(0xFFF0ECE5),
    primary: copper,
    onPrimary: Color(0xFF2A1B11),
    primaryContainer: Color(0xFFF6E1D0),
    onPrimaryContainer: Color(0xFF3B2414),
    secondary: turquoise,
    onSecondary: Color(0xFF123136),
    secondaryContainer: Color(0xFFD7F1F2),
    onSecondaryContainer: Color(0xFF153236),
    tertiary: coastalBlue,
    onTertiary: Color(0xFF08161E),
    tertiaryContainer: Color(0xFFDCE8EF),
    onTertiaryContainer: Color(0xFF172D3B),
    textPrimary: Color(0xFF1D292E),
    textSecondary: Color(0xFF53636B),
    success: seafoam,
    onSuccess: Color(0xFF15312D),
    warning: sand,
    onWarning: Color(0xFF302514),
    low: Color(0xFF35566D),
    onLow: Color(0xFFFFFFFF),
    danger: Color(0xFF9B4E46),
    onDanger: Color(0xFFFFFFFF),
    dangerContainer: Color(0xFFFFDAD5),
    onDangerContainer: Color(0xFF3C0907),
    border: Color(0xFFC9D4D5),
  );

  /// Coastal night: deep blue-charcoal surfaces and softened palette accents.
  static const dark = AppColors(
    background: Color(0xFF10191D),
    surface: Color(0xFF18262B),
    surfaceMuted: Color(0xFF22343A),
    primary: copper,
    onPrimary: Color(0xFF2A1B11),
    primaryContainer: Color(0xFF56351F),
    onPrimaryContainer: Color(0xFFF5D1AF),
    secondary: turquoise,
    onSecondary: Color(0xFF102B30),
    secondaryContainer: Color(0xFF17444A),
    onSecondaryContainer: Color(0xFFA7E3E7),
    tertiary: Color(0xFF8FB1C8),
    onTertiary: Color(0xFF102630),
    tertiaryContainer: Color(0xFF263F50),
    onTertiaryContainer: Color(0xFFC8DCE8),
    textPrimary: Color(0xFFF4F0E9),
    textSecondary: Color(0xFFB5C3C6),
    success: seafoam,
    onSuccess: Color(0xFF15312D),
    warning: sand,
    onWarning: Color(0xFF302514),
    low: Color(0xFF8FB1C8),
    onLow: Color(0xFF102630),
    danger: Color(0xFFE7A09A),
    onDanger: Color(0xFF3C1F1D),
    dangerContainer: Color(0xFF5B2927),
    onDangerContainer: Color(0xFFFFDAD6),
    border: Color(0xFF3D525A),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? textPrimary,
    Color? textSecondary,
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? onWarning,
    Color? low,
    Color? onLow,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? onDangerContainer,
    Color? border,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      secondaryContainer: secondaryContainer ?? this.secondaryContainer,
      onSecondaryContainer: onSecondaryContainer ?? this.onSecondaryContainer,
      tertiary: tertiary ?? this.tertiary,
      onTertiary: onTertiary ?? this.onTertiary,
      tertiaryContainer: tertiaryContainer ?? this.tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer ?? this.onTertiaryContainer,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      low: low ?? this.low,
      onLow: onLow ?? this.onLow,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      onDangerContainer: onDangerContainer ?? this.onDangerContainer,
      border: border ?? this.border,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primaryContainer: Color.lerp(
        primaryContainer,
        other.primaryContainer,
        t,
      )!,
      onPrimaryContainer: Color.lerp(
        onPrimaryContainer,
        other.onPrimaryContainer,
        t,
      )!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      secondaryContainer: Color.lerp(
        secondaryContainer,
        other.secondaryContainer,
        t,
      )!,
      onSecondaryContainer: Color.lerp(
        onSecondaryContainer,
        other.onSecondaryContainer,
        t,
      )!,
      tertiary: Color.lerp(tertiary, other.tertiary, t)!,
      onTertiary: Color.lerp(onTertiary, other.onTertiary, t)!,
      tertiaryContainer: Color.lerp(
        tertiaryContainer,
        other.tertiaryContainer,
        t,
      )!,
      onTertiaryContainer: Color.lerp(
        onTertiaryContainer,
        other.onTertiaryContainer,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      low: Color.lerp(low, other.low, t)!,
      onLow: Color.lerp(onLow, other.onLow, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      onDangerContainer: Color.lerp(
        onDangerContainer,
        other.onDangerContainer,
        t,
      )!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}
