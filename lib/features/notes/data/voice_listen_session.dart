import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/utils/voice_commands.dart';
import 'device_speech.dart';

/// Dinlemenin neden bittiği (çağıran kendi bitiş akışını buna göre seçer).
enum VoiceListenEnd {
  /// Konuşmadan sonra sessizlik (bkz. [SilenceGate]).
  silence,

  /// Yerli taraf oturumu kendi kapattı: uygulama arka plana düştü ya da
  /// uzun süre konuşma yok (MainActivity `speech_background`/`speech_idle`).
  closed,

  /// Tek oturumun üst sınırı doldu.
  maxDuration,
}

/// TEK DİNLEME ALTYAPISI — sesli yakalama levhası ve editörün sade
/// mikrofonu (canlı dikte) aynı oturumu kullanır.
///
/// KÖK NEDEN (2026-10-19, sadeleştirme): konuşmayı dinleyen ÜÇ ayrı kod
/// vardı — levha, editör diktesi ve Sesli Not Asistanı — ve her birinin kendi
/// akış aboneliği, zamanlayıcısı, yerli kapanış kodları ve süre sınırı vardı.
/// "Sessizlikte bitsin" düzeltmesi iki yere ayrı ayrı yazılmak zorunda
/// kaldı, üçüncüsünde hiç yoktu. Artık dinlemenin YAŞAM DÖNGÜSÜ burada:
/// cihaz tanımasına abonelik, sessizlik kapısı, üst sınır ve yerli kapanış.
/// Çağıranlar yalnız metni ne yapacaklarına (levhada göster / imlece yaz)
/// karar verir.
///
/// Cihazda yerleşik tanıma yoksa ([useDevice] false — web) oturum
/// mikrofonu kendisi açmaz; çağıran kendi kaydını yapar ve konuşma
/// kanıtını [reportSpeech]/[reportLevel] ile bildirir. Sessizlik ve üst sınır
/// yine buradan yönetilir.
class VoiceListenSession {
  VoiceListenSession({
    required this.onText,
    required this.onEnd,
    required this.autoStop,
    this.onError,
    this.onSilence,
    this.holdOpen,
    this.useDevice = true,
    this.maxDuration = const Duration(minutes: 10),
    this.locale = 'tr-TR',
    this.preferOffline = false,
    SilenceGate? gate,
  }) : _gate = gate ?? SilenceGate();

  /// Tanıyıcının o ana kadarki TAM metni (yalnız değiştiğinde).
  final void Function(String text) onText;

  /// Oturum kendiliğinden bitmek istiyor; çağıran [stop] ile bitirir.
  /// Bir oturumda en fazla bir kez çağrılır.
  final void Function(VoiceListenEnd reason) onEnd;

  /// Kapanış sayılmayan tanıma hatası (biriken metin korunur).
  final void Function(String message)? onError;

  /// Sessizlik geri sayımının oranı (0–1); yalnız konuşmadan SONRAKİ
  /// sessizlikte 0'dan büyüktür (açılır açılmaz dolan şerit telaş yaratırdı).
  final void Function(double progress)? onSilence;

  /// Ayar her yoklamada okunur: dinlerken değiştirilebilsin.
  final bool Function() autoStop;

  /// true dönerken sessizlikte bitmez (ör. basılı-tut modunda parmak düğmede).
  final bool Function()? holdOpen;

  final bool useDevice;
  final Duration maxDuration;
  final String locale;

  /// İnternetsiz tanıma tercihi (bkz. [DeviceSpeech.listen]).
  final bool preferOffline;

  final SilenceGate _gate;
  StreamSubscription<({String? text, double? level})>? _sub;
  Timer? _timer;
  DateTime? _startedAt;
  String _last = '';
  double _silence = 0;
  bool _ended = false;
  bool _active = false;

  bool get isActive => _active;

  /// En az bir kez konuşma algılandı mı.
  bool get heard => _gate.heard;

  void start() {
    if (_active) return;
    _active = true;
    _ended = false;
    _last = '';
    final now = DateTime.now();
    _startedAt = now;
    _gate.start(now);
    if (useDevice) {
      _sub = DeviceSpeech.listen(locale: locale, preferOffline: preferOffline)
          .listen(
            (event) {
              final level = event.level;
              if (level != null) _gate.onLevel(level, DateTime.now());
              final text = event.text;
              if (text == null || text == _last) return;
              _last = text;
              _gate.onSpeech(DateTime.now());
              onText(text);
            },
            onError: (Object e) {
              if (e is PlatformException &&
                  (e.code == 'speech_background' || e.code == 'speech_idle')) {
                _end(VoiceListenEnd.closed);
                return;
              }
              onError?.call(
                e is PlatformException ? (e.message ?? e.code) : e.toString(),
              );
            },
          );
    }
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  /// Kayıt yolunda (yerleşik tanıma yok) kesin konuşma kanıtı.
  void reportSpeech() => _gate.onSpeech(DateTime.now());

  /// Kayıt yolunda ses seviyesi (0–1).
  void reportLevel(double level) => _gate.onLevel(level, DateTime.now());

  void _tick() {
    if (!_active || _ended) return;
    final now = DateTime.now();
    final started = _startedAt;
    if (started != null && now.difference(started) >= maxDuration) {
      _end(VoiceListenEnd.maxDuration);
      return;
    }
    // Kayıt yolunda hiç konuşma algılanmadıysa kendiliğinden bitmez: seviye
    // eşiği mikrofona göre değişir, yanlış bir "duyulmadı" konuşulanı çöpe
    // atardı — o yolda bitiş yalnız konuşmadan SONRAKİ sessizlikle olur.
    final enabled =
        autoStop() &&
        !(holdOpen?.call() ?? false) &&
        (useDevice || _gate.heard);
    final progress = enabled ? _gate.progress(now) : 0.0;
    final shown = _gate.heard && progress > 0.3 ? progress : 0.0;
    if ((shown - _silence).abs() >= 0.05 || (shown == 0) != (_silence == 0)) {
      _silence = shown;
      onSilence?.call(shown);
    }
    if (enabled && progress >= 1) _end(VoiceListenEnd.silence);
  }

  void _end(VoiceListenEnd reason) {
    if (_ended) return;
    _ended = true;
    onEnd(reason);
  }

  /// Dinlemeyi bitirir; tanıyıcının SON sonucu [onText] ile gelir (kısa
  /// bekleme: son sonuç durdurma isteğinden biraz sonra düşer).
  Future<void> stop() async {
    if (!_active) return;
    _timer?.cancel();
    _timer = null;
    if (useDevice) {
      await DeviceSpeech.stop();
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    await _sub?.cancel();
    _sub = null;
    _active = false;
  }

  /// Dinlemeyi bekletmeden bırakır (iptal, ekran kapanışı).
  Future<void> cancel() async {
    _timer?.cancel();
    _timer = null;
    final sub = _sub;
    _sub = null;
    _active = false;
    await sub?.cancel();
  }
}
