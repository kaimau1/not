// DA-E1 (docs/plan_decisions_api.md §4.2): tek DecisionService — bayrak,
// kapı, savunmacı ayrıştırma, zaman aşımı/429/5xx → null (geri düşüş),
// önbellek, toplu soru. Sahte HTTP; canlı çağrı YOK.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/api_key_store.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';
import 'package:notlar/features/ai/data/decisions/decision_models.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';
import 'package:notlar/features/ai/data/gemini_service.dart';

class _Keys extends ApiKeyStore {
  const _Keys(this.key);

  final String? key;

  @override
  Future<String?> read(AiProvider provider) async => key;
}

const _qs = <String, DecisionQuestion>{
  'evet': NoulQuestion('Evet mi?'),
  'sec': ChoiceQuestion('Hangisi?', {'a_yok': 'Hiçbiri', 'n00': 'Market'}),
};

void main() {
  late List<http.Request> sent;

  DecisionService service(
    FutureOr<http.Response> Function(http.Request) reply, {
    Future<String?> Function()? key,
    Duration timeout = const Duration(milliseconds: 1500),
  }) {
    sent = [];
    return DecisionService(
      key: key ?? () async => 'k',
      timeout: timeout,
      http: JsonHttp(
        baseUrl: AiProvider.gemini.baseUrl,
        client: MockClient((r) async {
          sent.add(r);
          return reply(r);
        }),
      ),
    );
  }

  http.Response ok(Object body) => http.Response(
    jsonEncode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  final good = {
    'answers': {
      'evet': {'type': 'noul', 'noul': 0.97, 'confidence': 0.97},
      'sec': {
        'type': 'choice',
        'choice': 'n00',
        'probabilities': {'n00': 0.9, 'a_yok': 0.1},
        'confidence': 0.9,
      },
    },
    'usage': {'total_input_tokens': 10, 'total_output_tokens': 0},
  };

  setUp(
    () => AiDecisionsFlag.apply({
      'aiDecisionsFeatures': ['f'],
    }),
  );
  tearDown(AiDecisionsFlag.debugReset);

  group('bayrak', () {
    test('varsayılan: alan yok / bozuk = yazım doğrulaması hariç canlı', () {
      for (final data in <Map<String, dynamic>?>[
        null,
        {'aiDecisionsFeatures': 'f'},
      ]) {
        AiDecisionsFlag.apply(data);
        expect(AiDecisionsFlag.modeOf('f'), DecisionMode.off);
        for (final f in [
          DecisionFeature.dropTarget,
          DecisionFeature.titleOk,
          DecisionFeature.noteTriage,
        ]) {
          expect(AiDecisionsFlag.modeOf(f), DecisionMode.live);
        }
        // Yazım doğrulaması bilerek kapalı (ECE 0,15).
        expect(
          AiDecisionsFlag.modeOf(DecisionFeature.spellFixOk),
          DecisionMode.off,
        );
      }
      expect(AiDecisionsFlag.model, 'gemini-decision-1');
    });

    test('uzaktan kapatma: boş dizi = hepsi kapalı', () {
      AiDecisionsFlag.apply({'aiDecisionsFeatures': <String>[]});
      expect(
        AiDecisionsFlag.modeOf(DecisionFeature.dropTarget),
        DecisionMode.off,
      );
    });

    test('canlı / gölge / model', () {
      AiDecisionsFlag.apply({
        'aiDecisionsFeatures': ['a'],
        'aiDecisionsShadow': ['b'],
        'aiDecisionsModel': 'gemini-decision-2',
      });
      expect(AiDecisionsFlag.modeOf('a'), DecisionMode.live);
      // Gölge yalnız kişisel derlemede (testler kişisel derlemedir).
      expect(AiDecisionsFlag.modeOf('b'), DecisionMode.shadow);
      expect(AiDecisionsFlag.modeOf('c'), DecisionMode.off);
      expect(AiDecisionsFlag.model, 'gemini-decision-2');
    });

    test('bayrak kapalıyken ağ yok', () async {
      final s = service((_) => ok(good));
      expect(await s.decide('kapali', input: 'x', questions: _qs), isNull);
      expect(sent, isEmpty);
    });
  });

  test('istek biçimi: tek çağrı, toplu sorular, anahtar başlıkta', () async {
    final s = service((_) => ok(good));
    final r = await s.decide('f', input: 'cümle', questions: _qs);
    expect(sent, hasLength(1));
    final req = sent.single;
    expect(
      req.url.toString(),
      'https://generativelanguage.googleapis.com/v1beta/decisions',
    );
    expect(req.headers['x-goog-api-key'], 'k');
    final body = jsonDecode(req.body) as Map;
    expect(body['model'], 'gemini-decision-1');
    expect(body['input'], [
      {'type': 'text', 'text': 'cümle'},
    ]);
    expect((body['questions'] as Map).keys, ['evet', 'sec']);
    expect(body['questions']['sec']['criteria'], {
      'a_yok': 'Hiçbiri',
      'n00': 'Market',
    });
    expect(r!['evet']!.noul, 0.97);
    expect(r['sec']!.choice, 'n00');
    expect(r['sec']!.confidence, 0.9);
  });

  test('kısa önbellek: aynı girdi ikinci kez ağa çıkmaz', () async {
    final s = service((_) => ok(good));
    await s.decide('f', input: 'x', questions: _qs);
    await s.decide('f', input: 'x', questions: _qs);
    expect(sent, hasLength(1));
    await s.decide('f', input: 'y', questions: _qs);
    expect(sent, hasLength(2));
  });

  group('geri düşüş (null)', () {
    test('anahtarsız dahili kip: vekil yok → kullanılamaz', () async {
      final s = service((_) => ok(good), key: () async => null);
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
      expect(sent, isEmpty);
    });

    test('kapı reddi (AI kapalı / kill switch / rıza) → ağ yok', () async {
      final s = service(
        (_) => ok(good),
        key: () async =>
            throw const GeminiException.of(GeminiErrorKind.aiPaused),
      );
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
      expect(sent, isEmpty);
    });

    test('429 ve 5xx → null, kısa süre yeniden denemez', () async {
      final s = service((_) => http.Response('{"error":{}}', 429));
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
      expect(await s.decide('f', input: 'y', questions: _qs), isNull);
      expect(sent, hasLength(1));
      final s5 = service((_) => http.Response('oops', 503));
      expect(await s5.decide('f', input: 'x', questions: _qs), isNull);
    });

    test('400 güvenlik engeli → null (kullanıcıya hata yok)', () async {
      final s = service(
        (_) => http.Response(
          jsonEncode({
            'error': {'message': 'blocked', 'code': 'safety'},
          }),
          400,
        ),
      );
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
    });

    test('zaman aşımı (≤ 1,5 sn) → null', () async {
      final s = service((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return ok(good);
      }, timeout: const Duration(milliseconds: 50));
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
    });

    test('bozuk anahtar / boş girdi / çok soru → ağ yok', () async {
      final s = service((_) => ok(good));
      expect(
        await s.decide(
          'f',
          input: 'x',
          questions: {'boşluk var': const NoulQuestion('?')},
        ),
        isNull,
      );
      expect(await s.decide('f', input: ' ', questions: _qs), isNull);
      expect(
        await s.decide(
          'f',
          input: 'x',
          questions: {
            for (var i = 0; i < 61; i++) 'q$i': const NoulQuestion('?'),
          },
        ),
        isNull,
      );
      expect(sent, isEmpty);
    });
  });

  group('savunmacı ayrıştırma', () {
    test(
      'GERÇEK ham yanıt (DA-E0 koşusu 2026-11-18): noul + choice + score',
      () {
        final body = jsonDecode(
          File('test/fixtures/decisions/probe_noul_choice_score.json')
              .readAsStringSync(),
        );
        final r = parseDecisionResponse(body, const {
          'n': NoulQuestion('?'),
          'c': ChoiceQuestion('?', {
            'a_yok': '',
            'b_alisveris': '',
            'c_is': '',
          }),
          's': ScoreQuestion('?', ['a', 'b', 'c']),
        });
        expect(r['n']!.noul, closeTo(0.961, 1e-3));
        expect(r['c']!.choice, 'b_alisveris');
        expect(r['c']!.probabilities['a_yok'], closeTo(0.0034, 1e-4));
        // score: olasılık ve legend NESNE, anahtar düzey sırası ('0','1','2').
        expect(r['s']!.score, closeTo(1.053, 1e-3));
        expect(r['s']!.probabilities.keys.toSet(), {'0', '1', '2'});
        expect(r['s']!.confidence, closeTo(0.459, 1e-3));
      },
    );

    test('bozuk gövde boş harita; bilinmeyen alan yok sayılır', () {
      expect(parseDecisionResponse('x', _qs), isEmpty);
      expect(parseDecisionResponse({'answers': 3}, _qs), isEmpty);
      final r = parseDecisionResponse({
        'answers': {
          'evet': {'noul': '0.8', 'yeni_alan': true},
          'sec': {'type': 'choice', 'choice': 'n00'},
          'baska': {'type': 'noul', 'noul': 0.5},
        },
      }, _qs);
      // Tür yoksa sorudan; güven yoksa max(p, 1-p).
      expect(r['evet']!.noul, 0.8);
      expect(r['evet']!.confidence, closeTo(0.8, 1e-9));
      // Seçim var ama ne güven ne olasılık: karar yok.
      expect(r.containsKey('sec'), isFalse);
      expect(r.containsKey('baska'), isFalse);
    });

    test('choice güveni olasılıktan; değerler [0,1]e kırpılır', () {
      final a = parseDecisionAnswer({
        'type': 'choice',
        'choice': 'n01',
        'probabilities': {'n01': 1.2, 'a_yok': -0.1},
      })!;
      expect(a.confidence, 1);
      expect(a.probabilities['a_yok'], 0);
    });

    test('score: olasılıklar nesne, sayı dizisi ya da nesne dizisi', () {
      final m = parseDecisionAnswer({
        'type': 'score',
        'score': 1.12,
        'probabilities': {'0': 0.1, '1': 0.7, '2': 0.2},
      })!;
      expect(m.score, 1.12);
      expect(m.confidence, 0.7);
      final l = parseDecisionAnswer({
        'type': 'score',
        'score': 2,
        'probabilities': [0.1, 0.2, 0.7],
        'legend': ['a', 'b', 'c'],
      })!;
      expect(l.probabilities['2'], 0.7);
      expect(l.confidence, 0.7);
      final o = parseDecisionAnswer({
        'type': 'score',
        'score': 0.4,
        'probabilities': [
          {'level': 0, 'probability': 0.6},
          {'level': 1, 'probability': 0.4},
        ],
        'confidence': 0.6,
      })!;
      expect(o.probabilities['0'], 0.6);
      expect(o.confidence, 0.6);
    });

    test('NaN / dize olmayan seçim / eksik değer → null', () {
      expect(parseDecisionAnswer({'type': 'noul'}), isNull);
      expect(parseDecisionAnswer({'type': 'noul', 'noul': double.nan}), isNull);
      expect(parseDecisionAnswer({'type': 'choice', 'choice': 3}), isNull);
      expect(parseDecisionAnswer({'type': 'score'}), isNull);
      expect(parseDecisionAnswer(null), isNull);
    });

    test('iki eşik', () {
      DecisionAnswer n(double p) =>
          DecisionAnswer(type: 'noul', noul: p, confidence: p);
      expect(noulOutcome(n(0.9), hi: 0.85, lo: 0.5), DecisionOutcome.yes);
      expect(noulOutcome(n(0.5), hi: 0.85, lo: 0.5), DecisionOutcome.no);
      expect(noulOutcome(n(0.6), hi: 0.85, lo: 0.5), DecisionOutcome.unsure);
      expect(noulOutcome(null, hi: 0.85, lo: 0.5), isNull);
    });
  });

  test(
    'tek kapı: Decisions anahtarı GeminiService izin yardımcısından',
    () async {
      final src = File('lib/features/ai/data/decisions/decision_service.dart')
          .readAsStringSync();
      expect(src, isNot(contains('keyStore')));
      expect(src, contains('admittedDecisionKey'));
      // Başka sağlayıcıda Decisions yok; Gemini'de saklı anahtar döner.
      expect(
        await GeminiService(
          const _Keys('k'),
          provider: AiProvider.openai,
        ).admittedDecisionKey(),
        isNull,
      );
      expect(await GeminiService(const _Keys('k')).admittedDecisionKey(), 'k');
      expect(
        await GeminiService(const _Keys('')).admittedDecisionKey(),
        isNull,
      );
      // AiAdmission kapısı ilk satır; hız sınırı Decisions'ın kendi sayacında.
      bool? meteredSeen;
      final gated = GeminiService(
        const _Keys('k'),
        admit: ({bool metered = true}) {
          meteredSeen = metered;
          throw const GeminiException.of(GeminiErrorKind.aiTurnedOff);
        },
      );
      await expectLater(
        gated.admittedDecisionKey(),
        throwsA(isA<GeminiException>()),
      );
      expect(meteredSeen, isFalse);
    },
  );

  group('sunucu vekili (kendi anahtarı yok)', () {
    DecisionService proxied(
      DecisionProxy proxy, {
      Future<String?> Function()? key,
    }) => DecisionService(
      key: key ?? () async => null,
      proxy: proxy,
      http: JsonHttp(
        baseUrl: AiProvider.gemini.baseUrl,
        client: MockClient((r) async {
          fail('anahtarsız istemci doğrudan Gemini\'ye çıkmamalı');
        }),
      ),
    );

    test('anahtar yok → vekil; aynı gövde, yanıt ayrıştırılır', () async {
      Map<String, Object?>? sentBody;
      final s = proxied((body) async {
        sentBody = body;
        return good;
      });
      final r = await s.decide('f', input: 'cümle', questions: _qs);
      expect(sentBody!['model'], 'gemini-decision-1');
      expect((sentBody!['questions'] as Map).keys, ['evet', 'sec']);
      expect(r!['evet']!.noul, 0.97);
    });

    test('katman kapısı (ömür boyu, anahtarsız) → yine vekil', () async {
      var called = 0;
      final s = proxied(
        (_) async {
          called++;
          return good;
        },
        key: () async =>
            throw const GeminiException.of(GeminiErrorKind.needsPro),
      );
      expect(await s.decide('f', input: 'x', questions: _qs), isNotNull);
      expect(called, 1);
    });

    test('kendi anahtarı varsa vekil kullanılmaz', () async {
      final withProxy = DecisionService(
        key: () async => 'k',
        proxy: (_) async => fail('vekil çağrılmamalı'),
        http: JsonHttp(
          baseUrl: AiProvider.gemini.baseUrl,
          client: MockClient((r) async => ok(good)),
        ),
      );
      expect(
        await withProxy.decide('f', input: 'x', questions: _qs),
        isNotNull,
      );
    });

    test('hak bitti → null ve vekil bir süre susar', () async {
      var called = 0;
      final s = proxied((_) async {
        called++;
        throw const DecisionQuotaExhausted();
      });
      expect(await s.decide('f', input: 'a', questions: _qs), isNull);
      expect(await s.decide('f', input: 'b', questions: _qs), isNull);
      expect(called, 1);
    });

    test('vekil kapısı (AI kapalı) → null, günlük yok', () async {
      final s = proxied(
        (_) async =>
            throw const GeminiException.of(GeminiErrorKind.aiTurnedOff),
      );
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
    });

    test('vekil yoksa (ücretsiz) anahtarsız = null', () async {
      final s = service((_) => ok(good), key: () async => null);
      expect(await s.decide('f', input: 'x', questions: _qs), isNull);
      expect(sent, isEmpty);
    });
  });
}
