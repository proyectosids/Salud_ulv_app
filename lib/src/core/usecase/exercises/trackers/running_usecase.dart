import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/models/exercise_categories.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/exercise_sample_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/services/error_handlers.dart';
import 'package:salud_ulv_app/src/core/services/exercise_services.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/excercise_usecases.dart';
import 'package:salud_ulv_app/src/core/services/step_counter.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/step_fusion_tracker.dart';
import 'package:uuid/uuid.dart';

class RunningActivityUsecase
    implements
        IExerciseTrackUseCase,
        ISpeedTrackable,
        IStepTrackable,
        ILocationTrackable {
  final IExerciseLocalRepo exerciseLocalRepo;
  final IActivitySampleRepo aerobicSampleRepo;
  final ICurrentUserSession currentUserSession;

  final IAccelerometer accelerometerSensor;
  final IGeolocator geolocatorSensor;
  final bool indoor;

  RunningActivityUsecase(
    this.exerciseLocalRepo,
    this.aerobicSampleRepo,
    this.currentUserSession,
    this.accelerometerSensor,
    this.geolocatorSensor, {
    this.indoor = false,
  });

  static const int _categoryID = ExerciseCategoryIds.running;

  // MET aproximado para correr (~9.8 a ritmo moderado)
  static const double _runningMet = 9.8;
  static const double _weightKg = 70;

  static const double _maximumRunningSpeed = 8.5;
  static const double _estimatedStrideMeters = 1.05;

  final ExerciseTimer _timer = ExerciseTimer();

  static int _instanceCount = 0;
  final int _instanceId = ++_instanceCount;

  final StepDetector _stepCounter = StepDetector();
  final StepFusionTracker _stepFusion = StepFusionTracker(
    minimumInterval: Duration(milliseconds: 220),
    maximumInterval: Duration(milliseconds: 900),
  );

  String? _activityID;
  String? _userUUID;
  DateTime date = DateTime.now().toUtc();

  String get activityID {
    if (_activityID == null) {
      throw StateError('Activity has not started');
    }
    return _activityID!;
  }

  static const Duration _snapshotInterval = Duration(seconds: 2);

  Timer? _snapshotTimer;
  bool _snapshotBusy = false;
  // Los pasos NO se guardan en Running, pero se necesitan para la cadencia.
  int _steps = 0;
  double _fallbackDistance = 0;

  int _lastSnapshotSteps = 0;
  double _lastSnapshotDistance = 0.0;
  double _lastSnapshotElevation = 0.0;
  double _lastSnapshotCaloriesBurned = 0.0;
  Duration _lastSnapshotElapsed = Duration.zero;

  StreamSubscription? _accelSub;

  @override
  Stream<Duration>? get elapsedStream => _timer.stream;

  @override
  Duration? get elapsed => _timer.elapsed;

  @override
  double? get distance =>
      !indoor && geolocatorSensor.distance > _fallbackDistance
      ? geolocatorSensor.distance
      : _fallbackDistance;

  @override
  double? get caloriesBurned {
    final e = elapsed;
    if (e == null) return 0;
    return calculateCalories(
      elapsed: e,
      weightKg: _weightKg,
      met: _runningMet.toDouble(),
    );
  }

  /// Velocidad instantánea en m/s (GPS).
  @override
  double? get speed {
    if (!indoor) return geolocatorSensor.speed;
    final e = elapsed;
    if (e == null || e.inSeconds == 0) return 0;
    return _fallbackDistance / e.inSeconds;
  }

  /// Running already counts these steps to calculate cadence. Exposing the
  /// same value lets the tracking UI and final summary restore that metric.
  @override
  int? get steps => _steps;

  /// Velocidad promedio en m/s: distancia total / tiempo en movimiento.
  double get avgSpeed {
    final e = elapsed;
    final d = distance;
    if (e == null || d == null || e.inSeconds == 0) return 0;
    return d / e.inSeconds;
  }

  bool get isPaused => _timer.isPaused;

  @override
  Coordinates? get startLocation {
    if (indoor) return null;
    final lat = geolocatorSensor.startLatitude;
    final lng = geolocatorSensor.startLongitude;
    if (lat == null || lng == null) return null;
    return Coordinates(latitude: lat, longitude: lng);
  }

  @override
  Coordinates? get currentLocation {
    if (indoor) return null;
    // latitude/longitude arrancan en 0.0 hasta la primera lectura;
    // usa startLatitude como señal de que ya hay un fix real.
    if (geolocatorSensor.startLatitude == null) return null;
    return Coordinates(
      latitude: geolocatorSensor.latitude,
      longitude: geolocatorSensor.longitude,
    );
  }

  @override
  Future<void> start() async {
    // Los permisos se validan una sola vez en ExerciseTrackingBloc.
    final userUUID = await currentUserSession.getCurrentUserUUID();
    if (userUUID == null) return;

    // 2. Estado limpio
    _activityID = const Uuid().v4().toUpperCase();
    _userUUID = userUUID;
    debugPrint('RunningID: $activityID');

    _steps = 0;
    _fallbackDistance = 0;
    _stepCounter.reset();
    _stepFusion.reset();
    _lastSnapshotSteps = 0;
    _lastSnapshotDistance = 0.0;
    _lastSnapshotElevation = 0.0;
    _lastSnapshotCaloriesBurned = 0.0;
    _lastSnapshotElapsed = Duration.zero;

    // 3. Crear la fila en BD
    await exerciseLocalRepo.setIDs(activityID, userUUID, _categoryID, date);

    if (!indoor) {
      await geolocatorSensor.start(
        2,
        4,
        1,
        maxExpectedSpeed: _maximumRunningSpeed,
      );
    }
    await accelerometerSensor.start();

    final accelStream = streamSpeedReductor(accelerometerSensor.magnitude, 50);

    // Se cuentan pasos solo para calcular cadencia (pasos/min).
    _accelSub = accelStream.listen((raw) {
      final now = DateTime.now();
      final candidate = _stepCounter.update(raw!, timestamp: now);
      if (!candidate) return;

      final motionState = indoor || !geolocatorSensor.hasReliableFix
          ? LocationMotionState.unavailable
          : geolocatorSensor.hasMovement
          ? LocationMotionState.moving
          : LocationMotionState.stationary;
      final result = _stepFusion.addCandidate(
        timestamp: now,
        motionState: motionState,
        detectorConfidence: _stepCounter.confidence,
      );
      if (result.confirmedSteps > 0) {
        _steps += result.confirmedSteps;
        if (indoor || !geolocatorSensor.hasReliableFix) {
          final gpsDistance = geolocatorSensor.distance;
          if (_fallbackDistance < gpsDistance) _fallbackDistance = gpsDistance;
          _fallbackDistance += result.confirmedSteps * _estimatedStrideMeters;
        }
      }
    });

    _timer.start();
    _startSnapshotTimer();
  }

  @override
  void pause() {
    geolocatorSensor.pause();
    accelerometerSensor.pause();
    _accelSub?.pause();
    _timer.pause();
    _snapshotTimer?.cancel();
  }

  @override
  void resume() {
    geolocatorSensor.resume();
    accelerometerSensor.resume();
    _accelSub?.resume();
    _timer.resume();
    _startSnapshotTimer();
  }

  @override
  void reset() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;

    accelerometerSensor.reset();
    geolocatorSensor.reset();
    _timer.reset();
    _steps = 0;
    _fallbackDistance = 0;
    _stepCounter.reset();
    _stepFusion.reset();
    _lastSnapshotSteps = 0;
    _lastSnapshotDistance = 0.0;
    _lastSnapshotElevation = 0.0;
    _lastSnapshotCaloriesBurned = 0.0;
    _lastSnapshotElapsed = Duration.zero;
  }

  // ---------------------------------------------------------------------------
  // STOP / DISCARD
  // ---------------------------------------------------------------------------
  Future<void> _stopEverything() async {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _timer.stop();
    geolocatorSensor.stop();
    accelerometerSensor.stop();
    await _accelSub?.cancel();
    _accelSub = null;
  }

  @override
  Future<void> stopAndSave() async {
    await _stopEverything();
    reset();
  }

  @override
  Future<void> discard() async {
    await _stopEverything();

    final id = _activityID;
    if (id != null) {
      try {
        final userUUID =
            _userUUID ?? await currentUserSession.getCurrentUserUUID();
        if (userUUID != null) {
          await exerciseLocalRepo.delete(userUUID, id);
        }
        await aerobicSampleRepo.delete(id);
        debugPrint('cleanup successful ');
      } catch (e) {
        debugPrint('discard() cleanup failed: $e');
      }
    }

    reset();
  }

  @override
  Future<void> save() async {
    pause();

    final currentElapsed = elapsed;
    final currentDistance = distance;

    if (currentElapsed == null ||
        currentElapsed.inSeconds < 10 ||
        currentDistance == null ||
        currentDistance == 0) {
      await discard();
      throw ExerciseValidationException(
        'No es posible guardar actividades menores a 10 segundos o sin distancia recorrida',
      );
    }

    final sampleData = await aerobicSampleRepo.getSamples(activityID);
    if (sampleData == null || sampleData.isEmpty) {
      await discard();
      throw ExerciseValidationException(
        'No hay datos suficientes para guardar esta actividad',
      );
    }

    final paceList = sampleData
        .map((sample) => sample.pace)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();

    final speedList = sampleData
        .map((sample) => sample.speed)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();

    final elevationList = sampleData
        .map((sample) => sample.elevation)
        .whereType<double>()
        .toList();

    debugPrint('Making running class');

    final runningData = Running(
      activityID: activityID,
      duration: currentElapsed,
      distance: currentDistance,
      caloriesBurned: calculateCaloriesBurned(
        currentElapsed,
        _runningMet,
        _weightKg,
      ),
      elevationGain: elevationList.isEmpty
          ? 0
          : totalElevationGain(elevationList),
      avgCadence: calculateStepsPerMinute(_steps, currentElapsed),
      avgPace: paceList.isEmpty ? 0 : avgCalculator(paceList),
      speed: maxValue(speedList),
      avgSpeed: avgSpeed,
      registeredAt: date,
    );

    debugPrint('Saving running');

    await exerciseLocalRepo.save(runningData);
    await stopAndSave();
  }

  void _startSnapshotTimer() {
    debugPrint('Starting snapshot timer for instance $_instanceId');
    _snapshotTimer?.cancel();
    _snapshotTimer = Timer.periodic(_snapshotInterval, (_) => _takeSnapshot());
  }

  Future<void> _takeSnapshot() async {
    if (_snapshotBusy || _activityID == null) return;

    final currentElapsed = elapsed;
    final currentDistance = distance;
    if (currentElapsed == null || currentDistance == null) return;

    final interval = currentElapsed - _lastSnapshotElapsed;
    if (interval.inMilliseconds <= 0) return;

    _snapshotBusy = true;
    try {
      final currentSteps = _steps;
      final currentElevation = indoor ? 0.0 : geolocatorSensor.elevation;

      final currentCalories = calculateCalories(
        elapsed: currentElapsed,
        weightKg: _weightKg,
        met: _runningMet.toDouble(),
      );

      // Deltas respecto a los acumulados previos
      final stepsDelta = currentSteps - _lastSnapshotSteps;
      final distanceDelta = currentDistance - _lastSnapshotDistance;
      final elevationDelta = currentElevation - _lastSnapshotElevation;
      final caloriesDelta = currentCalories - _lastSnapshotCaloriesBurned;

      // Tasas del intervalo
      final cadence = calculateCadence(stepsDelta, interval);
      final isMoving = indoor ? stepsDelta > 0 : geolocatorSensor.hasMovement;
      final pace = isMoving ? calculatePace(interval, distanceDelta) : 0.0;
      final currentSpeed = interval.inMilliseconds > 0
          ? distanceDelta / (interval.inMilliseconds / 1000)
          : 0.0;

      final snapshotData = RunningActivitySample(
        activityID: activityID,
        timestampMs: currentElapsed,
        distance: distanceDelta,
        calories: caloriesDelta,
        elevation: elevationDelta,
        cadence: cadence,
        pace: pace,
        speed: currentSpeed,
        heartRate: 0,
        latitude: indoor ? null : geolocatorSensor.latitude,
        longitude: indoor ? null : geolocatorSensor.longitude,
      );

      await aerobicSampleRepo.save(snapshotData);

      _lastSnapshotSteps = currentSteps;
      _lastSnapshotDistance = currentDistance;
      _lastSnapshotElevation = currentElevation;
      _lastSnapshotCaloriesBurned = currentCalories;
      _lastSnapshotElapsed = currentElapsed;

      debugPrint(
        'Snapshot saved: activityID=$activityID '
        'distance=$distanceDelta calories=$caloriesDelta '
        'cadence=$cadence pace=$pace speed=$currentSpeed '
        'elapsed=$currentElapsed',
      );
    } catch (e, st) {
      debugPrint('Snapshot failed: $e\n$st');
    } finally {
      _snapshotBusy = false;
    }
  }
}
