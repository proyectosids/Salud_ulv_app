import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/exercise_permission.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';

// import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_type.dart';

abstract class ExerciseTrackingState {
  final ExerciseType selectedType;
  const ExerciseTrackingState({required this.selectedType});
}

class ExerciseInitial extends ExerciseTrackingState {
  const ExerciseInitial({super.selectedType = ExerciseType.walk});
}

class ExercisePermissionsDenied extends ExerciseTrackingState {
  const ExercisePermissionsDenied({
    required super.selectedType,
    required this.issue,
    required this.message,
    required this.canOpenSettings,
  });

  final ExercisePermissionIssue issue;
  final String message;
  final bool canOpenSettings;
}

class ActiveExerciseState extends ExerciseTrackingState {
  final double? distance;
  final int? steps;
  final double? speed;
  final Duration timeElapsed;
  final Coordinates? startLocation;
  final Coordinates? currentLocation;

  const ActiveExerciseState({
    required super.selectedType,
    required this.timeElapsed,
    this.steps,
    this.speed,
    this.distance,
    this.startLocation,
    this.currentLocation,
  });
}

class TrackingExercise extends ActiveExerciseState {
  const TrackingExercise({
    required super.selectedType,
    required super.timeElapsed,
    super.steps,
    super.speed,
    super.distance,
    super.startLocation,
    super.currentLocation,
  });
}

class ExercisePaused extends ActiveExerciseState {
  const ExercisePaused({
    required super.selectedType,
    required super.timeElapsed,
    super.steps,
    super.speed,
    super.distance,
    super.startLocation,
    super.currentLocation,
  });
}

class ExerciseResumed extends ExerciseTrackingState {
  const ExerciseResumed({required super.selectedType});
}

class ExerciseSaved extends ExerciseTrackingState {
  final Coordinates? startLocation;
  final Coordinates? endLocation;
  final Duration duration;
  final double distance;
  final double caloriesBurned;
  final DateTime completedAt;
  final int? steps;
  final double? speed;

  const ExerciseSaved({
    required super.selectedType,
    required this.duration,
    required this.distance,
    required this.caloriesBurned,
    required this.completedAt,
    this.startLocation,
    this.endLocation,
    this.steps,
    this.speed,
  });
}

class ExerciseDiscarded extends ExerciseTrackingState {
  const ExerciseDiscarded({required super.selectedType});
}

class ExerciseError extends ExerciseTrackingState {
  final String message;
  const ExerciseError({required super.selectedType, required this.message});
}
