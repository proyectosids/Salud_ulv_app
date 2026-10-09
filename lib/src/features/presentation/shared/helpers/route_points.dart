import 'package:latlong2/latlong.dart';
import 'package:salud_ulv_app/src/core/models/exercise_samples.dart';

List<LatLng> validRoutePoints(Iterable<IActivitySample> samples) {
  final result = <LatLng>[];

  for (final sample in samples) {
    final latitude = sample.latitude;
    final longitude = sample.longitude;
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude.abs() < 0.000001 && longitude.abs() < 0.000001)) {
      continue;
    }

    final point = LatLng(latitude, longitude);
    if (result.isEmpty || result.last != point) result.add(point);
  }

  return result;
}
