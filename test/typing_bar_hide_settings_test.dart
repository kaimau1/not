import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/settings/presentation/typing_bar_settings.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

/// **YAZARKEN ALT PANEL GİZLEME AYARLANABİLİR** (F60.S7, kullanıcı isteği
/// 2026-11-11: "kapatılabilsin; ne zaman kapanacak, kaç sn sonra açılacak —
/// 0,1 sn adımlı kaydırıcı"). Varsayılan = önceki davranış: art arda 3
/// değişiklikte hemen gizlenir, 1,1 sn duraklamada geri gelir.
const _note = Note(id: 'n', type: NoteType.text, title: 'Not', body: 'yazı');

bool _hidden(WidgetTester tester) =>
    tester.widget<TypingBarHide>(find.byType(TypingBarHide)).hidden.value;

/// Editörü kurar, gövdeye odaklanır, klavyeyi açıp OTURTUR.
Future<ProviderContainer> _openWithKeyboard(
  WidgetTester tester, {
  bool? enabled,
  int? hideTenths,
  int? showTenths,
}) async {
  final container = await pumpEditor(tester, _note);
  if (enabled != null) {
    container.read(hideBarWhileTypingProvider.notifier).set(enabled);
  }
  if (hideTenths != null) {
    container.read(typingBarHideDelayProvider.notifier).set(hideTenths);
  }
  if (showTenths != null) {
    container.read(typingBarShowDelayProvider.notifier).set(showTenths);
  }
  await tester.tap(find.text('yazı').last);
  await tester.pump(const Duration(milliseconds: 100));
  tester.view.viewInsets = const FakeViewPadding(bottom: 300);
  tester.view.padding = const FakeViewPadding(top: 30);
  await tester.pump(const Duration(milliseconds: 16));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

var _typed = 0;

/// Odaktaki alana [n] karakter, aralarında [gap] ms.
Future<void> _type(WidgetTester tester, int n, {int gap = 100}) async {
  for (var i = 0; i < n; i++) {
    _typed++;
    tester.testTextInput.enterText('yazı${'a' * _typed}');
    await tester.pump(Duration(milliseconds: gap));
  }
}

void main() {
  setUp(() => _typed = 0);

  testWidgets('varsayılan (bugünkü davranış): 3. değişiklikte hemen gizlenir, '
      '1,1 sn duraklamada geri gelir', (tester) async {
    final container = await _openWithKeyboard(tester);
    expect(container.read(typingBarHideDelayProvider), 0);
    expect(container.read(typingBarShowDelayProvider), 11);
    await _type(tester, 2);
    expect(_hidden(tester), isFalse);
    await _type(tester, 1, gap: 10);
    expect(_hidden(tester), isTrue);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_hidden(tester), isTrue, reason: '1,1 sn dolmadı');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_hidden(tester), isFalse);
    await endEditor(tester);
  });

  testWidgets('kapalıyken yazarken panel gizlenmez', (tester) async {
    await _openWithKeyboard(tester, enabled: false);
    await _type(tester, 12);
    expect(_hidden(tester), isFalse);
    // Çubuk tam boyunda ve yerinde.
    expect(tester.getSize(find.byType(BottomAppBar)).height, 50);
    await endEditor(tester);
  });

  testWidgets('gizlenme gecikmesi: yazma o kadar sürmeden gizlenmez; '
      'arada duraklarsa hiç gizlenmez', (tester) async {
    await _openWithKeyboard(tester, hideTenths: 10);
    // 3. değişiklikten itibaren 1,0 sn: 0,9 sn boyunca hâlâ görünür.
    await _type(tester, 3, gap: 10);
    expect(_hidden(tester), isFalse);
    await _type(tester, 9);
    expect(_hidden(tester), isFalse, reason: '0,9 sn — henüz değil');
    await _type(tester, 2);
    expect(_hidden(tester), isTrue, reason: '1,0 sn kesintisiz yazıldı');
    // Geri geldikten sonra: kısa bir yazıp bırakma çubuğu götürmez.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(_hidden(tester), isFalse);
    await _type(tester, 4);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_hidden(tester), isFalse, reason: 'gecikme dolmadan durdu');
    await tester.pump(const Duration(seconds: 2));
    expect(_hidden(tester), isFalse);
    await endEditor(tester);
  });

  testWidgets('yeniden görünme gecikmesi: duraklama o kadar sürmeden '
      'geri gelmez', (tester) async {
    await _openWithKeyboard(tester, showTenths: 30);
    await _type(tester, 3, gap: 10);
    expect(_hidden(tester), isTrue);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(_hidden(tester), isTrue, reason: '3,0 sn dolmadı');
    await tester.pump(const Duration(milliseconds: 150));
    expect(_hidden(tester), isFalse);
    await endEditor(tester);
  });

  testWidgets('yeniden görünme 0 sn: tuş bırakılır bırakılmaz geri gelir', (
    tester,
  ) async {
    await _openWithKeyboard(tester, showTenths: 0);
    await _type(tester, 3, gap: 10);
    await tester.pump(const Duration(milliseconds: 20));
    expect(_hidden(tester), isFalse);
    await endEditor(tester);
  });

  group('Ayarlar', () {
    Future<ProviderContainer> pump(WidgetTester tester, Locale locale) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: TypingBarSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      return container;
    }

    Slider slider(WidgetTester tester, String key) =>
        tester.widget<Slider>(find.byKey(ValueKey(key)));

    testWidgets('anahtar + iki kaydırıcı: 0–5 sn, 0,1 adım, "1,1 sn" etiketi', (
      tester,
    ) async {
      final container = await pump(tester, const Locale('tr'));
      expect(find.text('Gizlenme gecikmesi'), findsOneWidget);
      expect(find.text('Yeniden görünme gecikmesi'), findsOneWidget);
      expect(find.text('0,0 sn'), findsOneWidget);
      expect(find.text('1,1 sn'), findsOneWidget);
      for (final key in ['typing-bar-hide-delay', 'typing-bar-show-delay']) {
        final s = slider(tester, key);
        expect((s.min, s.max, s.divisions), (0.0, 5.0, 50));
      }
      // Sürükle → 0,1 adımına oturur, etiket güncellenir, tercih yazılır.
      final show = slider(tester, 'typing-bar-show-delay');
      show.onChanged!(2.34);
      await tester.pump();
      expect(find.text('2,3 sn'), findsOneWidget);
      show.onChangeEnd!(2.34);
      await tester.pump();
      expect(container.read(typingBarShowDelayProvider), 23);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getInt('typing_bar_show_delay_ds'),
        23,
      );
      final hide = slider(tester, 'typing-bar-hide-delay');
      hide.onChanged!(0.5);
      hide.onChangeEnd!(0.5);
      await tester.pump();
      expect(container.read(typingBarHideDelayProvider), 5);
      expect(find.text('0,5 sn'), findsOneWidget);
    });

    testWidgets('anahtar kapalıyken kaydırıcılar pasif', (tester) async {
      final container = await pump(tester, const Locale('tr'));
      await tester.tap(find.byKey(const ValueKey('hide-bar-typing-switch')));
      await tester.pump();
      expect(container.read(hideBarWhileTypingProvider), isFalse);
      expect(slider(tester, 'typing-bar-hide-delay').onChanged, isNull);
      expect(slider(tester, 'typing-bar-show-delay').onChanged, isNull);
    });

    testWidgets('İngilizce: "1.1 s"', (tester) async {
      await pump(tester, const Locale('en'));
      expect(find.text('1.1 s'), findsOneWidget);
      expect(find.text('Hide delay'), findsOneWidget);
    });
  });

  test('saklanan değer 0–50 aralığına çekilir', () async {
    SharedPreferences.setMockInitialValues({
      'typing_bar_hide_delay_ds': 999,
      'typing_bar_show_delay_ds': -4,
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(typingBarHideDelayProvider), 50);
    expect(container.read(typingBarShowDelayProvider), 0);
  });
}
