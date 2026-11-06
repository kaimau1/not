import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/data/task_note_sync.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/notes/domain/note_item.dart';

/// TAKVIM_PLANI F50.3 (K6): liste maddesi ↔ görev iki yönlü tamamlanma.
void main() {
  const items = [
    NoteItem(id: 'a', text: 'Süt'),
    NoteItem(id: 'b', text: 'Ekmek', checked: true),
  ];

  test('madde işareti yalnız değişince yazılır', () {
    expect(itemsWithChecked(items, 'a', false), isNull);
    expect(itemsWithChecked(items, 'yok', true), isNull);
    final next = itemsWithChecked(items, 'a', true)!;
    expect(next.map((i) => i.checked), [true, true]);
    expect(next.last, same(items.last));
  });

  test('maddeye bağlı, durumu farklı, tekrarsız görevler eşlenir', () {
    final tasks = [
      const TaskItem(id: '1', noteId: 'n', noteItemId: 'a'),
      const TaskItem(id: '2', noteId: 'n', noteItemId: 'a', completed: true),
      const TaskItem(id: '3', noteId: 'n', noteItemId: 'b'),
      const TaskItem(
        id: '4',
        noteId: 'n',
        noteItemId: 'a',
        due: '2026-11-06',
        repeat: 'daily',
      ),
      TaskItem(
        id: '5',
        noteId: 'n',
        noteItemId: 'a',
        deletedAt: DateTime(2026, 11, 1),
      ),
    ];
    expect(tasksToSync(tasks, 'n', 'a', true).map((t) => t.id), ['1']);
    expect(tasksToSync(tasks, 'n', 'a', false).map((t) => t.id), ['2']);
  });
}
