import 'package:flutter_test/flutter_test.dart';
import 'package:salud_ulv_app/src/features/presentation/shared/widgets/map.dart';
import 'package:salud_ulv_app/src/features/services/map_tile_cache_service.dart';

void main() {
  test('OpenStreetMap source uses HTTPS, XYZ placeholders and a safe zoom', () {
    expect(openStreetMapTileSource.urlTemplate, startsWith('https://'));
    expect(openStreetMapTileSource.urlTemplate, contains('{z}/{x}/{y}'));
    expect(openStreetMapTileSource.maxNativeZoom, 19);
    expect(openStreetMapTileSource.attribution, contains('OpenStreetMap'));
  });

  test('satellite source declares its provider and native zoom limit', () {
    expect(satelliteTileSource.urlTemplate, startsWith('https://'));
    expect(satelliteTileSource.urlTemplate, contains('{z}/{y}/{x}'));
    expect(satelliteTileSource.maxNativeZoom, 19);
    expect(satelliteTileSource.attribution, contains('Esri'));
  });

  test('map tile cache has a bounded persistent storage configuration', () {
    expect(MapTileCacheService.cacheDirectoryName, 'map_tiles');
    expect(MapTileCacheService.maxCacheBytes, 200 * 1024 * 1024);
    expect(mapTilePanBuffer, 0);
  });
}
