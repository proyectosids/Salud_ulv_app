import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restores and persists the selected theme mode', () async {
    SharedPreferences.setMockInitialValues({'theme_mode_v1': 'dark'});
    final controller = ThemeController();

    await controller.load();
    expect(controller.mode, ThemeMode.dark);

    await controller.setMode(ThemeMode.light);
    final restoredController = ThemeController();
    await restoredController.load();

    expect(restoredController.mode, ThemeMode.light);
  });

  testWidgets('applies light and dark palettes without rebuilding the app', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final controller = ThemeController();
    await controller.setMode(ThemeMode.light);

    await tester.pumpWidget(_ThemeTestApp(controller: controller));
    expect(
      Theme.of(tester.element(find.byKey(const Key('theme-probe')))).brightness,
      Brightness.light,
    );

    await controller.setMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byKey(const Key('theme-probe')))).brightness,
      Brightness.dark,
    );
  });
}

class _ThemeTestApp extends StatelessWidget {
  const _ThemeTestApp({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: controller.mode,
        home: const Scaffold(body: SizedBox(key: Key('theme-probe'))),
      ),
    );
  }
}
