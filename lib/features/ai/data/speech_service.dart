import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/speech_output.dart';
import '../../settings/settings_providers.dart';
import 'ai_speech.dart';
import 'antalia/antalia_engine.dart';
import 'antalia/antalia_speech.dart';
import 'gemini_service.dart';

/// **TEK SESLENDİRME KAPISI** (F3.9): uygulamadaki her "sesli oku" bunu
/// çağırır; motor (cihaz TTS'i, yapay zekâ sesi ya da cihazdaki Antalia
/// Türkçe sesi) Ayarlar → Ses → Seslendirme'den gelir. Motorların
/// denetleyicileri ([speechOutputProvider], [aiSpeechProvider],
/// [antaliaSpeechProvider]) yalnız motor olarak kalır; ekranlar onlara
/// doğrudan dokunmaz.
///
/// Durum, o an konuşan motorun durumudur — oynat/duraklat düğmesi ve
/// ilerleme çubuğu motordan bağımsız aynı [SpeechOutputState]i okur.
final speechProvider = NotifierProvider<SpeechService, SpeechOutputState>(
  SpeechService.new,
);

class SpeechService extends Notifier<SpeechOutputState> {
  /// Şu anki (ya da son) okumayı yapan motor.
  TtsEngine _active = TtsEngine.device;

  @override
  SpeechOutputState build() {
    ref.listen(speechOutputProvider, (_, next) {
      if (_active == TtsEngine.device) state = next;
    });
    ref.listen(aiSpeechProvider, (_, next) {
      if (_active == TtsEngine.gemini) state = next;
    });
    ref.listen(antaliaSpeechProvider, (_, next) {
      if (_active == TtsEngine.antalia) state = next;
    });
    return const SpeechOutputState();
  }

  /// Yapay zekâ sesi bu kurulumda kullanılabilir mi (kendi Gemini anahtarı).
  bool get aiAvailable => ref.read(aiSpeechProvider.notifier).isAvailable;

  /// Antalia Türkçe sesi bu cihazda kurulu mu (model indirilmiş, Android).
  bool get localAvailable =>
      ref.read(antaliaSpeechProvider.notifier).isAvailable;

  /// Ayar yapay zekâ sesini istiyor ve kullanılabilir.
  bool get prefersAi =>
      aiAvailable && ref.read(ttsEngineProvider) == TtsEngine.gemini;

  /// Ayar Antalia sesini istiyor ve model kurulu.
  bool get prefersLocal =>
      localAvailable && ref.read(ttsEngineProvider) == TtsEngine.antalia;

  /// Şu anki (ya da son) okuma yapay zekâ sesiyle mi.
  bool get usingAi => _active == TtsEngine.gemini;

  /// Şu anki (ya da son) okuma Antalia sesiyle mi.
  bool get usingLocal => _active == TtsEngine.antalia;

  /// [text]'i okur; zaten okuyorsa önce durdurur. [ai] verilmezse ayar
  /// geçerlidir (true: yapay zekâ sesi istenir, false: cihaz sesi). Seçilen
  /// ses başarısız olursa (kota, anahtar, ağ; Antalia'da model hatası)
  /// [onAiFailed] hata metniyle çağrılır ve okuma CİHAZ sesiyle sürer —
  /// sessizce hiçbir şey olmaması en kötü sonuç olurdu.
  ///
  /// Antalia yalnız Türkçe okur: [languageCode] Türkçe dışıysa cihaz sesi.
  Future<void> speak(
    String text, {
    bool? ai,
    String? languageCode,
    void Function(String message)? onAiFailed,
  }) async {
    await stop();
    if (ref.read(ttsEngineProvider) == TtsEngine.antalia) {
      await ref.read(antaliaModelProvider.notifier).checked;
    }
    final turkish = languageCode == null || languageCode == 'tr';
    if (ai != null) {
      _active = ai && aiAvailable ? TtsEngine.gemini : TtsEngine.device;
    } else if (prefersAi) {
      _active = TtsEngine.gemini;
    } else if (prefersLocal && turkish) {
      _active = TtsEngine.antalia;
    } else {
      _active = TtsEngine.device;
    }
    final device = ref.read(speechOutputProvider.notifier);
    if (_active == TtsEngine.device) {
      await device.speak(text, languageCode: languageCode);
      return;
    }
    try {
      if (_active == TtsEngine.gemini) {
        await ref.read(aiSpeechProvider.notifier).speak(text);
      } else {
        await ref.read(antaliaSpeechProvider.notifier).speak(text);
      }
    } catch (e) {
      _active = TtsEngine.device;
      state = ref.read(speechOutputProvider);
      onAiFailed?.call(e is GeminiException ? e.message : '$e');
      await device.speak(text, languageCode: languageCode);
    }
  }

  Future<void> pause() => switch (_active) {
    TtsEngine.gemini => ref.read(aiSpeechProvider.notifier).pause(),
    TtsEngine.antalia => ref.read(antaliaSpeechProvider.notifier).pause(),
    TtsEngine.device => ref.read(speechOutputProvider.notifier).pause(),
  };

  Future<void> resume() => switch (_active) {
    TtsEngine.gemini => ref.read(aiSpeechProvider.notifier).resume(),
    TtsEngine.antalia => ref.read(antaliaSpeechProvider.notifier).resume(),
    TtsEngine.device => ref.read(speechOutputProvider.notifier).resume(),
  };

  /// Ayarlardaki DENEME okuması: önce BÜTÜN motorları susturur, sonra
  /// yalnız [engine] örneği okur.
  ///
  /// KÖK NEDEN (kullanıcı bildirimi 2026-10-23: "model seçilip denenirken
  /// hem Türkçe ses hem yapay zekâ aynı anda çalışıyor"): deneme düğmeleri
  /// motorları DOĞRUDAN çağırıyordu; her motor yalnız kendini durduruyordu.
  /// Antalia örneği (model yüklemesiyle birkaç sn) sürerken yapay zekâ
  /// denemesine geçilince ikisi üst üste çalıyordu.
  Future<void> preview(
    TtsEngine engine,
    String sample, {
    String? languageCode,
  }) async {
    await stop();
    _active = engine;
    switch (engine) {
      case TtsEngine.device:
        await ref
            .read(speechOutputProvider.notifier)
            .speak(sample, languageCode: languageCode);
      case TtsEngine.gemini:
        await ref.read(aiSpeechProvider.notifier).previewVoice(sample);
      case TtsEngine.antalia:
        await ref.read(antaliaSpeechProvider.notifier).preview(sample);
    }
  }

  /// Bütün motorları durdurur.
  Future<void> stop() async {
    await ref.read(speechOutputProvider.notifier).stop();
    await ref.read(aiSpeechProvider.notifier).stop();
    await ref.read(antaliaSpeechProvider.notifier).stop();
    state = const SpeechOutputState();
  }
}
