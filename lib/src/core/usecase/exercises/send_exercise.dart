import 'package:salud_ulv_app/src/core/repositories/repos/excercise_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/check_connection_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/services/current_user_session_repo.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/excercise_usecases.dart';

class SendExerciseUseCase implements ISendExerciseUseCase {
  final List<IExerciseLocalRepo> exerciseLocalRepos;
  final IExerciseExtRepo exerciseExtRepo;
  final ICurrentUserSession currentUserSession;
  final ICheckConnectionRepo checkConnectionRepo;

  const SendExerciseUseCase(
    this.exerciseLocalRepos,
    this.exerciseExtRepo,
    this.currentUserSession,
    this.checkConnectionRepo,
  );

  @override
  Future<bool> execute() async {
    if (!await checkConnectionRepo.hasConnection()) return false;

    final userUUID = await currentUserSession.getCurrentUserUUID();
    if (userUUID == null) return false;

    var sentAny = false;
    Object? firstError;
    for (final repository in exerciseLocalRepos) {
      final pending = await repository.getUnsynced(userUUID);
      if (pending == null || pending.isEmpty) continue;

      for (final exercise in pending) {
        try {
          await exerciseExtRepo.send(exercise);
          final activityID = exercise.activityID;
          if (activityID == null) {
            throw StateError('La actividad no tiene identificador');
          }
          await repository.markAsSynced(activityID);
          sentAny = true;
        } catch (error) {
          firstError ??= error;
        }
      }
    }

    if (firstError != null) throw firstError;
    return sentAny;
  }
}
