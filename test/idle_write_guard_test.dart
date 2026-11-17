import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

import 'support/editor_harness.dart';

/// **BOŞTA YAZMA BEKÇİSİ** (senkron maliyeti korkuluk 2, 2026-11-17).
///
/// Firebase faturasının asıl batırıcısı hata yüzünden sonsuz yazma
/// döngüsüdür (takvimdeki "ping-pong" önlemi boşuna yazılmadı). Editör açık
/// ve kullanıcı hiçbir şey yapmıyorken buluta TEK yazma gitmemeli; tek bir
/// harften sonra da 2 dakika içinde TEK kayıt olmalı. Bu test bir döngüyü
/// yayına çıkmadan yakalar.
class _Repo extends CountingNotesRepository {
  int fieldCalls = 0;

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) {
    fieldCalls++;
    return Future.value();
  }
}

void main() {
  Future<void> idle(WidgetTester tester, Duration d) async {
    for (var t = Duration.zero; t < d; t += const Duration(seconds: 5)) {
      await tester.pump(const Duration(seconds: 5));
    }
  }

  for (final note in [
    Note(id: 't', type: NoteType.text, title: 'Yazı', body: 'gövde metni'),
    Note(
      id: 'l',
      type: NoteType.checklist,
      title: 'Liste',
      items: const [
        NoteItem(id: 'a', text: 'süt'),
        NoteItem(id: 'b', text: 'ekmek', checked: true),
      ],
    ),
  ]) {
    testWidgets('${note.type.name}: 2 dk boşta → bulut yazımı 0', (
      tester,
    ) async {
      final repo = _Repo();
      await pumpEditor(tester, note, repo: repo);
      await tester.pump(const Duration(seconds: 5));
      repo.resetCounts();
      repo.fieldCalls = 0;
      await idle(tester, const Duration(minutes: 2));
      expect(repo.updateNoteCalls, 0, reason: 'boşta updateNote');
      expect(repo.fieldCalls, 0, reason: 'boşta updateFields');
      await endEditor(tester);
    });
  }

  testWidgets('tek harf → 2 dk içinde tek kayıt (döngü yok)', (tester) async {
    final repo = _Repo();
    final note = Note(id: 't', type: NoteType.text, title: 'Yazı', body: 'a');
    await pumpEditor(tester, note, repo: repo);
    await tester.pump(const Duration(seconds: 5));
    repo.resetCounts();
    final body = find.byType(EditableText).last;
    await tester.tap(body);
    await tester.pump();
    await tester.enterText(body, 'ab');
    await idle(tester, const Duration(minutes: 2));
    expect(repo.updateNoteCalls, 1);
    await endEditor(tester);
  });
}
