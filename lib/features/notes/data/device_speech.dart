import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';

import '../../../core/utils/speech_text.dart';
import '../../../core/utils/web_speech_recognition.dart';

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

  /// Testte yerleşik tanıma var sayılır (`Platform.isAndroid` testte
  /// false; P63 S43 dikte kartını tam editörde ölçer).
  @visibleForTesting
  static bool? debugAvailable;

  /// Cihazda konuşma tanıma kullanılabilir mi. Android dışında web'de
  /// tarayıcının Web Speech API desteğine bakılır.
  static Future<bool> isAvailable() async {
    if (debugAvailable case final v?) return v;
    if (kIsWeb) return isWebSpeechAvailable;
    if (!Platform.isAndroid) return false;
    try {
      return await _method.invokeMethod<bool>('speechAvailable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Mikrofon izni ZATEN verilmiş mi — sistem kutusu AÇMADAN okur (KT-24:
  /// kendiliğinden dinleme izni istemez; izni kullanıcı mikrofona basınca
  /// [ensureMicPermission] ister).
  static Future<bool> micPermissionGranted() async {
    if (debugMicGranted case final v?) return v;
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      return await _method.invokeMethod<bool>('micPermissionGranted') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Testler için: [micPermissionGranted] yanıtı.
  @visibleForTesting
  static bool? debugMicGranted;

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
  /// Köprüden gelen metin BURADA tekrarlardan arındırılır: tanıyıcı kısa
  /// duraklamalarda segmenti kapatıp yeniden başlatıyor ve sınırdaki kelimeyi
  /// bilerek iki kez yazıyor (konuşulanı kaybetmemek için — bkz.
  /// MainActivity.isContinuation). Temizlik tek yerde yapılır ki dikte, sesli
  /// asistan ve dikte alt sayfası ayrı ayrı uğraşmasın.
  ///
  /// [preferOffline]: cihazda dil paketi varsa ağa gidilmez (Ayarlar →
  /// İnternetsiz tanıma). Paket yoksa yerli taraf kendiliğinden çevrimiçi
  /// tanımaya döner. Argüman geriye uyumlu tek dize: "tr-TR|offline".
  static Stream<({String? text, double? level})> listen({
    String locale = 'tr-TR',
    bool preferOffline = false,
  }) {
    final rawStream = kIsWeb
        ? listenWebSpeech(locale: locale)
        : _events
              .receiveBroadcastStream(preferOffline ? '$locale|offline' : locale)
              .map((event) {
                final map = event as Map<Object?, Object?>;
                return (
                  text: map['text'] as String?,
                  level: (map['level'] as num?)?.toDouble(),
                );
              });
    return rawStream.map((event) {
      final raw = event.text;
      final text = raw == null ? null : dedupeSpeechSegments(raw);
      return (
        // Boş metin olayı YOK SAYILIR: tanıyıcı bazı turlarda boş sonuç
        // gönderiyor ve bu, o ana kadar yazılmış metnin üzerine yazıp
        // siliyordu (ölçümle doğrulandı). Boşsa null döner, çağıran da
        // mevcut metni korur.
        text: (text == null || text.isEmpty) ? null : text,
        level: event.level,
      );
    });
  }

  /// Dinlemeyi bitirir; son (tamamlanmış) metin akıştan gelir.
  static Future<void> stop() async {
    if (kIsWeb) {
      await stopWebSpeech();
      return;
    }
    try {
      await _method.invokeMethod('stopSpeech');
    } on PlatformException {
      // Zaten kapalıysa sorun değil.
    }
  }
}
