import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';

void main() {
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
