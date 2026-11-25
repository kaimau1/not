import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notes/domain/note_item.dart';
import '../../features/notes/domain/text_merge.dart';
import 'sync_models.dart';
import 'sync_transport.dart';

/// **YEREL OUTBOX & DELTA İMLEÇ DEPOSU** (PLAN §5.5, Faz 2).
///
/// Hem Android/Masaüstü hem Web'de (`SharedPreferences` / tarayıcı kalıcı
/// deposu) çalışır:
///  - Aynı `(kind, id)` için art arda gelen düzenlemeleri tek girdide
///    birleştirir (batching — Lite & Web yazım patlamasını önler).
///  - İlk kuyruğa almadaki `baseVersion` ve `basePayload` taban kopyasını
///    korur; böylece çevrimdışı çakışma olduğunda [mergeText3] ve
///    [mergeItems3] ile gerçek 3-yönlü birleştirme yapılır.
class SyncOutbox {
  SyncOutbox(this._prefs, {required this.uid}) {
    _load();
  }

  final SharedPreferences _prefs;
  final String uid;

  String get _storageKey => 'cf_sync_outbox_v1_$uid';

  int _cursorSeq = 0;
  int _sharedCursorMs = 0;
  final Map<String, SyncChange> _pending = {};
  final Map<String, int> _versions = {};
  final Map<String, Object?> _snapshots = {};

  int get cursorSeq => _cursorSeq;
  int get sharedCursorMs => _sharedCursorMs;
  bool get hasPending => _pending.isNotEmpty;
  int get pendingCount => _pending.length;

  List<SyncChange> get pendingChanges => List.unmodifiable(_pending.values);

  int versionOf(SyncEntityKind kind, String id) =>
      _versions['${kind.wire}:$id'] ?? 0;

  Object? snapshotOf(SyncEntityKind kind, String id) =>
      _snapshots['${kind.wire}:$id'];

  void _load() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _cursorSeq = (decoded['cursorSeq'] as num?)?.toInt() ?? 0;
      _sharedCursorMs = (decoded['sharedCursorMs'] as num?)?.toInt() ?? 0;
      final versions = decoded['versions'];
      if (versions is Map) {
        for (final e in versions.entries) {
          if (e.value is num) {
            _versions[e.key.toString()] = (e.value as num).toInt();
          }
        }
      }
      final snaps = decoded['snapshots'];
      if (snaps is Map) {
        for (final e in snaps.entries) {
          _snapshots[e.key.toString()] = e.value;
        }
      }
      final pending = decoded['pending'];
      if (pending is List) {
        for (final item in pending) {
          final c = SyncChange.fromStorageJson(item);
          if (c != null) _pending[c.compositeKey] = c;
        }
      }
    } catch (_) {
      // Bozuk depo sessizce temiz başlar.
    }
  }

  Future<void> _persist() async {
    final data = {
      'cursorSeq': _cursorSeq,
      'sharedCursorMs': _sharedCursorMs,
      'versions': _versions,
      'snapshots': _snapshots,
      'pending': [for (final c in _pending.values) c.toStorageJson()],
    };
    await _prefs.setString(_storageKey, jsonEncode(data));
  }

  /// Değişikliği Outbox'a yazar; aynı kayıt zaten bekliyorsa ortak tabanı
  /// (`baseVersion`, `basePayload`) koruyarak son içerikle birleştirir.
  Future<void> enqueue({
    required SyncEntityKind kind,
    required String id,
    required Object? payload,
    bool deleted = false,
    bool encrypted = false,
    int? nowMs,
  }) async {
    final key = '${kind.wire}:$id';
    final existing = _pending[key];
    final baseVersion = existing?.baseVersion ?? (_versions[key] ?? 0);
    final basePayload = existing?.basePayload ?? _snapshots[key];
    _pending[key] = SyncChange(
      kind: kind,
      id: id,
      baseVersion: baseVersion,
      payload: payload,
      deleted: deleted,
      encrypted: encrypted,
      basePayload: basePayload,
      queuedAtMs: nowMs ?? DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  /// Çakışma çözüldükten sonra girdiyi sunucunun yeni `serverVersion` tabanına
  /// yükselterek bir sonraki döngüde gönderime hazırlar.
  Future<void> replaceWithMerged({
    required SyncChange merged,
    required int serverVersion,
    required Object? serverSnapshot,
  }) async {
    final key = merged.compositeKey;
    _versions[key] = serverVersion;
    _snapshots[key] = serverSnapshot;
    _pending[key] = SyncChange(
      kind: merged.kind,
      id: merged.id,
      baseVersion: serverVersion,
      payload: merged.payload,
      deleted: merged.deleted,
      encrypted: merged.encrypted,
      basePayload: serverSnapshot,
      queuedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _persist();
  }

  /// Sunucudan gelen kabul edilmiş yazım + delta kayıtlarını uygular.
  Future<void> commitServerResponse(SyncPushPullResponse res) async {
    if (res.cursorSeq > _cursorSeq) _cursorSeq = res.cursorSeq;
    if (res.sharedCursorMs > _sharedCursorMs) {
      _sharedCursorMs = res.sharedCursorMs;
    }
    for (final a in res.applied) {
      final key = '${a.kind.wire}:${a.id}';
      final sent = _pending.remove(key);
      _versions[key] = a.version;
      if (sent != null) _snapshots[key] = sent.payload;
    }
    for (final e in res.entities) {
      final key = e.compositeKey;
      final currentVer = _versions[key] ?? 0;
      if (e.version >= currentVer) {
        _versions[key] = e.version;
        _snapshots[key] = e.payload;
      }
    }
    await _persist();
  }
}

/// Çakışan not payload'larını mevcut [`mergeText3`] ve [`mergeItems3`] ile
/// 3-yönlü birleştirir (sıfır veri kaybı).
({Map<String, dynamic> merged, bool hadTextConflict}) mergeEntityPayload3Way({
  required Object? baseRaw,
  required Object? localRaw,
  required Object? remoteRaw,
}) {
  final base = baseRaw is Map
      ? Map<String, dynamic>.from(baseRaw)
      : const <String, dynamic>{};
  final local = localRaw is Map
      ? Map<String, dynamic>.from(localRaw)
      : <String, dynamic>{};
  final remote = remoteRaw is Map
      ? Map<String, dynamic>.from(remoteRaw)
      : <String, dynamic>{};

  final out = <String, dynamic>{...remote, ...local};
  var hadConflict = false;

  // 1. Başlık ve gövde: satır düzeyinde 3-yönlü metin birleştirme.
  for (final field in const ['title', 'body', 'content']) {
    if (local.containsKey(field) || remote.containsKey(field)) {
      final b = base[field] as String? ?? '';
      final l = local[field] as String? ?? '';
      final r = remote[field] as String? ?? '';
      final m = mergeText3(b, l, r);
      out[field] = m.text;
      if (m.conflict) hadConflict = true;
    }
  }

  // 2. Liste / alışveriş maddeleri: kimlikle 3-yönlü birleştirme.
  if (local['items'] is List || remote['items'] is List) {
    List<NoteItem> parseItems(Object? raw) {
      if (raw is! List) return const [];
      return [
        for (final e in raw)
          if (e is Map) NoteItem.fromMap(Map<String, dynamic>.from(e)),
      ];
    }

    final mergedItems = mergeItems3(
      parseItems(base['items']),
      parseItems(local['items']),
      parseItems(remote['items']),
    );
    out['items'] = [for (final item in mergedItems) item.toMap()];
  }

  return (merged: out, hadTextConflict: hadConflict);
}

@immutable
class SyncCycleSummary {
  const SyncCycleSummary({
    required this.pushedCount,
    required this.pulledCount,
    required this.sharedPulledCount,
    required this.conflictsResolved,
    required this.cursorSeq,
    required this.policy,
  });

  final int pushedCount;
  final int pulledCount;
  final int sharedPulledCount;
  final int conflictsResolved;
  final int cursorSeq;
  final SyncCadencePolicy policy;
}

/// Outbox + [SyncTransport] + 3-yönlü çakışma çözümü yürütücüsü.
class SyncEngine {
  SyncEngine({
    required this.transport,
    required this.outbox,
    this.onRemoteEntities,
    this.onSharedEntities,
  });

  final SyncTransport transport;
  final SyncOutbox outbox;
  final FutureOr<void> Function(List<SyncEntityRecord> entities)?
  onRemoteEntities;
  final FutureOr<void> Function(List<SharedSyncEntityRecord> shared)?
  onSharedEntities;

  SyncCadencePolicy _policy = const SyncCadencePolicy();
  SyncCadencePolicy get policy => _policy;

  /// Tek bir delta pull/push döngüsü koşar; çakışma gelirse [mergeEntityPayload3Way]
  /// ile otomatik birleştirip en fazla 1 kez daha gönderir.
  Future<SyncCycleSummary> syncNow({int limit = 200}) async {
    var pushed = 0;
    var pulled = 0;
    var sharedPulled = 0;
    var conflictsResolved = 0;

    for (var attempt = 0; attempt < 2; attempt++) {
      final changes = outbox.pendingChanges;
      final byKey = {for (final c in changes) c.compositeKey: c};

      final res = await transport.pushPull(
        SyncPushPullRequest(
          cursorSeq: outbox.cursorSeq,
          sharedCursorMs: outbox.sharedCursorMs,
          limit: limit,
          changes: changes,
        ),
      );
      _policy = res.policy;
      pushed += res.applied.length;
      pulled += res.entities.length;
      sharedPulled += res.sharedEntities.length;

      await outbox.commitServerResponse(res);

      if (res.entities.isNotEmpty && onRemoteEntities != null) {
        await onRemoteEntities!(res.entities);
      }
      if (res.sharedEntities.isNotEmpty && onSharedEntities != null) {
        await onSharedEntities!(res.sharedEntities);
      }

      if (res.conflicts.isEmpty) break;

      for (final conflict in res.conflicts) {
        final local = byKey[conflict.compositeKey];
        if (local == null) continue;
        final mergedPayload = conflict.serverEncrypted || local.encrypted
            // Şifreli gövde sunucuda açılamaz → yerel son düzenleme kazanır.
            ? local.payload
            : mergeEntityPayload3Way(
                baseRaw: local.basePayload,
                localRaw: local.payload,
                remoteRaw: conflict.serverPayload,
              ).merged;
        await outbox.replaceWithMerged(
          merged: SyncChange(
            kind: local.kind,
            id: local.id,
            baseVersion: conflict.serverVersion,
            payload: mergedPayload,
            deleted: local.deleted,
            encrypted: local.encrypted,
          ),
          serverVersion: conflict.serverVersion,
          serverSnapshot: conflict.serverPayload,
        );
        conflictsResolved++;
      }
    }

    return SyncCycleSummary(
      pushedCount: pushed,
      pulledCount: pulled,
      sharedPulledCount: sharedPulled,
      conflictsResolved: conflictsResolved,
      cursorSeq: outbox.cursorSeq,
      policy: _policy,
    );
  }
}

/// **WEB LITE TOPLU YAZIM GÜNLÜĞÜ** (PLAN §8 Faz 2: `lite_sync.dart` Web
/// IndexedDB/kalıcı depo toplu yazım düzeltmesi).
///
/// Mobilde [LocalNotesStore.journalFor] diske yazar; Web'de `dart:io` olmadığı
/// için Lite seyreltmesi devre dışı kalıyordu. Bu depo `SharedPreferences`
/// (Web'de kalıcı tarayıcı deposu) üstünde notları tek anahtarda toplu olarak
/// saklar, böylece Web Lite oturumunda da yazımlar güvenle biriktirilip
/// çökmeye/sekme kapanmasına karşı korunur ve açılışta kurtarılır.
class WebLiteJournal {
  WebLiteJournal(this._prefs, {required this.uid}) {
    _load();
  }

  final SharedPreferences _prefs;
  final String uid;

  /// Tarayıcı kotasını aşmamak için toplam günlük tavanı (~1,5 MB).
  static const int maxTotalChars = 1500000;

  String get _prefsKey => 'web_lite_journal_v1_$uid';
  final Map<String, Map<String, dynamic>> _docs = {};

  bool get isEmpty => _docs.isEmpty;
  bool contains(String id) => _docs.containsKey(id);

  Map<String, Map<String, dynamic>> rawEntries() => {
    for (final e in _docs.entries) e.key: Map<String, dynamic>.from(e.value),
  };

  void put(String id, Map<String, dynamic> firestoreMap) {
    _docs[id] = Map<String, dynamic>.from(firestoreMap);
    unawaited(_save());
  }

  void remove(String id) {
    if (_docs.remove(id) != null) unawaited(_save());
  }

  Future<void> flush() => _save();

  void _load() {
    final raw = _prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      for (final e in decoded.entries) {
        final v = _decode(e.value);
        if (v is Map<String, dynamic>) _docs[e.key.toString()] = v;
      }
    } catch (_) {
      // Bozuk kayıt sessizce temizlenir.
    }
  }

  Future<void> _save() async {
    if (_docs.isEmpty) {
      await _prefs.remove(_prefsKey);
      return;
    }
    final encoded = jsonEncode(_encode(_docs));
    if (encoded.length > maxTotalChars) return;
    await _prefs.setString(_prefsKey, encoded);
  }

  static Object? _encode(Object? v) {
    if (v is Timestamp) return {'__ts': v.millisecondsSinceEpoch};
    if (v is DateTime) return {'__ts': v.millisecondsSinceEpoch};
    if (v is FieldValue) return {'__ts': DateTime.now().millisecondsSinceEpoch};
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): _encode(e.value)};
    }
    if (v is List) return [for (final e in v) _encode(e)];
    return v;
  }

  static Object? _decode(Object? v) {
    if (v is Map) {
      if (v.length == 1 && v['__ts'] is int) {
        return Timestamp.fromMillisecondsSinceEpoch(v['__ts'] as int);
      }
      return <String, dynamic>{
        for (final e in v.entries) e.key.toString(): _decode(e.value),
      };
    }
    if (v is List) return [for (final e in v) _decode(e)];
    return v;
  }
}
