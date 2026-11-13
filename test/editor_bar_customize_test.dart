import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/settings/presentation/personalize_bar_list.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart';

/// Kullanıcı isteği 2026-11-13: "alt paneldeki tüm butonlar
/// değiştirilebilsin, kişi istediğini koyabilsin, istediğini çıkarabilsin;
/// ayarlarda seçenekler geniş olsun".
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));
  tearDown(Personalize.debugReset);

  group('sıra birleştirme', () {
    test('boş kayıt = varsayılan sıra', () {
      expect(UiPrefs.orderOf(const ['a', 'b', 'c'], const []), ['a', 'b', 'c']);
    });

    test('kayıtlı sıra önde, yeni düğme varsayılan yerine göre arkada', () {
      expect(UiPrefs.orderOf(const ['a', 'b', 'c', 'd'], const ['c', 'a']), [
        'c',
        'a',
        'b',
        'd',
      ]);
    });

    test('bilinmeyen/yinelenen kimlik atlanır', () {
      expect(UiPrefs.orderOf(const ['a', 'b'], const ['x', 'b', 'b', 'a']), [
        'b',
        'a',
      ]);
    });

    test('kayıt/okuma sırayı korur; eski kayıt (sırasız) okunur', () {
      const p = UiPrefs(
        barOrder: [UiItem.barSearch, UiItem.barFormat],
        aiOrder: [UiItem.barDictation],
      );
      final back = UiPrefs.fromJson(p.toJson());
      expect(back, p);
      expect(UiPrefs.fromJson({'hidden': <String>[]}).barOrder, isEmpty);
    });

    test('eklenebilen düğmeler varsayılan gizli, açılınca görünür', () {
      const p = UiPrefs();
      for (final id in [
        UiItem.barUndo,
        UiItem.barRedo,
        UiItem.barReminder,
        UiItem.barPhoto,
        UiItem.barCamera,
        UiItem.barScan,
        UiItem.barColor,
        UiItem.barShare,
      ]) {
        expect(p.shows(id), isFalse, reason: id);
        expect(p.withVisible(id, true).shows(id), isTrue, reason: id);
      }
      expect(p.shows(UiItem.barFormat), isTrue);
    });
  });

  group('editör alt çubuğu', () {
    const note = Note(id: 'n', type: NoteType.text, title: 'T', body: 'yazı');

    double xOf(WidgetTester tester, String tooltip) =>
        tester.getCenter(find.byTooltip(tooltip).first).dx;

    testWidgets('kullanıcı sırası çubuğa yansır (Ara, Biçim\'den önce)', (
      tester,
    ) async {
      await pumpEditor(tester, note);
      expect(
        xOf(tester, l10n.formatTitle),
        lessThan(xOf(tester, l10n.noteSearchTitle)),
      );
      Personalize.update(
        (p) => p.copyWith(barOrder: [UiItem.barSearch, UiItem.barFormat]),
      );
      await tester.pump();
      expect(
        xOf(tester, l10n.noteSearchTitle),
        lessThan(xOf(tester, l10n.formatTitle)),
      );
      await endEditor(tester);
    });

    testWidgets('eklenen düğme çubukta görünür, çıkarılan kaybolur', (
      tester,
    ) async {
      await pumpEditor(tester, note);
      expect(find.byTooltip(l10n.quickRowReminder), findsNothing);
      Personalize.update(
        (p) => p
            .withVisible(UiItem.barReminder, true)
            .withVisible(UiItem.barFormat, false),
      );
      await tester.pump();
      expect(find.byTooltip(l10n.quickRowReminder), findsOneWidget);
      expect(find.byTooltip(l10n.formatTitle), findsNothing);
      await endEditor(tester);
    });
  });

  group('Ayarlar listesi', () {
    Future<void> pumpList(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: SingleChildScrollView(child: PersonalizeBarList()),
          ),
        ),
      );
    }

    testWidgets('her düğme listede; anahtar ekler/çıkarır', (tester) async {
      await pumpList(tester);
      for (final id in [...UiItem.barLeftDefault, ...UiItem.barRightDefault]) {
        expect(find.byKey(ValueKey('bar-switch-$id')), findsOneWidget);
      }
      await tester.tap(
        find.byKey(const ValueKey('bar-switch-editor.bar.undo')),
      );
      await tester.pump();
      expect(Personalize.prefs.value.shows(UiItem.barUndo), isTrue);
      await tester.tap(
        find.byKey(const ValueKey('bar-switch-editor.bar.format')),
      );
      await tester.pump();
      expect(Personalize.prefs.value.shows(UiItem.barFormat), isFalse);
    });

    testWidgets('varsayılana dön: sıra ve görünürlük sıfırlanır', (
      tester,
    ) async {
      Personalize.update(
        (p) => p
            .copyWith(barOrder: [UiItem.barSearch])
            .withVisible(UiItem.barUndo, true)
            .withVisible(UiItem.barFormat, false),
      );
      await pumpList(tester);
      await tester.ensureVisible(
        find.byKey(const ValueKey('personalize-bar-reset')),
      );
      await tester.tap(find.byKey(const ValueKey('personalize-bar-reset')));
      await tester.pump();
      final p = Personalize.prefs.value;
      expect(p.barOrder, isEmpty);
      expect(p.shows(UiItem.barUndo), isFalse);
      expect(p.shows(UiItem.barFormat), isTrue);
    });
  });
}
