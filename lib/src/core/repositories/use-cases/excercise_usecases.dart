import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';
import 'package:salud_ulv_app/src/core/models/exercise_summaries.dart';
import 'package:salud_ulv_app/src/core/models/exercises.dart';
import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';

// General structure to the exercise tracking
abstract class IExerciseTrackUseCase {
  Stream<Duration>? get elapsedStream;
  double? get distance;
  Duration? get elapsed;
  double? get caloriesBurned;

  Future<void> start();
  void pause();
  void resume();
  Future<void> save();
  void reset();
  void stopAndSave();
  void discard();
}

abstract class IStepTrackable {
  int? get steps;
}

abstract class ISpeedTrackable {
  double? get speed;
}

abstract class ILocationTrackable {
  Coordinates? get startLocation;
  Coordinates? get currentLocation; // Like the end position
}

// Structures for a shared use case, all for physical activities

abstract class IGetRecentExerciseUseCase {
  Future<IPhysicalActivity?> execute();
}

abstract class IGetSamplesUseCase {
  Future<List<IActivitySample>?> execute(String activityID);
}

abstract class IGetAllExerciseUseCase {
  Future<List<IPhysicalActivity>?> execute();
}

abstract class IGetALlByFieldExerciseUseCase {
  Future<List<IPhysicalActivity>?> execute(String field);
}

abstract class IGetExerciseSummary {
  Future<IExerciseSummary?> execute(SummaryPeriod period);
}

abstract class ISendExerciseUseCase {
  Future<bool> execute();
}
