// DA-E0 (docs/plan_decisions_api.md §4.7–§4.8): Decisions altın setini CANLI
// koşar ve puanlar. Anahtar YALNIZ ortam değişkeninden; yoksa "atlandı".
//
//   GEMINI_API_KEY=... flutter test tool/ai_altin/decisions_kos_test.dart
//   ALTIN_PROFIL=dropTarget,titleOk   yalnız bu profiller
//
// Çıktı: build/ai_altin/decisions_<zaman>.json (profil başına doğruluk,
// kapsam@%95, ECE, K9 ret oranları, P50/P95 ms) ve ham yanıtlar
// build/ai_altin/decisions_ham/ (alan biçimi doğrulaması: score
// legend/probabilities, usage adları). Soru şemaları UYGULAMANIN profilleri
// (decision_profiles.dart) — set ile uygulama aynı soruları sorar.
// Anahtar dosyaya/kayda YAZILMAZ.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:notlar/core/net/json_http.dart';
import 'package:notlar/features/ai/data/ai_policy.dart' show AiRateLimiter;
import 'package:notlar/features/ai/data/ai_provider.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';
import 'package:notlar/features/ai/data/decisions/decision_models.dart';
import 'package:notlar/features/ai/data/decisions/decision_profiles.dart';
import 'package:notlar/features/ai/data/decisions/decision_service.dart';

import 'decisions_puan.dart';

/// Yanıt gövdelerini diske yazan istemci (istek başlıkları YAZILMAZ).
class _Kayit extends http.BaseClient {
  _Kayit(this.dir);

  final Directory dir;
  final _inner = http.Client();
  int n = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final r = await _inner.send(request);
    final bytes = await r.stream.toBytes();
    File('${dir.path}/${(n++).toString().padLeft(3, '0')}_${r.statusCode}.json')
        .writeAsBytesSync(bytes);
    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      r.statusCode,
      headers: r.headers,
      request: request,
    );
  }
}

String _bool(double? p) => p == null ? '-' : (p >= 0.5 ? 'true' : 'false');
double _conf(double? p) => p == null ? 0 : (p > .5 ? p : 1 - p);

void main() {
  final key = Platform.environment['GEMINI_API_KEY'];
  final only = Platform.environment['ALTIN_PROFIL']?.split(',').toSet();

  test(
    'Decisions altın set (canlı)',
    () async {
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final ham = Directory('build/ai_altin/decisions_ham/$stamp')
        ..createSync(recursive: true);
      final svc = DecisionService(
        key: () async => key,
        // Ölçüm için geniş: gecikme dağılımı görülsün (uygulama 1,5 sn).
        timeout: const Duration(seconds: 15),
        // Ücretsiz katman 200 RPM; uygulamanın 30/dk sınırı koşuyu keserdi.
        limiter: AiRateLimiter(perMinute: 150, perHour: 2000),
        http: JsonHttp(baseUrl: AiProvider.gemini.baseUrl, client: _Kayit(ham)),
      );
      AiDecisionsFlag.apply({
        AiDecisionsFlag.featuresField: [
          'probe',
          DecisionFeature.dropTarget,
          DecisionFeature.titleOk,
          DecisionFeature.spellFixOk,
          DecisionFeature.noteTriage,
        ],
      });

      // DA-E0 #1: noul + choice + score tek çağrı → ham biçim.
      await svc.decide(
        'probe',
        input: 'Süt, yumurta ve deterjan alınacak.',
        questions: const {
          'n': NoulQuestion('Bu bir alışveriş listesi mi?'),
          'c': ChoiceQuestion('Tür?', {
            'a_yok': 'Hiçbiri',
            'b_alisveris': 'Alışveriş',
            'c_is': 'İş',
          }),
          's': ScoreQuestion('Ne kadar acil?', ['Değil', 'Biraz', 'Çok']),
        },
      );

      // Kota (429: ücretsiz katman 50K TPM / 200 RPM) servisi 1 dk susturur:
      // bekleyip en çok 3 kez yeniden; gecikme yalnız SON denemeden ölçülür.
      final sw = Stopwatch();
      Future<Map<String, DecisionAnswer>?> ask(
        String feature, {
        required String input,
        required Map<String, DecisionQuestion> questions,
      }) async {
        for (var i = 0; ; i++) {
          sw
            ..reset()
            ..start();
          final r = await svc.decide(
            feature,
            input: input,
            questions: questions,
          );
          if (r != null || i == 3) return r;
          await Future<void>.delayed(const Duration(seconds: 61));
        }
      }

      final rapor = <String, Object?>{};
      for (final yol in kararSetleri()) {
        final set = kararSetiOku(yol);
        final profil = set['profil'] as String;
        if (only != null && !only.contains(profil)) continue;
        final ornekler = <KararOrnek>[];
        final ms = <int>[];
        final iyiMi = <String, bool>{};
        final ret = <String>{};
        var yanitsiz = 0;
        for (final o
            in (set['ornekler'] as List).cast<Map<String, dynamic>>()) {
          final id = o['id'] as String;

          Map<String, DecisionAnswer>? r;
          switch (profil) {
            case 'dropTarget':
              final titles = (set['basliklar'] as List).cast<String>();
              r = await ask(
                DecisionFeature.dropTarget,
                input: DropTargetProfile.input(o['cumle'] as String),
                questions: DropTargetProfile.questions(titles),
              );
              final b = o['beklenen'] as int?;
              final a = r?['hedef'];
              ornekler.add(
                KararOrnek(
                  id: id,
                  beklenen: b == null
                      ? 'a_yok'
                      : 'n${b.toString().padLeft(2, '0')}',
                  tahmin: a?.choice,
                  guven: a?.confidence ?? 0,
                ),
              );
            case 'titleOk':
              r = await ask(
                DecisionFeature.titleOk,
                input: TitleOkProfile.input(
                  o['baslik'] as String,
                  o['metin'] as String,
                ),
                questions: TitleOkProfile.questions,
              );
              final p = r?['baslik_uygun']?.noul;
              ornekler.add(
                KararOrnek(
                  id: id,
                  beklenen: '${o['beklenen']}',
                  tahmin: p == null ? null : _bool(p),
                  guven: _conf(p),
                ),
              );
              iyiMi[id] = o['beklenen'] as bool;
              if (r != null &&
                  TitleOkProfile.interpret(r) == DecisionOutcome.no) {
                ret.add(id);
              }
            case 'spellFixOk':
              final fix = (
                typed: o['yazilan'] as String,
                fixed: o['duzeltilen'] as String,
              );
              r = await ask(
                DecisionFeature.spellFixOk,
                input: SpellFixProfile.input([
                  fix,
                ], (set['baglam'] as List).cast<String>()),
                questions: SpellFixProfile.questions(1),
              );
              final p = r?['d00']?.noul;
              ornekler.add(
                KararOrnek(
                  id: id,
                  beklenen: '${o['beklenen']}',
                  tahmin: p == null ? null : _bool(p),
                  guven: _conf(p),
                ),
              );
              iyiMi[id] = o['beklenen'] as bool;
              if (r != null && SpellFixProfile.interpret(r, 1).isNotEmpty) {
                ret.add(id);
              }
            case 'noteTriage':
              final tags = (set['etiketler'] as List).cast<String>();
              final folders = (set['klasorler'] as Map).cast<String, String>();
              final title = o['baslik'] as String;
              r = await ask(
                DecisionFeature.noteTriage,
                input: NoteTriageProfile.input(title, o['metin'] as String),
                questions: NoteTriageProfile.questions(
                  tags: tags,
                  folders: folders,
                  hasTitle: title.trim().isNotEmpty,
                ),
              );
              final b = (o['beklenen'] as Map).cast<String, dynamic>();
              final want = (b['etiketler'] as List).cast<String>().toSet();
              for (var i = 0; i < tags.length; i++) {
                final p = r?['t${i.toString().padLeft(2, '0')}']?.noul;
                ornekler.add(
                  KararOrnek(
                    id: '$id/${tags[i]}',
                    beklenen: '${want.contains(tags[i])}',
                    tahmin: p == null ? null : _bool(p),
                    guven: _conf(p),
                  ),
                );
              }
              final ids = folders.keys.toList();
              final k = r?['klasor'];
              final fi = ids.indexOf('${b['klasor']}');
              ornekler.add(
                KararOrnek(
                  id: '$id/klasor',
                  beklenen: fi < 0
                      ? 'a_yok'
                      : 'f${fi.toString().padLeft(2, '0')}',
                  tahmin: k?.choice,
                  guven: k?.confidence ?? 0,
                ),
              );
              final h = r?['hatirlatici']?.noul;
              ornekler.add(
                KararOrnek(
                  id: '$id/hatirlatici',
                  beklenen: '${b['hatirlatici']}',
                  tahmin: h == null ? null : _bool(h),
                  guven: _conf(h),
                ),
              );
          }
          if (r == null) yanitsiz++;
          ms.add(sw.elapsedMilliseconds);
        }
        final k95 = kapsamAt(ornekler);
        final rets = iyiMi.isEmpty ? null : retOranlari(iyiMi, ret);
        rapor[profil] = {
          'ornek': ornekler.length,
          'yanitsiz_cagri': yanitsiz,
          'dogruluk': dogruluk(ornekler),
          'kapsam95': k95.kapsam,
          'esik95': k95.esik,
          'ece': ece(ornekler),
          if (rets != null) 'dogru_ret': rets.dogruRet,
          if (rets != null) 'yanlis_ret': rets.yanlisRet,
          'p50_ms': yuzdelik(ms, .5),
          'p95_ms': yuzdelik(ms, .95),
          'yanlislar': [
            for (final e in ornekler)
              if (!e.dogru)
                '${e.id}: ${e.tahmin} (${e.guven.toStringAsFixed(2)})',
          ],
        };
        // ignore: avoid_print
        print('$profil: ${jsonEncode(rapor[profil])}');
      }
      final out = File('build/ai_altin/decisions_$stamp.json')
        ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rapor));
      // ignore: avoid_print
      print('Sonuç: ${out.path}  ham: ${ham.path}');
      AiDecisionsFlag.apply(null);
    },
    skip: key == null || key.isEmpty
        ? 'GEMINI_API_KEY yok — Decisions canlı ölçümü atlandı'
        : false,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
