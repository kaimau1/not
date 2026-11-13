import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/presentation/editor/quick_row_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Hızlı menüyü düzenle levhası (kullanıcı isteği 2026-11-13): dokun = ekle/
/// çıkar, kaydetmeden anında uygulanır; menü boşalsa da geri getirilebilir.
void main() {
  setUp(() => Personalize.prefs.value = const UiPrefs());
  tearDown(() {
    Personalize.prefs.value = const UiPrefs();
    Personalize.draft.value = null;
  });

  testWidgets('eklenebilir düğmeye dokun → menüye girer; menüdekine dokun → '
      'çıkar; varsayılana dön', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: QuickRowEditor()),
      ),
    );
    String id(String k) => UiItem.quickRow(k);
    expect(Personalize.prefs.value.shows(id('italic')), isFalse);
    await tester.tap(find.byKey(const ValueKey('quick-row-edit-italic')));
    await tester.pump();
    expect(Personalize.prefs.value.shows(id('italic')), isTrue);
    expect(Personalize.editing, isFalse, reason: 'kaydet adımı olmamalı');
    await tester.tap(find.byKey(const ValueKey('quick-row-edit-bold')));
    await tester.pump();
    expect(Personalize.prefs.value.shows(id('bold')), isFalse);
    await tester.ensureVisible(
      find.byKey(const ValueKey('quick-row-edit-reset')),
    );
    await tester.tap(find.byKey(const ValueKey('quick-row-edit-reset')));
    await tester.pump();
    expect(Personalize.prefs.value.shows(id('bold')), isTrue);
    expect(Personalize.prefs.value.shows(id('italic')), isFalse);
    expect(tester.takeException(), isNull);
  });
}
