import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/after_route_transition.dart';
import 'package:notlar/core/widgets/expand_reveal.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/capture_mode_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/notebook_paper.dart';
import 'package:notlar/features/notes/presentation/file_use_sheet.dart';
import 'package:notlar/features/notes/presentation/filter_sheet.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-10-20 kullanıcı listesindeki düzeltmelerin korumaları.
void main() {
  Widget app(Widget home) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('tr'),
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  group('madde seçimi', () {
    Future<ItemsEditorState> pumpEditor(
      WidgetTester tester, {
      List<NoteItem>? items,
      ValueChanged<List<NoteItem>>? onChanged,
    }) async {
      await tester.pumpWidget(
        app(
          Scaffold(
            body: ItemsEditor(
              items:
                  items ??
                  [
                    for (var i = 0; i < 3; i++)
                      NoteItem(id: 'i$i', text: 'Öğe $i'),
                  ],
              onChanged: onChanged ?? (_) {},
              showCheckboxes: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final state = tester.state<ItemsEditorState>(find.byType(ItemsEditor));
      state.startSelection();
      await tester.pumpAndSettle();
      return state;
    }

    testWidgets('yuvarlağın KENARINA (dolguya) dokunmak da seçer', (
      tester,
    ) async {
      await pumpEditor(tester);
      final circle = tester.getRect(find.byIcon(Icons.circle_outlined).first);
      // Simgenin 8 dp solu: eskiden dolgu dokunuş almıyordu.
      await tester.tapAt(Offset(circle.left - 8, circle.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('1 madde seçildi'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('satırın sağındaki boş paya dokunmak da seçer', (tester) async {
      await pumpEditor(tester);
      final row = tester.getRect(find.text('Öğe 1'));
      final screen = tester.getSize(find.byType(Scaffold));
      await tester.tapAt(Offset(screen.width - 6, row.center.dy));
      await tester.pumpAndSettle();
      expect(find.text('1 madde seçildi'), findsOneWidget);
    });

    testWidgets('seçilenler topluca işaretlenir', (tester) async {
      List<NoteItem>? last;
      await pumpEditor(tester, onChanged: (items) => last = items);
      // Seçim kipinde metin alanı dokunuş ALMAZ (satır alır): uyarı beklenir.
      await tester.tap(find.text('Öğe 0'), warnIfMissed: false);
      await tester.tap(find.text('Öğe 2'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Seçilenleri işaretle'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(last, isNotNull);
      final checked = {
        for (final i in last!)
          if (i.checked) i.id,
      };
      expect(checked, {'i0', 'i2'});
    });
  });

  group('süz düğmesi', () {
    Future<ProviderContainer> pumpButton(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notesStreamProvider.overrideWith(
              (ref) => Stream.value(const <Note>[]),
            ),
            foldersStreamProvider.overrideWith(
              (ref) => Stream.value(const <NoteFolder>[]),
            ),
          ],
          child: app(
            const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [HomeFilterButton()],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(HomeFilterButton)),
      );
    }

    testWidgets('süzgeç yokken yalnız simge; seçilince ADI ve × görünür', (
      tester,
    ) async {
      final c = await pumpButton(tester);
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('Süz'), findsNothing);

      c.read(noteFilterProvider.notifier).set(NoteFilter.starred);
      await tester.pumpAndSettle();
      expect(find.text('Yıldızlı'), findsOneWidget);
      expect(find.byKey(const ValueKey('home-filter-clear')), findsOneWidget);

      c.read(selectedTagProvider.notifier).set('iş');
      await tester.pumpAndSettle();
      expect(find.text('Yıldızlı +1'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-filter-clear')));
      await tester.pumpAndSettle();
      expect(c.read(noteFilterProvider), NoteFilter.all);
      expect(c.read(selectedTagProvider), isNull);
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    test('yıldızlı süzgeci yalnız yıldızlı notu geçirir', () {
      const starred = Note(id: 'a', type: NoteType.text, starred: true);
      const pinned = Note(id: 'b', type: NoteType.text, pinned: true);
      expect(noteMatchesFilter(starred, NoteFilter.starred), isTrue);
      expect(noteMatchesFilter(pinned, NoteFilter.starred), isFalse);
      expect(noteMatchesFilter(starred, NoteFilter.pinned), isFalse);
    });
  });

  group('dosya levhası', () {
    test('tür uzantıdan; HEIC görsel sayılır', () {
      expect(PickedFileKind.of('a.HEIC'), PickedFileKind.image);
      expect(PickedFileKind.of('rapor.pdf'), PickedFileKind.pdf);
      expect(PickedFileKind.of('sunum.pptx'), PickedFileKind.slides);
      expect(PickedFileKind.of('kayit.opus'), PickedFileKind.audio);
      expect(PickedFileKind.of('v.mov'), PickedFileKind.video);
      expect(PickedFileKind.of('x.zip'), isNull);
    });

    test('seçenekler türe göre; varsayılan kip başta', () {
      expect(fileUsesFor(PickedFileKind.pdf, preferred: CaptureMode.classic), [
        FileUse.classic,
        FileUse.bubbles,
      ]);
      expect(fileUsesFor(PickedFileKind.image, web: false), [
        FileUse.bubbles,
        FileUse.classic,
        FileUse.transcribe,
      ]);
      // Ses artık sorulmadan metne dökülmüyor: ek olarak eklenebilir.
      expect(fileUsesFor(PickedFileKind.audio, web: false), [
        FileUse.audio,
        FileUse.transcribe,
      ]);
      expect(fileUsesFor(PickedFileKind.video, web: true), [FileUse.video]);
    });

    testWidgets('tek levha: özet, başlık ve seçim birlikte döner', (
      tester,
    ) async {
      FileUseChoice? picked;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => picked = await showFileUseSheet(
                  context,
                  kind: PickedFileKind.pdf,
                  names: const ['rapor.pdf', 'ek.pdf'],
                  preferred: CaptureMode.bubbles,
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      expect(find.text('rapor.pdf'), findsOneWidget);
      expect(find.text('+1 dosya daha'), findsOneWidget);
      expect(find.text('Varsayılan'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('file-use-title')),
        'Toplantı',
      );
      await tester.tap(find.byKey(const ValueKey('file-use-classic')));
      await tester.pumpAndSettle();
      expect(picked?.use, FileUse.classic);
      expect(picked?.title, 'Toplantı');
      expect(captureChoiceOf(picked!)?.mode, CaptureMode.classic);
    });
  });

  group('defter kâğıdı', () {
    test('yeni desenler kimlikle gidip gelir, bilinmeyen çizgiliye düşer', () {
      for (final paper in ArchivePaper.values) {
        expect(ArchivePaper.fromId(paper.id), paper);
      }
      expect(ArchivePaper.fromId('ileride-gelecek'), ArchivePaper.lined);
    });

    testWidgets('seçici her deseni önizlemeyle gösterir, dokunuş anında '
        'bildirir ve levha açık kalır', (tester) async {
      final picks = <ArchivePaper>[];
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: NotebookPaperPicker(
                initial: ArchivePaper.lined,
                onChanged: picks.add,
              ),
            ),
          ),
        ),
      );
      for (final paper in ArchivePaper.values) {
        expect(find.byKey(ValueKey('paper-${paper.id}')), findsOneWidget);
      }
      await tester.tap(find.text('Milimetrik'));
      await tester.pump();
      await tester.tap(find.text('Bloknot'));
      await tester.pump();
      expect(picks, [ArchivePaper.engineering, ArchivePaper.legal]);
      // Seçili döşemede onay işareti.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('paper-legal')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });
  });

  group('klavye penceresi', () {
    testWidgets('pencere daralırken çocuk YENİDEN ÖLÇÜLMEZ', (tester) async {
      final sizes = <Size>[];
      Widget window(double visible) => app(
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: KeyboardClipWindow(
              full: 300,
              visible: visible,
              child: LayoutBuilder(
                builder: (context, c) {
                  sizes.add(c.biggest);
                  return const ColoredBox(color: Colors.red);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(window(300));
      expect(tester.getSize(find.byType(KeyboardClipWindow)).height, 300);
      await tester.pumpWidget(window(120));
      await tester.pump(const Duration(milliseconds: 100));
      final mid = tester.getSize(find.byType(KeyboardClipWindow)).height;
      expect(mid, lessThan(300));
      expect(mid, greaterThan(120), reason: 'yumuşak geçiş, sıçrama yok');
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(KeyboardClipWindow)).height, 120);
      // Çocuk hep aynı boyda ölçüldü.
      expect(sizes.map((s) => s.height).toSet(), {300});
    });

    testWidgets('evre dinleyicisi yalnız açılış/kapanışta bildirir', (
      tester,
    ) async {
      final phases = <KeyboardPhase>[];
      Widget host(double inset) => MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          viewInsets: EdgeInsets.only(bottom: inset),
        ),
        child: KeyboardPhaseListener(
          onChanged: phases.add,
          child: const SizedBox(),
        ),
      );
      await tester.pumpWidget(host(0));
      for (final inset in const [40.0, 120.0, 220.0, 300.0]) {
        await tester.pumpWidget(host(inset));
      }
      await tester.pump();
      expect(phases.where((p) => p.open), isNotEmpty);
      expect(phases.last.open, isTrue);
      expect(phases.last.estimate, greaterThanOrEqualTo(300));
      final opened = phases.length;
      // Kapanış: düşüşün başında "kapalı" bildirilir.
      await tester.pumpWidget(host(150));
      await tester.pump();
      expect(phases.length, opened + 1);
      expect(phases.last.open, isFalse);
      await tester.pumpWidget(host(0));
      await tester.pump();
      expect(phases.length, opened + 1, reason: 'aynı evre tekrar bildirilmez');
    });
  });

  group('ayar açılışı', () {
    testWidgets('içerik ilk karede kurulur ama açılış SONRAKİ karede başlar', (
      tester,
    ) async {
      Widget host(bool open) => app(
        Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ExpandReveal(
              open: open,
              child: const SizedBox(height: 200, child: Text('içerik')),
            ),
          ),
        ),
      );
      await tester.pumpWidget(host(false));
      expect(find.text('içerik'), findsNothing);
      await tester.pumpWidget(host(true));
      // İlk kare: içerik ağaçta, boy sıfır (ağır ilk kare animasyonu yutmaz).
      expect(find.text('içerik', skipOffstage: false), findsOneWidget);
      expect(tester.getSize(find.byType(ExpandReveal)).height, 0);
      // Denetleyici ilk karenin SONUNDA başlar; ilk tıkı sıfır noktasıdır.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final mid = tester.getSize(find.byType(ExpandReveal)).height;
      expect(mid, greaterThan(0));
      expect(mid, lessThan(200));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(ExpandReveal)).height, 200);
      // Kapanınca animasyon bitince içerik ağaçtan düşer.
      await tester.pumpWidget(host(false));
      await tester.pumpAndSettle();
      expect(find.text('içerik', skipOffstage: false), findsNothing);
    });
  });

  testWidgets('ağır medya rota geçişi bitince kurulur', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  body: AfterRouteTransition(
                    placeholder: Text('yer tutucu'),
                    child: Text('medya'),
                  ),
                ),
              ),
            ),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('yer tutucu'), findsOneWidget);
    expect(find.text('medya'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('medya'), findsOneWidget);
  });
}
