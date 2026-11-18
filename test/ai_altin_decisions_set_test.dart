// DA-E0 bekçisi (anahtarsız): Decisions altın seti şeması + puanlama.
// Set `tool/ai_altin/decisions/*.json`, puan `tool/ai_altin/decisions_puan.dart`,
// canlı koşu `tool/ai_altin/decisions_kos_test.dart` (GEMINI_API_KEY ister).
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/decisions/decision_flag.dart';

import '../tool/ai_altin/decisions_puan.dart';

void main() {
  final yollar = kararSetleri();

  test('her karar profilinin seti var: ≥30 örnek, tekil kimlik', () {
    final profiller = {
      for (final y in yollar) kararSetiOku(y)['profil'] as String: y,
    };
    expect(profiller.keys.toSet(), {
      DecisionFeature.dropTarget,
      DecisionFeature.titleOk,
      DecisionFeature.spellFixOk,
      DecisionFeature.noteTriage,
    });
    final ids = <String>{};
    for (final y in yollar) {
      final ornekler = (kararSetiOku(y)['ornekler'] as List)
          .cast<Map<String, dynamic>>();
      expect(ornekler.length, greaterThanOrEqualTo(30), reason: y);
      for (final o in ornekler) {
        expect(ids.add(o['id'] as String), isTrue, reason: '${o['id']}');
        expect(o.containsKey('beklenen'), isTrue, reason: '${o['id']}');
      }
    }
  });

  test('K9: doğrulama setlerinde bilerek kötü örnekler var (≥ %40)', () {
    for (final y in yollar) {
      final s = kararSetiOku(y);
      if (!{
        DecisionFeature.titleOk,
        DecisionFeature.spellFixOk,
      }.contains(s['profil'])) {
        continue;
      }
      final o = (s['ornekler'] as List).cast<Map<String, dynamic>>();
      final kotu = o.where((e) => e['beklenen'] == false).length;
      expect(kotu / o.length, greaterThanOrEqualTo(0.4), reason: y);
    }
  });

  test('dropTarget: beklenen sıra başlık listesinde; "hiçbiri" örneği var', () {
    final s = kararSetiOku('tool/ai_altin/decisions/drop_target.json');
    final n = (s['basliklar'] as List).length;
    final o = (s['ornekler'] as List).cast<Map<String, dynamic>>();
    for (final e in o) {
      final b = e['beklenen'] as int?;
      if (b != null) expect(b, inInclusiveRange(0, n - 1), reason: e['id']);
    }
    expect(o.where((e) => e['beklenen'] == null).length, greaterThan(3));
  });

  group('puanlama', () {
    KararOrnek k(String b, String? t, double g) =>
        KararOrnek(id: '$b$t$g', beklenen: b, tahmin: t, guven: g);

    test('doğruluk ve kapsam@%95', () {
      final o = [
        k('a', 'a', 0.99),
        k('a', 'a', 0.95),
        k('b', 'b', 0.9),
        k('b', 'a', 0.6),
        k('a', null, 0),
      ];
      expect(dogruluk(o), 0.6);
      final c = kapsamAt(o);
      expect(c.kapsam, 0.6);
      expect(c.esik, 0.9);
    });

    test('ECE: kusursuz kalibrasyon 0, aşırı güven büyük', () {
      expect(ece([k('a', 'a', 1.0), k('a', 'a', 1.0)]), 0);
      expect(ece([k('a', 'b', 0.95), k('a', 'b', 0.95)]), closeTo(0.95, 1e-9));
    });

    test('K9 ret oranları ve yüzdelik', () {
      final r = retOranlari(
        {'iyi1': true, 'iyi2': true, 'kotu1': false, 'kotu2': false},
        {'kotu1', 'iyi2'},
      );
      expect(r.dogruRet, 0.5);
      expect(r.yanlisRet, 0.5);
      expect(yuzdelik([300, 100, 200, 400], .5), 200);
      expect(yuzdelik([300, 100, 200, 400], .95), 400);
      expect(yuzdelik(const [], .5), 0);
    });
  });
}
