// Karar profilleri (plan_decisions_api §3B, §4.2): soru şeması ve iki eşikli
// yorum; saf, ağsız.
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/decisions/decision_models.dart';
import 'package:notlar/features/ai/data/decisions/decision_profiles.dart';

DecisionAnswer _choice(String c, double conf) =>
    DecisionAnswer(type: 'choice', choice: c, confidence: conf);

DecisionAnswer _noul(double p) =>
    DecisionAnswer(type: 'noul', noul: p, confidence: p > .5 ? p : 1 - p);

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

  group('DA-2 noteTriage', () {
    const tags = ['is', 'kira', 'saglik'];
    const folders = {'fa': 'Ev', 'fb': 'İş'};

    test(
      'tek çağrı şeması: etiket başına noul + klasör + başlık + hatırlatıcı',
      () {
        final q = NoteTriageProfile.questions(
          tags: tags,
          folders: folders,
          hasTitle: false,
        );
        expect(q.keys, [
          't00',
          't01',
          't02',
          'klasor',
          'baslik_gerekli',
          'hatirlatici',
        ]);
        expect((q['klasor'] as ChoiceQuestion).options, {
          'a_yok': 'Uygun klasör yok',
          'f00': 'Ev',
          'f01': 'İş',
        });
        // Başlık varsa "başlık gerekli mi" sorulmaz; klasör yoksa klasör yok.
        final q2 = NoteTriageProfile.questions(
          tags: const [],
          folders: const {},
          hasTitle: true,
        );
        expect(q2.keys, ['hatirlatici']);
        expect(q.keys.every(decisionKeyPattern.hasMatch), isTrue);
      },
    );

    test('yorum: eşiği geçen ≤3 etiket güvene göre, klasör kimliği', () {
      final s = NoteTriageProfile.interpret(
        {
          't00': _noul(0.72),
          't01': _noul(0.95),
          't02': _noul(0.4),
          'klasor': _choice('f00', 0.8),
          'baslik_gerekli': _noul(0.9),
          'hatirlatici': _noul(0.6),
        },
        tags: tags,
        folders: folders,
      );
      expect(s.tags, ['kira', 'is']);
      expect(s.folderId, 'fa');
      expect(s.needsTitle, isTrue);
      expect(s.needsReminder, isFalse);
      final none = NoteTriageProfile.interpret(
        {'klasor': _choice('a_yok', 0.99), 'hatirlatici': _noul(0.1)},
        tags: tags,
        folders: folders,
      );
      expect(none.isEmpty, isTrue);
      // Düşük güvenli klasör önerilmez.
      expect(
        NoteTriageProfile.interpret(
          {'klasor': _choice('f01', 0.5)},
          tags: tags,
          folders: folders,
        ).folderId,
        isNull,
      );
    });
  });
}
