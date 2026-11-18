// DA-13 (plan_decisions_api §3B.1): AI başlığı Decisions ile doğrulanır;
// "yanlış/genel" ise generateTitle BİR kez daha. Sahte HTTP, canlı çağrı yok.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';
import 'package:notlar/features/ai/data/decisions/decision_models.dart';
import 'package:notlar/features/ai/data/decisions/decision_profiles.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';

DecisionAnswer _noul(double p) =>
    DecisionAnswer(type: 'noul', noul: p, confidence: p > .5 ? p : 1 - p);

void main() {
  var calls = 0;

  DecisionService fake(double ok, double generic) => DecisionService(
    key: () async => 'k',
    http: JsonHttp(
      baseUrl: AiProvider.gemini.baseUrl,
      client: MockClient((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'answers': {
              'baslik_uygun': {'type': 'noul', 'noul': ok},
              'baslik_cok_genel': {'type': 'noul', 'noul': generic},
            },
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    ),
  );

  late List<String?> asked;
  Future<String> gen({String? avoid}) async {
    asked.add(avoid);
    return avoid == null ? 'IMG_2034' : 'Market alışverişi';
  }

  setUp(() {
    calls = 0;
    asked = [];
  });
  tearDown(AiDecisionsFlag.debugReset);

  void flag(String field) => AiDecisionsFlag.apply({
    field: [DecisionFeature.titleOk],
  });

  test('eşikler', () {
    DecisionOutcome? v(double ok, double g) => TitleOkProfile.interpret({
      'baslik_uygun': _noul(ok),
      'baslik_cok_genel': _noul(g),
    });
    expect(v(0.9, 0.1), DecisionOutcome.yes);
    expect(v(0.3, 0.1), DecisionOutcome.no);
    expect(v(0.9, 0.8), DecisionOutcome.no, reason: 'çok genel');
    expect(v(0.6, 0.1), DecisionOutcome.unsure);
    expect(TitleOkProfile.interpret({}), isNull);
  });

  test('bayrak kapalı: tek üretim, ağ yok', () async {
    expect(await checkedTitle(fake(0.1, 0.1), 'süt', gen), 'IMG_2034');
    expect(asked, [null]);
    expect(calls, 0);
  });

  test(
    'canlı: "yanlış" → bir kez yeniden, reddedilen başlık istemde',
    () async {
      flag(AiDecisionsFlag.featuresField);
      expect(
        await checkedTitle(fake(0.1, 0.1), '- süt\n- yumurta', gen),
        'Market alışverişi',
      );
      expect(asked, [null, 'IMG_2034']);
      expect(calls, 1, reason: 'yeniden üretilen başlık tekrar doğrulanmaz');
    },
  );

  test('canlı: emin değil / doğru → ilk başlık', () async {
    flag(AiDecisionsFlag.featuresField);
    expect(await checkedTitle(fake(0.6, 0.1), 'süt', gen), 'IMG_2034');
    expect(await checkedTitle(fake(0.9, 0.1), 'yumurta', gen), 'IMG_2034');
    expect(asked, [null, null]);
  });

  test('gölge: karar hesaplanır ama başlık değişmez', () async {
    flag(AiDecisionsFlag.shadowField);
    expect(await checkedTitle(fake(0.1, 0.1), 'süt', gen), 'IMG_2034');
    expect(asked, [null]);
    expect(calls, 1);
  });
}
