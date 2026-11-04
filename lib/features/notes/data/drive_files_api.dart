import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/attachment_sync.dart';

/// **YENİ EK SENKRONU — DRIVE KATMANI** (F28.2-B, 2026-11-04).
///
/// Eski yol (`drive_store.dart`) gizli `appDataFolder`'a `drive.appdata`
/// kapsamıyla yazıyordu: kullanıcı dosyalarını göremiyordu. KARAR
/// (2026-11-03): asıl dosya kullanıcının Drive'ında, GÖRÜNÜR "Notlar"
/// klasöründe, `drive.file` kapsamıyla (hassas kapsam değil; uygulama yalnız
/// KENDİ oluşturduğu dosyaları görür).
///
/// Henüz hiçbir yere bağlı değil — `AttachmentSyncService` (C/D) kullanacak.
/// Konsol adımı F19'da: OAuth onay ekranına `drive.file` kapsamı.
const kDriveFileScope = 'https://www.googleapis.com/auth/drive.file';

const _filesApi = 'https://www.googleapis.com/drive/v3/files';
const _uploadApi =
    'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart&fields=id';
const _folderMime = 'application/vnd.google-apps.folder';

/// Drive isteği başarısız (durum kodu + kısa gövde). 401 → jeton geçersiz;
/// çağıran [DriveTokenCache.invalidate] edip bir kez yeniden dener.
class DriveApiException implements Exception {
  DriveApiException(this.status, this.body);
  final int status;
  final String body;
  bool get unauthorized => status == 401;
  @override
  String toString() =>
      'DriveApiException($status: '
      '${body.length > 120 ? body.substring(0, 120) : body})';
}

/// **JETON ÖNBELLEĞİ + SESSİZ YENİLEME** (web'in "her yenilemede yeniden
/// bağlan" sorununa yeni yapıdaki cevap). Platform yalnız [silentRefresh]
/// verir (Android: `google_sign_in` yetkilendirmesi; web: GIS sessiz
/// istem). Süresi [refreshMargin]'dan az kalan jeton yenilenir; aynı anda
/// gelen istekler TEK yenilemeyi bekler.
class DriveTokenCache {
  DriveTokenCache({
    required this.silentRefresh,
    DateTime Function()? clock,
    this.refreshMargin = const Duration(minutes: 2),
  }) : _now = clock ?? DateTime.now;

  /// Kullanıcıya pencere AÇMADAN yeni jeton dener; olmazsa null (o zaman
  /// arayüz "Google'a bağla" der).
  final Future<({String token, DateTime expiry})?> Function() silentRefresh;
  final DateTime Function() _now;
  final Duration refreshMargin;

  String? _token;
  DateTime? _expiry;
  Future<String?>? _inFlight;

  /// Etkileşimli bağlanmanın (açılır pencere) sonucunu yerleştirir.
  void put(String token, DateTime expiry) {
    _token = token;
    _expiry = expiry;
  }

  void invalidate() {
    _token = null;
    _expiry = null;
  }

  Future<String?> get() {
    final t = _token, e = _expiry;
    if (t != null && e != null && _now().add(refreshMargin).isBefore(e)) {
      return Future.value(t);
    }
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<String?> _refresh() async {
    try {
      final r = await silentRefresh();
      if (r == null) {
        invalidate();
        return null;
      }
      put(r.token, r.expiry);
      return r.token;
    } catch (_) {
      invalidate();
      return null;
    }
  }
}

/// Drive REST v3 — "Notlar" klasörü + dosya yükle/indir/sil.
class DriveFilesApi {
  DriveFilesApi({required this._client, required this._tokens});

  final http.Client _client;
  final DriveTokenCache _tokens;
  String? _folderId;

  Future<Map<String, String>> _auth() async {
    final token = await _tokens.get();
    if (token == null) throw DriveApiException(401, 'jeton yok');
    return {'Authorization': 'Bearer $token'};
  }

  /// 401'de jetonu bir kez yenileyip yeniden dener.
  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> auth) call,
  ) async {
    var res = await call(await _auth());
    if (res.statusCode == 401) {
      _tokens.invalidate();
      res = await call(await _auth());
    }
    if (res.statusCode >= 300) {
      throw DriveApiException(res.statusCode, res.body);
    }
    return res;
  }

  /// "Notlar" klasörünün kimliği: varsa bulur, yoksa oluşturur (oturum
  /// boyunca önbellekte). `drive.file` ile yalnız uygulamanın oluşturduğu
  /// klasör görünür — kullanıcının elle açtığı aynı adlı klasör karışmaz.
  Future<String> ensureFolder() async {
    final cached = _folderId;
    if (cached != null) return cached;
    final q =
        "name = '$kDriveFolderName' and mimeType = '$_folderMime' "
        "and trashed = false and 'root' in parents";
    final found = await _send(
      (auth) => _client.get(
        Uri.parse(_filesApi).replace(
          queryParameters: {'q': q, 'fields': 'files(id)', 'pageSize': '1'},
        ),
        headers: auth,
      ),
    );
    final files = (jsonDecode(found.body)['files'] as List?) ?? const [];
    if (files.isNotEmpty) {
      return _folderId = (files.first as Map)['id'] as String;
    }
    final created = await _send(
      (auth) => _client.post(
        Uri.parse('$_filesApi?fields=id'),
        headers: {...auth, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': kDriveFolderName,
          'mimeType': _folderMime,
          'parents': ['root'],
        }),
      ),
    );
    return _folderId = jsonDecode(created.body)['id'] as String;
  }

  /// Dosyayı klasöre yükler; Drive dosya kimliğini döndürür.
  /// [appProperties]'e ek kimliği yazılır (göç/onarımda eşleştirme için).
  Future<String> upload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String attachmentId,
  }) async {
    final folder = await ensureFolder();
    final body = buildMultipartBody(
      metadata: {
        'name': fileName,
        'parents': [folder],
        'appProperties': {'notlarAttachmentId': attachmentId},
      },
      bytes: bytes,
      mimeType: mimeType,
      boundary: _boundary,
    );
    final res = await _send(
      (auth) => _client.post(
        Uri.parse(_uploadApi),
        headers: {
          ...auth,
          'Content-Type': 'multipart/related; boundary=$_boundary',
        },
        body: body,
      ),
    );
    final id = jsonDecode(res.body)['id'] as String?;
    if (id == null || id.isEmpty) throw DriveApiException(500, 'kimlik yok');
    return id;
  }

  Future<Uint8List> download(String fileId) async {
    final res = await _send(
      (auth) =>
          _client.get(Uri.parse('$_filesApi/$fileId?alt=media'), headers: auth),
    );
    return res.bodyBytes;
  }

  /// Notun eki silinince Drive dosyası da çöpe (kalıcı silme değil —
  /// kullanıcı Drive çöpünden geri alabilir).
  Future<void> trash(String fileId) async {
    try {
      await _send(
        (auth) => _client.patch(
          Uri.parse('$_filesApi/$fileId?fields=id'),
          headers: {...auth, 'Content-Type': 'application/json'},
          body: jsonEncode({'trashed': true}),
        ),
      );
    } on DriveApiException catch (e) {
      if (e.status != 404) rethrow; // zaten yok: amaç sağlandı
    }
  }

  static const _boundary = 'notlar_drive_boundary_7f3a';
}

/// Drive `multipart/related` gövdesi: JSON üst veri + dosya baytları.
Uint8List buildMultipartBody({
  required Map<String, dynamic> metadata,
  required Uint8List bytes,
  required String mimeType,
  required String boundary,
}) {
  final head = utf8.encode(
    '--$boundary\r\n'
    'Content-Type: application/json; charset=UTF-8\r\n\r\n'
    '${jsonEncode(metadata)}\r\n'
    '--$boundary\r\n'
    'Content-Type: $mimeType\r\n\r\n',
  );
  final tail = utf8.encode('\r\n--$boundary--');
  return Uint8List.fromList([...head, ...bytes, ...tail]);
}
