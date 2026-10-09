import 'dart:async';
import 'package:flutter/material.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/models/exercise_categories.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/exercise_sample_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/anthro_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/services/error_handlers.dart';
import 'package:salud_ulv_app/src/core/services/exercise_services.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/excercise_usecases.dart';
import 'package:salud_ulv_app/src/core/services/step_counter.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/location_track_filter.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/step_fusion_tracker.dart';
import 'package:salud_ulv_app/src/core/services/motion_tracking/hybrid_step_tracker.dart';
import 'package:uuid/uuid.dart';

class WalkActivityUsecase
    implements IExerciseTrackUseCase, IStepTrackable, ILocationTrackable {
  final IExerciseLocalRepo exerciseLocalRepo;
  final IActivitySampleRepo aerobicSampleRepo;
  final ICurrentUserSession currentUserSession;
  final IAnthropometricLocalRepo anthropometricRepo;

  final IAccelerometer accelerometerSensor;
  final IGeolocator geolocatorSensor;
  final IPlatformStepCounter platformStepCounter;
  final IStepCalibrationRepo stepCalibrationRepo;

  WalkActivityUsecase(
    this.exerciseLocalRepo,
    this.aerobicSampleRepo,
    this.currentUserSession,
    this.anthropometricRepo,
    this.accelerometerSensor,
    this.geolocatorSensor,
    this.platformStepCounter,
    this.stepCalibrationRepo,
  );

  // categoryID de Walk en ActivityCategory
  static const int _categoryID = ExerciseCategoryIds.walk;

  // MET aproximado para caminata a ritmo moderado (~3.5)
  static const double _walkingMet = 3.5;
  static const double _weightKg = 70;

  static const double _maximumWalkingSpeed = 3.2;
  final ExerciseTimer _timer = ExerciseTimer();
  final StreamController<Duration> _metricsController =
      StreamController<Duration>.broadcast();

  static int _instanceCount = 0;
  final int _instanceId = ++_instanceCount;

  final StepDetector _stepCounter = StepDetector();
  final StepFusionTracker _stepFusion = StepFusionTracker();
  final HybridStepTracker _hybridSteps = HybridStepTracker();

  String? _activityID;
  String? _userUUID;
  DateTime date = DateTime.now().toUtc();

  String get activityID {
    if (_activityID == null) {
      throw StateError('Activity has not started');
    }
    return _activityID!;
  }

  // Two-second local samples preserve enough geometry to reconstruct turns
  // while keeping database writes modest and independent from the API.
  static const Duration _snapshotInterval = Duration(seconds: 2);

  Timer? _snapshotTimer;
  bool _snapshotBusy = false;
  double _fallbackDistance = 0;

  int _lastSnapshotSteps = 0;
  double _lastSnapshotDistance = 0.0;
  double _lastSnapshotElevation = 0.0;
  double _lastSnapshotCaloriesBurned = 0.0;
  Duration _lastSnapshotElapsed = Duration.zero;

  StreamSubscription? _accelSub;
  StreamSubscription<PlatformStepReading>? _platformStepSub;
  StreamSubscription<Duration>? _timerSub;

  @override
  Stream<Duration>? get elapsedStream => _metricsController.stream;

  @override
  Duration? get elapsed => _timer.elapsed;

  @override
  double? get distance {
    final gpsDistance = geolocatorSensor.distance;
    if (geolocatorSensor.hasReliableFix) return gpsDistance;

    final sensorDistance = _hybridSteps.estimatedDistanceMeters;
    final fallback = sensorDistance > _fallbackDistance
        ? sensorDistance
        : _fallbackDistance;
    return gpsDistance > fallback ? gpsDistance : fallback;
  }

  @override
  double? get caloriesBurned {
    final e = elapsed;
    if (e == null) return 0;
    return calculateCalories(elapsed: e, weightKg: _weightKg, met: _walkingMet);
  }

  @override
  int? get steps {
    final gpsDistance = geolocatorSensor.distance;

    return _hybridSteps.resolve(
      distanceMeters: gpsDistance,
      walkingSpeedMetersPerSecond: geolocatorSensor.speed,
      motionState: !geolocatorSensor.hasReliableFix
          ? LocationMotionState.unavailable
          : geolocatorSensor.hasMovement
          ? LocationMotionState.moving
          : LocationMotionState.stationary,
    );
  }

  bool get isPaused => _timer.isPaused;

  @override
  Coordinates? get startLocation {
    final lat = geolocatorSensor.startLatitude;
    final lng = geolocatorSensor.startLongitude;
    if (lat == null || lng == null) return null;
    return Coordinates(latitude: lat, longitude: lng);
  }

  @override
  Coordinates? get currentLocation {
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

    try {
      final anthropometrics = await anthropometricRepo.getRecent(userUUID);
      _hybridSteps.configureHeightCm(anthropometrics?.height);
    } catch (error) {
      // A missing/corrupt anthropometric record must never prevent tracking.
      _hybridSteps.configureHeightCm(null);
      debugPrint('Could not load height for step estimation: $error');
    }

    try {
      final calibratedLength = await stepCalibrationRepo.loadStepLengthMeters(
        userUUID,
      );
      _hybridSteps.configureCalibratedStepLengthMeters(calibratedLength);
    } catch (error) {
      debugPrint('Could not load step calibration: $error');
    }

    // 2. Estado limpio
    _activityID = const Uuid().v4().toUpperCase();
    _userUUID = userUUID;
    debugPrint('WalkID: $activityID');

    _fallbackDistance = 0;
    _stepCounter.reset();
    _stepFusion.reset();
    _hybridSteps.reset();
    _lastSnapshotSteps = 0;
    _lastSnapshotDistance = 0.0;
    _lastSnapshotElevation = 0.0;
    _lastSnapshotCaloriesBurned = 0.0;
    _lastSnapshotElapsed = Duration.zero;

    // 3. Crear la fila en BD
    await exerciseLocalRepo.setIDs(activityID, userUUID, _categoryID, date);

    await geolocatorSensor.start(
      1,
      4,
      1,
      maxExpectedSpeed: _maximumWalkingSpeed,
    );
    await accelerometerSensor.start();

    _platformStepSub = platformStepCounter.sessionSteps.listen(
      (reading) {
        if (_timer.isPaused) {
          _hybridSteps.discardPlatformReading(reading);
          return;
        }
        _hybridSteps.updatePlatformReading(reading);
        _metricsController.add(_timer.elapsed);
      },
      onError: (Object error, StackTrace stackTrace) {
        // Some devices do not expose a native pedometer. GPS and the
        // accelerometer remain active as transparent fallbacks.
        _hybridSteps.markPlatformUnavailable();
        debugPrint('Native step counter unavailable: $error');
      },
    );

    await _timerSub?.cancel();
    _timerSub = _timer.stream.listen(_metricsController.add);

    final accelStream = streamSpeedReductor(accelerometerSensor.magnitude, 50);

    _accelSub = accelStream.listen((raw) {
      final now = DateTime.now();
      final candidate = _stepCounter.update(raw!, timestamp: now);
      if (!candidate) return;

      final motionState = !geolocatorSensor.hasReliableFix
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
        _hybridSteps.addAccelerometerSteps(result.confirmedSteps);
        _metricsController.add(_timer.elapsed);
        if (!geolocatorSensor.hasReliableFix) {
          final gpsDistance = geolocatorSensor.distance;
          if (_fallbackDistance < gpsDistance) _fallbackDistance = gpsDistance;
          _fallbackDistance +=
              result.confirmedSteps * _hybridSteps.estimatedStepLengthMeters;
        }
      }
    });

    _timer.start();
    _startSnapshotTimer();
  }

  @override
  void pause() {
    _timer.pause();
    geolocatorSensor.pause();
    accelerometerSensor.pause();
    _accelSub?.pause();
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
    // Cancelar el timer primero para que un tick tardío no lea valores reseteados.
    _snapshotTimer?.cancel();
    _snapshotTimer = null;

    accelerometerSensor.reset();
    geolocatorSensor.reset();
    _platformStepSub?.cancel();
    _platformStepSub = null;
    _timerSub?.cancel();
    _timerSub = null;
    _timer.reset();
    _fallbackDistance = 0;
    _stepCounter.reset();
    _stepFusion.reset();
    _hybridSteps.reset();
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
    await _platformStepSub?.cancel();
    _platformStepSub = null;
    await _timerSub?.cancel();
    _timerSub = null;
  }

  @override
  Future<void> stopAndSave() async {
    await _stopEverything();
    reset();
  }

  @override
  Future<void> discard() async {
    await _stopEverything();

    // Nada que borrar si start() nunca llegó a crear la fila.
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
    await _takeSnapshot();
    pause();

    final currentElapsed = elapsed;
    final currentSteps = steps;

    if (currentElapsed == null ||
        currentElapsed.inSeconds < 10 ||
        currentSteps == null ||
        currentSteps == 0) {
      await discard();
      throw ExerciseValidationException(
        'No es posible guardar actividades menores a 10 segundos o sin pasos realizados',
      );
    }

    final sampleData = await aerobicSampleRepo.getSamples(activityID);
    if (sampleData == null || sampleData.isEmpty) {
      await discard();
      throw ExerciseValidationException(
        'No hay datos suficientes para guardar esta actividad',
      );
    }

    final stepsList = sampleData
        .map((sample) => sample.steps)
        .whereType<int>()
        .toList();

    final paceList = sampleData
        .map((sample) => sample.pace)
        .whereType<double>()
        .where((value) => value.isFinite)
        .toList();

    final elevationList = sampleData
        .map((sample) => sample.elevation)
        .whereType<double>()
        .toList();

    debugPrint('Making walk class');

    final walkData = Walk(
      activityID: activityID,
      duration: currentElapsed,
      distance: distance ?? 0,
      caloriesBurned: calculateCaloriesBurned(
        currentElapsed,
        _walkingMet,
        _weightKg,
      ),
      elevationGain: elevationList.isEmpty
          ? 0
          : totalElevationGain(elevationList),
      avgCadence: calculateStepsPerMinute(currentSteps, currentElapsed),
      avgPace: paceList.isEmpty ? 0 : avgCalculator(paceList),
      steps: currentSteps,
      avgSteps: stepsList.isEmpty ? 0 : valueByTime(stepsList, 60),
      registeredAt: date,
    );

    debugPrint('Saving walk: ${walkData.steps}');

    await exerciseLocalRepo.save(walkData);
    if (_hybridSteps.hasSessionCalibration) {
      try {
        await stepCalibrationRepo.saveStepLengthMeters(
          _userUUID!,
          _hybridSteps.estimatedStepLengthMeters,
        );
      } catch (error) {
        // Calibration is an optional enhancement and must never prevent an
        // otherwise valid activity from being saved.
        debugPrint('Could not save step calibration: $error');
      }
    }
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
    final currentSteps = steps;
    final currentDistance = distance;
    final currentPosition = currentLocation;
    if (currentElapsed == null ||
        currentSteps == null ||
        currentDistance == null ||
        currentPosition == null) {
      return;
    }

    final interval = currentElapsed - _lastSnapshotElapsed;
    if (interval.inMilliseconds <= 0) return;

    _snapshotBusy = true;
    try {
      final currentElevation = geolocatorSensor.elevation;

      final currentCalories = calculateCalories(
        elapsed: currentElapsed,
        weightKg: _weightKg,
        met: _walkingMet,
      );

      // Deltas respecto a los acumulados previos
      final stepsDelta = currentSteps - _lastSnapshotSteps;
      final distanceDelta = currentDistance - _lastSnapshotDistance;
      final elevationDelta = currentElevation - _lastSnapshotElevation;
      final caloriesDelta = currentCalories - _lastSnapshotCaloriesBurned;

      // Tasas del intervalo
      final cadence = calculateCadence(stepsDelta, interval);
      final pace = geolocatorSensor.hasMovement
          ? calculatePace(interval, distanceDelta)
          : 0.0;
      final currentSpeed = geolocatorSensor.speed;

      final snapshotData = WalkActivitySample(
        activityID: activityID,
        timestampMs: currentElapsed,
        steps: stepsDelta,
        distance: distanceDelta,
        calories: caloriesDelta,
        elevation: elevationDelta,
        cadence: cadence,
        pace: pace,
        speed: currentSpeed,
        heartRate: 0,
        latitude: currentPosition.latitude,
        longitude: currentPosition.longitude,
      );

      await aerobicSampleRepo.save(snapshotData);

      _lastSnapshotSteps = currentSteps;
      _lastSnapshotDistance = currentDistance;
      _lastSnapshotElevation = currentElevation;
      _lastSnapshotCaloriesBurned = currentCalories;
      _lastSnapshotElapsed = currentElapsed;

      debugPrint(
        'Snapshot saved: activityID=$activityID steps=$stepsDelta '
        'distance=$distanceDelta calories=$caloriesDelta '
        'cadence=$cadence pace=$pace speed=$currentSpeed '
        'elapsed=$currentElapsed',
      );
    } catch (e, st) {
      // Un snapshot fallido nunca debe tumbar la sesión de tracking.
      debugPrint('Snapshot failed: $e\n$st');
    } finally {
      _snapshotBusy = false;
    }
  }
}
