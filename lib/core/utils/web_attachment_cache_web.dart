import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'web_attachment_cache.dart';

const _kDbName = 'notlar_attachments_v1';
const _kStoreName = 'blobs';

/// Tarayıcı IndexedDB üzerinde kalıcı ek önbelleği: sayfalar arası ve
/// çevrimdışıyken hem Drive'dan indirilen dosyaları hem de henüz Drive'a
/// yüklenmemiş ekleri korur. IndexedDB kapalıysa (gizli kip) sessizce bellek
/// önbelleğine düşer.
class IndexedDbAttachmentCache extends WebAttachmentCache {
  final MemoryWebAttachmentCache _fallback = MemoryWebAttachmentCache();
  final Set<String> _localIds = <String>{};
  Future<web.IDBDatabase?>? _dbFuture;
  bool _disabled = false;
  bool _initialized = false;
  Future<void>? _initFuture;

  @override
  Set<String> get knownLocalIds =>
      _disabled ? _fallback.knownLocalIds : UnmodifiableSetView(_localIds);

  Future<web.IDBDatabase?> _openDb() {
    if (_disabled) return Future.value();
    return _dbFuture ??= _doOpenDb();
  }

  Future<web.IDBDatabase?> _doOpenDb() async {
    try {
      final idb = web.window.indexedDB;
      final req = idb.open(_kDbName, 1);
      final completer = Completer<web.IDBDatabase?>();

      req.onupgradeneeded = ((web.Event _) {
        try {
          final db = req.result as web.IDBDatabase;
          if (!db.objectStoreNames.contains(_kStoreName)) {
            db.createObjectStore(
              _kStoreName,
              web.IDBObjectStoreParameters(keyPath: 'key'.toJS),
            );
          }
        } catch (_) {}
      }).toJS;

      req.onsuccess = ((web.Event _) {
        if (!completer.isCompleted) {
          try {
            final db = req.result as web.IDBDatabase;
            completer.complete(db);
          } catch (_) {
            completer.complete(null);
          }
        }
      }).toJS;

      void fail(web.Event _) {
        _dbFuture = null;
        if (!completer.isCompleted) completer.complete(null);
      }

      req.onerror = fail.toJS;
      req.onblocked = fail.toJS;

      final db = await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (db == null) _disabled = true;
      return db;
    } catch (_) {
      _disabled = true;
      return null;
    }
  }

  Future<T?> _awaitRequest<T>(
    web.IDBRequest req,
    T? Function(JSAny? result) convert,
  ) {
    final completer = Completer<T?>();
    req.onsuccess = ((web.Event _) {
      if (!completer.isCompleted) {
        try {
          completer.complete(convert(req.result));
        } catch (_) {
          completer.complete(null);
        }
      }
    }).toJS;
    req.onerror = ((web.Event _) {
      if (!completer.isCompleted) completer.complete(null);
    }).toJS;
    return completer.future;
  }

  @override
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    if (_initialized) return;
    _initialized = true;
    final metas = await _readAllMetas();
    if (metas == null) return;
    var changed = false;
    for (final m in metas) {
      if (m.key.startsWith(kWebLocalCachePrefix)) {
        final id = m.key.substring(kWebLocalCachePrefix.length);
        if (_localIds.add(id)) changed = true;
      }
    }
    if (changed) revision.value++;
  }

  Future<List<WebCacheEntryMeta>?> _readAllMetas() async {
    final db = await _openDb();
    if (db == null) return null;
    try {
      final tx = db.transaction(_kStoreName.toJS, 'readonly');
      final store = tx.objectStore(_kStoreName);
      final cursorReq = store.openCursor();
      final out = <WebCacheEntryMeta>[];
      final done = Completer<List<WebCacheEntryMeta>?>();

      cursorReq.onsuccess = ((web.Event _) {
        try {
          final res = cursorReq.result;
          if (res == null || res.isUndefinedOrNull) {
            if (!done.isCompleted) done.complete(out);
            return;
          }
          final cursor = res as web.IDBCursorWithValue;
          final val = cursor.value;
          if (val != null && val.isA<JSObject>()) {
            final obj = val as JSObject;
            final key = _readString(obj, 'key');
            final sizeBytes = _readInt(obj, 'sizeBytes') ?? 0;
            final updatedAtMs = _readInt(obj, 'updatedAtMs') ?? 0;
            if (key != null && key.isNotEmpty) {
              out.add((
                key: key,
                sizeBytes: sizeBytes,
                updatedAtMs: updatedAtMs,
              ));
            }
          }
          cursor.continue_();
        } catch (_) {
          if (!done.isCompleted) done.complete(out);
        }
      }).toJS;

      cursorReq.onerror = ((web.Event _) {
        if (!done.isCompleted) done.complete(null);
      }).toJS;

      return await done.future;
    } catch (_) {
      return null;
    }
  }

  JSObject _buildRecord({
    required String key,
    required Uint8List bytes,
    required String mimeType,
    required int updatedAtMs,
  }) {
    final obj = JSObject();
    obj.setProperty('key'.toJS, key.toJS);
    obj.setProperty('bytes'.toJS, bytes.toJS);
    obj.setProperty('mimeType'.toJS, mimeType.toJS);
    obj.setProperty('sizeBytes'.toJS, bytes.length.toJS);
    obj.setProperty('updatedAtMs'.toJS, updatedAtMs.toJS);
    return obj;
  }

  @override
  Future<WebCachedBlob?> get(String key) async {
    final db = await _openDb();
    if (db == null) return _fallback.get(key);
    try {
      final tx = db.transaction(_kStoreName.toJS, 'readonly');
      final store = tx.objectStore(_kStoreName);
      final blob = await _awaitRequest<WebCachedBlob>(store.get(key.toJS), (
        res,
      ) {
        if (res == null || !res.isA<JSObject>()) return null;
        final obj = res as JSObject;
        final rawBytes = obj.getProperty<JSAny?>('bytes'.toJS);
        if (rawBytes == null || !rawBytes.isA<JSUint8Array>()) return null;
        final bytes = (rawBytes as JSUint8Array).toDart;
        final mimeType =
            _readString(obj, 'mimeType') ?? 'application/octet-stream';
        final updatedAtMs = _readInt(obj, 'updatedAtMs') ?? 0;
        return WebCachedBlob(
          bytes: bytes,
          mimeType: mimeType,
          updatedAtMs: updatedAtMs,
        );
      });
      if (blob != null && key.startsWith(kWebDriveCachePrefix)) {
        unawaited(_touchTimestamp(key, blob));
      }
      return blob ?? await _fallback.get(key);
    } catch (_) {
      return _fallback.get(key);
    }
  }

  Future<void> _touchTimestamp(String key, WebCachedBlob blob) async {
    final db = await _openDb();
    if (db == null) return;
    try {
      final tx = db.transaction(_kStoreName.toJS, 'readwrite');
      tx
          .objectStore(_kStoreName)
          .put(
            _buildRecord(
              key: key,
              bytes: blob.bytes,
              mimeType: blob.mimeType,
              updatedAtMs: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    } catch (_) {}
  }

  @override
  Future<void> put(String key, Uint8List bytes, String mimeType) async {
    final isLocal = key.startsWith(kWebLocalCachePrefix);
    if (isLocal) {
      _localIds.add(key.substring(kWebLocalCachePrefix.length));
    }
    final db = await _openDb();
    if (db == null) {
      await _fallback.put(key, bytes, mimeType);
      if (isLocal) revision.value++;
      return;
    }
    try {
      final copy = Uint8List.fromList(bytes);
      final tx = db.transaction(_kStoreName.toJS, 'readwrite');
      final store = tx.objectStore(_kStoreName);
      final req = store.put(
        _buildRecord(
          key: key,
          bytes: copy,
          mimeType: mimeType,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await _awaitRequest<Object?>(req, (_) => true);
      if (isLocal) {
        revision.value++;
      } else if (key.startsWith(kWebDriveCachePrefix)) {
        await _enforceDriveBudget();
      }
    } catch (_) {
      await _fallback.put(key, bytes, mimeType);
      if (isLocal) revision.value++;
    }
  }

  Future<void> _enforceDriveBudget() async {
    final metas = await _readAllMetas();
    if (metas == null) return;
    final victims = keysToEvictForDriveBudget(metas);
    if (victims.isEmpty) return;
    final db = await _openDb();
    if (db == null) return;
    try {
      final tx = db.transaction(_kStoreName.toJS, 'readwrite');
      final store = tx.objectStore(_kStoreName);
      for (final key in victims) {
        store.delete(key.toJS);
      }
    } catch (_) {}
  }

  @override
  Future<void> delete(String key) async {
    final isLocal = key.startsWith(kWebLocalCachePrefix);
    final removedLocal =
        isLocal && _localIds.remove(key.substring(kWebLocalCachePrefix.length));
    await _fallback.delete(key);
    final db = await _openDb();
    if (db == null) {
      if (removedLocal) revision.value++;
      return;
    }
    try {
      final tx = db.transaction(_kStoreName.toJS, 'readwrite');
      final req = tx.objectStore(_kStoreName).delete(key.toJS);
      await _awaitRequest<Object?>(req, (_) => true);
    } catch (_) {}
    if (removedLocal) revision.value++;
  }

  @override
  Future<WebCacheStats> stats() async {
    final metas = await _readAllMetas();
    if (metas == null) return _fallback.stats();
    var driveCount = 0;
    var driveBytes = 0;
    var localCount = 0;
    var localBytes = 0;
    for (final m in metas) {
      if (m.key.startsWith(kWebDriveCachePrefix)) {
        driveCount++;
        driveBytes += m.sizeBytes;
      } else if (m.key.startsWith(kWebLocalCachePrefix)) {
        localCount++;
        localBytes += m.sizeBytes;
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
    await _fallback.clearDriveCache();
    final metas = await _readAllMetas();
    if (metas == null) {
      revision.value++;
      return;
    }
    final db = await _openDb();
    if (db == null) return;
    var cleared = false;
    try {
      final tx = db.transaction(_kStoreName.toJS, 'readwrite');
      final store = tx.objectStore(_kStoreName);
      final pending = <Future<Object?>>[];
      for (final m in metas) {
        if (m.key.startsWith(kWebDriveCachePrefix)) {
          pending.add(
            _awaitRequest<Object?>(store.delete(m.key.toJS), (_) => true),
          );
        }
      }
      if (pending.isNotEmpty) {
        await Future.wait(pending);
        cleared = true;
      }
    } catch (_) {}
    if (cleared) revision.value++;
  }

  static String? _readString(JSObject obj, String name) {
    final v = obj.getProperty<JSAny?>(name.toJS);
    return v != null && v.isA<JSString>() ? (v as JSString).toDart : null;
  }

  static int? _readInt(JSObject obj, String name) {
    final v = obj.getProperty<JSAny?>(name.toJS);
    return v != null && v.isA<JSNumber>() ? (v as JSNumber).toDartInt : null;
  }
}

WebAttachmentCache createWebAttachmentCache() => IndexedDbAttachmentCache();
