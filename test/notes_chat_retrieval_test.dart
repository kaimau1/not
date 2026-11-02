import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/assistant_service.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// F18.18: "Tüm notlar" sohbeti soruyla alakalı notları getirir.
void main() {
  final old = Note(
    id: 'old',
    type: NoteType.text,
    title: 'Kombi',
    body: 'Kombi servisinin telefonu 0212 555 00 00',
    updatedAt: DateTime(2024),
  );
  final recent = [
    for (var i = 0; i < 100; i++)
      Note(
        id: 'n$i',
        type: NoteType.text,
        title: 'Not $i',
        body: 'sıradan içerik $i',
        updatedAt: DateTime(2026, 11, 2).subtract(Duration(minutes: i)),
      ),
  ];

  test('anahtar kelime yedeği eski notu bulur', () {
    final found = keywordRelevant('kombi servisi numarası', [...recent, old]);
    expect(found.first.id, 'old');
  });

  test('kilitli not getirilmez', () {
    final locked = old.copyWith(locked: true);
    expect(keywordRelevant('kombi', [locked]), isEmpty);
  });

  test('alakalı not bağlamda başta ve 80 sınırının dışında kalmaz', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(assistantServiceProvider);
    final without = service.buildNotesContext([...recent, old]);
    expect(without, isNot(contains('0212 555')));
    final with_ = service.buildNotesContext([...recent, old], relevant: [old]);
    expect(with_, contains('0212 555'));
    expect(with_.indexOf('id: old'), lessThan(with_.indexOf('id: n0')));
    expect('id: '.allMatches(with_).length, 80);
  });
}
