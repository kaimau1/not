import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/study_card.dart';
import 'package:notlar/features/notes/presentation/study_cards_screen.dart';

/// F18.19: SM-2 planlama ve bugünün kartları.
void main() {
  final now = DateTime(2026, 11, 2, 15);
  const card = StudyCard(id: 'c', question: 'Başkent?', answer: 'Ankara');

  test('doğru cevaplar aralığı 1 → 6 → aralık × EF büyütür', () {
    final r1 = reviewCard(card, CardGrade.good, now);
    expect(r1.interval, 1);
    expect(r1.due, DateTime(2026, 11, 3));
    final r2 = reviewCard(r1, CardGrade.good, now);
    expect(r2.interval, 6);
    final r3 = reviewCard(r2, CardGrade.good, now);
    expect(r3.interval, (6 * r3.ease).round());
  });

  test(
    'yanlış: tekrar sıfırlanır, yarın gelir, EF düşer ama 1.3 altına inmez',
    () {
      var c = reviewCard(card, CardGrade.good, now);
      c = reviewCard(c, CardGrade.good, now);
      final wrong = reviewCard(c, CardGrade.again, now);
      expect(wrong.reps, 0);
      expect(wrong.interval, 1);
      expect(wrong.ease, lessThan(c.ease));
      var low = card;
      for (var i = 0; i < 20; i++) {
        low = reviewCard(low, CardGrade.again, now);
      }
      expect(low.ease, 1.3);
    },
  );

  test('bugünün kartları: yeni ve vadesi gelen; kilitli not hariç', () {
    final later = card.copyWith(due: DateTime(2026, 11, 5));
    final notes = [
      Note(id: 'a', type: NoteType.text, cards: [card, later]),
      const Note(id: 'b', type: NoteType.text, locked: true, cards: [card]),
    ];
    expect(dueCards(notes, now).map((e) => e.note.id), ['a']);
  });

  test('kayıt gidiş-dönüş', () {
    final c = reviewCard(card, CardGrade.easy, now);
    final back = StudyCard.fromMap(c.toMap());
    expect(back.question, 'Başkent?');
    expect(back.interval, c.interval);
    expect(back.due, c.due);
  });
}
