import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/presentation/color_picker_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/tag_tap.dart';
import 'package:notlar/features/notes/presentation/note_theme_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-10-29: YouTube bağlantısına dokununca "Nota göm /
/// Bağlantıya git" seçimi; görünüm levhasında düz renkler + palet.
void main() {
  Widget host(void Function(BuildContext) onPressed) => MaterialApp(
    locale: const Locale('tr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => onPressed(context),
          child: const Text('aç'),
        ),
      ),
    ),
  );

  testWidgets('YouTube bağlantısı: "Nota göm" gömme işlevini çağırır', (
    tester,
  ) async {
    String? embedded;
    await tester.pumpWidget(
      host(
        (context) => handleLinkTap(
          context,
          'https://youtu.be/oTLnQRxAgFg?t=51',
          editing: false,
          onEmbedVideo: (url) => embedded = url,
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    expect(find.text('Bağlantıya git'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('link-embed-video')));
    await tester.pumpAndSettle();
    expect(embedded, 'https://youtu.be/oTLnQRxAgFg?t=51');
  });

  testWidgets('düz renk kartı rengi uygular, "Sade" rengi kaldırır', (
    tester,
  ) async {
    final picks = <NoteColorPick>[];
    final themes = <String>[];
    await tester.pumpWidget(
      host(
        (context) => showNoteThemeSheet(
          context,
          current: '',
          onTheme: themes.add,
          onColor: picks.add,
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('flat-color-blue')));
    await tester.pump();
    expect(picks.single.color, NoteColor.blue);
    await tester.tap(find.byKey(const ValueKey('theme-tile-')));
    await tester.pump();
    expect(picks.last.color, NoteColor.none);
    expect(themes.last, '');
  });
}
