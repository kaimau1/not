import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/carry_over.dart';
import 'package:notlar/features/notes/domain/context_highlight.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

void main() {
  group('ContextHighlightEngine', () {
    test('sabah saatinde morning slotunu öne çıkarır, kilitli ve arşivli notları atlar', () {
      final morning = DateTime(2026, 11, 25, 8, 30); // Çarşamba 08:30
      final notes = [
        Note(
          id: 'morning-routine',
          type: NoteType.checklist,
          title: 'Sabah Rutini',
          listMode: ListMode.routine,
          contextTimeSlot: ContextTimeSlot.morning,
          items: const [NoteItem(id: 'i1', text: 'Su iç')],
        ),
        Note(
          id: 'evening-routine',
          type: NoteType.checklist,
          title: 'Akşam Rutini',
          listMode: ListMode.routine,
          contextTimeSlot: ContextTimeSlot.evening,
        ),
        Note(
          id: 'locked-morning',
          type: NoteType.checklist,
          title: 'Kilitli Sabah',
          listMode: ListMode.routine,
          contextTimeSlot: ContextTimeSlot.morning,
          locked: true,
        ),
      ];

      final ids = ContextHighlightEngine.highlightedNoteIds(
        notes,
        now: morning,
      );
      expect(ids, contains('morning-routine'));
      expect(ids, isNot(contains('evening-routine')));
      expect(ids, isNot(contains('locked-morning')));

      final top = ContextHighlightEngine.topHighlight(notes, now: morning);
      expect(top?.id, 'morning-routine');
    });

    test(
      'hafta sonunda weekend slotu ve açık alışveriş listesini öne çıkarır',
      () {
        final saturday = DateTime(2026, 11, 28, 14); // Cumartesi
        final shop = Note(
          id: 'shop-1',
          type: NoteType.checklist,
          title: 'Haftalık Market',
          listMode: ListMode.shopping,
          items: const [NoteItem(id: 'i1', text: 'Süt')],
        );
        final ids = ContextHighlightEngine.highlightedNoteIds([
          shop,
        ], now: saturday);
        expect(ids, contains('shop-1'));
      },
    );
  });

  group('CarryOverEngine', () {
    test('önceki günden kalan bitmemiş görevleri bulur, kilitli/tamamlanmış/bugünküleri atlar', () {
      final today = DateTime(2026, 11, 28, 9);
      final yesterdayWithTime = DateTime(2026, 11, 27, 14, 30);
      final twoDaysAgo = DateTime(2026, 11, 26);

      final notes = [
        Note(
          id: 'proj-1',
          type: NoteType.checklist,
          title: 'Proje',
          listMode: ListMode.project,
          items: [
            NoteItem(id: 'due-past', text: 'Sunum', dueDate: yesterdayWithTime),
            NoteItem(
              id: 'done-past',
              text: 'Bitti',
              checked: true,
              dueDate: twoDaysAgo,
            ),
            NoteItem(id: 'due-today', text: 'Bugün', dueDate: today),
          ],
        ),
        Note(
          id: 'locked-1',
          type: NoteType.checklist,
          title: 'Kilitli',
          locked: true,
          items: [
            NoteItem(id: 'locked-past', text: 'Gizli', dueDate: twoDaysAgo),
          ],
        ),
      ];

      final plan = CarryOverEngine.scan(notes, now: today);
      expect(plan.totalItems, 1);
      expect(plan.entries.single.noteId, 'proj-1');
      expect(plan.entries.single.itemIds, ['due-past']);

      final batch = CarryOverEngine.buildCarryOverBatch(
        notes,
        plan,
        now: today,
      );
      expect(batch.updates.keys, ['proj-1']);
      final updatedItems = [
        for (final m in batch.updates['proj-1']!['items'] as List)
          NoteItem.fromMap(m as Map<String, dynamic>),
      ];
      final moved = updatedItems.firstWhere((i) => i.id == 'due-past');
      // Gün bugüne taşınır, saat (14:30) korunur!
      expect(moved.dueDate, DateTime(2026, 11, 28, 14, 30));
      expect(batch.undoSnapshots.keys, ['proj-1']);
    });
  });
}
