import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/settings/presentation/personalize_bar_list.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P20 M8: not üst çubuğunun sırası alt çubuğun modeliyle (`topOrder`).
void main() {
  tearDown(Personalize.debugReset);

  test('varsayılan sıra = bugünkü ekran sırası', () {
    expect(UiItem.topDefault, [
      UiItem.topHome,
      UiItem.topSync,
      UiItem.topUndo,
      UiItem.topPin,
      UiItem.topFullscreen,
    ]);
    // Eski kayıt (topOrder yok) bugünkü sırayı verir.
    final old = UiPrefs.fromJson(const {'hidden': <String>[]});
    expect(old.topOrder, isEmpty);
    expect(UiPrefs.orderOf(UiItem.topDefault, old.topOrder), UiItem.topDefault);
  });

  test('kayıtlı sıra korunur, bilinmeyen kimlik yok sayılır', () {
    expect(
      UiPrefs.orderOf(UiItem.topDefault, const [
        'editor.top.yok',
        UiItem.topPin,
        UiItem.topHome,
      ]),
      [
        UiItem.topPin,
        UiItem.topHome,
        UiItem.topSync,
        UiItem.topUndo,
        UiItem.topFullscreen,
      ],
    );
  });

  test('JSON gidiş-dönüş; boşken yazılmaz', () {
    const p = UiPrefs(topOrder: [UiItem.topPin, UiItem.topSync]);
    final back = UiPrefs.fromJson(p.toJson());
    expect(back, p);
    expect(back.hashCode, p.hashCode);
    expect(const UiPrefs().toJson().containsKey('topOrder'), isFalse);
    expect(p == const UiPrefs(), isFalse);
  });

  testWidgets('Ayarlar: üst çubuk grubu, ok yok, anahtar gizler', (
    tester,
  ) async {
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
    final group = find.byKey(const ValueKey('personalize-bar-top'));
    for (final id in UiItem.topDefault) {
      expect(
        find.descendant(
          of: group,
          matching: find.byKey(ValueKey('bar-switch-$id')),
        ),
        findsOneWidget,
      );
      expect(find.byKey(ValueKey('bar-move-$id')), findsNothing);
    }
    final pin = find.byKey(const ValueKey('bar-switch-${UiItem.topPin}'));
    await tester.ensureVisible(pin);
    await tester.tap(pin);
    await tester.pump();
    expect(Personalize.prefs.value.shows(UiItem.topPin), isFalse);
    expect(tester.takeException(), isNull);
  });
}
