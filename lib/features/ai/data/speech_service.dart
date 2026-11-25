import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/speech_output.dart';
import '../../settings/settings_providers.dart';
import 'antalia/antalia_engine.dart';
import 'antalia/antalia_speech.dart';

/// **TEK SESLENDİRME KAPISI** (F3.9): uygulamadaki her "sesli oku" bunu
/// çağırır; motor (cihaz TTS'i ya da cihazdaki Antalia Türkçe sesi)
/// Ayarlar → Ses → Seslendirme'den gelir.
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
    ref.listen(antaliaSpeechProvider, (_, next) {
      if (_active == TtsEngine.antalia) state = next;
    });
    return const SpeechOutputState();
  }

  /// Antalia Türkçe sesi bu cihazda kurulu mu (model indirilmiş, Android).
  bool get localAvailable =>
      ref.read(antaliaSpeechProvider.notifier).isAvailable;

  /// Ayar Antalia sesini istiyor ve model kurulu.
  bool get prefersLocal =>
      localAvailable && ref.read(ttsEngineProvider) == TtsEngine.antalia;

  /// Şu anki (ya da son) okuma Antalia sesiyle mi.
  bool get usingLocal => _active == TtsEngine.antalia;

  /// [text]'i okur; zaten okuyorsa önce durdurur. Antalia seçiliyse ve
  /// [languageCode] Türkçe ise cihaz içi Antalia ile, hata alırsa cihaz
  /// sesiyle sürer.
  Future<void> speak(
    String text, {
    String? languageCode,
    void Function(Object error)? onAiFailed,
  }) async {
    await stop();
    if (ref.read(ttsEngineProvider) == TtsEngine.antalia) {
      await ref.read(antaliaModelProvider.notifier).checked;
    }
    final turkish = languageCode == null || languageCode == 'tr';
    _active = prefersLocal && turkish ? TtsEngine.antalia : TtsEngine.device;
    final device = ref.read(speechOutputProvider.notifier);
    if (_active == TtsEngine.device) {
      await device.speak(text, languageCode: languageCode);
      return;
    }
    try {
      await ref.read(antaliaSpeechProvider.notifier).speak(text);
    } catch (e) {
      _active = TtsEngine.device;
      state = ref.read(speechOutputProvider);
      onAiFailed?.call(e);
      await device.speak(text, languageCode: languageCode);
    }
  }

  Future<void> pause() => switch (_active) {
    TtsEngine.antalia => ref.read(antaliaSpeechProvider.notifier).pause(),
    TtsEngine.device => ref.read(speechOutputProvider.notifier).pause(),
  };

  Future<void> resume() => switch (_active) {
    TtsEngine.antalia => ref.read(antaliaSpeechProvider.notifier).resume(),
    TtsEngine.device => ref.read(speechOutputProvider.notifier).resume(),
  };

  /// Ayarlardaki DENEME okuması: önce bütün motorları susturur, sonra yalnız
  /// [engine] örneği okur.
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
      case TtsEngine.antalia:
        await ref.read(antaliaSpeechProvider.notifier).preview(sample);
    }
  }

  /// Bütün motorları durdurur.
  Future<void> stop() async {
    await ref.read(speechOutputProvider.notifier).stop();
    await ref.read(antaliaSpeechProvider.notifier).stop();
    state = const SpeechOutputState();
  }
}
