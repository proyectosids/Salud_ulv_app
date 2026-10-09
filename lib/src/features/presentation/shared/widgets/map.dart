import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/fonts_size.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/shadows.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/themes/themes.dart';
import 'package:salud_ulv_app/src/features/services/map_tile_cache_service.dart';
import 'package:url_launcher/url_launcher.dart';

const _mapUserAgentPackageName = 'com.azaiulv.salud_ulv_app';
const _defaultMapCenter = LatLng(23.6345, -102.5528);
const mapTilePanBuffer = 0;

class MapTileSource {
  const MapTileSource({
    required this.urlTemplate,
    required this.maxNativeZoom,
    required this.attribution,
    required this.attributionUrl,
  });

  final String urlTemplate;
  final int maxNativeZoom;
  final String attribution;
  final String attributionUrl;
}

const openStreetMapTileSource = MapTileSource(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  maxNativeZoom: 19,
  attribution: '© OpenStreetMap contributors',
  attributionUrl: 'https://www.openstreetmap.org/copyright',
);

const satelliteTileSource = MapTileSource(
  urlTemplate:
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  maxNativeZoom: 19,
  attribution:
      '© Esri, Maxar, Earthstar Geographics and the GIS User Community',
  attributionUrl:
      'https://www.esri.com/en-us/legal/terms/full-master-agreement',
);

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng? startPoint;
  final LatLng? endPoint;
  final LatLng? initialCenter;
  final List<LatLng> routePoints;
  final bool interactive;
  final VoidCallback? mapReady;
  final double pointSize = 26;
  final bool satellite;
  final bool showCurrentLocation;

  const MapWidget({
    super.key,
    required this.mapController,
    this.startPoint,
    this.endPoint,
    this.initialCenter,
    this.routePoints = const [],
    this.interactive = true,
    this.mapReady,
    this.satellite = false,
    this.showCurrentLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    // const cornerValue = WidgetCircleRadius.buttonRadius;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    final tileSource = satellite
        ? satelliteTileSource
        : openStreetMapTileSource;

    CameraFit? initialFit() {
      if (routePoints.length < 2) return null;

      final bounds = LatLngBounds.fromPoints(routePoints);

      // Zero-area bounds (all points identical) would produce Infinity/NaN zoom
      if (bounds.north == bounds.south && bounds.east == bounds.west) {
        return null;
      }

      return CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(30),
        maxZoom: 18,
      );
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCameraFit: initialFit(),
        // Only used if there is no route
        initialCenter: startPoint ?? initialCenter ?? _defaultMapCenter,
        initialZoom: startPoint == null && initialCenter == null ? 5 : 18,
        minZoom: 3,
        // A small amount of overzoom keeps gestures fluid without asking the
        // provider for tile levels that do not exist.
        maxZoom: 21,
        onMapReady: mapReady,

        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),

      children: [
        _CachedNetworkTileLayer(
          key: ValueKey(tileSource.urlTemplate),
          tileSource: tileSource,
          useDarkFilter: !satellite && isDark,
        ),

        // Ruta recorrida (opcional)
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 5,
                gradientColors: [
                  colors.primary,
                  colors.secondary,
                  colors.tertiary,
                  // colors.success,
                ],
                // optional: where each color sits, from 0.0 to 1.0
                // colorsStop: [0.0, 1.0],
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          ),

        // Marcadores de inicio / fin
        MarkerLayer(
          markers: [
            if (startPoint != null)
              Marker(
                point: startPoint!,
                width: pointSize,
                height: pointSize,
                child: _RoutePin(
                  icon: Icons.play_arrow_rounded,
                  color: colors.success,
                  foregroundColor: colors.onSuccess,
                ),
              ),
            if (endPoint != null)
              Marker(
                point: endPoint!,
                width: pointSize,
                height: pointSize,
                child: _RoutePin(
                  icon: Icons.flag_rounded,
                  color: colors.warning,
                  foregroundColor: colors.onWarning,
                ),
              ),
          ],
        ),

        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution(
              tileSource.attribution,
              onTap: () => launchUrl(Uri.parse(tileSource.attributionUrl)),
            ),
          ],
        ),

        if (showCurrentLocation)
          CurrentLocationLayer(
            style: LocationMarkerStyle(
              markerAlignment: .center,
              marker: DefaultLocationMarker(
                child: Icon(Icons.location_pin, color: context.colors.primary),
              ),
              markerSize: Size(15, 15),
              markerDirection: .heading,
            ),
          ),
      ],
    );
  }
}

/// Keeps one HTTP tile provider alive while this map layer is mounted.
///
/// Exercise screens rebuild frequently as elapsed time, distance and steps
/// change. Creating a provider from every build would also create repeated
/// HTTP clients and discard their reusable connections.
class _CachedNetworkTileLayer extends StatefulWidget {
  const _CachedNetworkTileLayer({
    super.key,
    required this.tileSource,
    required this.useDarkFilter,
  });

  final MapTileSource tileSource;
  final bool useDarkFilter;

  @override
  State<_CachedNetworkTileLayer> createState() =>
      _CachedNetworkTileLayerState();
}

class _CachedNetworkTileLayerState extends State<_CachedNetworkTileLayer> {
  late final NetworkTileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = NetworkTileProvider(
      cachingProvider: MapTileCacheService.provider,
      silenceExceptions: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: widget.tileSource.urlTemplate,
      userAgentPackageName: _mapUserAgentPackageName,
      maxNativeZoom: widget.tileSource.maxNativeZoom,
      // Prioritize only the tiles visible on screen. They remain available in
      // the persistent cache after the first successful network load.
      panBuffer: mapTilePanBuffer,
      retinaMode: false,
      tileDisplay: const TileDisplay.instantaneous(),
      tileProvider: _tileProvider,
      tileBuilder: widget.useDarkFilter ? darkModeTileBuilder : null,
    );
  }
}

class _RoutePin extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? foregroundColor;

  const _RoutePin({required this.icon, this.color, this.foregroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? context.colors.secondary,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.surface, width: 2),
        boxShadow: context.shadows.smBoxShadow,
      ),
      child: Icon(
        icon,
        color: foregroundColor ?? context.colors.onSecondary,
        size: context.fontsSize.body,
      ),
    );
  }
}

void fitRouteToScreen(List<LatLng> routePoints, MapController mapController) {
  if (routePoints.isEmpty) return;

  if (routePoints.length == 1) {
    mapController.move(routePoints.first, 16);
    return;
  }

  final bounds = LatLngBounds.fromPoints(routePoints);

  mapController.fitCamera(
    CameraFit.bounds(
      bounds: bounds,
      padding: EdgeInsets.all(30),
      maxZoom: 18,
      // minZoom: 15
    ),
  );
}
