import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../auth/data/android_google_auth.dart';
import '../../auth/data/desktop_oauth_flow.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';

/// **EKLERİN GOOGLE DRIVE SENKRONU** (kullanıcı isteği 2026-10-15: "eklerin
/// ve görsellerin senkronizasyonu Google Drive'a bağlanabilir mi, oradaki
/// kota kullanılsa daha iyi olur — Google ile giriş yapanlarda; diğerlerinde
/// sadece metin senkronu olsun").
///
/// KARARLAR:
/// * Kapsam `drive.appdata`: dosyalar kullanıcının Drive'ında, uygulamaya
///   ÖZEL gizli klasörde durur (Drive listesini kirletmez, yanlışlıkla
///   taşınıp silinemez) ve KULLANICININ kotasından düşer. Google'ın
///   "hassas olmayan" kapsamlarından — doğrulama gerektirmez. Kullanıcı
///   alanı Drive → Ayarlar → Uygulamaları yönet'ten görür/siler.
/// * Drive dosyası ÖZELDİR (herkese açık adres yok). Başka cihaz dosyayı
///   kendi yetkisiyle indirip yerel kopyaya yazar; uygulamanın her ekranı
///   zaten önce yerel kopyaya bakıyor (bkz. `Attachment.driveId`).
/// * Ortak çalışanlar Drive dosyasına erişemez: PAYLAŞILAN notun ekleri eski
///   yoldan (Firebase Storage) gider (bkz. `UploadQueue`).
/// * Web'de dosya sistemi yok: orada eski yol sürer.
const kDriveScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Ek senkronunun kipi — hesaba ve platforma göre.
enum AttachmentSyncMode {
  /// Google hesabı (Android/Windows): ekler kullanıcının Google Drive'ına.
  drive,

  /// Google'sız (misafir) hesap: yalnız METİN senkronlanır, ekler cihazda.
  textOnly,

  /// Web: dosya sistemi yok, ekler doğrudan Firebase Storage'a (eski yol).
  storage,
}

/// Oturumdaki hesap Google hesabı mı (misafir/anonim değil).
bool isGoogleUser(User? user) =>
    user != null &&
    !user.isAnonymous &&
    user.providerData.any((p) => p.providerId == 'google.com');

/// Saf karar (test edilir).
AttachmentSyncMode attachmentSyncModeFor({
  required bool web,
  required bool googleUser,
}) {
  if (web) return AttachmentSyncMode.storage;
  return googleUser ? AttachmentSyncMode.drive : AttachmentSyncMode.textOnly;
}

final attachmentSyncModeProvider = Provider<AttachmentSyncMode>((ref) {
  final user = ref.watch(authStateProvider).value;
  return attachmentSyncModeFor(web: kIsWeb, googleUser: isGoogleUser(user));
});

/// Kullanıcı Drive'ı BAĞLADI mı (bir kez izin verdi)? Arka plandaki
/// sessiz token istekleri yalnız bağlıysa yapılır; bağlı değilken ekler
/// "Drive bağlantısı bekliyor" olarak cihazda durur.
final driveConnectedProvider = NotifierProvider<DriveConnectedNotifier, bool>(
  DriveConnectedNotifier.new,
);

class DriveConnectedNotifier extends Notifier<bool> {
  String get _key => 'drive_connected_${ref.read(currentUidProvider) ?? ''}';

  @override
  bool build() {
    ref.watch(currentUidProvider);
    return ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
  }

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Cihazdaki ek dosyalarının "değişti" sayacı. Drive'dan bir ek inince
/// artar; kartlar ve editör bunu izleyip yerel kopyayı yeniden arar (ekranlar
/// dosyanın varlığını çizim anında soruyor, kendiliğinden haberleri olmaz).
final localFilesRevisionProvider = NotifierProvider<LocalFilesRevision, int>(
  LocalFilesRevision.new,
);

class LocalFilesRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// Kalıcı silmede (çöp boşaltma) Drive dosyasını da silen kanca. Not deposu
/// Drive'ı tanımıyor; sağlayıcı kurulunca buraya bağlanır.
Future<void> Function(String driveId)? driveFileDeleter;

// ── Yetki ────────────────────────────────────────────────────────────────

/// Drive erişim jetonu kaynağı (platforma göre).
abstract class DriveAuth {
  /// Kullanıcıya bir şey göstermeden jeton; yoksa null.
  Future<String?> accessToken();

  /// Kullanıcıdan izin ister (onay ekranı). Başarılıysa true.
  Future<bool> connect();

  /// Sunucu jetonu reddetti (401): önbellekteki jeton atılır.
  Future<void> invalidate(String token);

  /// Bağlantıyı keser (jeton/yenileme anahtarı silinir).
  Future<void> disconnect();
}

/// Android: google_sign_in'in YETKİ istemcisi. Hesap, Firebase oturumunun
/// e-postasıyla belirtilir — cihazda birden çok Google hesabı varsa yanlış
/// hesabın Drive'ına yazılmasın.
class AndroidDriveAuth implements DriveAuth {
  AndroidDriveAuth({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  String? get _email {
    final user = _auth.currentUser;
    if (user == null) return null;
    for (final p in user.providerData) {
      if (p.providerId == 'google.com' && p.email != null) return p.email;
    }
    return user.email;
  }

  Future<String?> _authorize({required bool prompt}) async {
    await AndroidGoogleAuth.ensureInitialized();
    final data = await GoogleSignInPlatform.instance
        .clientAuthorizationTokensForScopes(
          ClientAuthorizationTokensForScopesParameters(
            request: AuthorizationRequestDetails(
              scopes: const [kDriveScope],
              userId: null,
              email: _email,
              promptIfUnauthorized: prompt,
            ),
          ),
        );
    return data?.accessToken;
  }

  @override
  Future<String?> accessToken() async {
    try {
      return await _authorize(prompt: false);
    } catch (e) {
      debugPrint('Drive jetonu alınamadı: $e');
      return null;
    }
  }

  @override
  Future<bool> connect() async => (await _authorize(prompt: true)) != null;

  @override
  Future<void> invalidate(String token) async {
    try {
      await AndroidGoogleAuth.ensureInitialized();
      await GoogleSignInPlatform.instance.clearAuthorizationToken(
        ClearAuthorizationTokenParams(accessToken: token),
      );
    } catch (_) {}
  }

  @override
  Future<void> disconnect() async {}
}

/// Windows: tarayıcıda yetki (loopback + PKCE) ve güvenli depoda saklanan
/// YENİLEME anahtarı.
///
/// Giriş akışı yenileme anahtarı İSTEMİYOR (kimse okumuyordu — bkz.
/// DesktopOAuthFlow). Drive senkronu arka planda saatlerce çalıştığı için
/// burada gerekiyor: yalnız `drive.appdata` kapsamlı, ayrı bir anahtar;
/// çıkışta silinir (bkz. TokenStore.clear).
class DesktopDriveAuth implements DriveAuth {
  DesktopDriveAuth({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const refreshKey = 'google_drive_refresh_token';

  String? _token;
  DateTime? _expires;

  @override
  Future<String?> accessToken() async {
    final token = _token;
    final expires = _expires;
    if (token != null &&
        expires != null &&
        DateTime.now().isBefore(expires.subtract(const Duration(minutes: 2)))) {
      return token;
    }
    final refresh = await _storage.read(key: refreshKey);
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        body: {
          'client_id': AppConstants.desktopClientId,
          'client_secret': AppConstants.desktopClientSecret,
          'refresh_token': refresh,
          'grant_type': 'refresh_token',
        },
      );
      if (response.statusCode != 200) {
        // Anahtar iptal edilmiş (kullanıcı Google hesabından erişimi
        // kaldırdı): yeniden bağlanması gerekir.
        if (response.statusCode == 400 || response.statusCode == 401) {
          await _storage.delete(key: refreshKey);
        }
        return null;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _token = json['access_token'] as String?;
      _expires = DateTime.now().add(
        Duration(seconds: (json['expires_in'] as num?)?.toInt() ?? 3600),
      );
      return _token;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> connect() async {
    final tokens = await DesktopOAuthFlow(
      scopes: const [kDriveScope],
      offline: true,
    ).run();
    _token = tokens.accessToken;
    _expires = DateTime.now().add(Duration(seconds: tokens.expiresIn));
    final refresh = tokens.refreshToken;
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: refreshKey, value: refresh);
    }
    return true;
  }

  @override
  Future<void> invalidate(String token) async {
    if (_token == token) {
      _token = null;
      _expires = null;
    }
  }

  @override
  Future<void> disconnect() async {
    _token = null;
    _expires = null;
    await _storage.delete(key: refreshKey);
  }
}

/// Drive'ın olmadığı yer (web, testler).
class NoDriveAuth implements DriveAuth {
  const NoDriveAuth();

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> connect() async => false;

  @override
  Future<void> invalidate(String token) async {}

  @override
  Future<void> disconnect() async {}
}

final driveAuthProvider = Provider<DriveAuth>((ref) {
  if (kIsWeb) return const NoDriveAuth();
  if (Platform.isAndroid) return AndroidDriveAuth();
  if (Platform.isWindows) return DesktopDriveAuth();
  return const NoDriveAuth();
});

/// Drive deposu — yalnız Google hesabında VE Drive bağlıyken; aksi hâlde
/// null (kuyruk ekleri cihazda tutar).
final driveStoreProvider = Provider<DriveStore?>((ref) {
  if (ref.watch(attachmentSyncModeProvider) != AttachmentSyncMode.drive) {
    driveFileDeleter = null;
    return null;
  }
  if (!ref.watch(driveConnectedProvider)) {
    driveFileDeleter = null;
    return null;
  }
  final store = DriveStore(ref.watch(driveAuthProvider));
  driveFileDeleter = store.delete;
  ref.onDispose(store.close);
  return store;
});

/// Drive'a bağlanılamadı: jeton yok (izin geri alındı) ya da API kapalı.
class DriveUnavailableException implements Exception {
  const DriveUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'DriveUnavailableException: $message';
}

// ── Depo ─────────────────────────────────────────────────────────────────

/// Drive REST v3 üzerinden uygulama klasörüne (appDataFolder) dosya
/// yükler, indirir ve siler. Paket bağımlılığı yok: üç uç nokta, `http`.
class DriveStore {
  DriveStore(this._auth, {http.Client? client})
    : _client = client ?? http.Client();

  final DriveAuth _auth;
  final http.Client _client;

  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';

  void close() => _client.close();

  /// Yetkili istek; sunucu jetonu reddederse (401) jeton atılır ve BİR KEZ
  /// yeniden denenir (önbellekteki jeton süresi dolmuş olabilir).
  Future<http.StreamedResponse> _send(
    Future<http.BaseRequest> Function(String token) build,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _auth.accessToken();
      if (token == null) {
        throw const DriveUnavailableException('no-token');
      }
      final response = await _client.send(await build(token));
      if (response.statusCode == 401 && attempt == 0) {
        await response.stream.drain<void>();
        await _auth.invalidate(token);
        continue;
      }
      return response;
    }
    throw const DriveUnavailableException('unauthorized');
  }

  static Future<String> _failure(http.StreamedResponse response) async {
    final body = await response.stream.bytesToString();
    return 'Drive ${response.statusCode}: '
        '${body.length > 300 ? body.substring(0, 300) : body}';
  }

  /// [file]'ı uygulama klasörüne yükler ve Drive dosya kimliğini döner.
  ///
  /// Sürdürülebilir (resumable) yükleme: önce oturum açılır, sonra dosya
  /// AKIŞ olarak gönderilir — 25 MB'lık bir PDF belleğe okunmaz.
  Future<String> upload(
    File file, {
    required String name,
    required String mimeType,
  }) async {
    final length = await file.length();
    final session = await _send((token) async {
      final request =
          http.Request(
              'POST',
              Uri.parse('$_upload?uploadType=resumable&fields=id'),
            )
            ..headers.addAll({
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
              'X-Upload-Content-Type': mimeType,
              'X-Upload-Content-Length': '$length',
            })
            ..body = jsonEncode({
              'name': name,
              'parents': ['appDataFolder'],
              'mimeType': mimeType,
            });
      return request;
    });
    if (session.statusCode != 200) {
      if (session.statusCode == 403) {
        throw DriveUnavailableException(await _failure(session));
      }
      throw HttpException(await _failure(session));
    }
    await session.stream.drain<void>();
    final location = session.headers['location'];
    if (location == null) throw const HttpException('Drive: oturum adresi yok');
    final put = http.StreamedRequest('PUT', Uri.parse(location))
      ..headers['Content-Type'] = mimeType
      ..contentLength = length;
    // `asFuture` KULLANILMAZ: aboneliğin onDone'unu ezer, gövde hiç
    // kapanmaz ve istek sonsuza dek asılı kalır (test bunu yakaladı).
    unawaited(() async {
      try {
        await for (final chunk in file.openRead()) {
          put.sink.add(chunk);
        }
      } catch (e, st) {
        put.sink.addError(e, st);
      } finally {
        await put.sink.close();
      }
    }());
    final response = await _client.send(put);
    final body = await response.stream.bytesToString();
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException('Drive ${response.statusCode}: $body');
    }
    final id = (jsonDecode(body) as Map<String, dynamic>)['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const HttpException('Drive: dosya kimliği dönmedi');
    }
    return id;
  }

  /// Dosyayı [target]'a indirir (önce geçici dosyaya, bitince yerine —
  /// yarım inen dosya "var" sanılmasın).
  Future<void> download(String fileId, File target) async {
    final response = await _send(
      (token) async => http.Request(
        'GET',
        Uri.parse('$_api/${Uri.encodeComponent(fileId)}?alt=media'),
      )..headers['Authorization'] = 'Bearer $token',
    );
    if (response.statusCode != 200) {
      throw HttpException(await _failure(response));
    }
    await target.parent.create(recursive: true);
    final temp = File('${target.path}.part');
    final sink = temp.openWrite();
    try {
      await response.stream.pipe(sink);
    } catch (_) {
      try {
        await temp.delete();
      } catch (_) {}
      rethrow;
    }
    await temp.rename(target.path);
  }

  /// Dosyayı baytlar olarak indirir (web dışı yedek yol — bkz.
  /// `AttachmentRepository.readBytes`).
  Future<Uint8List> downloadBytes(String fileId) async {
    final response = await _send(
      (token) async => http.Request(
        'GET',
        Uri.parse('$_api/${Uri.encodeComponent(fileId)}?alt=media'),
      )..headers['Authorization'] = 'Bearer $token',
    );
    if (response.statusCode != 200) {
      throw HttpException(await _failure(response));
    }
    return response.stream.toBytes();
  }

  /// Dosyayı siler; zaten yoksa (404) sessiz.
  Future<void> delete(String fileId) async {
    try {
      final response = await _send(
        (token) async => http.Request(
          'DELETE',
          Uri.parse('$_api/${Uri.encodeComponent(fileId)}'),
        )..headers['Authorization'] = 'Bearer $token',
      );
      await response.stream.drain<void>();
    } catch (e) {
      // Silinemeyen dosya yalnız yer kaplar; veri riski yok.
      debugPrint('Drive dosyası silinemedi ($fileId): $e');
    }
  }

  /// Drive'a ULAŞILABİLİYOR mu? null = evet; değilse sunucunun yanıtı
  /// (ör. Cloud projesinde Drive API kapalıysa `accessNotConfigured`).
  Future<String?> probe() async {
    try {
      final response = await _send(
        (token) async => http.Request(
          'GET',
          Uri.parse('$_api?spaces=appDataFolder&pageSize=1&fields=files(id)'),
        )..headers['Authorization'] = 'Bearer $token',
      );
      if (response.statusCode == 200) {
        await response.stream.drain<void>();
        return null;
      }
      return _failure(response);
    } catch (e) {
      return '$e';
    }
  }

  /// Drive'daki kullanım/tavan (bayt). Ayarlar ekranının göstergesi için;
  /// okunamazsa null.
  Future<({int used, int? limit})?> quota() async {
    try {
      final response = await _send(
        (token) async => http.Request(
          'GET',
          Uri.parse(
            'https://www.googleapis.com/drive/v3/about?fields=storageQuota',
          ),
        )..headers['Authorization'] = 'Bearer $token',
      );
      final body = await response.stream.bytesToString();
      if (response.statusCode != 200) return null;
      final q =
          (jsonDecode(body) as Map<String, dynamic>)['storageQuota']
              as Map<String, dynamic>?;
      if (q == null) return null;
      return (
        used: int.tryParse('${q['usage']}') ?? 0,
        limit: int.tryParse('${q['limit']}'),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Drive'a yüklenecek dosyanın adı: not + ek kimliği + özgün ad. Kimlikler
/// adı benzersiz yapar; özgün ad Drive'ın "Uygulamaları yönet" listesinde
/// ne olduğunu belli eder.
String driveFileName({
  required String noteId,
  required String attachmentId,
  required String fileName,
}) => '${noteId}_${attachmentId}_$fileName';
