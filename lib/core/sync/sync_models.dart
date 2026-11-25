import 'package:flutter/foundation.dart' show immutable;

import '../../features/entitlement/domain/entitlement.dart';

/// Cloudflare D1 `entities.kind` değerleri (`cloudflare/src/sync.ts` ile aynı).
enum SyncEntityKind {
  note('note'),
  folder('folder'),
  event('event'),
  task('task'),
  taskList('task_list'),
  routine('routine'),
  pref('pref'),
  shopPrice('shop_price'),
  shopMeta('shop_meta'),
  friend('friend');

  const SyncEntityKind(this.wire);
  final String wire;

  static SyncEntityKind? tryParse(String? raw) {
    for (final k in values) {
      if (k.wire == raw) return k;
    }
    return null;
  }
}

/// Yerel Outbox'ta biriken tek bir değişiklik.
@immutable
class SyncChange {
  const SyncChange({
    required this.kind,
    required this.id,
    required this.baseVersion,
    required this.payload,
    this.deleted = false,
    this.encrypted = false,
    this.basePayload,
    this.queuedAtMs = 0,
  });

  final SyncEntityKind kind;
  final String id;
  final int baseVersion;
  final Object? payload;
  final bool deleted;
  final bool encrypted;

  /// Çakışma durumunda 3-yönlü birleştirme (`mergeText3`/`mergeItems3`) için
  /// son eşitlenen ortak taban kopya (yalnız yerelde tutulur, ağa gitmez).
  final Object? basePayload;
  final int queuedAtMs;

  String get compositeKey => '${kind.wire}:$id';

  Map<String, Object?> toWireJson() => {
    'kind': kind.wire,
    'id': id,
    'baseVersion': baseVersion,
    'payload': payload,
    if (deleted) 'deleted': true,
    if (encrypted) 'encrypted': true,
  };

  Map<String, Object?> toStorageJson() => {
    ...toWireJson(),
    if (basePayload != null) 'basePayload': basePayload,
    'queuedAtMs': queuedAtMs,
  };

  static SyncChange? fromStorageJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = SyncEntityKind.tryParse(raw['kind'] as String?);
    final id = raw['id'] as String?;
    if (kind == null || id == null || id.isEmpty) return null;
    return SyncChange(
      kind: kind,
      id: id,
      baseVersion: (raw['baseVersion'] as num?)?.toInt() ?? 0,
      payload: raw['payload'],
      deleted: raw['deleted'] == true,
      encrypted: raw['encrypted'] == true,
      basePayload: raw['basePayload'],
      queuedAtMs: (raw['queuedAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Sunucudan dönen kabul edilmiş yazım özeti.
@immutable
class SyncAppliedResult {
  const SyncAppliedResult({
    required this.kind,
    required this.id,
    required this.version,
    required this.seq,
    required this.updatedAtMs,
    this.deletedAtMs,
  });

  final SyncEntityKind kind;
  final String id;
  final int version;
  final int seq;
  final int updatedAtMs;
  final int? deletedAtMs;

  static SyncAppliedResult? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = SyncEntityKind.tryParse(raw['kind'] as String?);
    final id = raw['id'] as String?;
    if (kind == null || id == null) return null;
    return SyncAppliedResult(
      kind: kind,
      id: id,
      version: (raw['version'] as num?)?.toInt() ?? 1,
      seq: (raw['seq'] as num?)?.toInt() ?? 0,
      updatedAtMs: (raw['updatedAt'] as num?)?.toInt() ?? 0,
      deletedAtMs: (raw['deletedAt'] as num?)?.toInt(),
    );
  }
}

/// İyimser eşzamanlılık çakışması (`baseVersion != serverVersion`).
@immutable
class SyncConflict {
  const SyncConflict({
    required this.kind,
    required this.id,
    required this.clientBaseVersion,
    required this.serverVersion,
    required this.serverSeq,
    required this.serverUpdatedAtMs,
    required this.serverPayload,
    this.serverDeletedAtMs,
    this.serverEncrypted = false,
  });

  final SyncEntityKind kind;
  final String id;
  final int clientBaseVersion;
  final int serverVersion;
  final int serverSeq;
  final int serverUpdatedAtMs;
  final int? serverDeletedAtMs;
  final bool serverEncrypted;
  final Object? serverPayload;

  String get compositeKey => '${kind.wire}:$id';

  static SyncConflict? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = SyncEntityKind.tryParse(raw['kind'] as String?);
    final id = raw['id'] as String?;
    if (kind == null || id == null) return null;
    return SyncConflict(
      kind: kind,
      id: id,
      clientBaseVersion: (raw['clientBaseVersion'] as num?)?.toInt() ?? 0,
      serverVersion: (raw['serverVersion'] as num?)?.toInt() ?? 1,
      serverSeq: (raw['serverSeq'] as num?)?.toInt() ?? 0,
      serverUpdatedAtMs: (raw['serverUpdatedAt'] as num?)?.toInt() ?? 0,
      serverDeletedAtMs: (raw['serverDeletedAt'] as num?)?.toInt(),
      serverEncrypted: raw['serverEncrypted'] == true,
      serverPayload: raw['serverPayload'],
    );
  }
}

/// Sunucudan delta ile çekilen kayıt.
@immutable
class SyncEntityRecord {
  const SyncEntityRecord({
    required this.kind,
    required this.id,
    required this.seq,
    required this.version,
    required this.updatedAtMs,
    required this.payload,
    this.deletedAtMs,
    this.encrypted = false,
  });

  final SyncEntityKind kind;
  final String id;
  final int seq;
  final int version;
  final int updatedAtMs;
  final int? deletedAtMs;
  final bool encrypted;
  final Object? payload;

  bool get isDeleted => deletedAtMs != null;
  String get compositeKey => '${kind.wire}:$id';

  static SyncEntityRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = SyncEntityKind.tryParse(raw['kind'] as String?);
    final id = raw['id'] as String?;
    if (kind == null || id == null) return null;
    return SyncEntityRecord(
      kind: kind,
      id: id,
      seq: (raw['seq'] as num?)?.toInt() ?? 0,
      version: (raw['version'] as num?)?.toInt() ?? 1,
      updatedAtMs: (raw['updatedAt'] as num?)?.toInt() ?? 0,
      deletedAtMs: (raw['deletedAt'] as num?)?.toInt(),
      encrypted: raw['encrypted'] == true,
      payload: raw['payload'],
    );
  }
}

/// Aktif paylaşımla gelen başkasının kaydı.
@immutable
class SharedSyncEntityRecord {
  const SharedSyncEntityRecord({
    required this.ownerUid,
    required this.kind,
    required this.id,
    required this.role,
    required this.version,
    required this.updatedAtMs,
    required this.payload,
    this.deletedAtMs,
    this.encrypted = false,
  });

  final String ownerUid;
  final SyncEntityKind kind;
  final String id;
  final String role;
  final int version;
  final int updatedAtMs;
  final int? deletedAtMs;
  final bool encrypted;
  final Object? payload;

  static SharedSyncEntityRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = SyncEntityKind.tryParse(raw['kind'] as String?);
    final id = raw['id'] as String?;
    final ownerUid = raw['ownerUid'] as String?;
    if (kind == null || id == null || ownerUid == null) return null;
    return SharedSyncEntityRecord(
      ownerUid: ownerUid,
      kind: kind,
      id: id,
      role: raw['role'] as String? ?? 'read',
      version: (raw['version'] as num?)?.toInt() ?? 1,
      updatedAtMs: (raw['updatedAt'] as num?)?.toInt() ?? 0,
      deletedAtMs: (raw['deletedAt'] as num?)?.toInt(),
      encrypted: raw['encrypted'] == true,
      payload: raw['payload'],
    );
  }
}

/// Sunucunun bildirdiği Lite vs Tam Sürüm senkron hız politikası.
@immutable
class SyncCadencePolicy {
  const SyncCadencePolicy({
    this.isLite = true,
    this.debounceMs = 1500,
    this.intervalSec = 300,
    this.flushOnBackground = true,
    this.liveShoppingWs = false,
  });

  final bool isLite;
  final int debounceMs;
  final int intervalSec;
  final bool flushOnBackground;
  final bool liveShoppingWs;

  Duration get interval => Duration(seconds: intervalSec.clamp(15, 900));
  Duration get debounce => Duration(milliseconds: debounceMs.clamp(500, 10000));

  static SyncCadencePolicy fromJson(Object? raw) {
    if (raw is! Map) return const SyncCadencePolicy();
    return SyncCadencePolicy(
      isLite: raw['mode'] != 'full',
      debounceMs: (raw['debounceMs'] as num?)?.toInt() ?? 1500,
      intervalSec: (raw['intervalSec'] as num?)?.toInt() ?? 300,
      flushOnBackground: raw['flushOnBackground'] != false,
      liveShoppingWs: raw['liveShoppingWs'] == true,
    );
  }
}

@immutable
class SyncPushPullRequest {
  const SyncPushPullRequest({
    required this.cursorSeq,
    this.sharedCursorMs = 0,
    this.limit = 200,
    this.changes = const [],
  });

  final int cursorSeq;
  final int sharedCursorMs;
  final int limit;
  final List<SyncChange> changes;

  Map<String, Object?> toJson() => {
    'cursorSeq': cursorSeq,
    'sharedCursorMs': sharedCursorMs,
    'limit': limit,
    'changes': [for (final c in changes) c.toWireJson()],
  };
}

@immutable
class SyncPushPullResponse {
  const SyncPushPullResponse({
    required this.cursorSeq,
    required this.sharedCursorMs,
    required this.serverTimeMs,
    required this.hasMore,
    required this.applied,
    required this.conflicts,
    required this.entities,
    required this.sharedEntities,
    required this.policy,
  });

  final int cursorSeq;
  final int sharedCursorMs;
  final int serverTimeMs;
  final bool hasMore;
  final List<SyncAppliedResult> applied;
  final List<SyncConflict> conflicts;
  final List<SyncEntityRecord> entities;
  final List<SharedSyncEntityRecord> sharedEntities;
  final SyncCadencePolicy policy;

  factory SyncPushPullResponse.fromJson(Map<String, dynamic> map) {
    return SyncPushPullResponse(
      cursorSeq: (map['cursorSeq'] as num?)?.toInt() ?? 0,
      sharedCursorMs: (map['sharedCursorMs'] as num?)?.toInt() ?? 0,
      serverTimeMs: (map['serverTimeMs'] as num?)?.toInt() ?? 0,
      hasMore: map['hasMore'] == true,
      applied: [
        for (final r in (map['applied'] as List?) ?? const [])
          ?SyncAppliedResult.fromJson(r),
      ],
      conflicts: [
        for (final r in (map['conflicts'] as List?) ?? const [])
          ?SyncConflict.fromJson(r),
      ],
      entities: [
        for (final r in (map['entities'] as List?) ?? const [])
          ?SyncEntityRecord.fromJson(r),
      ],
      sharedEntities: [
        for (final r in (map['sharedEntities'] as List?) ?? const [])
          ?SharedSyncEntityRecord.fromJson(r),
      ],
      policy: SyncCadencePolicy.fromJson(map['policy']),
    );
  }
}

/// `GET /v1/entitlement` ve `POST /v1/billing/verify` yanıtı.
@immutable
class RemoteEntitlement {
  const RemoteEntitlement({
    required this.entitlement,
    this.remainingCalls,
    this.remainingTokens,
  });

  final Entitlement entitlement;
  final int? remainingCalls;
  final int? remainingTokens;

  factory RemoteEntitlement.fromJson(Map<String, dynamic> map) {
    final ent = Entitlement.fromMap({
      'tier': map['tier'],
      'lifetimeOwned': map['lifetimeOwned'] == true,
      'decisionCredits': map['decisionCredits'] ?? 0,
      'decisionTokenCredits': map['decisionTokenCredits'] ?? 0,
      if (map['proUntil'] is num)
        'proUntil': DateTime.fromMillisecondsSinceEpoch(
          (map['proUntil'] as num).toInt(),
          isUtc: true,
        ),
      if (map['trialEndsAt'] is num)
        'trialEndsAt': DateTime.fromMillisecondsSinceEpoch(
          (map['trialEndsAt'] as num).toInt(),
          isUtc: true,
        ),
    });
    return RemoteEntitlement(
      entitlement: ent,
      remainingCalls: _sumBucket(map['remaining']),
      remainingTokens: _sumBucket(map['remainingTokens']),
    );
  }

  static int? _sumBucket(Object? raw) {
    if (raw is! Map) return null;
    var sum = 0;
    var found = false;
    for (final v in raw.values) {
      if (v is num) {
        sum += v.toInt().clamp(0, 1000000000);
        found = true;
      }
    }
    return found ? sum : null;
  }
}

/// `PUT /v1/media/:key` yanıtı.
@immutable
class MediaUploadResult {
  const MediaUploadResult({
    required this.key,
    required this.sizeBytes,
    required this.bytesUsed,
    required this.quotaBytes,
  });

  final String key;
  final int sizeBytes;
  final int bytesUsed;
  final int quotaBytes;

  factory MediaUploadResult.fromJson(Map<String, dynamic> map) =>
      MediaUploadResult(
        key: map['key'] as String? ?? '',
        sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
        bytesUsed: (map['bytesUsed'] as num?)?.toInt() ?? 0,
        quotaBytes: (map['quotaBytes'] as num?)?.toInt() ?? 262144000,
      );
}
