import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Ortak ZIP bombası koruması (PLAN Faz 0 / P1-3 / G-21).
///
/// `.notyedek`, `.notpaket` ve içe aktarılan `.zip` arşivlerinde dosya sayısı
/// ve toplam açılmış boyut tavanı aşıldığında belleği tüketmeden
/// [FormatException] fırlatır.
abstract final class ZipGuard {
  /// Bir arşivde izin verilen en fazla dosya sayısı.
  static const int maxFiles = 5000;

  /// Bir arşivin izin verilen en büyük toplam açılmış boyutu (250 MB).
  static const int maxUncompressedBytes = 250 * 1024 * 1024;

  /// Arşivin merkezi dizinindeki dosya sayısı ve bildirilen açılmış boyut
  /// toplamını (hiçbir dosyayı belleğe açmadan) denetler.
  static void validateArchive(
    Archive archive, {
    int maxFileCount = maxFiles,
    int maxBytes = maxUncompressedBytes,
  }) {
    var count = 0;
    var totalBytes = 0;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      count++;
      if (count > maxFileCount) {
        throw FormatException(
          'Arşivde izin verilenden fazla dosya var (en çok $maxFileCount).',
        );
      }
      final declared = file.size;
      if (declared < 0 || declared > maxBytes) {
        throw FormatException(
          'Arşiv boyutu sınırı aşıyor '
          '(en çok ${maxBytes ~/ (1024 * 1024)} MB).',
        );
      }
      totalBytes += declared;
      if (totalBytes > maxBytes) {
        throw FormatException(
          'Arşiv boyutu sınırı aşıyor '
          '(en çok ${maxBytes ~/ (1024 * 1024)} MB).',
        );
      }
    }
  }

  /// ZIP baytlarını çözer ve tavanları doğrular.
  static Archive decodeBytes(
    Uint8List bytes, {
    String? password,
    int maxFileCount = maxFiles,
    int maxBytes = maxUncompressedBytes,
  }) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, password: password);
    } on ArchiveException {
      rethrow;
    } catch (e) {
      throw FormatException('Arşiv açılamadı: $e');
    }
    validateArchive(archive, maxFileCount: maxFileCount, maxBytes: maxBytes);
    return archive;
  }

  /// Tek bir arşiv dosyasını okur ve kümülatif gerçek açılmış boyut bütçesini
  /// (sahte başlık taşıyan ZIP'lere karşı) denetler.
  static Uint8List readEntryBytes(ArchiveFile file, ZipByteBudget budget) {
    final bytes = file.content;
    budget.consume(bytes.length);
    return bytes;
  }
}

/// Gerçek açılmış bayt toplamı için kümülatif bütçe izleyicisi.
class ZipByteBudget {
  ZipByteBudget({this.maxBytes = ZipGuard.maxUncompressedBytes});

  final int maxBytes;
  int _used = 0;

  int get used => _used;

  void consume(int byteCount) {
    if (byteCount < 0 || _used + byteCount > maxBytes) {
      throw FormatException(
        'Arşiv boyutu sınırı aşıyor '
        '(en çok ${maxBytes ~/ (1024 * 1024)} MB).',
      );
    }
    _used += byteCount;
  }
}
