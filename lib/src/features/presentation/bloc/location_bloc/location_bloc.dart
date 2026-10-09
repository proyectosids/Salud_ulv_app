import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:salud_ulv_app/src/core/repositories/use-cases/location_usecases.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/location_bloc/location_event.dart';
import 'package:salud_ulv_app/src/features/presentation/bloc/location_bloc/location_state.dart';

class GetCurrentLocationBloc extends Bloc<LocationEvent, LocationState> {
  final IGetUserCurrentLocation currentLocation;

  GetCurrentLocationBloc({required this.currentLocation})
    : super(LocationInitial()) {
    on<GetCurrentLocation>((event, emit) async {
      try {
        emit(LocationLoading());
        final position = await currentLocation.execute();
        if (position == null) {
          emit(LocationUnavailable());
          return;
        }
        emit(CurrentLocationLoaded(position));
      } catch (e) {
        emit(LocationError('No se pudo obtener la ubicación actual'));
      }
    });
  }
}
