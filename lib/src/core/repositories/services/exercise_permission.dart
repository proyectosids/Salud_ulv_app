enum ExercisePermissionIssue {
  none,
  locationServicesDisabled,
  locationDenied,
  locationPreviouslyDenied,
  locationPermanentlyDenied,
  activityRecognitionDenied,
  activityRecognitionPreviouslyDenied,
  activityRecognitionPermanentlyDenied,
}

class ExercisePermissionResult {
  const ExercisePermissionResult._(this.issue);

  const ExercisePermissionResult.granted()
    : this._(ExercisePermissionIssue.none);

  const ExercisePermissionResult.denied(ExercisePermissionIssue issue)
    : this._(issue);

  final ExercisePermissionIssue issue;

  bool get isGranted => issue == ExercisePermissionIssue.none;

  bool get canOpenSettings =>
      issue == ExercisePermissionIssue.locationPreviouslyDenied ||
      issue == ExercisePermissionIssue.locationPermanentlyDenied ||
      issue == ExercisePermissionIssue.locationServicesDisabled ||
      issue == ExercisePermissionIssue.activityRecognitionPreviouslyDenied ||
      issue == ExercisePermissionIssue.activityRecognitionPermanentlyDenied;

  String get message => switch (issue) {
    ExercisePermissionIssue.none => '',
    ExercisePermissionIssue.locationServicesDisabled =>
      'Activa la ubicación del dispositivo para registrar tu recorrido.',
    ExercisePermissionIssue.locationDenied =>
      'La ubicación es necesaria para evitar pasos falsos y medir la distancia.',
    ExercisePermissionIssue.locationPreviouslyDenied =>
      'El permiso de ubicación ya fue solicitado. Puedes habilitarlo desde los ajustes del dispositivo.',
    ExercisePermissionIssue.locationPermanentlyDenied =>
      'Habilita la ubicación para Salud ULV desde los ajustes del dispositivo.',
    ExercisePermissionIssue.activityRecognitionDenied =>
      'Permite reconocer la actividad física para contar tus pasos.',
    ExercisePermissionIssue.activityRecognitionPreviouslyDenied =>
      'El permiso de actividad física ya fue solicitado. Puedes habilitarlo desde los ajustes del dispositivo.',
    ExercisePermissionIssue.activityRecognitionPermanentlyDenied =>
      'Habilita Actividad física para Salud ULV desde los ajustes del dispositivo.',
  };
}

abstract class IExercisePermissionService {
  Future<ExercisePermissionResult> check({bool requiresLocation = true});
  Future<ExercisePermissionResult> requestWhenNeeded({
    bool requiresLocation = true,
  });
  Future<bool> openSettingsFor(ExercisePermissionIssue issue);
}
