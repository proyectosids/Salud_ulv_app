import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/cycling_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/running_repo.dart';
import 'package:salud_ulv_app/src/core/usecase/auth/check_auth_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/trackers/cycling_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/trackers/running_usecase.dart';
import 'package:salud_ulv_app/src/core/usecase/exercises/trackers/walk_usecase.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sensors/accelerometer_sensor.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sensors/geolocator_sensor.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sensors/platform_step_counter.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sensors/step_calibration_store.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_repo.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/anthro_repo.dart';
// import 'package:salud_ulv_app/src/core/data/source/local/sqflite/walk_samples_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';
import 'package:salud_ulv_app/src/features/services/background_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/current_user_service.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token.dart';
import 'package:salud_ulv_app/src/core/data/source/token/token_storage.dart';
import 'package:salud_ulv_app/src/core/data/source/local/sqflite/user_repo.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/auth_bloc/auth_state.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/auth/splash_page.dart';
import 'package:salud_ulv_app/src/features/presentation/screens/main_wrapper.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:salud_ulv_app/src/features/services/exercise_permission_service.dart';
import 'package:salud_ulv_app/src/features/services/map_tile_cache_service.dart';

import 'src/features/presentation/shared/themes/themes.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await initializeService();
  try {
    await MapTileCacheService.initialize();
  } catch (error) {
    debugPrint('No se pudo inicializar la caché persistente del mapa: $error');
  }
  final exercisePermissionService = ExercisePermissionService();
  final themeController = ThemeController();
  await themeController.load();

  runApp(
    ThemeControllerScope(
      controller: themeController,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => CheckAuthBloc(
              checkAuthUseCase: CheckAuthUsecase(
                TokenStorage(),
                TokenHandler(),
                CurrentUserSession(),
                UserLocalRepo(),
              ),
            )..add(CheckAuthEvent()),
          ),

          BlocProvider(
            create: (_) => ExerciseTrackingBloc(
              permissionService: exercisePermissionService,
              usecases: {
                ExerciseType.walk: WalkActivityUsecase(
                  WalkRepo(),
                  WalkSamplesRepo(),
                  CurrentUserSession(),
                  AnthroLocalStorage(),
                  AccelerometerSensor(),
                  GeolocatorSensor(),
                  const PlatformStepCounter(),
                  const StepCalibrationStore(),
                ),
                ExerciseType.running: RunningActivityUsecase(
                  RunningRepo(),
                  RunningSamplesRepo(),
                  CurrentUserSession(),
                  AccelerometerSensor(),
                  GeolocatorSensor(),
                ),
                ExerciseType.cycling: CyclingActivityUsecase(
                  CyclingRepo(),
                  CyclingSamplesRepo(),
                  CurrentUserSession(),
                  GeolocatorSensor(),
                ),
              },
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final themeController = ThemeControllerScope.of(context);
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) => MaterialApp(
        title: 'Salud ULV',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeController.mode,

        home: BlocConsumer<CheckAuthBloc, AuthState>(
          builder: (context, state) {
            return switch (state) {
              Authenticated() => const MainWrapper(),
              Unauthenticated() => const SplashPage(),
              AuthInitial() => const SizedBox.shrink(),
              AuthState() => throw UnimplementedError(),
            };
          },

          listener: (context, state) {
            if (state is! AuthInitial) {
              FlutterNativeSplash.remove();
            }
          },
        ),
      ),
    );
  }
}
