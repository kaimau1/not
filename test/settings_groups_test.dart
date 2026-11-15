import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/sheet_header.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P62 PA1 (plan_tasarim_A §2.2): ayar alanları başlıklı GRUP kartlarına
/// bölünür; geniş ekranda seçili kategori `primary` rolünde.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Future<void> _pump(WidgetTester tester, Size size, {String? area}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_NoAuth()),
        currentUidProvider.overrideWithValue(null),
        isAnonymousProvider.overrideWithValue(true),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
      ],
      child: MaterialApp(
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(initialArea: area),
      ),
    ),
  );
  // Satırlar karelere yayılarak kuruluyor: hepsi gelsin.
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

List<String> _labels(WidgetTester tester, String area) => [
  for (final w in tester.widgetList<SectionLabel>(
    find.descendant(
      // Yalnız grup etiketleri (tema seçicinin kendi aile başlıkları değil).
      of: find.byWidgetPredicate(
        (w) => '${w.key}'.contains('settings-group-label-'),
      ),
      matching: find.byType(SectionLabel),
    ),
  ))
    w.text,
];

void main() {
  testWidgets('Yazma alanı: Kalem · Yazım · Ekran grupları sırayla', (
    tester,
  ) async {
    await _pump(tester, const Size(412, 915), area: 'writing');
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(_labels(tester, 'writing'), [
      l10n.settingsPenSection,
      l10n.settingsSpellSection,
      l10n.settingsScreenSection,
    ]);
  });

  testWidgets('AI alanı: "Kendiliğinden" grubu', (tester) async {
    await _pump(tester, const Size(412, 915), area: 'ai');
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    expect(_labels(tester, 'ai'), [l10n.settingsGroupAutomatic]);
  });

  testWidgets('Görünüm alanı: grup sırası', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await _pump(tester, const Size(412, 2400), area: 'appearance');
    expect(_labels(tester, 'appearance'), [
      l10n.settingsThemeHeader,
      l10n.settingsGroupText,
      l10n.settingsCardsHeader,
    ]);
  });

  testWidgets('Ses alanı: grup sırası, "Seslendirme" bir kez', (tester) async {
    final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
    await _pump(tester, const Size(412, 2400), area: 'sound');
    expect(_labels(tester, 'sound'), [
      l10n.ttsSectionTitle,
      l10n.settingsGroupDictation,
    ]);
    // "Seslendirme" yalnız grup etiketinde (bölümün içinde ikinci kez yok).
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('settings-area-sound')),
        matching: find.text(l10n.ttsSectionTitle),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Geniş ekran: seçili kategori primaryContainer, alan değişir', (
    tester,
  ) async {
    await _pump(tester, const Size(1280, 800));
    final tile = find.byKey(const ValueKey('settings-cat-sound'));
    await tester.ensureVisible(tile);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(tile);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('settings-area-sound')), findsOneWidget);
    final scheme = Theme.of(tester.element(tile)).colorScheme;
    final box = tester.widget<AnimatedContainer>(
      find.ancestor(of: tile, matching: find.byType(AnimatedContainer)).first,
    );
    expect((box.decoration as BoxDecoration?)?.color, scheme.primaryContainer);
  });
}
