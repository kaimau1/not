import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/a11y/chip_roles.dart';
import 'package:notlar/core/a11y/color_names.dart';
import 'package:notlar/core/a11y/min_tap_target.dart';
import 'package:notlar/core/a11y/motion.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/core/widgets/color_palette.dart';
import 'package:notlar/features/ai/presentation/ai_sheet.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/format_menu.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/notes/presentation/note_actions_sheet.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/share_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faz 15 — erişilebilirlik: sistem yazı boyutu (F15.1), adlar ve roller
/// (F15.2–F15.3), dokunma hedefleri (F15.4), hareketi azalt (F15.5),
/// kontrast (F15.6) ve Flutter'ın erişilebilirlik rehberleri (F15.7).
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final note = Note(
    id: 'n1',
    type: NoteType.checklist,
    title: 'Alışveriş',
    tags: const ['ev'],
    updatedAt: DateTime(2026, 10, 31, 9, 30),
    items: const [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek', checked: true),
    ],
  );

  /// [systemScale]/[bold]: telefonun ayarı; [follow]: uygulamadaki
  /// "Sistem yazı boyutunu izle". Uygulamanın kökündeki gibi
  /// `fixedTypography` sarar.
  Widget app(
    Widget home, {
    double systemScale = 1,
    bool follow = false,
    bool bold = false,
    bool disableAnimations = false,
    ThemeData? theme,
  }) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      isAnonymousProvider.overrideWithValue(false),
      notesStreamProvider.overrideWith((ref) => Stream.value([note])),
      foldersStreamProvider.overrideWith(
        (ref) => Stream.value(const <NoteFolder>[]),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(412, 915),
        textScaler: TextScaler.linear(systemScale),
        boldText: bold,
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => fixedTypography(
          context,
          child ?? const SizedBox.shrink(),
          1,
          followSystem: follow,
        ),
        home: home,
      ),
    ),
  );

  Widget opener(void Function(BuildContext, WidgetRef) open) => Scaffold(
    body: Consumer(
      builder: (context, ref, _) => Center(
        child: TextButton(
          onPressed: () => open(context, ref),
          child: const Text('aç'),
        ),
      ),
    ),
  );

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
  }

  Future<void> meetsAll(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  group('F15.1 sistem yazı boyutu', () {
    double scaleIn(WidgetTester tester) =>
        MediaQuery.textScalerOf(tester.element(find.text('x'))).scale(10) / 10;

    testWidgets('varsayılan KAPALI: sistem ölçeği ve kalın metin yok sayılır', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const Text('x'), systemScale: 1.6, bold: true),
      );
      expect(scaleIn(tester), 1);
      expect(MediaQuery.boldTextOf(tester.element(find.text('x'))), isFalse);
      // Kayıtlı tercih yokken anahtar kapalı.
      final c = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      expect(c.read(followSystemTextScaleProvider), isFalse);
    });

    testWidgets('açıkken kademe sistemle çarpılır, kalın metin geçer', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const Text('x'), systemScale: 1.3, follow: true, bold: true),
      );
      expect(scaleIn(tester), closeTo(1.3, 0.001));
      expect(MediaQuery.boldTextOf(tester.element(find.text('x'))), isTrue);
    });

    testWidgets('çarpım üst sınırda durur', (tester) async {
      await tester.pumpWidget(
        app(const Text('x'), systemScale: 3, follow: true),
      );
      expect(scaleIn(tester), maxFollowedTextScale);
    });

    for (final scale in [1.3, 1.6]) {
      testWidgets('$scale× yazıda kart, Süz ve not menüsü taşmaz', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          app(
            Scaffold(
              body: Consumer(
                builder: (context, ref, _) => ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Row(
                      children: [
                        Expanded(child: NoteCard(note: note)),
                        const SizedBox(width: 8),
                        Expanded(child: NoteCard(note: note)),
                      ],
                    ),
                    TextButton(
                      onPressed: () => showFilterSheet(context),
                      child: const Text('süz'),
                    ),
                    TextButton(
                      onPressed: () => showNoteActionsSheet(context, ref, note),
                      child: const Text('menü'),
                    ),
                  ],
                ),
              ),
            ),
            systemScale: scale,
            follow: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('süz'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(200, 20));
        await tester.pumpAndSettle();

        await tester.tap(find.text('menü'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('F15.2–F15.3 adlar ve roller', () {
    testWidgets('kart TEK düğüm; ⋮ kendi adıyla ayrı ve 48 dp', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Center(
              child: SizedBox(width: 200, child: NoteCard(note: note)),
            ),
          ),
        ),
      );
      await tester.pump();
      final card = find.bySemanticsLabel(RegExp('^Alışveriş'));
      expect(card, findsOneWidget);
      expect(
        tester
            .getSemantics(card)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      // Kartın içindeki yazılar ayrı ayrı okunmaz.
      expect(find.bySemanticsLabel('Süt'), findsNothing);
      final menu = find.bySemanticsLabel('Not menüsü');
      expect(menu, findsOneWidget);
      final rect = tester.getSemantics(menu).rect;
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
      semantics.dispose();
    });

    testWidgets('madde kutucuğu madde metniyle okunur', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ItemsEditor(
              items: note.items,
              onChanged: (_) {},
              showCheckboxes: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final box = tester
          .getSemantics(find.byType(Checkbox).first)
          .getSemanticsData();
      expect(box.label, 'Süt');
      expect(
        box.flagsCollection.isChecked.toString(),
        isNot(contains('isTrue')),
      );
      expect(box.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('palet daireleri renk adıyla okunur', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: ColorPalette(title: 'Zemin', onPick: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Kırmızı, açık'), findsOneWidget);
      expect(find.bySemanticsLabel('Mavi, koyu'), findsOneWidget);
      expect(find.bySemanticsLabel('Beyaz'), findsOneWidget);
      semantics.dispose();
    });

    test('her renge bir ad', () {
      final l10n = lookupAppLocalizations(const Locale('tr'));
      for (final c in NoteColor.values) {
        expect(noteColorName(l10n, c), isNotEmpty);
      }
      final names = {
        for (var i = 0; i < kPaletteColors.length; i++)
          paletteColorName(l10n, i),
      };
      // 32 renkli ton birbirinden ayrı adla okunur.
      expect(names.length, greaterThanOrEqualTo(32));
      expect(colorNameFor(l10n, const Color(0xFFE53935)), 'Kırmızı');
      expect(colorNameFor(l10n, const Color(0xFF757575)), 'Gri');
    });

    testWidgets('tekli seçim çipi radyo gibi, eylem çipi düğme', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Column(children: [radioChipForTest(), actionChipForTest()]),
          ),
        ),
      );
      final radio = tester.getSemantics(find.text('Orta')).getSemanticsData();
      expect(radio.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(radio.label, 'Orta');
      final action = tester.getSemantics(find.text('#ev')).getSemanticsData();
      expect(action.flagsCollection.isButton, isTrue);
      expect(action.flagsCollection.isSelected, isNot(true));
      semantics.dispose();
    });
  });

  group('F15.5 hareketi azalt', () {
    testWidgets('motionOf sistemin ayarını izler', (tester) async {
      late bool motion;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) {
              motion = motionOf(context);
              return const SizedBox();
            },
          ),
          disableAnimations: true,
        ),
      );
      expect(motion, isFalse);
    });
  });

  group('F15.6 kontrast', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    test('ikincil metin her temada her yüzeyde ≥ 4,5:1', () {
      for (final theme in [
        for (final f in ThemeFamily.values)
          for (final b in Brightness.values) AppTheme.of(f, b),
      ]) {
        final s = theme.colorScheme;
        for (final bg in [
          s.surface,
          s.surfaceContainerLow,
          s.surfaceContainer,
          s.surfaceContainerHigh,
          s.surfaceContainerHighest,
        ]) {
          expect(ratio(s.onSurfaceVariant, bg), greaterThanOrEqualTo(4.5));
        }
      }
    });
  });

  group('F15.7 erişilebilirlik rehberleri', () {
    testWidgets('ana ekran: kart ve Süz düğmesi', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 200, child: NoteCard(note: note)),
                  const SizedBox(height: 24),
                  const HomeFilterButton(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await meetsAll(tester);
      semantics.dispose();
    });

    testWidgets('not ekranı: madde listesi', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ItemsEditor(
              items: note.items,
              onChanged: (_) {},
              showCheckboxes: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      semantics.dispose();
    });

    testWidgets('biçim levhası', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = WrapTextController(text: 'merhaba dünya');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          opener(
            (context, _) => showFormatSheet(
              context,
              controller: controller,
              onApplied: () {},
            ),
          ),
        ),
      );
      await openSheet(tester);
      await meetsAll(tester);
      semantics.dispose();
    });

    testWidgets('Süz levhası', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(opener((context, _) => showFilterSheet(context))),
      );
      await openSheet(tester);
      await meetsAll(tester);
      semantics.dispose();
    });

    testWidgets('Paylaş levhası', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(opener((context, ref) => showNoteShareSheet(context, ref, note))),
      );
      await openSheet(tester);
      await meetsAll(tester);
      semantics.dispose();
    });

    testWidgets('Yapay zekâ levhası', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        app(opener((context, _) => showAiSheet(context, note))),
      );
      await openSheet(tester);
      await meetsAll(tester);
      semantics.dispose();
    });
  });

  // F75.2 (DENEYIM D8): segment 40 dp GÖRÜNÜR, dokunma alanı 48 dp yüksek;
  // yatayda yalnız aradaki boşluğa uzanır — komşunun kutusuna taşmaz.
  testWidgets('not alt çubuğu: segmentler 48 dp dokunma alanı', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final semantics = tester.ensureSemantics();
    // Kalem ipucu görülmüş say: 5 sn içinde ikinci ipucu çıkınca ilkinin
    // zamanlayıcısı kalkmış katmanı yeniden kaldırmaya çalışıyor (debug
    // assert, `core/tips.dart` — bu testin konusu değil).
    await prefs.setStringList(TipOnce.prefsKey, [TipOnce.penTwoFinger]);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue(null),
        updateRequiredProvider.overrideWithValue(false),
        notesRepositoryProvider.overrideWithValue(null),
        attachmentRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        noteStreamProvider('n1').overrideWith((ref) => Stream.value(note)),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NoteEditorScreen(noteId: 'n1'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final targets = find.descendant(
      of: find.byType(BottomAppBar),
      matching: find.byType(MinTapTarget),
    );
    // Biçim · Ekle · Kalem · Ara · Seç + AI · ses kaydı · dikte.
    expect(targets, findsNWidgets(8));
    for (final element in targets.evaluate()) {
      final visible = tester.getRect(find.byWidget(element.widget));
      final node = tester.getSemantics(find.byWidget(element.widget));
      expect(visible.height, 40, reason: 'görünen boy değişmez');
      expect(node.rect.height, greaterThanOrEqualTo(48));
      expect(node.rect.width, greaterThan(visible.width));
    }
    expect(tester.getSize(find.byType(BottomAppBar)).height, 50);

    final pen = find.byKey(const ValueKey('editor-bar-pen'));
    final box = tester.getRect(pen);
    final target = tester.renderObject(pen);
    bool hitsPen(Offset at) =>
        tester.hitTestOnBinding(at).path.any((e) => e.target == target);
    // Görünen kutunun en sağ ve en sol pikseli KALEM (komşunun payı çalmaz);
    // aradaki boşluğun ötesi komşunun.
    expect(hitsPen(box.center), isTrue);
    expect(hitsPen(box.centerRight - const Offset(0.5, 0)), isTrue);
    expect(hitsPen(box.centerLeft + const Offset(0.5, 0)), isTrue);
    expect(hitsPen(box.centerRight + const Offset(3.5, 0)), isFalse);
    // Segmentin 3 dp ÜSTÜ (kapsülün dolgusu) kalemi açar: alt çubuğun yerini
    // kalem tepsisi alır.
    expect(find.byKey(const ValueKey('pen-close')), findsNothing);
    await tester.tapAt(box.topCenter - const Offset(0, 3));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('pen-close')), findsOneWidget);

    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}

Widget radioChipForTest() => Builder(
  builder: (context) => radioChip(
    ChoiceChip(label: const Text('Orta'), selected: true, onSelected: (_) {}),
  ),
);

Widget actionChipForTest() => Builder(
  builder: (context) =>
      actionChip(ActionChip(label: const Text('#ev'), onPressed: () {})),
);
