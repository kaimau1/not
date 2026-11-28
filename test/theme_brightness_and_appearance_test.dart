import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/dashboard_wallpapers.dart';
import 'package:notlar/app/theme/note_themes.dart';
import 'package:notlar/core/utils/note_fonts.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/app_background_layers.dart';
import 'package:notlar/features/settings/presentation/appearance_studio_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(disableFontRuntimeFetching);

  test(
    'tüm 20 tema ailesi açık, koyu ve otomatik kipler arasında bağımsız geçer',
    () async {
      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
      );
      addTearDown(container.dispose);

      final familyNotifier = container.read(themeFamilyProvider.notifier);
      final modeNotifier = container.read(themeBrightnessModeProvider.notifier);

      for (final family in ThemeFamily.values) {
        familyNotifier.set(family);
        expect(container.read(themeFamilyProvider), family);

        modeNotifier.set(AppBrightnessMode.light);
        expect(container.read(themeFamilyProvider), family);
        expect(
          container.read(themeBrightnessModeProvider),
          AppBrightnessMode.light,
        );
        expect(container.read(effectiveThemeModeProvider), ThemeMode.light);

        modeNotifier.set(AppBrightnessMode.dark);
        expect(container.read(themeFamilyProvider), family);
        expect(
          container.read(themeBrightnessModeProvider),
          AppBrightnessMode.dark,
        );
        expect(container.read(effectiveThemeModeProvider), ThemeMode.dark);

        modeNotifier.set(AppBrightnessMode.system);
        expect(container.read(themeFamilyProvider), family);
        expect(
          container.read(themeBrightnessModeProvider),
          AppBrightnessMode.system,
        );
      }

      // Döngüleyici: Light -> Dark -> System -> Light
      modeNotifier.set(AppBrightnessMode.light);
      modeNotifier.cycle();
      expect(
        container.read(themeBrightnessModeProvider),
        AppBrightnessMode.dark,
      );
      modeNotifier.cycle();
      expect(
        container.read(themeBrightnessModeProvider),
        AppBrightnessMode.system,
      );
      modeNotifier.cycle();
      expect(
        container.read(themeBrightnessModeProvider),
        AppBrightnessMode.light,
      );
    },
  );

  test('ana ekran zemini "Notlara da uygula" açıkken özel zemini olmayan notlara iner', () async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(dashboardBackgroundProvider.notifier);
    notifier.setNoteTheme(NoteThemes.aurora);
    notifier.setApplyToNotes(true);
    final bg = container.read(dashboardBackgroundProvider);

    const plainNote = Note(id: 'n1', type: NoteType.text);
    const coloredNote = Note(
      id: 'n2',
      type: NoteType.text,
      color: NoteColor.amber,
    );
    const optedOutNote = Note(
      id: 'n3',
      type: NoteType.text,
      theme: Note.plainThemeSentinel,
    );

    expect(noteInheritsHomeBackground(plainNote, bg), isTrue);
    expect(noteInheritsHomeBackground(coloredNote, bg), isFalse);
    expect(noteInheritsHomeBackground(optedOutNote, bg), isFalse);

    expect(effectiveNoteWithHomeBg(plainNote, bg).theme, NoteThemes.aurora);
    expect(effectiveNoteWithHomeBg(coloredNote, bg).color, NoteColor.amber);
    expect(
      effectiveNoteWithHomeBg(optedOutNote, bg).theme,
      Note.plainThemeSentinel,
    );

    // Duvar kâğıdı + applyToNotes = false iken devralınmaz.
    notifier
      ..setPreset(DashboardWallpapers.sakuraBreeze)
      ..setApplyToNotes(false);
    expect(
      noteInheritsHomeBackground(
        plainNote,
        container.read(dashboardBackgroundProvider),
      ),
      isFalse,
    );
  });

  testWidgets('Görünüm Stüdyosu tüm bağlamlarda taşmadan 3 sekmeyi açar', (
    tester,
  ) async {
    Future<void> pumpStudio(
      Size size,
      AppearanceContext mode, {
      NoteAppearanceBridge? bridge,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          proFeatureProvider(ProFeature.extraAppearance)
              .overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            key: ValueKey(mode),
            theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showAppearanceStudio(
                    ctx,
                    contextMode: mode,
                    noteBridge: bridge,
                  ),
                  child: const Text('AC'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('AC'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('appearance-tab-theme')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('appearance-tab-background')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('appearance-tab-layout')),
        findsOneWidget,
      );
      if (size.width <= 360 && mode != AppearanceContext.note) {
        // 360 dp dar ekranda "Otomatik | Açık | Koyu" tek satırda kalmalı.
        final autoFinder = find.text('Otomatik').last;
        final autoLabel = tester.widget<Text>(autoFinder);
        expect(autoLabel.maxLines, 1);
        expect(autoLabel.softWrap, isFalse);
        expect(tester.getSize(autoFinder).height, lessThanOrEqualTo(24));
      }

      await tester.tap(find.byKey(const ValueKey('appearance-tab-background')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('appearance-tab-layout')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await pumpStudio(const Size(360, 800), AppearanceContext.home);

    await pumpStudio(const Size(1280, 800), AppearanceContext.calendar);
    await pumpStudio(
      const Size(360, 800),
      AppearanceContext.note,
      bridge: NoteAppearanceBridge(
        readNote: () => const Note(id: 'n1', type: NoteType.text),
        onTheme: (_) {},
        onColor: (_) {},
        onFrame: (_) {},
        onPresetWallpaper: (_) async {},
        onPickImage: () async {},
        onRemoveImage: () async {},
        onBgOpacity: (_) {},
        onPaper: (_) {},
        onLineSpacing: (_) {},
        onPaged: (_) {},
        onUseHomeBackground: () {},
      ),
    );
  });
}
