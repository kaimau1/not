import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Videodan **kare** çıkarır (Android; `MediaMetadataRetriever`).
///
/// Balonlu görüntülü not için: balon, vurgu ve el yazısı bir SAYFANIN üzerinde
/// yaşıyor (bkz. `PageBubble` — konum sayfa oranı). Videonun sayfası yok, bu
/// yüzden balonlu kipte videonun kareleri belge sayfalarına dönüştürülür;
/// video da nota ek olarak bağlı kalır, yani hiçbir şey kaybolmaz.
///
/// Çıkaramazsa (desteklenmeyen kodlayıcı, masaüstü, köprüsüz eski kurulum)
/// null döner — çağıran klasik yola düşer.
abstract final class VideoFrame {
  static const _channel = MethodChannel('dev.kaimau.notlar/system');

  static bool get supported => !kIsWeb && Platform.isAndroid;

  /// Kapak karesi (1. saniye).
  static Future<Uint8List?> cover(String path) => _frame(path, null);

  /// Videonun [at] anındaki kare (en yakın anahtar kare).
  static Future<Uint8List?> at(String path, Duration at) =>
      _frame(path, at.inMicroseconds);

  static Future<Uint8List?> _frame(String path, int? atUs) async {
    if (!supported) return null;
    try {
      return await _channel.invokeMethod<Uint8List>('videoFrame', {
        'path': path,
        if (atUs != null) 'atUs': atUs,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Videonun süresi; okunamazsa [Duration.zero].
  static Future<Duration> duration(String path) async {
    if (!supported) return Duration.zero;
    try {
      final ms = await _channel.invokeMethod<int>('videoDuration', {
        'path': path,
      });
      return Duration(milliseconds: ms ?? 0);
    } on PlatformException {
      return Duration.zero;
    } on MissingPluginException {
      return Duration.zero;
    }
  }

  /// Videoyu BAŞTAN SONA örnekleyip birden çok kare döndürür.
  ///
  /// **KÖK NEDEN (kullanıcı bulgusu: "balonlu mod açılıyor ama sadece videonun
  /// ilk karesine balon yerleşiyor, görsele dönüşüyor").** Balonlu görüntülü
  /// not tek bir KAPAK karesinden kuruluyordu: sonuç, üzerine not alınabilen
  /// tek sayfalık bir fotoğraftı — yani videodan alınan not, videonun ilk
  /// saniyesinden alınan nota indirgeniyordu. Kaydın geri kalanına (tahtanın
  /// sonraki hâli, sunumun sonraki slaydı, konuşmanın devamı) balon
  /// bırakmanın hiçbir yolu yoktu.
  ///
  /// Artık kayıt boyunca eşit aralıklarla kare alınır ve her kare belgenin bir
  /// SAYFASI olur: kullanıcı videonun istediği anına balon bırakır, vurgular,
  /// üstüne yazar. Video yine nota ek olarak bağlanır (asıl içerik odur).
  ///
  /// Aralık [every], sayfa sayısı [maxFrames] ile sınırlı: 40 sayfalık bir
  /// belge, üzerinde çalışılabilir olmaktan çıkar ve kare çıkarmak (her biri
  /// ayrı bir çözme işi) uzun sürer.
  static Future<List<Uint8List>> sample(
    String path, {
    Duration every = const Duration(seconds: 10),
    int maxFrames = 12,
  }) async {
    if (!supported) return const [];
    final total = await duration(path);
    // Süre okunamadıysa ya da video örnekleme aralığından kısaysa tek kare
    // (eski davranış) — bölmeye çalışmak boş liste üretirdi.
    if (total <= every) {
      final one = await cover(path);
      return one == null ? const [] : [one];
    }
    var count = (total.inMilliseconds / every.inMilliseconds).floor();
    if (count > maxFrames) count = maxFrames;
    if (count < 1) count = 1;
    // Kareler aralığın ORTALARINDAN alınır: son kare çoğu çekimde kameranın
    // indirildiği bulanık an, ilk kare de karanlık açılış oluyor.
    final step = total.inMicroseconds / count;
    final frames = <Uint8List>[];
    for (var i = 0; i < count; i++) {
      final bytes = await at(
        path,
        Duration(microseconds: (step * (i + 0.5)).round()),
      );
      if (bytes != null) frames.add(bytes);
    }
    if (frames.isEmpty) {
      final one = await cover(path);
      if (one != null) frames.add(one);
    }
    return frames;
  }
}
