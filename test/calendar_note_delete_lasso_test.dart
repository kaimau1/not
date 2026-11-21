import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/calendar/presentation/google_calendar_ui.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/ink_gestures.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-11-21: takvimdeki bağlı not kartında ÇÖP düğmesi
/// (kilitli notta yok); ek göm dairesinde en yakın UYGUN yazı alanı seçilir
/// (büyük halkada başlık alanı seçimi çalmasın).
void main() {
  Widget host(Widget child) => ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('bağlı not kartında sil; kilitli notta yok', (tester) async {
    const open = Note(id: 'a', type: NoteType.text, title: 'Deneme');
    const locked = Note(
      id: 'b',
      type: NoteType.text,
      title: 'Gizli',
      locked: true,
    );
    final deleted = <String>[];
    await tester.pumpWidget(
      host(
        LinkedNotesList(
          noteIds: const ['a', 'b'],
          preloadedNotes: const [open, locked],
          onDelete: (n) => deleted.add(n.id),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('linked-note-delete-a')), findsOneWidget);
    expect(find.byKey(const ValueKey('linked-note-delete-b')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('linked-note-delete-a')));
    expect(deleted, ['a']);
  });

  testWidgets('daire hedefi: payı geniş halkada ilk alan değil, noktayı '
      'içeren / kabul edilen alan', (tester) async {
    final title = TextEditingController(text: 'Başlık');
    final body = TextEditingController(text: 'Espanso kısaltma yap');
    final rootKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            key: rootKey,
            children: [
              TextField(controller: title),
              const SizedBox(height: 40),
              TextField(controller: body),
            ],
          ),
        ),
      ),
    );
    final center = tester.getCenter(find.byType(TextField).last);
    final root = rootKey.currentContext!;
    // Pay 200: iki alan da aday — noktayı içeren gövde seçilmeli.
    final hit = editableTextAt(root, center, slop: 200);
    expect(hit?.widget.controller, same(body));
    // İki alanın ARASINDA: kabul edilmeyen başlık atlanır.
    final gap =
        tester.getBottomLeft(find.byType(TextField).first) +
        const Offset(20, 10);
    final only = editableTextAt(
      root,
      gap,
      slop: 200,
      accept: (s) => identical(s.widget.controller, body),
    );
    expect(only?.widget.controller, same(body));
    title.dispose();
    body.dispose();
  });
}
