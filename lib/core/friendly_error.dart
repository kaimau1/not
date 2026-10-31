import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import 'error_log.dart';

/// İletisi uygulamanın kendi yazdığı, kullanıcıya olduğu gibi gösterilebilen
/// istisna (ör. `GeminiException`: "Kota aşıldı, sonra tekrar deneyin").
abstract interface class UserFacingException implements Exception {
  String get message;
}

/// Kullanıcıya gösterilen hatanın türü (bkz. [friendlyError]).
enum ErrorKind {
  offline,
  timeout,
  quota,
  permission,
  tooLarge,
  unsupported,
  unknown,
}

/// Bir istisnayı kaba türüne ayırır. Tür denetimi önce (Firebase kodları,
/// zaman aşımı, desteklenmeyen işlem), sonra metin — paket türlerine
/// (`SocketException`, `ClientException`, Dio…) bağımlı kalmamak ve web'de de
/// aynı sonucu vermek için. Web'de sınıf adları küçültülür; o yüzden metin
/// eşleşmesi sınıf ADINA değil, iletiye bakar.
ErrorKind classifyError(Object error) {
  if (error is TimeoutException) return ErrorKind.timeout;
  if (error is UnsupportedError || error is MissingPluginException) {
    return ErrorKind.unsupported;
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'network-request-failed':
        return ErrorKind.offline;
      case 'deadline-exceeded':
        return ErrorKind.timeout;
      case 'resource-exhausted':
      case 'quota-exceeded':
        return ErrorKind.quota;
      case 'permission-denied':
      case 'unauthorized':
      case 'unauthenticated':
        return ErrorKind.permission;
    }
  }
  final text = '$error'.toLowerCase();
  bool has(List<String> parts) => parts.any(text.contains);
  if (has(const [
    'socketexception',
    'failed host lookup',
    'network is unreachable',
    'connection refused',
    'connection reset',
    'connection closed',
    'network-request-failed',
    'xmlhttprequest error',
    'failed to fetch',
    'clientexception',
    'bağlantı hatası',
  ])) {
    return ErrorKind.offline;
  }
  if (has(const ['timed out', 'timeout', 'deadline'])) return ErrorKind.timeout;
  if (has(const [
    'quota',
    'kota',
    'rate limit',
    'resource_exhausted',
    'resource-exhausted',
    'too many requests',
  ])) {
    return ErrorKind.quota;
  }
  if (has(const ['permission', 'izin', 'not authorized', 'unauthorized'])) {
    return ErrorKind.permission;
  }
  if (has(const ['too large', 'toolarge', 'çok büyük'])) {
    return ErrorKind.tooLarge;
  }
  if (has(const ['unsupported operation', 'not supported', 'unimplemented'])) {
    return ErrorKind.unsupported;
  }
  return ErrorKind.unknown;
}

/// Ham istisnayı kısa, anlaşılır bir metne çevirir (F10.4, 2026-10-31).
///
/// KÖK NEDEN: ~80 yerde `genericError('$e')` / `aiError('$e')` kullanıcıya
/// "Unsupported operation: RawReceivePort" ya da
/// "[cloud_firestore/permission-denied] …" gibi ham metin basıyordu. Artık
/// çağıran kendi cümlesini ("Ek eklenemedi: …") korur, yer tutucuya bu metin
/// girer. Ham metin kaybolmaz: [ErrorLog]a yazılır (Ayarlar → Hakkında →
/// "Hata günlüğünü paylaş").
///
/// Uygulamanın kendi ürettiği, zaten okunur iletiler ([UserFacingException]
/// — ör. `GeminiException`) türü bilinmiyorsa olduğu gibi gösterilir.
String friendlyError(AppLocalizations l10n, Object error) {
  ErrorLog.record('ui', error);
  final text = switch (classifyError(error)) {
    ErrorKind.offline => l10n.errorOffline,
    ErrorKind.timeout => l10n.errorTimeout,
    ErrorKind.quota => l10n.errorQuota,
    ErrorKind.permission => l10n.errorPermission,
    ErrorKind.tooLarge => l10n.errorTooLarge,
    ErrorKind.unsupported => l10n.errorUnsupported,
    ErrorKind.unknown =>
      error is UserFacingException ? error.message : l10n.errorUnknown,
  };
  _last = (
    text: text,
    raw: '$error',
    label: l10n.copyErrorDetail,
    at: DateTime.now(),
  );
  return text;
}

({String text, String raw, String label, DateTime at})? _last;

/// Az önce [friendlyError]den geçmiş bir hatanın bildirimi mi? Öyleyse ham
/// metin ve "Ayrıntıyı kopyala" etiketi döner — `showMessage` bildirime bu
/// eylemi kendiliğinden ekler (her çağrı yerine ayrı ayrı eklemek yerine).
/// Pencere 5 sn: hata ile bildirim arasında `await` olabilir.
({String raw, String label})? errorDetailFor(String message) {
  final last = _last;
  if (last == null) return null;
  if (DateTime.now().difference(last.at) > const Duration(seconds: 5)) {
    return null;
  }
  if (!message.contains(last.text)) return null;
  // Ham metin kullanıcı metniyle aynıysa (okunur ileti) kopyalanacak bir
  // ayrıntı yok.
  if (last.raw == last.text) return null;
  return (raw: last.raw, label: last.label);
}
