import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/features/settings/presentation/personalize_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-10-16 (4. tur) kullanıcı bulguları: Kişiselleştir'de aç/kapa
/// çalışmıyor ve ayarlardan da yapılabilmeli, ana ekran kişiselleştirilemiyor,
/// balona dokununca odak aşağı yukarı gidiyor, düzenlemede başka şeyler de
/// kapanıyor, + menüsünün "Tümü"sü çok yukarı uzuyor.
void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);

  Future<void> pumpPersonalize(WidgetTester tester) async {
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
          builder: (context, child) => CustomizeModeHost(child: child!),
          home: const PersonalizeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Kişiselleştir ekranı', () {
    testWidgets('eklenti anahtarı EKRANDA da kapanıp açılır', (tester) async {
      // KÖK NEDEN: bölümler `const` idi; kayıt değişse de yeniden
      // kurulmuyor, anahtar yerinden oynamıyordu.
      await pumpPersonalize(tester);
      Switch aiSwitch() => tester.widget<Switch>(
        find.descendant(
          of: find.byKey(const ValueKey('module-ai')),
          matching: find.byType(Switch),
        ),
      );
      expect(aiSwitch().value, isTrue);
      await tester.tap(find.byKey(const ValueKey('module-ai')));
      await tester.pumpAndSettle();
      expect(aiSwitch().value, isFalse);
      expect(Personalize.prefs.value.shows(UiItem.barAi), isFalse);
      await tester.tap(find.byKey(const ValueKey('module-ai')));
      await tester.pumpAndSettle();
      expect(aiSwitch().value, isTrue);
      expect(Personalize.prefs.value.shows(UiItem.barAi), isTrue);
    });

    testWidgets('çipe iki kez dokunmak geri açar (bayat değer yazılmaz)', (
      tester,
    ) async {
      await pumpPersonalize(tester);
      final chip = find.byKey(ValueKey('ui-chip-${UiItem.barFormat}'));
      await tester.scrollUntilVisible(
        chip,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(Personalize.prefs.value.shows(UiItem.barFormat), isFalse);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(
        Personalize.prefs.value.shows(UiItem.barFormat),
        isTrue,
        reason: 'eskiden ikinci dokunuş da "gizle" yazıyordu',
      );
      // Başka hiçbir öğe kendiliğinden kapanmadı.
      expect(Personalize.prefs.value.hidden, isEmpty);
    });

    testWidgets('ana ekran öğeleri de listede ve kapanır', (tester) async {
      await pumpPersonalize(tester);
      final chip = find.byKey(ValueKey('ui-chip-${UiItem.homeAi}'));
      await tester.scrollUntilVisible(
        chip,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(Personalize.prefs.value.shows(UiItem.homeAi), isFalse);
    });
  });

  testWidgets('ayarlardaki eklenti anahtarları aynı kayda yazar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: const Scaffold(
          body: SingleChildScrollView(child: PersonalizeModuleSwitches()),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('module-voice')));
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.moduleState(UiModule.voice), isFalse);
    expect(
      Personalize.prefs.value.moduleState(UiModule.ai),
      isTrue,
      reason: 'Ses kapatılınca Yapay zekâ "kısmen açık"a düşmez',
    );
  });

  test('eklentiler ayrık: bir öğe tek eklentide', () {
    final seen = <String, String>{};
    for (final module in UiModule.all) {
      for (final id in module.items) {
        expect(
          seen[id],
          isNull,
          reason: '$id hem ${seen[id]} hem ${module.id} eklentisinde',
        );
        seen[id] = module.id;
      }
    }
  });

  testWidgets('ana ekran öğesi düzenleme modunda dokunuşla gizlenir', (
    tester,
  ) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        builder: (context, child) => CustomizeModeHost(child: child!),
        home: Scaffold(
          body: Center(
            child: Customizable(
              id: UiItem.homeDictation,
              child: IconButton(
                key: const ValueKey('dictation'),
                onPressed: () => tapped++,
                icon: const Icon(Icons.mic),
              ),
            ),
          ),
        ),
      ),
    );
    Personalize.startEditing();
    await tester.pump();
    // Dokunuş çerçevenin kendisine gider (düğmenin işi kapalı).
    await tester.tap(
      find.byKey(const ValueKey('dictation')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(tapped, 0);
    await tester.tap(find.byKey(const ValueKey('customize-save')));
    await tester.pumpAndSettle();
    expect(Personalize.prefs.value.shows(UiItem.homeDictation), isFalse);
    expect(find.byKey(const ValueKey('dictation')), findsNothing);
  });

  group('balon odağı', () {
    const region = Rect.fromLTRB(0, 100, 400, 500);

    test('balon rahatça görünüyorsa HİÇ kaydırılmaz', () {
      expect(BubbleReveal.revealDelta(300, region, editing: true), 0);
      expect(BubbleReveal.revealDelta(300, region, editing: false), 0);
    });

    test('kartın/klavyenin arkasındaysa ortaya getirilir', () {
      // Alt kenara 20 px: yazarken payın (48) içinde → ortalanır.
      expect(BubbleReveal.revealDelta(480, region, editing: true), 180);
      // Görünür alanın üstünde (ekran dışı) → aşağı.
      expect(BubbleReveal.revealDelta(40, region, editing: true), -260);
    });

    testWidgets('görüntüleyici klavye açıkken boy DEĞİŞTİRMEZ', (tester) async {
      // KÖK NEDEN: pdfrx boy her değiştiğinde sayfanın başına sıçrıyordu.
      var height = 600.0;
      var keyboard = 0.0;
      late StateSetter set;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            set = setState;
            return MediaQuery(
              data: MediaQueryData(
                size: const Size(400, 800),
                viewInsets: EdgeInsets.only(bottom: keyboard),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 400,
                  height: height,
                  child: const StableViewport(
                    child: SizedBox.expand(key: ValueKey('viewer')),
                  ),
                ),
              ),
            );
          },
        ),
      );
      Size viewer() => tester.getSize(find.byKey(const ValueKey('viewer')));
      expect(viewer().height, 600);

      // Yazma kipi: klavye açıldı, bölme kısaldı → görüntüleyici aynı boyda.
      set(() {
        keyboard = 300;
        height = 380;
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(viewer().height, 600);

      // Klavye kapandı, bölme eski boyuna döndü → hiç değişmedi.
      set(() {
        keyboard = 0;
        height = 600;
      });
      await tester.pump(const Duration(seconds: 1));
      expect(viewer().height, 600);

      // Klavyesiz KALICI değişim (ör. not alanı büyüdü) yerleşince benimsenir.
      set(() => height = 450);
      await tester.pump();
      expect(viewer().height, 600, reason: 'ara karelerde beklenir');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(viewer().height, 450);
    });
  });
}
