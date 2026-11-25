import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/app/theme/app_tokens.dart';
import 'package:notlar/app/theme/dashboard_wallpapers.dart';
import 'package:notlar/app/theme/note_themes.dart';
import 'package:notlar/app/theme/page_transitions.dart';
import 'package:notlar/core/utils/note_fonts.dart';
import 'package:notlar/core/widgets/confirm_dialog.dart';
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/presentation/dashboard_background_sheet.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/notes/presentation/note_theme_sheet.dart';
import 'package:notlar/features/settings/presentation/theme_picker.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(disableFontRuntimeFetching);

  final tr = lookupAppLocalizations(const Locale('tr'));
  final en = lookupAppLocalizations(const Locale('en'));

  group('40 özgün palet ve varsayılan Adaçayı', () {
    test('tüm 20 ailenin açık ve koyu paleti özgün, 5 klasik koyu artık beyaz-koyu değil', () {
      final whiteDark = FamilyPalettes.of(ThemeFamily.white, Brightness.dark);
      for (final classic in [
        ThemeFamily.classic,
        ThemeFamily.newsprint,
        ThemeFamily.notebook,
        ThemeFamily.graphite,
        ThemeFamily.ledger,
      ]) {
        final dark = FamilyPalettes.of(classic, Brightness.dark);
        expect(
          dark.ground == whiteDark.ground &&
              dark.primary == whiteDark.primary &&
              dark.card == whiteDark.card,
          isFalse,
          reason: '${classic.name} özgün koyu palete sahip olmalı',
        );
      }

      for (final family in ThemeFamily.values) {
        for (final brightness in Brightness.values) {
          final theme = AppTheme.of(family, brightness);
          final tokens = AppTokens.fromTheme(theme);
          final scheme = theme.colorScheme;
          expect(
            tokens.sheetCard,
            isNotNull,
            reason: '${family.name}/$brightness',
          );
          expect(tokens.accentBorder, isNotNull);
          expect(tokens.tintSoft, isNotNull);
          expect(tokens.warmTint, isNotNull);
          if (brightness == Brightness.dark) {
            // Koyu kipte kart ve levha kartı zeminden daha aydınlık olmalı.
            expect(
              tokens.card.computeLuminance(),
              greaterThan(scheme.surface.computeLuminance()),
              reason: '${family.name} dark card luminance',
            );
            expect(
              tokens.resolvedSheetCard(scheme).computeLuminance(),
              greaterThan(scheme.surface.computeLuminance()),
              reason: '${family.name} dark sheetCard luminance',
            );
          }
        }
      }
    });

    test('Adaçayı yeni M3 bileşen temalarını eksiksiz tanımlar', () {
      for (final b in Brightness.values) {
        final t = AppTheme.of(ThemeFamily.sage, b);
        expect(t.segmentedButtonTheme.style, isNotNull);
        expect(t.switchTheme.thumbColor, isNotNull);
        expect(t.sliderTheme.activeTrackColor, isNotNull);
        expect(t.checkboxTheme.fillColor, isNotNull);
        expect(t.filledButtonTheme.style, isNotNull);
        expect(t.outlinedButtonTheme.style, isNotNull);
        expect(t.tabBarTheme.indicatorColor, t.colorScheme.primary);
        expect(
          t.pageTransitionsTheme.builders[TargetPlatform.linux],
          isA<SmoothDesktopPageTransitionsBuilder>(),
        );
      }
    });
  });

  group('18 hazır renkli arka plan ve 14 not teması', () {
    test('tüm 18 duvar kâğıdı diskte mevcut, geçerli ve yerelleştirilmiş', () {
      expect(DashboardWallpapers.all, hasLength(18));
      final ids = <String>{};
      for (final w in DashboardWallpapers.all) {
        expect(ids.add(w.id), isTrue, reason: 'çift kimlik: ${w.id}');
        expect(File(w.asset).existsSync(), isTrue, reason: '${w.asset} eksik');
        expect(File(w.asset).lengthSync(), greaterThan(1024));
        expect(w.label(tr), isNotEmpty);
        expect(w.label(en), isNotEmpty);
        expect(DashboardWallpapers.byId(w.id), same(w));
      }
    });

    test(
      'DashboardBackgroundNotifier preset kaydı, path dışlaması ve sıfırlama',
      () async {
        SharedPreferences.setMockInitialValues({});
        final sp = await SharedPreferences.getInstance();
        final container = ProviderContainer(
          overrides: [sharedPreferencesProvider.overrideWithValue(sp)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(dashboardBackgroundProvider.notifier);
        expect(
          container.read(dashboardBackgroundProvider).isCustomized,
          isFalse,
        );

        notifier.setPreset(
          DashboardWallpapers.auroraBloom,
          defaultOpacity: 0.65,
        );
        final afterPreset = container.read(dashboardBackgroundProvider);
        expect(afterPreset.preset, DashboardWallpapers.auroraBloom);
        expect(afterPreset.path, isNull);
        expect(afterPreset.opacity, closeTo(0.65, 0.001));
        expect(afterPreset.isCustomized, isTrue);
        expect(
          sp.getString('dashboard_bg_preset'),
          DashboardWallpapers.auroraBloom,
        );

        // Cihaz fotoğrafı seçilince hazır görsel temizlenir.
        notifier.setPath('/tmp/custom.jpg');
        final afterPath = container.read(dashboardBackgroundProvider);
        expect(afterPath.path, '/tmp/custom.jpg');
        expect(afterPath.preset, isNull);
        expect(sp.getString('dashboard_bg_preset'), isNull);

        notifier.reset();
        expect(
          container.read(dashboardBackgroundProvider).isCustomized,
          isFalse,
        );
        expect(sp.getString('dashboard_bg_preset'), isNull);
        expect(sp.getString('dashboard_bg_path'), isNull);
      },
    );

    test('14 not teması hem açık hem koyu kipte eksiksiz palet verir', () {
      expect(NoteThemes.all, hasLength(14));
      for (final theme in NoteThemes.all) {
        expect(NoteThemes.byId(theme.id), same(theme));
        expect(theme.palette(false), isNotNull);
        expect(theme.palette(true), isNotNull);
      }
    });
  });

  group('yenilenen menüler', () {
    Future<ProviderContainer> pumpSheetHost(
      WidgetTester tester,
      VoidCallback Function(BuildContext) open, {
      Brightness brightness = Brightness.light,
      bool reduceMotion = false,
    }) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final sp = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
          notesStreamProvider.overrideWith((_) => Stream.value(const <Note>[])),
          foldersStreamProvider.overrideWith(
            (_) => Stream.value(const <NoteFolder>[]),
          ),
          proFeatureProvider(ProFeature.extraAppearance)
              .overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.of(ThemeFamily.sage, brightness),
            locale: const Locale('tr'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (outerCtx) => MediaQuery(
                data: MediaQuery.of(outerCtx)
                    .copyWith(disableAnimations: reduceMotion),
                child: Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: open(context),
                      child: const Text('AÇ'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('AÇ'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets(
      'Ana ekran zemini: hazır görsel seçimi, görünürlük ve takvim şeridi',
      (tester) async {
        final container = await pumpSheetHost(
          tester,
          (ctx) =>
              () => showDashboardBackgroundSheet(ctx),
        );

        expect(find.text(tr.dashboardBackground), findsOneWidget);
        expect(find.text(tr.dashboardBackgroundGallery), findsOneWidget);
        expect(
          find.byKey(const ValueKey('dashboard-calendar-strip')),
          findsOneWidget,
        );

        // İlk hazır görsele dokun → sağlayıcıya yazılır ve saydamlık kaydırıcısı çıkar.
        final firstTile = find.byKey(
          const ValueKey('bg-wallpaper-aurora_bloom'),
        );
        await tester.ensureVisible(firstTile);
        await tester.tap(firstTile);
        await tester.pumpAndSettle();

        expect(
          container.read(dashboardBackgroundProvider).preset,
          DashboardWallpapers.auroraBloom,
        );
        expect(find.text(tr.dashboardBackgroundOpacity), findsOneWidget);

        // Sıfırla düğmesi zemini temizler.
        final resetBtn = find.text(tr.dashboardBackgroundReset);
        await tester.ensureVisible(resetBtn);
        await tester.tap(resetBtn);
        await tester.pumpAndSettle();
        expect(
          container.read(dashboardBackgroundProvider).isCustomized,
          isFalse,
        );
      },
    );

    testWidgets(
      'Görünüm ve süz: bölüm kartları, görünüm modu ve süzgeç sıfırlama',
      (tester) async {
        await pumpSheetHost(
          tester,
          (ctx) =>
              () => showFilterSheet(ctx),
          brightness: Brightness.dark,
        );

        expect(find.text(tr.filterSheetTitle), findsOneWidget);
        expect(find.byKey(const ValueKey('filter-view-mode')), findsOneWidget);
        expect(
          find.byKey(const ValueKey('filter-manual-reorder')),
          findsOneWidget,
        );

        final starred = find.text(tr.filterStarred);
        await tester.ensureVisible(starred);
        await tester.tap(starred);
        await tester.pumpAndSettle();
        expect(find.text(tr.filterReset), findsOneWidget);

        await tester.tap(find.text(tr.filterReset));
        await tester.pumpAndSettle();
        expect(find.text(tr.filterReset), findsNothing);
      },
    );

    testWidgets(
      'Tema levhası: grup süzgeci ve Vazgeç ile önceki temaya dönüş',
      (tester) async {
        final container = await pumpSheetHost(
          tester,
          (ctx) =>
              () => showThemePickerSheet(ctx),
        );

        expect(find.text(tr.themeGroupAll), findsOneWidget);
        expect(find.text(tr.themeGroupVivid), findsOneWidget);

        // Canlı grubuna süz ve Okyanus'u seç.
        await tester.tap(find.text(tr.themeGroupVivid));
        await tester.pumpAndSettle();

        final ocean = find.byKey(const ValueKey('theme-sheet-ocean'));
        expect(ocean, findsOneWidget);
        await tester.tap(ocean);
        await tester.pumpAndSettle();
        expect(container.read(themeChoiceProvider), AppThemeChoice.ocean);

        // Vazgeç başlangıçtaki Adaçayı'na döndürür.
        await tester.tap(find.byKey(const ValueKey('theme-sheet-revert')));
        await tester.pumpAndSettle();
        expect(container.read(themeChoiceProvider), AppThemeChoice.sage);
      },
    );

    testWidgets('Not teması levhası 14 temayı taşmadan ve seçimle çizer', (
      tester,
    ) async {
      var picked = '';
      await pumpSheetHost(
        tester,
        (ctx) =>
            () => showNoteThemeSheet(
              ctx,
              current: '',
              onTheme: (id) => picked = id,
            ),
      );

      expect(find.text(tr.noteAppearance), findsOneWidget);
      expect(find.text(tr.noteThemeNone), findsOneWidget);
      final aurora = find.text(tr.noteThemeAurora);
      await tester.ensureVisible(aurora);
      await tester.tap(aurora);
      await tester.pumpAndSettle();
      expect(picked, NoteThemes.aurora);
    });

    testWidgets(
      'Onay penceresi normal ve hareketi azalt kiplerinde açılır/kapanır',
      (tester) async {
        for (final reduced in [false, true]) {
          bool? confirmed;
          await pumpSheetHost(
            tester,
            (ctx) => () async {
              confirmed = await showConfirmDialog(
                ctx,
                title: 'Sil',
                message: 'Emin misin?',
                confirmLabel: 'Onayla',
                destructive: true,
              );
            },
            reduceMotion: reduced,
          );
          expect(find.text('Emin misin?'), findsOneWidget);
          await tester.tap(find.byKey(const ValueKey('confirm-ok')));
          await tester.pumpAndSettle();
          expect(confirmed, isTrue);
        }
      },
    );
  });
}
