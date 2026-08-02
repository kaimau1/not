import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/model_catalog.dart';
import 'package:notlar/features/settings/settings_providers.dart';

/// Kısayol: sağlayıcının görünen ad vermediği (Gemini gibi) liste.
Map<String, String?> _ids(List<String> ids) => {for (final id in ids) id: null};

List<String> _rank(AiProvider provider, List<String> ids) =>
    [for (final m in rankModels(provider, _ids(ids))) m.id];

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

  group('rankModels — eleme', () {
    test('tts/embed/görsel/canlı modeller hiç dönmez', () {
      expect(
        _rank(AiProvider.gemini, [
          'gemini-3.5-flash',
          'gemini-2.5-flash-preview-tts',
          'gemini-3.5-flash-live',
          'gemini-embedding-001',
          'imagen-4.0',
        ]),
        ['gemini-3.5-flash'],
      );
    });

    test('OpenAI sohbet dışı modelleri elenir', () {
      expect(
        _rank(AiProvider.openai, [
          'gpt-5-mini',
          'whisper-1',
          'tts-1-hd',
          'text-embedding-3-large',
          'dall-e-3',
          'omni-moderation-latest',
        ]),
        ['gpt-5-mini'],
      );
    });

    test('boş liste boş döner (çağıran yedeğe düşer)', () {
      expect(rankModels(AiProvider.gemini, const {}), isEmpty);
    });
  });

  group('rankModels — öneri sırası', () {
    test('Gemini: flash-lite önce, sonra flash, sonra kalanlar', () {
      expect(
        _rank(AiProvider.gemini, [
          'gemini-3.5-pro',
          'gemini-3.5-flash',
          'gemini-3.5-flash-lite',
        ]),
        ['gemini-3.5-flash-lite', 'gemini-3.5-flash', 'gemini-3.5-pro'],
      );
    });

    test('aynı öneri sınıfında yeni sürüm önce gelir', () {
      expect(
        _rank(AiProvider.gemini, [
          'gemini-2.5-flash',
          'gemini-4.0-flash',
          'gemini-3.8-flash',
        ]),
        ['gemini-4.0-flash', 'gemini-3.8-flash', 'gemini-2.5-flash'],
      );
    });

    test('pro/opus önerilmez ama listede kalır', () {
      final models = rankModels(
        AiProvider.anthropic,
        _ids(['claude-opus-4-1', 'claude-haiku-4-5']),
      );
      expect(models.first.id, 'claude-haiku-4-5');
      expect(models.first.recommended, isTrue);
      expect(models.last.id, 'claude-opus-4-1');
      expect(models.last.recommended, isFalse);
    });

    test('OpenRouter ücretsiz modelleri en başa alır', () {
      expect(
        _rank(AiProvider.openrouter, [
          'openai/gpt-5-mini',
          'meta-llama/llama-4:free',
        ]),
        ['meta-llama/llama-4:free', 'openai/gpt-5-mini'],
      );
    });

    test('önerilen modellerin gerekçesi dolu, ötekilerinki boş', () {
      final models = rankModels(
        AiProvider.gemini,
        _ids(['gemini-3.5-flash', 'gemini-3.5-pro']),
      );
      expect(models.firstWhere((m) => m.recommended).note, isNotNull);
      expect(models.firstWhere((m) => !m.recommended).note, isNull);
    });
  });

  group('parseModelList', () {
    test('Gemini: generateContent desteklemeyen model atlanır', () {
      final parsed = parseModelList(AiProvider.gemini, {
        'models': [
          {
            'name': 'models/gemini-3.5-flash',
            'displayName': 'Gemini 3.5 Flash',
            'supportedGenerationMethods': ['generateContent'],
          },
          {
            'name': 'models/gemini-embedding-001',
            'supportedGenerationMethods': ['embedContent'],
          },
        ],
      });
      expect(parsed, {'gemini-3.5-flash': 'Gemini 3.5 Flash'});
    });

    test('OpenAI/OpenRouter: data listesi id ile okunur', () {
      expect(
        parseModelList(AiProvider.openai, {
          'data': [
            {'id': 'gpt-5-mini', 'name': 'GPT-5 mini'},
            {'id': 'gpt-5'},
          ],
        }),
        {'gpt-5-mini': 'GPT-5 mini', 'gpt-5': null},
      );
    });

    test('Anthropic: display_name görünen ad olarak alınır', () {
      expect(
        parseModelList(AiProvider.anthropic, {
          'data': [
            {'id': 'claude-haiku-4-5', 'display_name': 'Claude Haiku 4.5'},
          ],
        }),
        {'claude-haiku-4-5': 'Claude Haiku 4.5'},
      );
    });

    test('beklenmedik gövde çökmez, boş döner', () {
      expect(parseModelList(AiProvider.openai, null), isEmpty);
      expect(parseModelList(AiProvider.gemini, 'bozuk'), isEmpty);
      expect(parseModelList(AiProvider.openai, {'data': 'liste değil'}), isEmpty);
    });
  });
}
