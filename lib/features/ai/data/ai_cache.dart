import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Üretilmiş AI çıktılarını cihazda saklar: aynı girdi ikinci kez model
/// çağırmaz. Bir PDF'i podcast'e çevirmek tek seferde binlerce token
/// harcıyor, ekrana her girişte yeniden harcamasının anlamı yok.
///
/// Firestore yerine cihaza yazılıyor çünkü (1) podcast metni 20-50 KB tutuyor
/// ve nota gömülseydi her not düzenlemesinde yeniden senkronlanırdı,
/// (2) "Belge oku" akışının bağlı olduğu bir not yok.
///
/// KİLİTLİ nottan türeyen çıktılar buraya YAZILMAZ (çağıranlar cacheKey'i
/// null geçer): dosyalar düz metin ve kilidin amacı içeriğin diskte açıkta
/// dolaşmaması.
abstract final class AiCache {
  /// Üstünde tutulacak dosya sayısı. Metin küçük ama sınırsız büyüyen bir
  /// önbellek cihazda yıllar içinde birikir.
  static const maxEntries = 40;

  /// Testler gerçek uygulama klasörüne yazmasın diye.
  @visibleForTesting
  static Directory? overrideDir;

  /// Budama oturum başına bir kez yeter: her yazımda klasörü listeleyip her
  /// dosyayı stat'lamak (ana izolede senkron sistem çağrıları) israftı.
  static bool _prunedThisSession = false;

  /// Girdi bir belgenin tamamı kadar uzun olabildiğinden anahtar özetlenir.
  /// Tür uzunluk önekiyle yazılıyor: düz birleştirme olsaydı ('a','bc') ile
  /// ('ab','c') aynı anahtara düşerdi.
  static String keyFor(String kind, String input) =>
      sha256.convert(utf8.encode('${kind.length}:$kind$input')).toString();

  static Future<Directory> _dir() async {
    final override = overrideDir;
    if (override != null) return override..createSync(recursive: true);
    final base = await getApplicationSupportDirectory();
    return Directory(p.join(base.path, 'ai_cache'))
      ..createSync(recursive: true);
  }

  static Future<String?> read(String key) async {
    final file = File(p.join((await _dir()).path, '$key.txt'));
    try {
      if (!await file.exists()) return null;
      // Erişim tazelenir ki budama sık kullanılanı değil gerçekten eskiyeni
      // atsın.
      await file.setLastModified(DateTime.now());
      return await file.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    final dir = await _dir();
    try {
      await File(
        p.join(dir.path, '$key.txt'),
      ).writeAsString(value, flush: true);
    } on FileSystemException {
      // Önbellek yazılamadıysa özellik yine çalışır, sadece yavaşlar.
      return;
    }
    if (_prunedThisSession) return;
    _prunedThisSession = true;
    await prune(dir);
  }

  /// [maxEntries] üstünü en eskiden başlayarak atar. Her dosya BİR KEZ
  /// stat'lanır — eskiden stat, sıralama karşılaştırıcısının içindeydi
  /// (O(n log n) senkron sistem çağrısı).
  @visibleForTesting
  static Future<void> prune(Directory dir) async {
    final files = <(File, DateTime)>[];
    await for (final entry in dir.list()) {
      if (entry is! File) continue;
      try {
        files.add((entry, (await entry.stat()).modified));
      } on FileSystemException {
        // Stat edilemeyen dosya budamaya girmez.
      }
    }
    if (files.length <= maxEntries) return;
    files.sort((a, b) => a.$2.compareTo(b.$2));
    for (final (file, _) in files.take(files.length - maxEntries)) {
      try {
        await file.delete();
      } on FileSystemException {
        // Kilitliyse bir dahaki budamada tekrar denenir.
      }
    }
  }
}
