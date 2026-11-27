import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/utils/gms.dart';
import '../../../core/utils/local_file.dart';
import '../../../core/utils/web_gis_auth.dart';
import '../../../core/utils/web_session.dart';
import '../../auth/data/android_google_auth.dart';
import '../../auth/data/google_scope_auth.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../entitlement/data/entitlement_service.dart';
import '../../entitlement/domain/entitlement.dart';
import '../../settings/settings_providers.dart';

/// **EKLERİN GOOGLE DRIVE SENKRONU** (kullanıcı isteği 2026-10-15: "eklerin
/// ve görsellerin senkronizasyonu Google Drive'a bağlanabilir mi, oradaki
/// kota kullanılsa daha iyi olur — Google ile giriş yapanlarda; diğerlerinde
/// sadece metin senkronu olsun").
///
/// KARARLAR:
/// * **2026-11-06 (F28.2/F19.E1, kullanıcı kararı):** yeni ekler kullanıcının
///   Drive'ında GÖRÜNÜR "Notlar" klasörüne gider (`drive.file` — yalnız
///   uygulamanın açtığı dosyalar, hassas değil). Eski ekler gizli uygulama
///   klasöründe (`drive.appdata`) kalır ve OKUNUR: iki kapsam tek jetonla
///   istenir, indirme kimlikle yapıldığı için hangi klasörde olduğu önemsiz.
///   Kotası KULLANICININ; dosyalar silinmez, taşınmaz.
/// * Drive dosyası ÖZELDİR (herkese açık adres yok). Başka cihaz dosyayı
///   kendi yetkisiyle indirip yerel kopyaya yazar; uygulamanın her ekranı
///   zaten önce yerel kopyaya bakıyor (bkz. `Attachment.driveId`).
/// * Ortak çalışanlar Drive dosyasına erişemez: PAYLAŞILAN notun ekleri eski
///   yoldan (Firebase Storage) gider (bkz. `UploadQueue`).
/// * Web'de dosya sistemi yok: orada eski yol sürer.
const kDriveScopes = [
  'https://www.googleapis.com/auth/drive.file',
  'https://www.googleapis.com/auth/drive.appdata',
];

/// Drive'da eklerin durduğu görünür klasörün adı (kökte).
const kDriveFolderName = 'Notlar';

/// Ek senkronunun kipi — hesaba ve platforma göre.
enum AttachmentSyncMode {
  /// Google hesabı (Android ve Web): ekler kullanıcının Google Drive'ına.
  drive,

  /// Google'sız (misafir) hesap: yalnız METİN senkronlanır, ekler cihazda/tarayıcıda.
  textOnly,

  /// Paylaşılan notlar veya özel hedefler: Firebase Storage.
  storage,
}

/// Oturumdaki hesap Google hesabı mı (misafir/anonim değil).
bool isGoogleUser(User? user) =>
    user != null &&
    !user.isAnonymous &&
    user.providerData.any((p) => p.providerId == 'google.com');

/// Saf karar (test edilir). Android ve Web eşdeğerliği: Google hesabı her
/// platformda Drive kotasını, Google'sız/misafir hesap yalnız-metni kullanır.
///
/// [cloudAttachments]: `ProFeature.cloudAttachments` hakkı (Pro) VE Play
/// derlemesi — yeni ekler bizim buluta (Storage) gider. Hak yoksa (Lite)
/// Google hesabı Drive'ına gider, Google'sız hesap yalnız cihazda tutar.
/// Bayraksız derlemede (kişisel APK / web) HEP false: bugünkü gibi.
AttachmentSyncMode attachmentSyncModeFor({
  required bool web,
  required bool googleUser,
  bool cloudAttachments = false,
}) => cloudAttachments
    ? AttachmentSyncMode.storage
    : googleUser
    ? AttachmentSyncMode.drive
    : AttachmentSyncMode.textOnly;

final attachmentSyncModeProvider = Provider<AttachmentSyncMode>((ref) {
  final user = ref.watch(authStateProvider).value;
  // `EntitlementGate.active` şart: bayraksız derlemede kapı hep açık görünür
  // ama ekler Storage'a GİTMEZ (kişisel APK davranışı değişmez).
  final cloud =
      EntitlementGate.active &&
      ref.watch(proFeatureProvider(ProFeature.cloudAttachments));
  return attachmentSyncModeFor(
    web: kIsWeb,
    googleUser: isGoogleUser(user),
    cloudAttachments: cloud,
  );
});

/// Kullanıcı Drive'ı BAĞLADI mı (bir kez izin verdi)? Arka plandaki
/// sessiz token istekleri yalnız bağlıysa yapılır; bağlı değilken ekler
/// "Drive bağlantısı bekliyor" olarak cihazda durur.
final driveConnectedProvider = NotifierProvider<DriveConnectedNotifier, bool>(
  DriveConnectedNotifier.new,
);

class DriveConnectedNotifier extends Notifier<bool> {
  /// Sessiz bağlanma hesap başına bir kez denenir (her yeniden kurulumda değil).
  static final _silentTried = <String>{};

  String get _key => 'drive_connected_${ref.read(currentUidProvider) ?? ''}';

  @override
  bool build() {
    final uid = ref.watch(currentUidProvider);
    // Misafir → Google bağlanınca uid aynı kalır; hesap türü için auth izlenir.
    final user = ref.watch(authStateProvider).value;
    final saved = ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;
    // KÖK NEDEN (2026-11-06, "telefondaki ek web'e gelmiyor / sürekli
    // bekliyor"): Google hesabının ekleri yalnız Ayarlar'da elle "Bağla"
    // denince yükleniyordu; denmeyen hesapta ekler sessizce cihazda kalıyordu.
    // İzin daha önce verildiyse (giriş, başka kurulum) pencere açmadan bağlan.
    if (uid != null &&
        isGoogleUser(user) &&
        (kIsWeb || (!saved && Platform.isAndroid)) &&
        _silentTried.add(uid)) {
      unawaited(() async {
        final token = await ref.read(driveAuthProvider).accessToken();
        if (!ref.mounted) return;
        if (token != null) {
          if (!saved) set(true);
        } else if (kIsWeb && saved) {
          state = false;
        }
      }());
    }
    return saved;
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

  void bump() {
    // Yeni inen dosyalar kısa süreli "yok" önbelleğinde kalmasın (F6.9).
    forgetMissingLocalFiles();
    state++;
  }
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
              scopes: kDriveScopes,
              userId: null,
              email: _email,
              promptIfUnauthorized: prompt,
            ),
          ),
        );
    return data?.accessToken;
  }

  /// GMS'siz cihazda tarayıcı jetonunun saklandığı anahtar (bkz.
  /// [browserScopeToken]).
  static const _browserKey = 'notlar_drive_token_v2';

  @override
  Future<String?> accessToken() async {
    if (!await gmsInstalled()) {
      return (await storedBrowserToken(_browserKey))?.token;
    }
    try {
      return await _authorize(prompt: false);
    } catch (e) {
      if (kDebugMode) debugPrint('Drive jetonu alınamadı: $e');
      return null;
    }
  }

  @override
  Future<bool> connect() async => await gmsInstalled()
      ? (await _authorize(prompt: true)) != null
      : (await browserScopeToken(kDriveScopes, _browserKey)) != null;

  @override
  Future<void> invalidate(String token) async {
    if (!await gmsInstalled()) return forgetBrowserToken(_browserKey);
    try {
      await AndroidGoogleAuth.ensureInitialized();
      await GoogleSignInPlatform.instance.clearAuthorizationToken(
        ClearAuthorizationTokenParams(accessToken: token),
      );
    } catch (_) {
      // Jeton zaten geçersiz olabilir; yeniden alınır.
    }
  }

  @override
  Future<void> disconnect() async {}
}

/// **WEB: DRIVE YETKİSİ + GIS SESSİZ YENİLEME** (F4.4).
///
/// Aynı Cloud projesinin istemcisi olduğu için `appDataFolder` Android'inkiyle
/// aynı klasördür. Google Identity Services
/// (`google.accounts.oauth2.initTokenClient`) üzerinden pencere açmadan
/// (`prompt: 'none'`) yenileme ve etkileşimli bağlanma desteklenir; GIS
/// kullanılamıyorsa (engelli betik / istemci kimliği boş) Firebase'in Google
/// açılır penceresiyle yedek akış çalışır. Jeton kısa ömürlü olarak
/// `sessionStorage` + bellekte tutulur.
typedef WebGisRequester = Future<WebGisToken?> Function({
  required String clientId,
  required List<String> scopes,
  String? loginHint,
  required bool silent,
});

class WebDriveAuth implements DriveAuth {
  WebDriveAuth({
    this._auth,
    String Function()? clientId,
    WebGisRequester? gisRequester,
    bool Function()? gisAvailable,
    this._popupConnect,
    this._uidProvider,
    this._emailProvider,
    DateTime Function()? now,
  }) : _clientId = clientId ?? (() => AppConstants.serverClientId),
       _gisRequester = gisRequester ?? requestWebGisToken,
       _gisAvailable =
           gisAvailable ??
           (gisRequester != null ? () => true : () => isWebGisAvailable),
       _now = now ?? DateTime.now;

  final FirebaseAuth? _auth;
  final String Function() _clientId;
  final WebGisRequester _gisRequester;
  final bool Function() _gisAvailable;
  final Future<String?> Function()? _popupConnect;
  final String? Function()? _uidProvider;
  final String? Function()? _emailProvider;
  final DateTime Function() _now;

  String? _token;
  DateTime? _expiry;
  Future<String?>? _silentInFlight;
  DateTime? _lastSilentNullAt;

  // _v2: kapsam değişti (2026-11-06); eski yalnız-appdata jetonu kullanılmasın.
  static const _sessionKey = 'notlar_drive_token_v2';

  /// SEKMELER ARASI KALICI (kullanıcı bulgusu 2026-11-27: "web'de Drive'a her
  /// seferinde baştan bağlanmam gerekiyor"). KÖK NEDEN: jeton yalnız
  /// `sessionStorage`'daydı — yeni sekme, sayfayı kapatıp açma, bağlantıdan
  /// açılan not her seferinde "Bağla" istiyordu; sessiz yenileme de açılır
  /// pencere gerektirdiğinden tarayıcı engelliyor, hiç tutmuyordu. Artık
  /// `localStorage`'da (uid'e bağlı, süresi yazılı, ≤ ~55 dk; başka hesapta
  /// ya da süresi geçince silinir). Süresi dolan jeton için yine tek dokunuş
  /// gerekir (Google tarayıcıda yenileme anahtarı vermiyor).
  static const _localKey = 'notlar_drive_token_v3';

  String? get _uid => _uidProvider != null
      ? _uidProvider()
      : (_auth ?? FirebaseAuth.instance).currentUser?.uid;

  String? get _email => _emailProvider != null
      ? _emailProvider()
      : (_auth ?? FirebaseAuth.instance).currentUser?.email;

  void _restore() {
    if (_token != null) return;
    final raw = localRead(_localKey) ?? sessionRead(_sessionKey);
    if (raw == null) return;
    final parts = raw.split('|');
    final uid = _uid;
    if (uid == null) return;
    final ms = parts.length == 3 ? int.tryParse(parts[1]) : null;
    if (ms == null || parts[2] != uid) {
      // Başka hesabın ya da bozuk kayıt: bırakılmaz.
      localWrite(_localKey, null);
      return;
    }
    final expiry = DateTime.fromMillisecondsSinceEpoch(ms);
    if (!_now().isBefore(expiry)) {
      localWrite(_localKey, null);
      return;
    }
    _token = parts[0];
    _expiry = expiry;
  }

  void _save(String token, {int expiresInSeconds = 3300}) {
    final safeSeconds = math.max(60, expiresInSeconds - 120);
    _token = token;
    _expiry = _now().add(Duration(seconds: safeSeconds));
    _lastSilentNullAt = null;
    final uid = _uid;
    if (uid != null) {
      localWrite(_localKey, '$token|${_expiry!.millisecondsSinceEpoch}|$uid');
    }
    webDriveTokenRevision.value++;
  }

  void _clear() {
    _token = null;
    _expiry = null;
    _silentInFlight = null;
    _lastSilentNullAt = null;
    sessionWrite(_sessionKey, null);
    localWrite(_localKey, null);
  }

  @override
  Future<String?> accessToken() async {
    final stale = _expiry;
    if (_token != null && stale != null && !_now().isBefore(stale)) {
      // Süresi dolmuş: başka sekme yenilemiş olabilir, kayıttan yeniden oku.
      _token = null;
      _expiry = null;
    }
    _restore();
    final expiry = _expiry;
    if (_token != null && expiry != null && _now().isBefore(expiry)) {
      return _token;
    }
    final cid = _clientId();
    if (cid.isEmpty || _uid == null) return null;
    final lastNull = _lastSilentNullAt;
    if (lastNull != null &&
        _now().difference(lastNull) < const Duration(seconds: 60)) {
      return null;
    }
    return _silentInFlight ??= _trySilentGis(cid);
  }

  Future<String?> _trySilentGis(String cid) async {
    try {
      final res = await _gisRequester(
        clientId: cid,
        scopes: kDriveScopes,
        loginHint: _email,
        silent: true,
      );
      if (res != null && res.token.isNotEmpty) {
        _save(res.token, expiresInSeconds: res.expiresIn);
        return res.token;
      }
      _lastSilentNullAt = _now();
      return null;
    } catch (_) {
      _lastSilentNullAt = _now();
      return null;
    } finally {
      _silentInFlight = null;
    }
  }

  Future<String?> _defaultPopupConnect() async {
    final user = (_auth ?? FirebaseAuth.instance).currentUser;
    if (user == null) return null;
    final provider = GoogleAuthProvider();
    for (final scope in kDriveScopes) {
      provider.addScope(scope);
    }
    final email = user.email;
    if (email != null) provider.setCustomParameters({'login_hint': email});
    final result = await user.reauthenticateWithPopup(provider);
    final credential = result.credential;
    return credential is OAuthCredential ? credential.accessToken : null;
  }

  @override
  Future<bool> connect() async {
    if (_uid == null) return false;
    _lastSilentNullAt = null;
    final cid = _clientId();
    if (cid.isNotEmpty && _gisAvailable()) {
      try {
        final gis = await _gisRequester(
          clientId: cid,
          scopes: kDriveScopes,
          loginHint: _email,
          silent: false,
        );
        if (gis != null && gis.token.isNotEmpty) {
          _save(gis.token, expiresInSeconds: gis.expiresIn);
          return true;
        }
      } catch (_) {
        // GIS başarısız olduysa Firebase açılır pencere yedeğine geç.
      }
    }
    final popupToken = _popupConnect != null
        ? await _popupConnect()
        : await _defaultPopupConnect();
    if (popupToken == null || popupToken.isEmpty) return false;
    _save(popupToken);
    return true;
  }

  @override
  Future<void> invalidate(String token) async {
    if (token == _token) _clear();
  }

  @override
  Future<void> disconnect() async => _clear();
}

/// Web'de Drive jetonu alındıkça artar: açık ek kutuları ve not şeridi
/// yeniden bakıp beklemedeki ekleri indirir.
final webDriveTokenRevision = ValueNotifier<int>(0);

/// Drive'ın olmadığı yer (misafir, testler).
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
  if (kIsWeb) return WebDriveAuth();
  if (Platform.isAndroid) return AndroidDriveAuth();
  return const NoDriveAuth();
});

/// Drive deposu — yalnız Google hesabında VE Drive bağlıyken; aksi hâlde
/// null (kuyruk ekleri cihazda tutar).
final driveStoreProvider = Provider<DriveStore?>((ref) {
  // Web'de Google hesabı Drive'daki ekleri OKUYABİLİR (bkz. [WebDriveAuth]);
  // yükleme yine Storage'a (kip `storage` kalır).
  final googleUser = isGoogleUser(ref.watch(authStateProvider).value);
  final webReader = kIsWeb && googleUser;
  // Pro (Storage kipi): Lite iken Drive'a yüklenmiş eski ekler OKUNMAYA
  // devam eder (Drive bağlıysa). Drive kipinde bu kol zaten açık; kişisel
  // APK'da kip hep drive/textOnly → davranış aynı.
  final driveReader = googleUser && ref.watch(driveConnectedProvider);
  if (!webReader &&
      !driveReader &&
      ref.watch(attachmentSyncModeProvider) != AttachmentSyncMode.drive) {
    driveFileDeleter = null;
    return null;
  }
  // Web'de bağlantı kalıcı değil (jeton bellekte): depo hep kurulur,
  // jetonsuzken okuma "Bağla" ister (bkz. drive_ui.dart).
  if (!webReader && !ref.watch(driveConnectedProvider)) {
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
      // ZAMAN AŞIMI (2026-11-06 cihazda: yükleme hatasız ASILI kaldı, ek
      // sonsuza dek "yükleniyor" dedi): her adım adıyla düşer, kuyruk
      // yeniden dener ve hata günlüğü hangi adımın takıldığını söyler.
      final token = await _auth.accessToken().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException('drive-token'),
      );
      if (token == null) {
        throw const DriveUnavailableException('no-token');
      }
      final response = await _client
          .send(await build(token))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('drive-request'),
          );
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
  }) async => _uploadStream(
    await file.length(),
    file.openRead,
    name: name,
    mimeType: mimeType,
  );

  /// Bellekteki baytları yükler (WEB: dosya sistemi yok — Storage yüklemesi
  /// düşünce yedek yol, 2026-11-09 "web'de PDF hiç eklenmiyor").
  Future<String> uploadBytes(
    Uint8List bytes, {
    required String name,
    required String mimeType,
  }) => _uploadStream(
    bytes.length,
    () => Stream.value(bytes),
    name: name,
    mimeType: mimeType,
  );

  Future<String> _uploadStream(
    int length,
    Stream<List<int>> Function() open, {
    required String name,
    required String mimeType,
  }) async {
    final folder = await ensureFolder();
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
              'parents': [folder],
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
        await for (final chunk in open()) {
          put.sink.add(chunk);
        }
      } catch (e, st) {
        put.sink.addError(e, st);
      } finally {
        await put.sink.close();
      }
    }());
    // Gövde akarken de bekleme sınırlı: 25 MB yavaş bağlantıda ~dakikalar.
    final response = await _client
        .send(put)
        .timeout(
          const Duration(minutes: 10),
          onTimeout: () => throw TimeoutException('drive-put'),
        );
    final body = await response.stream.bytesToString().timeout(
      const Duration(minutes: 2),
      onTimeout: () => throw TimeoutException('drive-put-body'),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw HttpException('Drive ${response.statusCode}: $body');
    }
    final id = (jsonDecode(body) as Map<String, dynamic>)['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const HttpException('Drive: dosya kimliği dönmedi');
    }
    return id;
  }

  String? _folderId;

  /// Görünür "Notlar" klasörünün kimliği; yoksa kökte açılır. `drive.file`
  /// yalnız uygulamanın açtığı klasörü görür — kullanıcının aynı adlı kendi
  /// klasörüne dokunulmaz.
  Future<String> ensureFolder() async {
    final cached = _folderId;
    if (cached != null) return cached;
    const folderMime = 'application/vnd.google-apps.folder';
    final q = Uri.encodeQueryComponent(
      "name = '$kDriveFolderName' and mimeType = '$folderMime' "
      "and trashed = false and 'root' in parents",
    );
    final found = await _send(
      (token) async => http.Request(
        'GET',
        Uri.parse('$_api?q=$q&pageSize=1&fields=files(id)'),
      )..headers['Authorization'] = 'Bearer $token',
    );
    final foundBody = await found.stream.bytesToString();
    if (found.statusCode != 200) {
      throw HttpException('Drive ${found.statusCode}: $foundBody');
    }
    final files = (jsonDecode(foundBody) as Map)['files'] as List? ?? const [];
    if (files.isNotEmpty) {
      return _folderId = (files.first as Map)['id'] as String;
    }
    final created = await _send(
      (token) async => http.Request('POST', Uri.parse('$_api?fields=id'))
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        })
        ..body = jsonEncode({
          'name': kDriveFolderName,
          'mimeType': folderMime,
          'parents': ['root'],
        }),
    );
    final createdBody = await created.stream.bytesToString();
    if (created.statusCode != 200) {
      throw HttpException('Drive ${created.statusCode}: $createdBody');
    }
    return _folderId = (jsonDecode(createdBody) as Map)['id'] as String;
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
      } catch (_) {
        // Yarım geçici dosya; açılıştaki temizlik toplar.
      }
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

  /// appDataFolder'daki BÜTÜN dosyaları siler (hesap silme, F1.2). Sayfa
  /// sayfa listeler; listeleme başarısızsa sessizce durur — dosyalar
  /// kullanıcının kendi Drive'ında kalır, veri sızıntısı değil.
  Future<void> deleteAllAppData() async {
    await _deleteListed('spaces=appDataFolder');
    // Görünür "Notlar" klasöründekiler (yalnız uygulamanın açtıkları).
    try {
      final folder = await ensureFolder();
      await _deleteListed(
        'q=${Uri.encodeQueryComponent("'$folder' in parents")}',
      );
    } catch (e) {
      debugPrint('Drive klasörü temizlenemedi: $e');
    }
  }

  Future<void> _deleteListed(String filter) async {
    String? pageToken;
    try {
      do {
        final query = StringBuffer(
          '$_api?$filter&pageSize=1000'
          '&fields=nextPageToken,files(id)',
        );
        if (pageToken != null) {
          query.write('&pageToken=${Uri.encodeQueryComponent(pageToken)}');
        }
        final response = await _send(
          (token) async =>
              http.Request('GET', Uri.parse(query.toString()))
                ..headers['Authorization'] = 'Bearer $token',
        );
        if (response.statusCode != 200) {
          if (kDebugMode) debugPrint(await _failure(response));
          return;
        }
        final body = jsonDecode(
          await response.stream.bytesToString(),
        ) as Map<String, dynamic>;
        for (final f in (body['files'] as List? ?? const [])) {
          final id = (f as Map)['id'] as String?;
          if (id != null) await delete(id);
        }
        pageToken = body['nextPageToken'] as String?;
      } while (pageToken != null);
    } catch (e) {
      if (kDebugMode) debugPrint('Drive uygulama verisi silinemedi: $e');
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
      return await _failure(response);
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
