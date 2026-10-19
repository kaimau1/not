import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/speech_output.dart';
import '../../settings/settings_providers.dart';
import 'ai_speech.dart';
import 'gemini_service.dart';

/// **TEK SESLENDİRME KAPISI** (F3.9): uygulamadaki her "sesli oku" bunu
/// çağırır; motor (cihaz TTS'i ya da yapay zekâ sesi) Ayarlar → Ses →
/// Seslendirme'den gelir. İki motorun denetleyicisi ([speechOutputProvider],
/// [aiSpeechProvider]) yalnız motor olarak kalır; ekranlar onlara doğrudan
/// dokunmaz.
///
/// Durum, o an konuşan motorun durumudur — oynat/duraklat düğmesi ve
/// ilerleme çubuğu motordan bağımsız aynı [SpeechOutputState]i okur.
final speechProvider = NotifierProvider<SpeechService, SpeechOutputState>(
  SpeechService.new,
);

class SpeechService extends Notifier<SpeechOutputState> {
  bool _ai = false;

  @override
  SpeechOutputState build() {
    ref.listen(speechOutputProvider, (_, next) {
      if (!_ai) state = next;
    });
    ref.listen(aiSpeechProvider, (_, next) {
      if (_ai) state = next;
    });
    return const SpeechOutputState();
  }

  /// Yapay zekâ sesi bu kurulumda kullanılabilir mi (kendi Gemini anahtarı).
  bool get aiAvailable => ref.read(aiSpeechProvider.notifier).isAvailable;

  /// Ayar yapay zekâ sesini istiyor ve kullanılabilir.
  bool get prefersAi =>
      aiAvailable && ref.read(ttsEngineProvider) == TtsEngine.gemini;

  /// Şu anki (ya da son) okuma yapay zekâ sesiyle mi.
  bool get usingAi => _ai;

  /// [text]'i okur; zaten okuyorsa önce durdurur. [ai] verilmezse ayar
  /// geçerlidir. Yapay zekâ sesi başarısız olursa (kota, anahtar, ağ)
  /// [onAiFailed] hata metniyle çağrılır ve okuma CİHAZ sesiyle sürer —
  /// sessizce hiçbir şey olmaması en kötü sonuç olurdu.
  Future<void> speak(
    String text, {
    bool? ai,
    String? languageCode,
    void Function(String message)? onAiFailed,
  }) async {
    await stop();
    _ai = (ai ?? prefersAi) && aiAvailable;
    final device = ref.read(speechOutputProvider.notifier);
    if (!_ai) {
      await device.speak(text, languageCode: languageCode);
      return;
    }
    try {
      await ref.read(aiSpeechProvider.notifier).speak(text);
    } catch (e) {
      _ai = false;
      state = ref.read(speechOutputProvider);
      onAiFailed?.call(e is GeminiException ? e.message : '$e');
      await device.speak(text, languageCode: languageCode);
    }
  }

  Future<void> pause() => _ai
      ? ref.read(aiSpeechProvider.notifier).pause()
      : ref.read(speechOutputProvider.notifier).pause();

  Future<void> resume() => _ai
      ? ref.read(aiSpeechProvider.notifier).resume()
      : ref.read(speechOutputProvider.notifier).resume();

  /// İki motoru da durdurur.
  Future<void> stop() async {
    await ref.read(speechOutputProvider.notifier).stop();
    await ref.read(aiSpeechProvider.notifier).stop();
    state = const SpeechOutputState();
  }
}
