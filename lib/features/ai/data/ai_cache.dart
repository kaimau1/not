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
abstract final class AiCache {
  /// Üstünde tutulacak dosya sayısı. Metin küçük ama sınırsız büyüyen bir
  /// önbellek cihazda yıllar içinde birikir.
  static const maxEntries = 40;

  /// Testler gerçek uygulama klasörüne yazmasın diye.
  @visibleForTesting
  static Directory? overrideDir;

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
    if (!file.existsSync()) return null;
    try {
      // Erişim tazelenir ki budama sık kullanılanı değil gerçekten eskiyeni
      // atsın.
      file.setLastModifiedSync(DateTime.now());
      return file.readAsStringSync();
    } on FileSystemException {
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    final dir = await _dir();
    try {
      File(p.join(dir.path, '$key.txt')).writeAsStringSync(value, flush: true);
    } on FileSystemException {
      // Önbellek yazılamadıysa özellik yine çalışır, sadece yavaşlar.
      return;
    }
    prune(dir);
  }

  /// [maxEntries] üstünü en eskiden başlayarak atar.
  @visibleForTesting
  static void prune(Directory dir) {
    final files = dir.listSync().whereType<File>().toList();
    if (files.length <= maxEntries) return;
    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );
    for (final file in files.take(files.length - maxEntries)) {
      try {
        file.deleteSync();
      } on FileSystemException {
        // Kilitliyse bir dahaki yazımda tekrar denenir.
      }
    }
  }
}
