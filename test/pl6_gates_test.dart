import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/utils/note_fonts.dart' show kAppDefaultFont;
import 'package:notlar/features/entitlement/data/entitlement_service.dart';
import 'package:notlar/features/entitlement/domain/entitlement.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/note_menu_model.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/settings/presentation/backup_ui.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart'
    show appFontLocked;
import 'package:notlar/features/settings/presentation/theme_picker.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

/// PL6 kalan kapılar: `versionHistory`, `encryptedBackup`, `extraAppearance`.
///
/// Kapı kararı testte `proFeatureProvider` geçersiz kılınarak verilir (Play
/// derlemesi `--dart-define` ister; bayraksız derlemede kapı hep açık).
void main() {
  final l10n = lookupAppLocalizations(const Locale('tr'));

  Override gate(ProFeature f, bool open) =>
      proFeatureProvider(f).overrideWithValue(open);

  /// `/premium` rotası Pro ekranı yerine işaret metni gösterir.
  GoRouter routerOf(Widget home) => GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: '/premium',
        builder: (_, _) => const Scaffold(body: Text('PRO-EKRANI')),
      ),
    ],
  );

  Future<ProviderContainer> pumpApp(
    WidgetTester tester,
    Widget home, {
    required List<Override> overrides,
    Map<String, Object> prefs = const {},
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: routerOf(home),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  group('ücretsiz temel set (extraAppearance)', () {
    test('seçili olan asla kilitlenmez; temel set serbest; gerisi kilitli', () {
      bool locked(String id, {String? cur, bool open = false}) =>
          AppearanceGate.locked(
            id,
            free: AppearanceGate.freeThemes,
            current: cur,
            unlocked: open,
          );
      expect(locked('ocean'), isTrue);
      expect(locked('ocean', open: true), isFalse);
      // Kimsenin seçili ayarı elinden alınmaz.
      expect(locked('ocean', cur: 'ocean'), isFalse);
      for (final free in ['system', 'sage', 'dark']) {
        expect(locked(free), isFalse, reason: free);
      }
    });

    test('bugünkü varsayılan tema ve yazı tipi ücretsiz sette', () {
      expect(
        AppearanceGate.freeThemes,
        contains(AppThemeChoice.fromStored(null).name),
      );
      expect(AppearanceGate.freeFonts, {kAppDefaultFont});
      final names = {for (final c in AppThemeChoice.values) c.name};
      expect(names.containsAll(AppearanceGate.freeThemes), isTrue);
    });

    test('tema ve yazı tipi yardımcıları kapıyı izler', () {
      expect(
        themeChoiceLocked(
          AppThemeChoice.rose,
          AppThemeChoice.sage,
          unlocked: false,
        ),
        isTrue,
      );
      expect(
        themeChoiceLocked(
          AppThemeChoice.rose,
          AppThemeChoice.rose,
          unlocked: false,
        ),
        isFalse,
      );
      expect(
        themeChoiceLocked(
          AppThemeChoice.dark,
          AppThemeChoice.sage,
          unlocked: false,
        ),
        isFalse,
      );
    });
  });

  group('tema ızgarası', () {
    Future<void> tapTheme(WidgetTester tester, String label) async {
      final f = find.text(label);
      await tester.ensureVisible(f);
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    Widget host() =>
        const Scaffold(body: SingleChildScrollView(child: ThemeChoiceGrid()));

    testWidgets('kilitliyken yeni tema seçilmez, Pro ekranı açılır', (
      tester,
    ) async {
      final c = await pumpApp(
        tester,
        host(),
        overrides: [gate(ProFeature.extraAppearance, false)],
      );
      // Kilitli her kartta rozet var; temel set (3 tema) rozetsiz.
      expect(
        find.byIcon(Icons.lock_outline),
        findsNWidgets(AppThemeChoice.values.length - 3),
      );
      await tapTheme(tester, l10n.themeOcean);
      expect(c.read(themeChoiceProvider), AppThemeChoice.sage);
      expect(find.text('PRO-EKRANI'), findsOneWidget);
    });

    testWidgets('kilitliyken temel set seçilebilir', (tester) async {
      final c = await pumpApp(
        tester,
        host(),
        overrides: [gate(ProFeature.extraAppearance, false)],
      );
      await tapTheme(tester, l10n.themeDark);
      expect(c.read(themeChoiceProvider), AppThemeChoice.dark);
      expect(find.text('PRO-EKRANI'), findsNothing);
    });

    testWidgets('kilitliyken zaten seçili ek tema kilitlenmez, kalır', (
      tester,
    ) async {
      final c = await pumpApp(
        tester,
        host(),
        overrides: [gate(ProFeature.extraAppearance, false)],
        prefs: {'theme_mode': 'ocean'},
      );
      expect(c.read(themeChoiceProvider), AppThemeChoice.ocean);
      expect(
        find.byIcon(Icons.lock_outline),
        findsNWidgets(AppThemeChoice.values.length - 4),
      );
      // Başka bir ek tema kilitli, seçili olan değil.
      await tapTheme(tester, l10n.themeRose);
      expect(c.read(themeChoiceProvider), AppThemeChoice.ocean);
      expect(find.text('PRO-EKRANI'), findsOneWidget);
    });

    testWidgets('açıkken (kişisel APK / Pro) hepsi seçilir, rozet yok', (
      tester,
    ) async {
      final c = await pumpApp(
        tester,
        host(),
        overrides: [gate(ProFeature.extraAppearance, true)],
      );
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      await tapTheme(tester, l10n.themeOcean);
      expect(c.read(themeChoiceProvider), AppThemeChoice.ocean);
    });
  });

  group('yazı tipi kapısı', () {
    test('kilitliyken yalnız varsayılan ve seçili serbest', () {
      expect(appFontLocked('Lora', kAppDefaultFont, unlocked: false), isTrue);
      expect(appFontLocked('Lora', 'Lora', unlocked: false), isFalse);
      expect(appFontLocked(kAppDefaultFont, 'Lora', unlocked: false), isFalse);
      expect(appFontLocked('Lora', kAppDefaultFont, unlocked: true), isFalse);
    });
  });

  group('parolalı yedek penceresi (encryptedBackup)', () {
    Widget host(void Function(({String? password})?) onResult) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              onResult(await showBackupExportPasswordDialog(context)),
          child: const Text('aç'),
        ),
      ),
    );

    testWidgets('kilitliyken alan yok; parolasız yedek serbest', (
      tester,
    ) async {
      ({String? password})? result;
      var called = false;
      await pumpApp(
        tester,
        host((r) {
          result = r;
          called = true;
        }),
        overrides: [gate(ProFeature.encryptedBackup, false)],
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('backup-export-pass')), findsNothing);
      expect(
        find.byKey(const ValueKey('backup-export-with-pass')),
        findsNothing,
      );
      expect(find.text(l10n.backupPasswordProLocked), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('backup-export-no-pass')));
      await tester.pumpAndSettle();
      expect(called, isTrue);
      expect(result, (password: null));
    });

    testWidgets('kilitliyken şifreli düğme Pro ekranına götürür', (
      tester,
    ) async {
      var called = false;
      await pumpApp(
        tester,
        host((_) => called = true),
        overrides: [gate(ProFeature.encryptedBackup, false)],
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('backup-export-pro')));
      await tester.pumpAndSettle();
      expect(find.text('PRO-EKRANI'), findsOneWidget);
      // Pencere kapandı, yedek sonucu iptal (null) döndü.
      expect(find.byKey(const ValueKey('backup-export-no-pass')), findsNothing);
      expect(called, isTrue);
    });

    testWidgets('açıkken parola alanları ve şifreli düğme var', (tester) async {
      await pumpApp(
        tester,
        host((_) {}),
        overrides: [gate(ProFeature.encryptedBackup, true)],
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('backup-export-pass')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('backup-export-with-pass')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('backup-export-pro')), findsNothing);
    });
  });

  group('sürüm geçmişi (versionHistory)', () {
    const base = Note(id: 'n', type: NoteType.text, title: 'T', body: 'g');

    test('menü modeli: kilitliyken satır kalır, rozet taşır', () {
      ActionMenu m({bool locked = false}) => noteMenuModel(
        l10n,
        base,
        surface: NoteMenuSurface.editor,
        historyLocked: locked,
      );
      MenuAction history(ActionMenu menu) =>
          [for (final s in menu.sections) ...s.actions]
              .singleWhere((a) => a.id == 'history');
      expect(history(m()).badge, isNull);
      expect(history(m(locked: true)).badge, isNotNull);
    });

    Future<void> openHistory(WidgetTester tester, {required bool open}) async {
      final router = routerOf(const NoteEditorScreen(noteId: 'n'));
      await pumpEditor(
        tester,
        base,
        repo: CountingNotesRepository(),
        overrides: [gate(ProFeature.versionHistory, open)],
        home: MaterialApp.router(
          theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const ValueKey('editor-more')));
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('menu-tile-history'));
      await tester.ensureVisible(tile);
      if (!open) {
        expect(
          find.descendant(of: tile, matching: find.byIcon(Icons.lock_outline)),
          findsOneWidget,
        );
      }
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('kilitliyken editör menüsü Pro ekranını açar', (tester) async {
      await openHistory(tester, open: false);
      expect(find.text('PRO-EKRANI'), findsOneWidget);
      await endEditor(tester);
    });

    testWidgets('açıkken geçmiş levhası açılır (bugünkü davranış)', (
      tester,
    ) async {
      await openHistory(tester, open: true);
      expect(find.text('PRO-EKRANI'), findsNothing);
      expect(find.text(l10n.versionHistoryEmpty), findsOneWidget);
      await endEditor(tester);
    });
  });
}
