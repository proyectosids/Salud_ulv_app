import 'package:salud_ulv_app/src/features/presentation/bloc/exercise_tracking_bloc/exercise_tracking_bloc.dart';

abstract class ExerciseTrackingEvent {}

class SelectExerciseTypeEvent extends ExerciseTrackingEvent {
  final ExerciseType type;
  SelectExerciseTypeEvent(this.type);
}

class StartExerciseEvent extends ExerciseTrackingEvent {}

class OpenExercisePermissionSettingsEvent extends ExerciseTrackingEvent {}

class PauseExerciseEvent extends ExerciseTrackingEvent {}

class ResumeExerciseEvent extends ExerciseTrackingEvent {}

class StopExerciseEvent extends ExerciseTrackingEvent {}

class SaveExerciseEvent extends ExerciseTrackingEvent {}

class DiscardExerciseEvent extends ExerciseTrackingEvent {}
