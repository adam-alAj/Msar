import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

class TileCacheService {
  static CacheStore? _store;
  static CacheOptions? _options;

  static const int maxCacheMB = 100;
  static const Duration maxStale = Duration(days: 7);

  static Future<void> init() async {
    if (kIsWeb) {
      _store = MemCacheStore();
    } else {
      final dir = await getApplicationDocumentsDirectory();
      _store = HiveCacheStore('${dir.path}/map_tiles');
    }
    _options = CacheOptions(
      store: _store!,
      policy: CachePolicy.forceCache,
      maxStale: maxStale,
      hitCacheOnErrorExcept: [401, 403],
    );
  }

  static CacheStore get store => _store!;
  static CacheOptions get options => _options!;

  /// Delete all cached tiles.
  static Future<void> clearCache() async {
    await _store?.clean();
  }
}
