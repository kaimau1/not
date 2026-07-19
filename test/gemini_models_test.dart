import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/settings/settings_providers.dart';

void main() {
  group('AiTask ayar anahtarları', () {
    test('her görev ayrı anahtar kullanır', () {
      final keys = AiTask.values.map((t) => t.prefsKey).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('eski tekil ayarların anahtarları korunur', () {
      // Bu iki anahtar tek dropdown'lu sürümde kullanılıyordu; değişirse
      // güncelleyen kullanıcının kayıtlı model seçimi sessizce kaybolur.
      expect(AiTask.general.prefsKey, 'model_chat');
      expect(AiTask.voice.prefsKey, 'model_voice');
    });
  });

  group('GeminiService.rankModels', () {
    test('tercih sırası korunur, API listesinde olmayan atlanır', () {
      final order = GeminiService.rankModels({
        'gemini-2.5-flash',
        'gemini-3.5-flash',
      });
      expect(order, ['gemini-3.5-flash', 'gemini-2.5-flash']);
    });

    test('tercihte olmayan flash modeller sona, yeniden eskiye eklenir', () {
      final order = GeminiService.rankModels({
        'gemini-3.5-flash',
        'gemini-3.8-flash',
        'gemini-4.0-flash',
      });
      expect(order,
          ['gemini-3.5-flash', 'gemini-4.0-flash', 'gemini-3.8-flash']);
    });

    test('tts/live/embed ve flash olmayan modeller elenir', () {
      final order = GeminiService.rankModels({
        'gemini-3.5-flash',
        'gemini-2.5-flash-preview-tts',
        'gemini-3.5-flash-live',
        'gemini-3.5-pro',
        'gemini-embedding-001',
      });
      expect(order, ['gemini-3.5-flash']);
    });

    test('boş API listesi boş döner (çağıran tercih listesine düşer)', () {
      expect(GeminiService.rankModels(<String>{}), isEmpty);
    });

    test('tercih listesi API listesinin tamamıyla aynı sırada', () {
      final order = GeminiService.rankModels(
        AppConstants.geminiModelPreference.toSet(),
      );
      expect(order, AppConstants.geminiModelPreference);
    });
  });
}
