import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

  /// KAMERALI tarayıcı (ML Kit) yalnız eklentinin platform kodu olan yerlerde
  /// vardır (Android/iOS).
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// "Belge tara" menüde görünsün mü (web'de ML Kit yok).
  static bool get available => supported;

  /// Eklentinin kendi kanalı (bkz. `CunningDocumentScanner._channel`).
  static const _channel = MethodChannel('cunning_document_scanner');

  /// Tarama arayüzünü açar; kullanıcı vazgeçerse null, aksi hâlde taranan
  /// sayfaların (JPEG) dosya yolları döner.
  ///
  /// **KAMERA İZNİ SORULMAZ** (2026-11-07, dosya-okuyucu'nun davranışı —
  /// `DocumentScanner.scanPages`): Google'ın tarayıcısı kamerayı Play
  /// Hizmetleri'nin kendi sürecinde açar, uygulamanın iznine ihtiyacı yok.
  /// Eklentinin `getPictures`'ı ise önce izin istiyor ve reddedilince
  /// "Permission not granted" fırlatıyordu — izni vermeyen kullanıcı hiç
  /// tarayamıyordu. Kanal doğrudan çağrılır; yalnız Google tarayıcısı
  /// açılamazsa (Play Hizmetleri yok → eklentinin kendi kameralı yedeği)
  /// izinli eski yola düşülür.
  static Future<List<String>?> scanPages({int maxPages = 20}) async {
    List<String>? pages;
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('getPictures', {
        'noOfPages': maxPages,
        'isGalleryImportAllowed': true,
      });
      pages = raw?.map((e) => e as String).toList();
    } on PlatformException {
      // Yedek etkinlik kamerayı uygulama içinde açar → izin gerekir.
      pages = await CunningDocumentScanner.getPictures(
        noOfPages: maxPages,
        isGalleryImportAllowed: true,
      );
    } on MissingPluginException {
      return null;
    }
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
