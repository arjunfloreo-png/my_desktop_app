import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// In-memory cache entry with last-access tracking for LRU eviction.
class _CacheEntry {
  final Uint8List data;
  final DateTime createdAt;
  DateTime lastAccessedAt;
  final Duration ttl;

  _CacheEntry({
    required this.data,
    required this.ttl,
  })  : createdAt = DateTime.now(),
        lastAccessedAt = DateTime.now();

  bool get isExpired => DateTime.now().difference(createdAt) > ttl;

  void touch() => lastAccessedAt = DateTime.now();
}

/// High-performance thumbnail cache with:
/// • In-memory LRU cache (configurable max size)
/// • TTL-based expiration
/// • Concurrent request deduplication
/// • Prefetch support with priority queue
/// • Headers for CDN bypass (ngrok compatibility)
class ThumbnailCacheService {
  static const int _defaultMaxMemoryMB = 100;
  static const int _defaultMaxPrefetchQueue = 50;
  static const Duration _defaultTtl = Duration(hours: 24);

  final int maxMemorySizeBytes;
  final int maxPrefetchQueue;
  final Duration ttl;

  final Map<String, _CacheEntry> _memoryCache = {};
  int _currentMemoryBytes = 0;

  /// Prevent duplicate concurrent requests for same URL
  final Map<String, Future<Uint8List>> _pendingRequests = {};

  /// Prefetch queue with priority
  final List<String> _prefetchQueue = [];
  Timer? _prefetchTimer;
  bool _isPrefetching = false;

  ThumbnailCacheService({
    int? maxMemoryMB,
    int? maxPrefetchQueue,
    Duration? ttl,
  })  : maxMemorySizeBytes = (maxMemoryMB ?? _defaultMaxMemoryMB) * 1024 * 1024,
        maxPrefetchQueue = maxPrefetchQueue ?? _defaultMaxPrefetchQueue,
        ttl = ttl ?? _defaultTtl;

  /// Get thumbnail. Checks memory first, then network with dedup.
  Future<Uint8List?> getImage(String url) async {
    if (url.isEmpty) return null;

    // Check memory cache
    if (_memoryCache.containsKey(url)) {
      final entry = _memoryCache[url]!;
      if (!entry.isExpired) {
        entry.touch();
        return entry.data;
      } else {
        // Expired entry → remove
        _removeCacheEntry(url);
      }
    }

    // Check pending requests (dedup in-flight)
    if (_pendingRequests.containsKey(url)) {
      try {
        return await _pendingRequests[url];
      } catch (e) {
        _pendingRequests.remove(url);
        return null;
      }
    }

    // Fetch from network
    final request = _fetchImage(url);
    _pendingRequests[url] = request;

    try {
      final data = await request;
      _pendingRequests.remove(url);
      _addToCache(url, data);
      return data;
    } catch (e) {
      _pendingRequests.remove(url);
      debugPrint('ThumbnailCache fetch error for $url: $e');
      return null;
    }
  }

  /// Fetch image from URL with ngrok headers
  Future<Uint8List> _fetchImage(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {'ngrok-skip-browser-warning': 'true'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Thumbnail fetch timeout'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw HttpException('HTTP ${response.statusCode}');
      }
    } on Exception catch (e) {
      throw FetchException('Failed to fetch $url: $e');
    }
  }

  /// Add data to cache with LRU eviction if needed
  void _addToCache(String url, Uint8List data) {
    final sizeBytes = data.length;

    // Check if would exceed max size
    if (sizeBytes > maxMemorySizeBytes) {
      debugPrint('ThumbnailCache: Image too large ($sizeBytes bytes), skipping');
      return;
    }

    // Evict old entries if needed
    while (_currentMemoryBytes + sizeBytes > maxMemorySizeBytes &&
        _memoryCache.isNotEmpty) {
      _evictOldest();
    }

    // Add to cache
    final entry = _CacheEntry(data: data, ttl: ttl);
    _memoryCache[url] = entry;
    _currentMemoryBytes += sizeBytes;
  }

  /// LRU eviction: remove least recently accessed
  void _evictOldest() {
    if (_memoryCache.isEmpty) return;

    String? lruKey;
    DateTime? lruTime;

    for (final entry in _memoryCache.entries) {
      if (lruTime == null || entry.value.lastAccessedAt.isBefore(lruTime)) {
        lruKey = entry.key;
        lruTime = entry.value.lastAccessedAt;
      }
    }

    if (lruKey != null) {
      _removeCacheEntry(lruKey);
    }
  }

  void _removeCacheEntry(String url) {
    if (_memoryCache.containsKey(url)) {
      _currentMemoryBytes -= _memoryCache[url]!.data.length;
      _memoryCache.remove(url);
    }
  }

  /// Queue URLs for prefetch with priority
  void prefetch(List<String> urls, {bool highPriority = false}) {
    for (final url in urls) {
      if (url.isEmpty || _memoryCache.containsKey(url)) continue;

      if (highPriority) {
        _prefetchQueue.insert(0, url);
      } else {
        _prefetchQueue.add(url);
      }

      if (_prefetchQueue.length > maxPrefetchQueue) {
        _prefetchQueue.removeLast();
      }
    }

    _startPrefetch();
  }

  void _startPrefetch() {
    if (_isPrefetching || _prefetchQueue.isEmpty) return;

    _isPrefetching = true;
    _prefetchTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (_prefetchQueue.isEmpty) {
        _prefetchTimer?.cancel();
        _isPrefetching = false;
        return;
      }

      final url = _prefetchQueue.removeAt(0);
      try {
        await getImage(url);
      } catch (e) {
        debugPrint('Prefetch failed for $url: $e');
      }
    });
  }

  /// Clear cache
  void clear() {
    _memoryCache.clear();
    _currentMemoryBytes = 0;
    _prefetchQueue.clear();
    _prefetchTimer?.cancel();
    _isPrefetching = false;
  }

  /// Get cache stats
  Map<String, dynamic> getStats() => {
    'cachedItems': _memoryCache.length,
    'memoryUsedMB': _currentMemoryBytes / (1024 * 1024),
    'memoryLimitMB': maxMemorySizeBytes / (1024 * 1024),
    'pendingRequests': _pendingRequests.length,
    'prefetchQueueSize': _prefetchQueue.length,
  };

  @override
  String toString() {
    final stats = getStats();
    return 'ThumbnailCache(items=${stats['cachedItems']}, '
        'memory=${(stats['memoryUsedMB'] as double).toStringAsFixed(2)}MB)';
  }

  void dispose() {
    _prefetchTimer?.cancel();
    clear();
  }
}

/// Exception types
class FetchException implements Exception {
  final String message;
  FetchException(this.message);

  @override
  String toString() => 'FetchException: $message';
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}
