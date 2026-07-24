import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

/// Cihazın YERLEŞİK konuşma tanıması (Android SpeechRecognizer) için ince
/// köprü. Dikte ve Sesli Not Asistanı bunu kullanır: ücretsiz, anlık ve
/// Gemini kotası harcamaz — ses modele gönderilmek yerine cihazda metne
/// çevrilir, modele yalnızca kısa metin gider.
///
/// Akışa abone olmak dinlemeyi BAŞLATIR; her olayda o ana kadarki TAM metin
/// gelir (biriktirmeyi Kotlin tarafı yapar). [stop] son sonucu getirir,
/// aboneliği iptal etmek dinlemeyi tümüyle bırakır.
class DeviceSpeech {
  const DeviceSpeech._();

  static const _method = MethodChannel('dev.kaimau.notlar/system');
  static const _events = EventChannel('dev.kaimau.notlar/speech');

  /// Cihazda konuşma tanıma kullanılabilir mi. Android dışında (Windows)
  /// yerleşik tanıma yoktur; çağıranlar eski ses yoluna düşer.
  static Future<bool> isAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _method.invokeMethod<bool>('speechAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Mikrofon iznini denetler, yoksa sistem iletişim kutusuyla İSTER.
  /// SpeechRecognizer izin eksikken kendi kutusunu AÇMAZ, sessizce
  /// ERROR_INSUFFICIENT_PERMISSIONS ile düşer — kullanıcı bunu "sesle yazma
  /// çalışmıyor" olarak görür. [listen] çağrılmadan önce bu çağrılmalı.
  /// (record eklentisinin hasPermission'ı hem denetler hem ister; yeni
  /// bağımlılık gerektirmez.)
  static Future<bool> ensureMicPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    final recorder = AudioRecorder();
    try {
      return await recorder.hasPermission();
    } catch (_) {
      return false;
    } finally {
      await recorder.dispose();
    }
  }

  /// Dinlemeyi başlatır. Olaylar iki türlüdür: metin güncellemesi ([text]
  /// dolu, o ana kadarki TAM metin) veya ses seviyesi ([level] 0–1, düğme
  /// animasyonu için). Mikrofon tanıyıcıda olduğundan seviye ayrıca
  /// ölçülemez, bu yüzden aynı akıştan gelir.
  static Stream<({String? text, double? level})> listen({
    String locale = 'tr-TR',
  }) => _events.receiveBroadcastStream(locale).map((event) {
    final map = event as Map<Object?, Object?>;
    final text = map['text'] as String?;
    return (
      // Boş metin olayı YOK SAYILIR: tanıyıcı bazı turlarda boş sonuç
      // gönderiyor ve bu, o ana kadar yazılmış metnin üzerine yazıp
      // siliyordu (ölçümle doğrulandı). Boşsa null döner, çağıran da
      // mevcut metni korur.
      text: (text == null || text.isEmpty) ? null : text,
      level: (map['level'] as num?)?.toDouble(),
    );
  });

  /// Dinlemeyi bitirir; son (tamamlanmış) metin akıştan gelir.
  static Future<void> stop() async {
    try {
      await _method.invokeMethod('stopSpeech');
    } on PlatformException {
      // Zaten kapalıysa sorun değil.
    }
  }
}
