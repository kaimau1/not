import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';

import 'support/editor_harness.dart';

/// P20 adım 5 (M5): biçim kipi notifier'a taşındı — geri tuşu yine önce
/// paneli kapatır (PopScope kipi dar dinliyor), not açık kalır.
void main() {
  const text = Note(id: 'n', type: NoteType.text, title: 'Kısa', body: 'yazı');

  testWidgets('biçim paneli açıkken geri → panel kapanır, not kalır', (
    tester,
  ) async {
    await pumpEditor(tester, text);
    await tester.tap(find.byTooltip('Biçim'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FormatBar), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(FormatBar), findsNothing);
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(find.byTooltip('Biçim'), findsOneWidget, reason: 'alt çubuk döndü');
    await endEditor(tester);
  });
}
