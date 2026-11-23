import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'font_sources.dart';
import 'local_file.dart' show appSupportPath;

/// Pakette OLMAYAN yazı tiplerinin (PL10) kullanıcı seçince indirilmesi.
///
/// Neden `google_fonts`un kendi indirmesi değil: başarısız indirmede paket
/// hatayı yakalanmamış bırakır ve başarısız işi `pendingFonts()` kümesinde
/// tutar (sonraki her bekleme patlar). Burada indirme KENDİ yolumuzda,
/// `fonts.gstatic.com/s/a/<sha256>.ttf` (paketin aynı adres kuralı) ve
/// SHA-256 + uzunluk doğrulamalı; dosya uygulama destek klasöründe
/// önbelleklenir, sonraki açılışta ağsız yüklenir.
///
/// Görünüm: indirilen aile her zaman KENDİ adıyla ([downloadedFontFamily])
/// istenir ve yedek listede varsayılan yazı tipi durur; aile yüklenince motor
/// "yazı tipleri değişti" der ve metin yeniden dizilir — kart önbelleklerini
/// ya da widget'ları yeniden kurmak gerekmez. İndirme bitene dek (ya da
/// çevrimdışıyken) varsayılan yazı tipi görünür; hata çökme yapmaz.
String downloadedFontFamily(String id, int weight) => 'dl:$id:$weight';

class FontDownloads extends ChangeNotifier {
  FontDownloads({
    this.client,
    String? Function()? cacheDir,
    Future<void> Function(String family, Uint8List bytes)? register,
    this.timeout = const Duration(seconds: 30),
    this.sources = kDownloadableFontSources,
  }) : _cacheDir = cacheDir ?? _defaultCacheDir,
       _register = register ?? _registerFont;

  final http.Client? client;
  final String? Function() _cacheDir;
  final Future<void> Function(String family, Uint8List bytes) _register;
  final Duration timeout;

  /// Yalnız testte değişir.
  final Map<String, List<FontSource>> sources;

  final Set<String> _ready = {};
  final Set<String> _failed = {};
  final Map<String, Future<bool>> _inflight = {};
  http.Client? _ownClient;

  /// Aile yüklendi (bu oturumda motorda kayıtlı).
  bool isReady(String id) => _ready.contains(id);

  bool isFetching(String id) => _inflight.containsKey(id);

  /// [build] içinden de çağrılabilir: indirme mikro görev olarak sonra başlar.
  /// Bu oturumda başarısız olan aile kendiliğinden yeniden denenmez (açılışta
  /// ya da kullanıcı seçince denenir, bkz. [ensure] `retry`).
  void request(String id) {
    if (_ready.contains(id) ||
        _failed.contains(id) ||
        _inflight.containsKey(id) ||
        !sources.containsKey(id)) {
      return;
    }
    scheduleMicrotask(() => unawaited(ensure(id)));
  }

  /// Ailenin 400/500 kesimlerini önbellekten yükler, yoksa indirir. Asla
  /// atmaz; başarıyı döner. [retry]: kullanıcı seçimi — önceki başarısızlığı
  /// unutup yeniden dener.
  Future<bool> ensure(String id, {bool retry = false}) {
    if (_ready.contains(id)) return Future.value(true);
    final list = sources[id];
    if (list == null) return Future.value(false);
    if (retry) _failed.remove(id);
    final running = _inflight[id];
    if (running != null) return running;
    if (_failed.contains(id)) return Future.value(false);
    final job = Future.microtask(() => _run(id, list)).whenComplete(() {
      _inflight.remove(id);
      notifyListeners();
    });
    _inflight[id] = job;
    notifyListeners();
    return job;
  }

  Future<bool> _run(String id, List<FontSource> files) async {
    try {
      final dir = _cacheDir();
      for (final s in files) {
        final bytes = await _bytes(s, dir);
        await _register(downloadedFontFamily(id, s.weight), bytes);
      }
      _ready.add(id);
      return true;
    } catch (e) {
      _failed.add(id);
      debugPrint('Yazı tipi indirilemedi ($id): $e');
      return false;
    }
  }

  Future<Uint8List> _bytes(FontSource s, String? dir) async {
    final file = dir == null ? null : File('$dir/${s.sha256}.ttf');
    if (file != null) {
      try {
        if (await file.exists()) {
          final cached = await file.readAsBytes();
          if (_matches(s, cached)) return cached;
        }
      } catch (_) {}
    }
    final http.Client c = client ?? (_ownClient ??= http.Client());
    final response = await c
        .get(Uri.parse('https://fonts.gstatic.com/s/a/${s.sha256}.ttf'))
        .timeout(timeout);
    if (response.statusCode != 200 || !_matches(s, response.bodyBytes)) {
      throw Exception('HTTP ${response.statusCode} ya da özet uyuşmadı');
    }
    if (file != null) {
      try {
        await file.parent.create(recursive: true);
        await file.writeAsBytes(response.bodyBytes, flush: true);
      } catch (_) {
        // Önbelleğe yazılamadı: yazı tipi bu oturumda yine çalışır.
      }
    }
    return response.bodyBytes;
  }

  static bool _matches(FontSource s, Uint8List bytes) =>
      bytes.length == s.length && sha256.convert(bytes).toString() == s.sha256;

  static String? _defaultCacheDir() {
    final base = appSupportPath;
    return kIsWeb || base == null ? null : '$base/dl_fonts';
  }

  static Future<void> _registerFont(String family, Uint8List bytes) async {
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

/// Uygulama geneli örnek. Testler kendi örneğini atar.
FontDownloads fontDownloads = FontDownloads();
