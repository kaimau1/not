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
  ///
  /// KÖK NEDEN (izin VERİLMİŞKEN "Mikrofon izni verilmedi" çıkması): eskiden
  /// doğrudan record eklentisinin hasPermission'ı çağrılıyor ve altındaki
  /// `catch` HER hatayı "izin yok"a katlıyordu. O çağrı önce eklentinin
  /// create'ini bekler (patlarsa istisna fırlar), ayrıca activity o an bağlı
  /// değilse izni hiç OKUMADAN false döner — ikisi de izinli cihazda yalan
  /// mesaj demekti. Artık önce checkSelfPermission okunur (sistem kutusu
  /// açmaz, eklentiye/activity'ye bağlı değildir); yalnızca izin gerçekten
  /// yoksa eklenti yoluna düşülür — kutuyu açması gereken tek durum odur.
  static Future<bool> ensureMicPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final granted = await _method.invokeMethod<bool>('micPermissionGranted');
      if (granted ?? false) return true;
    } on PlatformException {
      // Köprü yanıtlamadı; aşağıdaki eklenti yolu yine de deneyecek.
    }
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

  /// Keep tarzı sesli giriş: Google'ın tanıma EKRANINI açar; kullanıcı
  /// konuşur, ekran kapanınca hem metin hem Google'ın kendi kaydettiği ses
  /// dosyası (AMR, telefon kalitesi) döner. Tek mikrofon istemcisi Google
  /// olduğundan [listen] + AudioRecorder ikilisinin yaşadığı mikrofon
  /// çakışması (Android'de son açan kazanır) burada hiç yoktur.
  ///
  /// Dönüş: kullanıcı iptal ettiyse ya da ekran açılamadıysa null; yoksa
  /// metin + varsa ses yolu (GET_AUDIO belgesiz olduğundan ses gelmeyebilir;
  /// o durumda çağıran yalnız metinle devam eder).
  static Future<({String text, String? audioPath})?> voiceInputWithAudio({
    String locale = 'tr-TR',
  }) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final map = await _method.invokeMethod<Map<Object?, Object?>>(
        'voiceInputWithAudio',
        {'locale': locale},
      );
      if (map == null) return null;
      return (
        text: (map['text'] as String?) ?? '',
        audioPath: map['audioPath'] as String?,
      );
    } on PlatformException {
      return null;
    }
  }

  /// Dinlemeyi bitirir; son (tamamlanmış) metin akıştan gelir.
  static Future<void> stop() async {
    try {
      await _method.invokeMethod('stopSpeech');
    } on PlatformException {
      // Zaten kapalıysa sorun değil.
    }
  }
}
