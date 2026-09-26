import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// **CİHAZDAKİ YER** (kullanıcı bulgusu 2026-09-26: "uygulama yüklenince
/// boyutu 300 MB'ı aşıyor, çok fazla").
///
/// KÖK NEDENLER (APK 65 MB; gerisi zamanla büyüyen veri):
/// 1. **Geçici klasör hiç temizlenmiyordu.** Paylaşılan her not paketi ve
///    balonlu PDF, dışa aktarılan her PDF/Word, taranan her sayfa (tam
///    çözünürlük), ses kaydı, yapay zekâ podcast'i (dakikası ~3 MB) ve
///    paylaşımla gelen dosyalar geçici klasöre yazılıp orada kalıyordu.
///    Android bu klasörü ancak disk dolmak üzereyken boşaltır.
///    → Açılışta [staleTempAge]'den eski dosyalar silinir ([pruneTempFiles]).
/// 2. **Firestore yerel önbelleği SINIRSIZDI** (main.dart). Artık tavanlı;
///    açık dinleyicilerin belgeleri (notlar) her zaman yerelde kalır, tavan
///    yalnız eski sorgu sonuçlarını budar.
/// 3. Kullanıcı kullandığı yeri göremiyor, boşaltamıyordu → Ayarlar →
///    Senkron ve depolama → "Bu cihazda" ([measureDeviceStorage],
///    [clearDeviceCaches]).
///
/// Web'de dosya sistemi yok: hepsi hiçbir şey yapmaz.
class DeviceStorage {
  const DeviceStorage._();

  /// Bu yaştan eski geçici dosyalar açılışta silinir. İki gün: paylaşım
  /// levhasının dosyayı karşı uygulamaya teslim etmesine fazlasıyla yeter.
  static const Duration staleTempAge = Duration(days: 2);

  /// Görsel önbelleğinin (cached_network_image) klasörü — açılış
  /// temizliğinde KORUNUR (kendi 200 dosyalık tavanı var; silmek yalnız
  /// yeniden indirme demek). "Önbelleği temizle" onu da siler.
  static const String imageCacheDir = 'libCachedImageData';
}

/// Cihazda kaplanan yer, kalem kalem (bayt).
typedef DeviceStorageUsage = ({
  int attachments,
  int cache,
  int aiCache,
  int database,
  int total,
});

/// Açılışta eski geçici dosyaları siler (bkz. [DeviceStorage]). Hata yutulur:
/// temizlik başarısız olsa da uygulama çalışır.
Future<int> pruneTempFiles({
  Duration olderThan = DeviceStorage.staleTempAge,
  Directory? dir,
  DateTime? now,
}) async {
  if (kIsWeb) return 0;
  try {
    final root = dir ?? await getTemporaryDirectory();
    final limit = (now ?? DateTime.now()).subtract(olderThan);
    var freed = 0;
    // Görsel önbelleğinin klasörüne HİÇ girilmez (kasma, 2026-09-26): eski
    // sürüm her şeyi özyinelemeli listeleyip onun yüzlerce dosyasını tek
    // tek atlıyordu — açılışın ilk saniyelerinde ana iş parçacığında boşa
    // iş.
    Future<void> sweep(Directory dir, {required bool top}) async {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is Directory) {
          if (top && p.basename(entity.path) == DeviceStorage.imageCacheDir) {
            continue;
          }
          await sweep(entity, top: false);
          continue;
        }
        if (entity is! File) continue;
        try {
          final stat = await entity.stat();
          if (stat.modified.isAfter(limit)) continue;
          await entity.delete();
          freed += stat.size;
        } catch (_) {
          // Kullanımda / izinsiz dosya: atla.
        }
      }
    }

    await sweep(root, top: true);
    return freed;
  } catch (_) {
    return 0;
  }
}

/// Bir klasörün toplam boyutu (yoksa 0).
Future<int> directorySize(Directory dir) async {
  if (!await dir.exists()) return 0;
  var total = 0;
  try {
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
  } catch (_) {}
  return total;
}

/// Uygulamanın bu cihazda kapladığı yer (APK hariç).
Future<DeviceStorageUsage?> measureDeviceStorage() async {
  if (kIsWeb) return null;
  try {
    final support = await getApplicationSupportDirectory();
    final temp = await getTemporaryDirectory();
    final attachments = await directorySize(
      Directory(p.join(support.path, 'attachments')),
    );
    final aiCache = await directorySize(
      Directory(p.join(support.path, 'ai_cache')),
    );
    final cache = await directorySize(temp);
    // Android: Firestore'un ve görsel önbellek kaydının SQLite dosyaları
    // uygulama veri kökündeki `databases` klasöründe.
    final database = Platform.isAndroid
        ? await directorySize(
            Directory(p.join(support.parent.path, 'databases')),
          )
        : 0;
    final supportTotal = await directorySize(support);
    return (
      attachments: attachments,
      cache: cache,
      aiCache: aiCache,
      database: database,
      total: supportTotal + cache + database,
    );
  } catch (_) {
    return null;
  }
}

/// Önbellekleri boşaltır: geçici klasörün TAMAMI (görsel önbelleği dahil —
/// görseller gerektikçe yeniden iner), yapay zekâ yanıt önbelleği ve
/// bellekteki çözülmüş görseller. Notlar, ekler ve ayarlar DOKUNULMAZ.
/// Boşaltılan bayt sayısını döner.
Future<int> clearDeviceCaches() async {
  if (kIsWeb) return 0;
  // Yalnız önbellekte BEKLEYEN görseller; ekranda çizilenler kalır (yoksa
  // açık sayfadaki görseller bir an kaybolurdu).
  PaintingBinding.instance.imageCache.clear();
  var freed = 0;
  try {
    final temp = await getTemporaryDirectory();
    freed += await _emptyDirectory(temp);
    final support = await getApplicationSupportDirectory();
    freed += await _emptyDirectory(Directory(p.join(support.path, 'ai_cache')));
  } catch (_) {}
  return freed;
}

Future<int> _emptyDirectory(Directory dir) async {
  if (!await dir.exists()) return 0;
  var freed = 0;
  await for (final entity in dir.list(followLinks: false)) {
    try {
      if (entity is File) {
        freed += await entity.length();
        await entity.delete();
      } else if (entity is Directory) {
        freed += await directorySize(entity);
        await entity.delete(recursive: true);
      }
    } catch (_) {
      // Kullanımda olan dosya: atla.
    }
  }
  return freed;
}
