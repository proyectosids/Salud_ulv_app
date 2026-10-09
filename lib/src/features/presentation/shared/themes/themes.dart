import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/color_palettes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/icon_sizes.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/spacers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light =>
      _build(colors: AppColors.light, brightness: Brightness.light);

  static ThemeData get dark =>
      _build(colors: AppColors.dark, brightness: Brightness.dark);

  static ThemeData _build({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.secondary,
          brightness: brightness,
        ).copyWith(
          primary: colors.primary,
          onPrimary: colors.onPrimary,
          primaryContainer: colors.primaryContainer,
          onPrimaryContainer: colors.onPrimaryContainer,
          secondary: colors.secondary,
          onSecondary: colors.onSecondary,
          secondaryContainer: colors.secondaryContainer,
          onSecondaryContainer: colors.onSecondaryContainer,
          tertiary: colors.tertiary,
          onTertiary: colors.onTertiary,
          tertiaryContainer: colors.tertiaryContainer,
          onTertiaryContainer: colors.onTertiaryContainer,
          surface: colors.surface,
          onSurface: colors.textPrimary,
          onSurfaceVariant: colors.textSecondary,
          surfaceContainerLowest: colors.background,
          surfaceContainerLow: colors.surface,
          surfaceContainer: colors.surface,
          surfaceContainerHigh: colors.surfaceMuted,
          surfaceContainerHighest: colors.surfaceMuted,
          error: colors.danger,
          onError: colors.onDanger,
          errorContainer: colors.dangerContainer,
          onErrorContainer: colors.onDangerContainer,
          outline: colors.border,
          outlineVariant: colors.border.withValues(alpha: 0.65),
          inverseSurface: isDark
              ? AppColors.light.surfaceMuted
              : const Color(0xFF25363D),
          onInverseSurface: isDark
              ? AppColors.light.textPrimary
              : AppColors.dark.textPrimary,
          inversePrimary: isDark
              ? AppColors.light.primary
              : AppColors.dark.warning,
          surfaceTint: colors.primary,
          shadow: Colors.black,
        );

    final baseTextTheme = ThemeData(
      brightness: brightness,
      useMaterial3: true,
    ).textTheme;
    final textTheme = GoogleFonts.aBeeZeeTextTheme(baseTextTheme).copyWith(
      displayLarge: GoogleFonts.aBeeZee(
        fontSize: 38,
        height: 1.08,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headlineLarge: GoogleFonts.aBeeZee(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      headlineSmall: GoogleFonts.aBeeZee(
        fontSize: 22,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleLarge: GoogleFonts.aBeeZee(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      titleMedium: GoogleFonts.aBeeZee(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      bodyLarge: GoogleFonts.aBeeZee(
        fontSize: 16,
        height: 1.5,
        color: colors.textPrimary,
      ),
      bodyMedium: GoogleFonts.aBeeZee(
        fontSize: 14,
        height: 1.45,
        color: colors.textPrimary,
      ),
      bodySmall: GoogleFonts.aBeeZee(
        fontSize: 12,
        height: 1.4,
        color: colors.textSecondary,
      ),
      labelLarge: GoogleFonts.aBeeZee(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
    );

    final roundedMedium = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.standard.radiusLg),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      iconTheme: IconThemeData(color: colors.textPrimary),
      primaryIconTheme: IconThemeData(color: colors.onPrimary),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: roundedMedium.copyWith(side: BorderSide(color: colors.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.standard.radiusLg),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.standard.radiusLg),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.standard.radiusLg),
          borderSide: BorderSide(color: colors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.standard.radiusLg),
          borderSide: BorderSide(color: colors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.textSecondary.withValues(alpha: 0.7),
          textStyle: textTheme.labelLarge,
          shape: roundedMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.surfaceMuted,
          disabledForegroundColor: colors.textSecondary.withValues(alpha: 0.7),
          textStyle: textTheme.labelLarge,
          shape: roundedMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          foregroundColor: colors.secondary,
          disabledForegroundColor: colors.textSecondary.withValues(alpha: 0.7),
          textStyle: textTheme.labelLarge,
          side: BorderSide(color: colors.border),
          shape: roundedMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: colors.secondary,
          disabledForegroundColor: colors.textSecondary.withValues(alpha: 0.7),
          textStyle: textTheme.labelLarge,
          shape: roundedMedium,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: colors.surface,
        indicatorColor: colors.primary,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? colors.onPrimary
                : colors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? colors.textPrimary
                : colors.textSecondary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: colors.surface,
        selectedItemColor: colors.secondary,
        unselectedItemColor: colors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        shape: roundedMedium.copyWith(side: BorderSide(color: colors.border)),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: colors.textSecondary,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.secondary,
        textColor: colors.textPrimary,
        selectedColor: colors.onSecondaryContainer,
        selectedTileColor: colors.secondaryContainer,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceMuted,
        selectedColor: colors.secondaryContainer,
        disabledColor: colors.surfaceMuted.withValues(alpha: 0.7),
        labelStyle: textTheme.labelLarge,
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colors.onSecondaryContainer,
        ),
        side: BorderSide(color: colors.border),
        shape: roundedMedium,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.secondary
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(colors.onSecondary),
        side: BorderSide(color: colors.border, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.secondary
              : colors.textSecondary,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colors.secondary,
        inactiveTrackColor: colors.border,
        thumbColor: colors.primary,
        overlayColor: colors.primary.withValues(alpha: 0.12),
        valueIndicatorColor: colors.tertiaryContainer,
        valueIndicatorTextStyle: textTheme.labelLarge?.copyWith(
          color: colors.onTertiaryContainer,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.secondary,
        selectionColor: colors.secondary.withValues(alpha: 0.28),
        selectionHandleColor: colors.secondary,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: scheme.inversePrimary,
        shape: roundedMedium,
      ),
      dividerTheme: DividerThemeData(color: colors.border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onPrimary
              : colors.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : colors.border,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.secondary,
        linearTrackColor: colors.border,
        circularTrackColor: colors.border,
      ),
      extensions: [
        colors,
        AppSpacing.standard,
        AppFonts.standard,
        AppIconSizes.standard,
        isDark ? AppShadows.dark : AppShadows.standard,
      ],
    );
  }
}

class ThemeController extends ChangeNotifier {
  static const _preferencesKey = 'theme_mode_v1';

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _mode = switch (preferences.getString(_preferencesKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferencesKey, mode.name);
  }
}

class ThemeControllerScope extends InheritedNotifier<ThemeController> {
  const ThemeControllerScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ThemeControllerScope>();
    assert(
      scope != null,
      'ThemeControllerScope was not found in the widget tree.',
    );
    return scope!.notifier!;
  }
}

extension ThemeContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  AppSpacing get spacing => Theme.of(this).extension<AppSpacing>()!;
  AppFonts get fonts => Theme.of(this).extension<AppFonts>()!;
  AppIconSizes get iconSize => Theme.of(this).extension<AppIconSizes>()!;
}
