// Karar profilleri (plan_decisions_api §3B, §4.2): soru şeması ve iki eşikli
// yorum; saf, ağsız.
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/decisions/decision_models.dart';
import 'package:notlar/features/ai/data/decisions/decision_profiles.dart';

DecisionAnswer _choice(String c, double conf) =>
    DecisionAnswer(type: 'choice', choice: c, confidence: conf);

void main() {
  group('DA-1 dropTarget', () {
    test('şema: a_yok alfabetik ilk, ≤40 başlık, 60 karakter', () {
      final q =
          DropTargetProfile.questions([
                for (var i = 0; i < 45; i++) '${'x' * 70}$i',
              ])['hedef']!
              as ChoiceQuestion;
      expect(q.options.length, 41);
      final keys = q.options.keys.toList()..sort();
      expect(keys.first, ChoiceQuestion.none);
      expect(q.options['n00']!.length, 60);
      expect(q.options.keys.every(decisionKeyPattern.hasMatch), isTrue);
    });

    test(
      'eşikler: emin → uygula, orta → sor, düşük/a_yok/bozuk → eski yol',
      () {
        ({int? index, DecisionOutcome outcome}) r(DecisionAnswer a) =>
            DropTargetProfile.interpret({'hedef': a}, 3);
        expect(r(_choice('n02', 0.9)), (
          index: 2,
          outcome: DecisionOutcome.yes,
        ));
        expect(r(_choice('n01', 0.6)), (
          index: 1,
          outcome: DecisionOutcome.unsure,
        ));
        expect(r(_choice('n01', 0.3)).outcome, DecisionOutcome.no);
        expect(r(_choice('a_yok', 0.99)).index, isNull);
        expect(r(_choice('n07', 0.99)).index, isNull, reason: 'aralık dışı');
        expect(r(_choice('zzz', 0.99)).index, isNull);
        expect(DropTargetProfile.interpret({}, 3).outcome, DecisionOutcome.no);
      },
    );
  });
}
