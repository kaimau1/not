import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/widget_service.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// "Bugün" widget'ının verisi (bkz. [todayWidgetPayload]).
void main() {
  final now = DateTime(2026, 9, 23, 21);

  test('7 günlük pencere, saat sırasıyla; arşiv ve geçmiş gün dışarıda', () {
    final notes = [
      Note(
        id: 'b',
        type: NoteType.text,
        title: 'Akşam',
        reminderAt: DateTime(2026, 9, 23, 22),
      ),
      Note(
        id: 'a',
        type: NoteType.text,
        title: 'Sabah',
        reminderAt: DateTime(2026, 9, 23, 8),
      ),
      Note(
        id: 'dun',
        type: NoteType.text,
        title: 'Dün',
        reminderAt: DateTime(2026, 9, 22, 8),
      ),
      Note(
        id: 'uzak',
        type: NoteType.text,
        title: 'Uzak',
        reminderAt: DateTime(2026, 10, 5),
      ),
      Note(
        id: 'arsiv',
        type: NoteType.text,
        title: 'Arşiv',
        reminderAt: DateTime(2026, 9, 24),
        archivedAt: DateTime(2026, 9),
      ),
    ];
    final lines = todayWidgetPayload(notes, now).split('\n');
    expect(lines.map((l) => l.split('\t').last).toList(), ['Sabah', 'Akşam']);
    expect(
      lines.first.split('\t').first,
      '${DateTime(2026, 9, 23, 8).millisecondsSinceEpoch}',
    );
  });

  test('kilitli notun başlığı sızmaz, sekme/satır sonu temizlenir', () {
    final notes = [
      Note(
        id: 'k',
        type: NoteType.text,
        title: 'Gizli şifre',
        locked: true,
        reminderAt: DateTime(2026, 9, 23, 9),
      ),
      Note(
        id: 't',
        type: NoteType.text,
        title: 'a\tb',
        reminderAt: DateTime(2026, 9, 23, 10),
      ),
    ];
    final text = todayWidgetPayload(notes, now);
    expect(text.contains('Gizli'), isFalse);
    expect(text.split('\n').last.split('\t').last, 'a b');
  });
}
