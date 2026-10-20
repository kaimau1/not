import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/archive_insights_sheet.dart';

/// Arşiv özeti (geliştirme raporu D5): cihazdaki sayılar ve dokunulmamışlar.
void main() {
  test('klasör dağılımı çoktan aza, bir yıldır dokunulmamışlar en eskiden', () {
    final now = DateTime(2026, 10, 20);
    Note n(String id, {String? folder, required DateTime updated}) => Note(
      id: id,
      type: NoteType.text,
      folderId: folder,
      updatedAt: updated,
      archivedAt: updated,
    );
    final stats = archiveStats([
      n('a', folder: 'f1', updated: DateTime(2026, 9)),
      n('b', folder: 'f1', updated: DateTime(2024, 1)),
      n('c', updated: DateTime(2025, 3)),
      n('d', folder: 'f2', updated: DateTime(2026, 10)),
    ], now: now);
    expect(stats.count, 4);
    expect(stats.byFolder.first, (folderId: 'f1', count: 2));
    expect([for (final s in stats.stale) s.id], ['b', 'c']);
  });
}
