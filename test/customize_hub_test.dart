import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/settings/presentation/customize_hub.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P63 PB2 (plan_tasarim_B §1.2 `CustomizeHub`): yüzey karar tablosu, yüzey
/// çipi panoyu değiştirir, ana ekran anahtarları var olan tercihleri sürer,
/// hızlı satır ve Ekle sırası kayda yazılır.
void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);

  test(
    'surfaceFor: not → alt çubuk, klavyeyle hızlı satır, kök → ana ekran',
    () {
      expect(
        surfaceFor('/note/abc', keyboard: false),
        CustomizeSurface.bottomBar,
      );
      expect(
        surfaceFor('/note/abc', keyboard: true),
        CustomizeSurface.quickRow,
      );
      expect(surfaceFor('/', keyboard: false), CustomizeSurface.home);
      expect(surfaceFor('/calendar', keyboard: true), CustomizeSurface.home);
    },
  );

  test('reorderShown: gizliler yerinde kalır', () {
    expect(reorderShown(['a', 'b', 'c', 'd'], ['a', 'c', 'd'], 2, 0), [
      'd',
      'b',
      'a',
      'c',
    ]);
  });

  Future<SharedPreferences> pumpHub(
    WidgetTester tester, {
    CustomizeSurface initial = CustomizeSurface.bottomBar,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(body: CustomizeHub(initial: initial)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  testWidgets('yüzey çipi değişince pano değişir', (tester) async {
    await pumpHub(tester);
    expect(find.byKey(const ValueKey('personalize-bar-left')), findsOneWidget);
    final chip = find.byKey(const ValueKey('customize-surface-quickRow'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('personalize-bar-left')), findsNothing);
    expect(find.byKey(const ValueKey('quick-row-edit-bold')), findsOneWidget);
  });

  testWidgets('ana ekran: takvim şeridi ve hızlı yakalama var olan tercih', (
    tester,
  ) async {
    await pumpHub(tester, initial: CustomizeSurface.home);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CustomizeHub)),
    );
    final strip = container.read(homeCalendarStripProvider);
    await tester.tap(find.byKey(const ValueKey('home-calendar-strip')));
    await tester.pumpAndSettle();
    expect(container.read(homeCalendarStripProvider), !strip);
    final capture = container.read(quickCaptureRowProvider);
    await tester.tap(find.byKey(const ValueKey('home-quick-capture')));
    await tester.pumpAndSettle();
    expect(container.read(quickCaptureRowProvider), !capture);
    // Ana ekran öğesi karosu gizler.
    await tester.tap(find.byKey(ValueKey('ui-chip-${UiItem.homeAi}')));
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.shows(UiItem.homeAi), isFalse);
  });

  testWidgets('Ekle levhası: gizle + sıfırla', (tester) async {
    await pumpHub(tester, initial: CustomizeSurface.attach);
    final first = find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith('attach-board-') &&
          !(w.key! as ValueKey<String>).value.contains('preview') &&
          !(w.key! as ValueKey<String>).value.contains('drag') &&
          !(w.key! as ValueKey<String>).value.endsWith('reset'),
    );
    final key = (tester.widget(first.first).key! as ValueKey<String>).value
        .substring('attach-board-'.length);
    await tester.tap(first.first);
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.shows(UiItem.attach(key)), isFalse);
    await tester.tap(find.byKey(const ValueKey('attach-board-reset')));
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.shows(UiItem.attach(key)), isTrue);
  });
}
