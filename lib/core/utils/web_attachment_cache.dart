import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueNotifier, visibleForTesting;

import 'web_attachment_cache_stub.dart'
    if (dart.library.js_interop) 'web_attachment_cache_web.dart';

const kWebDriveCachePrefix = 'drive:';
const kWebLocalCachePrefix = 'local:';

/// Tarayıcı IndexedDB önbelleğinde Drive dosyaları için LRU tavanı (250 MB).
/// Henüz buluta çıkmamış `local:*` girdiler hiçbir zaman kendiliğinden silinmez.
const int kMaxWebDriveCacheBytes = 250 * 1024 * 1024;

String webDriveCacheKey(String driveId) => '$kWebDriveCachePrefix$driveId';

String webLocalCacheKey(String attachmentId) =>
    '$kWebLocalCachePrefix$attachmentId';

class WebCachedBlob {
  const WebCachedBlob({
    required this.bytes,
    required this.mimeType,
    required this.updatedAtMs,
  });

  final Uint8List bytes;
  final String mimeType;
  final int updatedAtMs;

  int get sizeBytes => bytes.length;
}

typedef WebCacheStats = ({
  int driveCount,
  int driveBytes,
  int localCount,
  int localBytes,
});

typedef WebCacheEntryMeta = ({String key, int sizeBytes, int updatedAtMs});

/// [maxDriveBytes] tavanını aşan en eski `drive:*` girdilerinin anahtarlarını
/// döner; `local:*` girdilere dokunmaz.
List<String> keysToEvictForDriveBudget(
  List<WebCacheEntryMeta> entries, {
  int maxDriveBytes = kMaxWebDriveCacheBytes,
}) {
  final driveEntries = [
    for (final e in entries)
      if (e.key.startsWith(kWebDriveCachePrefix)) e,
  ]..sort((a, b) => a.updatedAtMs.compareTo(b.updatedAtMs));

  var total = 0;
  for (final e in driveEntries) {
    total += e.sizeBytes;
  }
  final evict = <String>[];
  var index = 0;
  while (total > maxDriveBytes && index < driveEntries.length) {
    final victim = driveEntries[index++];
    evict.add(victim.key);
    total -= victim.sizeBytes;
  }
  return evict;
}

/// Tarayıcıda kalıcı ek önbelleği soyutlaması: Android'deki yerel ek klasörü
/// karşılığı. VM'de/testte [MemoryWebAttachmentCache], web'de IndexedDB
/// ([IndexedDbAttachmentCache]).
abstract class WebAttachmentCache {
  /// Henüz buluta çıkmamış yerel (`local:*`) ek kimlikleri — `build()` ve
  /// `pendingUploadsProvider` senkron okuyabilsin diye bellekte tutulur.
  Set<String> get knownLocalIds;

  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  Future<void> init();

  Future<WebCachedBlob?> get(String key);

  Future<void> put(String key, Uint8List bytes, String mimeType);

  Future<void> delete(String key);

  Future<WebCacheStats> stats();

  /// Yalnızca indirilen `drive:*` önbelleğini temizler; henüz senkronlanmamış
  /// `local:*` girdiler korunur.
  Future<void> clearDriveCache();
}

/// Bellek içi önbellek: VM varsayılanı, test sahtesi ve IndexedDB erişimi
/// kapalı gizli tarayıcı sekmeleri için yedek.
class MemoryWebAttachmentCache extends WebAttachmentCache {
  final Map<String, WebCachedBlob> _entries = <String, WebCachedBlob>{};
  final Set<String> _localIds = <String>{};
  int _tick = 0;

  @override
  Set<String> get knownLocalIds => UnmodifiableSetView(_localIds);

  @override
  Future<void> init() async {}

  @override
  Future<WebCachedBlob?> get(String key) async {
    final hit = _entries[key];
    if (hit == null) return null;
    if (key.startsWith(kWebDriveCachePrefix)) {
      _entries[key] = WebCachedBlob(
        bytes: hit.bytes,
        mimeType: hit.mimeType,
        updatedAtMs: _nextTimestamp(),
      );
    }
    return _entries[key];
  }

  @override
  Future<void> put(String key, Uint8List bytes, String mimeType) async {
    final copy = Uint8List.fromList(bytes);
    _entries[key] = WebCachedBlob(
      bytes: copy,
      mimeType: mimeType,
      updatedAtMs: _nextTimestamp(),
    );
    var notify = false;
    if (key.startsWith(kWebLocalCachePrefix)) {
      _localIds.add(key.substring(kWebLocalCachePrefix.length));
      notify = true;
    } else if (key.startsWith(kWebDriveCachePrefix)) {
      _enforceDriveBudget();
    }
    if (notify) revision.value++;
  }

  @override
  Future<void> delete(String key) async {
    final removed = _entries.remove(key) != null;
    var notify = false;
    if (key.startsWith(kWebLocalCachePrefix)) {
      notify = _localIds.remove(key.substring(kWebLocalCachePrefix.length));
    }
    if (removed && notify) revision.value++;
  }

  @override
  Future<WebCacheStats> stats() async {
    var driveCount = 0;
    var driveBytes = 0;
    var localCount = 0;
    var localBytes = 0;
    for (final e in _entries.entries) {
      if (e.key.startsWith(kWebDriveCachePrefix)) {
        driveCount++;
        driveBytes += e.value.sizeBytes;
      } else if (e.key.startsWith(kWebLocalCachePrefix)) {
        localCount++;
        localBytes += e.value.sizeBytes;
      }
    }
    return (
      driveCount: driveCount,
      driveBytes: driveBytes,
      localCount: localCount,
      localBytes: localBytes,
    );
  }

  @override
  Future<void> clearDriveCache() async {
    final before = _entries.length;
    _entries.removeWhere((k, _) => k.startsWith(kWebDriveCachePrefix));
    if (_entries.length != before) revision.value++;
  }

  int _nextTimestamp() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _tick = now > _tick ? now : _tick + 1;
    return _tick;
  }

  void _enforceDriveBudget() {
    final metas = [
      for (final e in _entries.entries)
        (
          key: e.key,
          sizeBytes: e.value.sizeBytes,
          updatedAtMs: e.value.updatedAtMs,
        ),
    ];
    for (final victim in keysToEvictForDriveBudget(metas)) {
      _entries.remove(victim);
    }
  }
}

WebAttachmentCache _webAttachmentCache = createWebAttachmentCache();

/// Etkin tarayıcı ek önbelleği.
WebAttachmentCache get webAttachmentCache => _webAttachmentCache;

@visibleForTesting
void setWebAttachmentCacheForTest(WebAttachmentCache cache) {
  _webAttachmentCache = cache;
}

bool webLocalCacheContains(String attachmentId) =>
    attachmentId.isNotEmpty &&
    webAttachmentCache.knownLocalIds.contains(attachmentId);
