import 'package:salud_ulv_app/src/core/repositories/repos/sensors_repo.dart';

abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationUnavailable extends LocationState {}

class CurrentLocationLoaded extends LocationState {
  final Coordinates currentLocation;
  CurrentLocationLoaded(this.currentLocation);
}

class LocationError extends LocationState {
  final String message;
  LocationError(this.message);
}
