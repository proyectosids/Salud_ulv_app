import 'dart:ui' as ui;

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
  final bool navigationMode;
  final Stream<LocationMarkerPosition?>? positionStream;
  final Stream<double?>? alignPositionStream;
  final Stream<void>? alignDirectionStream;
  final bool followCurrentLocation;
  final VoidCallback? onUserInteraction;

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
    this.navigationMode = false,
    this.positionStream,
    this.alignPositionStream,
    this.alignDirectionStream,
    this.followCurrentLocation = false,
    this.onUserInteraction,
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
        initialZoom: startPoint == null && initialCenter == null ? 5 : 17,
        minZoom: 3,
        // A small amount of overzoom keeps gestures fluid without asking the
        // provider for tile levels that do not exist.
        maxZoom: 21,
        onMapReady: mapReady,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) onUserInteraction?.call();
        },

        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
      ),

      children: [
        // A lightweight local base is always painted first. Cached/network
        // tiles cover it when available; on a first launch without internet
        // the user still gets a usable spatial canvas, location marker and
        // recorded route instead of a blank/error surface.
        const _OfflineMapBackdrop(),
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
            positionStream: positionStream,
            focalPoint: navigationMode
                ? const FocalPoint(
                    ratio: Offset(0, 0.42),
                    offset: Offset(0, -48),
                  )
                : const FocalPoint(),
            alignPositionStream: alignPositionStream,
            alignDirectionStream: alignDirectionStream,
            alignPositionOnUpdate: navigationMode && followCurrentLocation
                ? AlignOnUpdate.always
                : AlignOnUpdate.never,
            alignDirectionOnUpdate: navigationMode && followCurrentLocation
                ? AlignOnUpdate.always
                : AlignOnUpdate.never,
            alignPositionAnimationDuration: const Duration(milliseconds: 320),
            alignDirectionAnimationDuration: const Duration(milliseconds: 180),
            moveAnimationDuration: const Duration(milliseconds: 320),
            rotateAnimationDuration: const Duration(milliseconds: 180),
            style: LocationMarkerStyle(
              markerAlignment: .center,
              marker: DefaultLocationMarker(
                child: Icon(
                  navigationMode
                      ? Icons.navigation_rounded
                      : Icons.location_pin,
                  color: navigationMode
                      ? context.colors.onSecondary
                      : context.colors.primary,
                ),
              ),
              markerSize: navigationMode
                  ? const Size(40, 40)
                  : const Size(15, 15),
              markerDirection: .heading,
              showAccuracyCircle: navigationMode,
              accuracyCircleColor: context.colors.secondary.withValues(
                alpha: 0.12,
              ),
              showHeadingSector: navigationMode,
              headingSectorColor: context.colors.secondary.withValues(
                alpha: 0.18,
              ),
            ),
          ),
      ],
    );
  }
}

class _OfflineMapBackdrop extends StatelessWidget {
  const _OfflineMapBackdrop();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? const Color(0xFF142126) : const Color(0xFFE8ECE8),
      child: CustomPaint(
        painter: _OfflineMapPainter(dark: dark),
        child: Align(
          alignment: const Alignment(-0.88, 0.88),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (dark ? Colors.black : Colors.white).withValues(
                alpha: 0.7,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Mapa disponible sin conexión',
              style: TextStyle(
                color: dark ? Colors.white70 : const Color(0xFF405157),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineMapPainter extends CustomPainter {
  const _OfflineMapPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = (dark ? Colors.white : const Color(0xFF607D78)).withValues(
        alpha: 0.07,
      )
      ..strokeWidth = 1;
    final major = Paint()
      ..color = (dark ? const Color(0xFF7AA6A2) : const Color(0xFF78918B))
          .withValues(alpha: 0.16)
      ..strokeWidth = 2;

    const cell = 44.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minor);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minor);
    }

    final roadA = ui.Path()
      ..moveTo(-20, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.58,
        size.width * 0.55,
        size.height * 0.78,
        size.width + 20,
        size.height * 0.42,
      );
    final roadB = ui.Path()
      ..moveTo(size.width * 0.22, -20)
      ..cubicTo(
        size.width * 0.4,
        size.height * 0.24,
        size.width * 0.34,
        size.height * 0.58,
        size.width * 0.62,
        size.height + 20,
      );
    canvas.drawPath(roadA, major);
    canvas.drawPath(roadB, major);
  }

  @override
  bool shouldRepaint(covariant _OfflineMapPainter oldDelegate) =>
      dark != oldDelegate.dark;
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
