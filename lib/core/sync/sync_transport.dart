import 'dart:typed_data';

import 'sync_models.dart';

/// Senkron taşıyıcı hata türleri (üst katmanlar HTTP kodlarına bağımlı olmaz).
class SyncTransportException implements Exception {
  const SyncTransportException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'SyncTransportException($code, $statusCode): $message';
}

class SyncAuthException extends SyncTransportException {
  const SyncAuthException(super.code, super.message, {super.statusCode});
}

class SyncQuotaException extends SyncTransportException {
  const SyncQuotaException(super.code, super.message, {super.statusCode});
}

class SyncKillSwitchException extends SyncTransportException {
  const SyncKillSwitchException(super.code, super.message, {super.statusCode});
}

/// **SENKRON TAŞIYICI SOYUTLAMASI** (PLAN §5.6, Faz 2).
///
/// İstemci katmanları (Notlar, Klasörler, Takvim, Haklar, Decisions, Medya)
/// doğrudan HTTP veya Firestore ayrıntısına değil bu arayüze konuşur;
/// Cloudflare Worker (`CloudflareSyncTransport`) ya da test içi bellek
/// taşıyıcısı takılıp çıkarılabilir.
abstract class SyncTransport {
  /// Tek uç noktalı delta pull/push (`POST /v1/sync`).
  Future<SyncPushPullResponse> pushPull(SyncPushPullRequest request);

  /// Kullanıcının güncel hak ve Decisions kotası (`GET /v1/entitlement`).
  Future<RemoteEntitlement> fetchEntitlement();

  /// Google Play satın alma doğrulaması (`POST /v1/billing/verify`).
  Future<RemoteEntitlement> verifyPurchase({
    required String productId,
    required String purchaseToken,
  });

  /// Decisions API sunucu vekili (`POST /v1/decide`).
  /// Ham yanıt haritası `{response, remaining, remainingTokens}` döner.
  Future<Map<String, dynamic>?> decide(
    Map<String, Object?> body, {
    Duration? timeout,
  });

  /// D1 indeksli kullanıcı arama (`GET /v1/users/search`).
  Future<List<Map<String, dynamic>>> searchUsers(String query);

  /// Kullanıcı dizini kaydını güncelle (`PUT /v1/users/me`).
  Future<void> upsertUserDirectory({
    required String name,
    required String email,
    required bool discoverable,
  });

  /// Ortak not/klasör paylaşımı oluştur/güncelle (`POST /v1/shares`).
  Future<void> upsertShare({
    required String entityKind,
    required String entityId,
    required String memberUid,
    String role = 'both',
    String status = 'active',
  });

  /// R2 ortak medya yükleme (`PUT /v1/media/:key`, 250 MB kişi kotası).
  Future<MediaUploadResult> uploadMedia({
    required String key,
    required Uint8List bytes,
    required String contentType,
    String? noteId,
  });

  /// R2 ortak medya okuma (`GET /v1/media/:key`, \$0 egress).
  Future<Uint8List> downloadMedia(String key);

  /// R2 ortak medya silme (`DELETE /v1/media/:key`).
  Future<void> deleteMedia(String key);

  /// Bulut senkronundaki tüm kullanıcı verilerini kalıcı siler
  /// (`DELETE /v1/users/me`).
  Future<void> deleteAccount();
}
