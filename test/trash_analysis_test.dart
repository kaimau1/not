import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/trash_analysis.dart';

/// Çöp kutusu akıllı analizi (2026-10-20): cihazdaki kurallar.
void main() {
  final now = DateTime(2026, 10, 20, 12);
  Note trashed(
    String id, {
    String title = '',
    String body = '',
    List<NoteItem> items = const [],
    DateTime? reminderAt,
    bool locked = false,
    DateTime? deletedAt,
  }) => Note(
    id: id,
    type: NoteType.text,
    title: title,
    body: body,
    items: items,
    reminderAt: reminderAt,
    locked: locked,
    deletedAt: deletedAt ?? DateTime(2026, 10, 19),
  );

  TrashSuggestion? of(TrashAnalysis a, String id) =>
      a.suggestions.where((s) => s.noteId == id).firstOrNull;

  test(
    'boş ve kopya notlar silinebilir; iş/bilgi kalanlar geri yüklenmeli',
    () {
      final active = [
        const Note(
          id: 'aktif',
          type: NoteType.text,
          title: 'Market',
          body: 'süt',
        ),
      ];
      final trash = [
        trashed('bos', body: ' '),
        trashed('kopya', title: 'Market', body: 'süt'),
        trashed('eski', body: 'aynı metin', deletedAt: DateTime(2026, 10)),
        trashed('yeni', body: 'aynı metin', deletedAt: DateTime(2026, 10, 18)),
        trashed('alarm', body: 'toplantı', reminderAt: DateTime(2026, 11)),
        trashed('sifre', body: 'wifi şifre: 1234'),
        trashed(
          'is',
          title: 'Yapılacak',
          items: const [
            NoteItem(id: 'a', text: 'fatura'),
            NoteItem(id: 'b', text: 'kira', checked: true),
          ],
        ),
        trashed('kilitli', body: 'gizli şifre', locked: true),
        trashed('sade', body: 'kısa bir düşünce'),
      ];
      final a = analyzeTrash(
        trash,
        active: active,
        daysLeft: (n) => n.id == 'eski' ? 1 : 20,
        now: now,
      );
      expect(of(a, 'bos')?.reason, TrashReason.empty);
      expect(of(a, 'kopya')?.reason, TrashReason.duplicateOfActive);
      expect(of(a, 'kopya')?.note, 'Market');
      expect(of(a, 'eski')?.reason, TrashReason.duplicateInTrash);
      // Kopyanın EN YENİSİ silinmeye önerilmez.
      expect(of(a, 'yeni'), isNull);
      expect(of(a, 'alarm')?.reason, TrashReason.futureReminder);
      expect(of(a, 'sifre')?.reason, TrashReason.sensitiveInfo);
      expect(of(a, 'is')?.reason, TrashReason.openTasks);
      expect(of(a, 'is')?.note, '1');
      // Kilitli notun içeriğine bakılmaz.
      expect(of(a, 'kilitli'), isNull);
      expect(of(a, 'sade'), isNull);
      expect(a.stats.count, trash.length);
      expect(a.stats.lockedCount, 1);
      expect(a.stats.soonCount, 1);
      expect(a.of(TrashVerdict.delete).length, 3);
      expect(a.of(TrashVerdict.restore).length, 3);
    },
  );

  test('AI dökümü kilitli notu içermez, kimlikleri sıra numarasıyla eşler', () {
    final (:digest, :ids) = trashDigest([
      trashed('x', body: 'merhaba'),
      trashed('k', body: 'gizli', locked: true),
      trashed('y'),
    ]);
    expect(ids, {'n1': 'x', 'n2': 'y'});
    expect(digest, contains('[n1] merhaba'));
    expect(digest, contains('[n2] (boş)'));
    expect(digest, isNot(contains('gizli')));
  });
}
