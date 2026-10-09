import 'package:flutter_map/flutter_map.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Configures the cache used by every network-backed map layer.
///
/// The cache lives under the application's persistent database directory so
/// that Android does not treat it as disposable temporary cache. Tiles are
/// still cached only as they are requested by the visible map; this respects
/// public tile-server policies that prohibit bulk/offline region downloads.
class MapTileCacheService {
  MapTileCacheService._();

  static const int maxCacheBytes = 200 * 1024 * 1024;
  static const String cacheDirectoryName = 'map_tiles';

  static BuiltInMapCachingProvider? _provider;

  static Future<void> initialize() async {
    if (_provider != null) return;

    final databasesDirectory = await getDatabasesPath();
    _provider = BuiltInMapCachingProvider.getOrCreateInstance(
      cacheDirectory: path.join(databasesDirectory, cacheDirectoryName),
      maxCacheSize: maxCacheBytes,
    );
  }

  /// Falls back to flutter_map's platform cache when persistent storage could
  /// not be prepared. A cache failure must never prevent the map from opening.
  static BuiltInMapCachingProvider get provider =>
      _provider ??= BuiltInMapCachingProvider.getOrCreateInstance(
        maxCacheSize: maxCacheBytes,
      );
}
