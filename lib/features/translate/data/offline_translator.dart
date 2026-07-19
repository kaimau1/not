import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Cihazda çalışan çeviri (ML Kit). Ağ, API anahtarı ve kota gerektirmez —
/// dil modeli bir kez indirildikten sonra çevrimdışı da çalışır.
///
/// Neden: eski yol ses dosyasının TAMAMINI Gemini'ye gönderiyordu (ses ≈ 32
/// token/sn, bu projede ölçüldü). Cihaz tanıma + cihaz çevirisiyle bas-konuş
/// modu tümüyle bedava hale geliyor.
///
/// Sınır: ML Kit 56 dil destekler ve kalitesi Gemini'nin altındadır (deyim ve
/// uzun bağlamda fark açılır). Desteklenmeyen dilde [supports] false döner ve
/// çağıran Gemini yoluna düşer — sessizce yanlış çeviri ÜRETMEZ.
class OfflineTranslator {
  const OfflineTranslator();

  /// ML Kit yalnız mobilde var; masaüstünde çağıran Gemini'ye düşer.
  static bool get isPlatformSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Kısa dil kodunu ('tr', 'en') ML Kit diline çevirir; desteklenmiyorsa
  /// null (ör. Azerbaycanca ML Kit'te YOK).
  ///
  /// `fromRawValue` enum'ın değil `BCP47Code` UZANTISININ statiği; enum
  /// üzerinden çağrılmaz.
  static TranslateLanguage? languageFor(String code) =>
      BCP47Code.fromRawValue(code.toLowerCase());

  /// Bu dil çifti cihazda çevrilebilir mi (platform + her iki dil).
  static bool supportsPair(String from, String to) =>
      isPlatformSupported &&
      languageFor(from) != null &&
      languageFor(to) != null;

  OnDeviceTranslatorModelManager get _models =>
      OnDeviceTranslatorModelManager();

  /// Dil modeli cihazda indirilmiş mi.
  Future<bool> isModelReady(String code) async {
    final language = languageFor(code);
    if (language == null) return false;
    return _models.isModelDownloaded(language.bcpCode);
  }

  /// Modeli indirir (~30 MB). [wifiOnly] false verilirse mobil veriyle de
  /// iner; çağıran kullanıcıya sormalı.
  Future<bool> downloadModel(String code, {bool wifiOnly = true}) async {
    final language = languageFor(code);
    if (language == null) return false;
    return _models.downloadModel(language.bcpCode, isWifiRequired: wifiOnly);
  }

  Future<bool> deleteModel(String code) async {
    final language = languageFor(code);
    if (language == null) return false;
    return _models.deleteModel(language.bcpCode);
  }

  /// Metni çevirir. Dil çifti desteklenmiyorsa [UnsupportedError] atar —
  /// çağıran Gemini'ye düşmeli.
  Future<String> translate({
    required String text,
    required String from,
    required String to,
  }) async {
    final source = languageFor(from);
    final target = languageFor(to);
    if (source == null || target == null) {
      throw UnsupportedError('ML Kit bu dil çiftini desteklemiyor: $from→$to');
    }
    final translator = OnDeviceTranslator(
      sourceLanguage: source,
      targetLanguage: target,
    );
    try {
      return await translator.translateText(text);
    } finally {
      // Her çeviride yeni örnek: kapatılmazsa yerel kaynak sızar.
      await translator.close();
    }
  }
}
