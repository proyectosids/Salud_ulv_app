import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/excercise_usecases.dart';
import 'package:salud_ulv_app/src/core/repositories/services/exercise_permission.dart';
import 'package:salud_ulv_app/src/core/services/error_handlers.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_state.dart';
import 'package:salud_ulv_app/src/features/services/background_service.dart';

enum ExerciseType { walk, running, cycling }

extension ExerciseTypeX on ExerciseType {
  String get label => switch (this) {
    ExerciseType.walk => 'Caminata',
    ExerciseType.running => 'Running',
    ExerciseType.cycling => 'Ciclismo',
  };

  IconData get icon => switch (this) {
    ExerciseType.walk => Icons.directions_walk_rounded,
    ExerciseType.running => Icons.directions_run_rounded,
    ExerciseType.cycling => Icons.directions_bike_rounded,
  };
}

class ExerciseTrackingBloc
    extends Bloc<ExerciseTrackingEvent, ExerciseTrackingState> {
  final Map<ExerciseType, IExerciseTrackUseCase> usecases;
  final IExercisePermissionService permissionService;
  ExerciseType _selectedType;

  ExerciseType get selectedType => _selectedType;
  IExerciseTrackUseCase get usecase => usecases[_selectedType]!;

  ExerciseTrackingBloc({
    required this.usecases,
    required this.permissionService,
    ExerciseType initialType = ExerciseType.walk,
  }) : _selectedType = initialType,
       super(ExerciseInitial(selectedType: initialType)) {
    on<SelectExerciseTypeEvent>(_onSelectType);
    on<StartExerciseEvent>(_onStart);
    on<OpenExercisePermissionSettingsEvent>(_onOpenPermissionSettings);
    on<PauseExerciseEvent>(_onPause);
    on<ResumeExerciseEvent>(_onResume);
    on<SaveExerciseEvent>(_onSave);
    on<DiscardExerciseEvent>(_onDiscard);
  }

  // Helpers para no repetir los getters opcionales del use case.
  int? get _steps =>
      usecase is IStepTrackable ? (usecase as IStepTrackable).steps : null;

  double? get _speed =>
      usecase is ISpeedTrackable ? (usecase as ISpeedTrackable).speed : null;

  ILocationTrackable? get _location =>
      usecase is ILocationTrackable ? usecase as ILocationTrackable : null;

  void _onSelectType(
    SelectExerciseTypeEvent event,
    Emitter<ExerciseTrackingState> emit,
  ) {
    // No se puede cambiar de ejercicio con una actividad en curso/pausada.
    if (state is ActiveExerciseState) return;

    _selectedType = event.type;
    emit(ExerciseInitial(selectedType: _selectedType));
  }

  Future<void> _onStart(
    StartExerciseEvent event,
    Emitter<ExerciseTrackingState> emit,
  ) async {
    final permission = await permissionService.requestWhenNeeded();
    if (!permission.isGranted) {
      emit(
        ExercisePermissionsDenied(
          selectedType: _selectedType,
          issue: permission.issue,
          message: permission.message,
          canOpenSettings: permission.canOpenSettings,
        ),
      );
      return;
    }

    try {
      await startBackgroundService();
      await usecase.start();
      await _startTracking(emit);
    } catch (error, stackTrace) {
      debugPrint('Exercise start failed: $error\n$stackTrace');
      finishExercise();
      emit(
        ExerciseError(
          selectedType: _selectedType,
          message: 'No se pudo iniciar el registro de la actividad.',
        ),
      );
      emit(ExerciseInitial(selectedType: _selectedType));
    }
  }

  Future<void> _onOpenPermissionSettings(
    OpenExercisePermissionSettingsEvent event,
    Emitter<ExerciseTrackingState> emit,
  ) async {
    final current = state;
    if (current is! ExercisePermissionsDenied || !current.canOpenSettings) {
      return;
    }
    await permissionService.openSettingsFor(current.issue);
  }

  Future<void> _startTracking(Emitter<ExerciseTrackingState> emit) async {
    startExerciseTracking();

    await emit.forEach<Duration>(
      usecase.elapsedStream!,
      onData: (elapsed) => TrackingExercise(
        selectedType: _selectedType,
        distance: usecase.distance,
        steps: _steps,
        speed: _speed,
        timeElapsed: elapsed,
        startLocation: _location?.startLocation,
        currentLocation: _location?.currentLocation,
      ),
    );
  }

  void _onPause(PauseExerciseEvent event, Emitter<ExerciseTrackingState> emit) {
    usecase.pause();
    pauseExerciseTracking();

    emit(
      ExercisePaused(
        selectedType: _selectedType,
        distance: usecase.distance,
        steps: _steps,
        speed: _speed,
        timeElapsed: usecase.elapsed!,
        startLocation: _location?.startLocation,
        currentLocation: _location?.currentLocation,
      ),
    );
  }

  Future<void> _onResume(
    ResumeExerciseEvent event,
    Emitter<ExerciseTrackingState> emit,
  ) async {
    usecase.resume();
    startExerciseTracking();

    emit(
      TrackingExercise(
        selectedType: _selectedType,
        distance: usecase.distance,
        steps: _steps,
        speed: _speed,
        timeElapsed: usecase.elapsed!,
        startLocation: _location?.startLocation,
        currentLocation: _location?.currentLocation,
      ),
    );

    await _startTracking(emit);
  }

  Future<void> _onSave(
    SaveExerciseEvent event,
    Emitter<ExerciseTrackingState> emit,
  ) async {
    try {
      final endLocation = _location?.currentLocation;

      await usecase.save();

      if (endLocation != null) {
        emit(
          ExerciseSaved(selectedType: _selectedType, endLocation: endLocation),
        );
      }
      emit(ExerciseInitial(selectedType: _selectedType));
    } on ExerciseValidationException catch (e) {
      emit(ExerciseError(selectedType: _selectedType, message: e.message));
      emit(ExerciseInitial(selectedType: _selectedType));
    } catch (e, st) {
      debugPrint('Save failed: $e\n$st');
      emit(
        ExerciseError(
          selectedType: _selectedType,
          message: 'No se pudo guardar la actividad',
        ),
      );
      emit(ExerciseInitial(selectedType: _selectedType));
    } finally {
      finishExercise();
    }
  }

  Future<void> _onDiscard(
    DiscardExerciseEvent event,
    Emitter<ExerciseTrackingState> emit,
  ) async {
    usecase.discard();
    finishExercise();

    emit(ExerciseInitial(selectedType: _selectedType));
  }
}
