import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';
import 'package:notlar/features/ai/data/model_catalog.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Görev başına otomatik model sırası (kullanıcı isteği 2026-11-15:
/// "model sıralamasını baştan yap, otomatik modu ayarla"). Katalog, hesabın
/// AI Studio listesine benzer: kotası 0 olanlar ve uyumsuzlar da içinde.
const _raw = <String, String>{
  'gemini-3.5-flash-lite': 'Gemini 3.5 Flash Lite',
  'gemini-3.1-flash-lite': 'Gemini 3.1 Flash Lite',
  'gemini-3.1-flash-lite-preview': 'Gemini 3.1 Flash Lite Preview',
  'gemini-3.1-flash-lite-image': 'Nano Banana 2 Lite',
  'gemini-2.5-flash-lite': 'Gemini 2.5 Flash-Lite',
  'gemini-3.8-flash': 'Gemini 3.8 Flash',
  'gemini-3.6-flash': 'Gemini 3.6 Flash',
  'gemini-3-flash': 'Gemini 3 Flash',
  'gemini-2.5-flash': 'Gemini 2.5 Flash',
  'gemini-4-hydrogen': 'Gemini 4 Hydrogen',
  'gemini-4-argon': 'Gemini 4 Argon',
  'gemini-2.5-pro': 'Gemini 2.5 Pro',
  'gemini-3-pro-image': 'Nano Banana Pro',
  'gemini-3-pro-image-preview': 'Nano Banana Pro',
  'gemma-4-31b-it': 'Gemma 4 31B',
  'gemma-4-26b-a4b-it': 'Gemma 4 26B',
  'gemini-3.8-flash-tts': 'Gemini 3.8 Flash TTS',
  'gemini-3.8-flash-lite-tts': 'Gemini 3.8 Flash Lite TTS',
  'gemini-3.1-flash-tts': 'Gemini 3.1 Flash TTS',
  'gemini-2.5-flash-preview-tts': 'Gemini 2.5 Flash Preview TTS',
  'gemini-2.5-pro-preview-tts': 'Gemini 2.5 Pro Preview TTS',
  'gemini-3.5-transcribe': 'Gemini 3.5 Transcribe',
};

final _catalog = rankModels(AiProvider.gemini, _raw);

List<String> _order(ModelChain chain) => [
  for (final m in orderForChain(chain, _catalog)) m.id,
];

class _KeyStore extends ApiKeyStore {
  const _KeyStore();

  @override
  Future<String?> read(AiProvider provider) async => 'anahtar';
}

/// `/models` kataloğu döndürür; [fail] içindeki modellere 429 verir.
class _Net {
  _Net({this.fail = const {}, this.perDay = false, this.reply = 'tamam'});

  final Set<String> fail;
  final bool perDay;
  final String reply;
  final tried = <String>[];

  /// Model çağrılarının gövdeleri (sırayla).
  final bodies = <Map<String, dynamic>>[];

  late final client = MockClient((request) async {
    final path = request.url.path;
    if (path.endsWith('/models')) {
      return _json({
        'models': [
          for (final e in _raw.entries)
            {
              'name': 'models/${e.key}',
              'displayName': e.value,
              'supportedGenerationMethods': ['generateContent'],
            },
        ],
      });
    }
    final model = path.split('/models/').last.split(':').first;
    tried.add(model);
    bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
    if (fail.contains(model)) {
      return _json({
        'error': {
          'code': 429,
          'message': perDay
              ? 'GenerateRequestsPerDayPerProjectPerModel-FreeTier'
              : 'GenerateRequestsPerMinutePerProjectPerModel-FreeTier',
        },
      }, 429);
    }
    if (model.contains('tts')) {
      return _json({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'inlineData': {
                    'mimeType': 'audio/L16;rate=24000',
                    'data': base64Encode([0, 0, 0, 0]),
                  },
                },
              ],
            },
          },
        ],
      });
    }
    return _json({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': reply},
            ],
          },
        },
      ],
    });
  });

  static http.Response _json(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );
}

GeminiService _service(_Net net, {String? chosen}) => GeminiService(
  const _KeyStore(),
  http: JsonHttp(baseUrl: AiProvider.gemini.baseUrl, client: net.client),
  taskModel: (_) => chosen,
);

void main() {
  group('görev başına sıra', () {
    test('metin: Flash Lite → Gemma (kısa iş) → Flash → yedekler', () {
      expect(_order(ModelChain.general), [
        'gemini-3.5-flash-lite',
        'gemini-3.1-flash-lite',
        'gemma-4-31b-it',
        'gemma-4-26b-a4b-it',
        'gemini-3.8-flash',
        'gemini-3-flash',
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
        'gemini-3.6-flash',
        'gemini-4-hydrogen',
      ]);
    });

    test('belge/PDF/çeviri: Gemma yok', () {
      expect(_order(ModelChain.long), isNot(contains('gemma-4-31b-it')));
      expect(_order(ModelChain.long).first, 'gemini-3.5-flash-lite');
    });

    test('sesli asistan: standart Flash önce', () {
      expect(_order(ModelChain.voice).first, 'gemini-3.8-flash');
    });

    test('seslendirme: yalnız TTS modelleri, 2.5 Pro TTS yok', () {
      expect(_order(ModelChain.tts), [
        'gemini-3.8-flash-tts',
        'gemini-3.8-flash-lite-tts',
        'gemini-3.1-flash-tts',
        'gemini-2.5-flash-preview-tts',
      ]);
    });

    test('döküm: Transcribe önce', () {
      expect(_order(ModelChain.transcribe).first, 'gemini-3.5-transcribe');
    });

    test('kota 0, görüntü modeli ve önizleme kopyası hiçbir zincirde yok', () {
      for (final chain in ModelChain.values) {
        final ids = _order(chain);
        expect(ids, isNot(contains('gemini-3.1-flash-lite-image')));
        expect(ids, isNot(contains('gemini-3.1-flash-lite-preview')));
        expect(ids, isNot(contains('gemini-2.5-pro')));
        expect(ids, isNot(contains('gemini-4-argon')));
        expect(ids, isNot(contains('gemini-3-pro-image')));
      }
    });

    test('görev → zincir eşlemesi', () {
      expect(GeminiService.chainOf(AiTask.general), ModelChain.general);
      expect(GeminiService.chainOf(AiTask.voice), ModelChain.voice);
      expect(GeminiService.chainOf(AiTask.podcast), ModelChain.long);
    });
  });

  group('seçici listesi', () {
    test('Tümünü göster kapalı: yalnız görevin zinciri', () {
      final list = pickerModels(ModelChain.long, _catalog, showAll: false)!;
      expect(list.every((m) => m.recommended), isTrue);
      expect(list.map((m) => m.id), isNot(contains('gemini-2.5-pro')));
    });

    test('Tümünü göster açık: geri kalanlar tekil, önerilmemiş', () {
      final list = pickerModels(ModelChain.long, _catalog, showAll: true)!;
      final banana = list.where((m) => m.label == 'Nano Banana Pro');
      expect(banana, hasLength(1));
      expect(
        list.firstWhere((m) => m.id == 'gemini-2.5-pro').recommended,
        isFalse,
      );
    });

    test('başka sağlayıcıda tablo eşleşmez → eski liste', () {
      final other = rankModels(AiProvider.openai, {'gpt-5-mini': null});
      expect(pickerModels(ModelChain.general, other, showAll: false), isNull);
    });

    test('katalogda olmayan eski seçim → Otomatik (null)', () {
      expect(validChoice('gemini-1.5-flash', _catalog), isNull);
      expect(validChoice('gemini-3-flash', _catalog), 'gemini-3-flash');
      expect(validChoice('x', const []), 'x');
    });
  });

  group('ModelCooldown', () {
    test('günlük kota Pasifik gece yarısına, dakikalık 1 dk', () {
      var now = DateTime.utc(2026, 11, 15, 12); // Pasifik 04:00
      final c = ModelCooldown(clock: () => now)
        ..hit('a', 429, body: 'PerDay')
        ..hit('b', 429, body: 'PerMinute');
      now = now.add(const Duration(minutes: 2));
      expect(c.isCooling('a'), isTrue);
      expect(c.isCooling('b'), isFalse);
      now = DateTime.utc(2026, 11, 16, 8, 1); // Pasifik gece yarısını geçti
      expect(c.isCooling('a'), isFalse);
    });
  });

  group('servis', () {
    test('429 → sıradaki; o model sonraki çağrıda atlanır', () async {
      final net = _Net(fail: {'gemini-3.5-flash-lite'}, perDay: true);
      final s = _service(net);
      await s.translateText('merhaba', 'en');
      expect(net.tried, ['gemini-3.5-flash-lite', 'gemini-3.1-flash-lite']);
      net.tried.clear();
      await s.translateText('merhaba', 'en');
      expect(net.tried, ['gemini-3.1-flash-lite']);
    });

    test(
      "kısa metin işinde Flash Lite'lar dolunca Gemma; çeviride değil",
      () async {
        const lites = {'gemini-3.5-flash-lite', 'gemini-3.1-flash-lite'};
        final net = _Net(fail: lites);
        await _service(net).composeBriefing('kısa veri');
        expect(net.tried.last, 'gemma-4-31b-it');
        final net2 = _Net(fail: lites);
        await _service(net2).translateText('a', 'en');
        expect(net2.tried.last, 'gemini-3.8-flash');
      },
    );

    test('katalogda olmayan elle seçim yok sayılır', () async {
      final net = _Net();
      await _service(net, chosen: 'gemini-1.5-flash').translateText('a', 'en');
      expect(net.tried, ['gemini-3.5-flash-lite']);
    });

    test('katalogdaki elle seçim önce denenir', () async {
      final net = _Net();
      await _service(net, chosen: 'gemini-3-flash').translateText('a', 'en');
      expect(net.tried, ['gemini-3-flash']);
    });

    test('seslendirme 429 → sıradaki TTS', () async {
      final net = _Net(fail: {'gemini-3.8-flash-tts'});
      await _service(net).speech('merhaba', voice: 'Kore');
      expect(net.tried, ['gemini-3.8-flash-tts', 'gemini-3.8-flash-lite-tts']);
    });
  });

  // Kullanıcı isteği 2026-11-15: "etiket ve başlıkta gemma önce olsa onların
  // modeli seçimi ayrı olsa".
  group('kısa işler (başlık, etiket, ayar arama)', () {
    test('sıra: Gemma 31B → 26B → Flash Lite\'lar → Flash zinciri', () {
      expect(_order(ModelChain.short), [
        'gemma-4-31b-it',
        'gemma-4-26b-a4b-it',
        'gemini-3.5-flash-lite',
        'gemini-3.1-flash-lite',
        'gemini-3.8-flash',
        'gemini-3-flash',
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
        'gemini-3.6-flash',
        'gemini-4-hydrogen',
      ]);
      expect(GeminiService.chainOf(AiTask.short), ModelChain.short);
    });

    test('başlık önce Gemma 31B ile', () async {
      final net = _Net(reply: 'Market listesi');
      final title = await _service(net).generateTitle(
        const Note(id: 'n', type: NoteType.text, body: 'süt, ekmek'),
      );
      expect(net.tried, ['gemma-4-31b-it']);
      expect(title, 'Market listesi');
    });

    test(
      'etiket Gemma\'ya düz metin gider (JSON kipi yok), ayrıştırılır',
      () async {
        final net = _Net(reply: 'Etiketler: is, Ev, alisveris, fazla');
        final tags = await _service(net).suggestTags(
          const Note(id: 'n', type: NoteType.text, body: 'toplantı notları'),
        );
        expect(net.tried, ['gemma-4-31b-it']);
        expect(
          jsonEncode(net.bodies.single),
          isNot(contains('responseMimeType')),
        );
        expect(tags, ['is', 'ev', 'alisveris']);
      },
    );

    test('uzun not kırpılır, Gemma yine kullanılır (16K TPM)', () async {
      final net = _Net(reply: 'is');
      await _service(net)
          .suggestTags(Note(id: 'n', type: NoteType.text, body: 'a' * 50000));
      expect(net.tried, ['gemma-4-31b-it']);
      final sent = jsonEncode(net.bodies.single);
      expect(sent.length, lessThan(GeminiService.shortTaskInputChars + 1500));
    });

    test('24K karakteri aşan girdi Gemma\'yı atlar (ayar arama)', () async {
      final net = _Net(reply: '[1, 0]');
      final hits = await _service(net)
          .matchSettings('yazı büyüt', List.filled(400, 'x' * 80));
      expect(net.tried, ['gemini-3.5-flash-lite']);
      expect(hits, [1, 0]);
    });

    test('etiket ayrıştırma: JSON, madde, kod çiti, tekrar', () {
      expect(GeminiService.parseTagList('["is", "ev"]'), ['is', 'ev']);
      expect(GeminiService.parseTagList('```json\n["saglik"]\n```'), [
        'saglik',
      ]);
      expect(GeminiService.parseTagList('- #okul\n- Okul\n2. finans.'), [
        'okul',
        'finans',
      ]);
      expect(GeminiService.parseTagList('alis veris'), ['alis-veris']);
      expect(GeminiService.parseTagList(''), isEmpty);
    });

    test('sıra ayrıştırma: aralık dışı ve tekrar atılır', () {
      expect(GeminiService.parseIndexList('3, 12, 3, 99', 20), [3, 12]);
      expect(GeminiService.parseIndexList('yok', 20), isEmpty);
    });
  });

  group('göç: eski tek seçim → başlık/etiket', () {
    Future<ProviderContainer> container(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('elle seçilmiş model iki göreve de geçer', () async {
      final c = await container({'model_chat': 'gemini-3-flash'});
      final m = c.read(aiTaskModelsProvider);
      expect(m[AiTask.general], 'gemini-3-flash');
      expect(m[AiTask.short], 'gemini-3-flash');
    });

    test('Otomatik ise Otomatik kalır', () async {
      final c = await container({});
      expect(c.read(aiTaskModelsProvider)[AiTask.short], isNull);
    });

    test('göç bir kez: sonra Otomatik\'e alınan kısa iş geri dönmez', () async {
      final c = await container({'model_chat': 'gemini-3-flash'});
      c.read(aiTaskModelsProvider.notifier).set(AiTask.short, null);
      c.invalidate(aiTaskModelsProvider);
      expect(c.read(aiTaskModelsProvider)[AiTask.short], isNull);
    });
  });
}
