import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';

/// **Belge tarayıcı** — kamerayla çekilen sayfayı masaüstü tarayıcıdan çıkmış
/// gibi (kenar tespiti, perspektif düzeltme, kontrast) düzgün bir sayfaya
/// çevirir.
///
/// Kenar bulma/kırpma/filtre işini **Google ML Kit Belge Tarayıcı** yapıyor
/// (`cunning_document_scanner` → `play-services-mlkit-document-scanner`).
/// Kendi kamera + kırpma ekranımızı yazmak yerine bu seçildi: kenar tespiti
/// Google'ın modeli, bakımı bizde değil, sonuç JPEG olarak geliyor. Aynı
/// yaklaşım "dosya-okuyucu" projesinde de kullanılıyor (bkz. HAFIZA).
///
/// Bizim payımız: gelen sayfaları not ekine çevirmek. Sayfalar sıradan görsel
/// ekidir — notta sürüklenir, boyutlandırılır, üzerine yazılır ve "Metni al"
/// (OCR) ile yazıya dökülür.
class DocumentScan {
  const DocumentScan._();

  /// Tarayıcı yalnız eklentinin platform kodu olan yerlerde vardır
  /// (Android/iOS). Windows'ta menüde HİÇ görünmemeli — çalışmayan bir
  /// düğme göstermektense (bkz. `qrScanSupported`).
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Tarama arayüzünü açar; kullanıcı vazgeçerse null, aksi hâlde taranan
  /// sayfaların (JPEG) dosya yolları döner. Kamera iznini paket ister.
  static Future<List<String>?> scanPages({int maxPages = 20}) async {
    final pages = await CunningDocumentScanner.getPictures(
      noOfPages: maxPages,
      isGalleryImportAllowed: true,
    );
    if (pages == null || pages.isEmpty) return null;
    return pages;
  }

  /// Taranan sayfayı okur; okunamayan sayfa null döner (çağıran atlar).
  static Future<Uint8List?> readPage(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
