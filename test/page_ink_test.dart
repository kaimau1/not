import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folder_order.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_heavy.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';

const _stroke = InkStroke(
  page: 1,
  color: 0xFF000000,
  width: 0.01,
  points: [0.1, 0.2, 0.3, 1.8],
);

Note _note({List<InkStroke> ink = const []}) =>
    Note(id: 'n', type: NoteType.text, pageInk: ink);

/// Kalemin yazısı sayfanın üstünde, parmak altındaki metne gider.
Future<({InkController ink, TextEditingController text, FocusNode focus})>
_pump(WidgetTester tester, {bool penMode = false}) async {
  final ink = InkController(initial: const [], onChanged: (_) {})
    ..setEditing(true)
    ..setPenOnly(true, chosen: false)
    ..allowedKinds = {
      PointerDeviceKind.stylus,
      PointerDeviceKind.invertedStylus,
      if (penMode) PointerDeviceKind.touch,
    };
  final text = TextEditingController(text: 'yazı');
  final focus = FocusNode();
  addTearDown(ink.dispose);
  addTearDown(text.dispose);
  addTearDown(focus.dispose);
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(
        body: SingleChildScrollView(
          controller: scroll,
          child: PageInkStack(
            ink: ink,
            page: 1,
            penActive: penMode,
            scroll: scroll,
            child: TextField(controller: text, focusNode: focus),
          ),
        ),
      ),
    ),
  );
  return (ink: ink, text: text, focus: focus);
}

void main() {
  group('Note.pageInk', () {
    test('belgede sahte ek olarak gider, ek listesine girmez', () {
      final map = _note(ink: const [_stroke]).toMap();
      final raw = map['attachments'] as List;
      expect(raw.single['id'], kPageInkId);
      final back = Note.fromMap('n', {'attachments': raw});
      expect(back.attachments, isEmpty);
      expect(back.pageInk.single.points, hasLength(4));
      // y genişlik biriminde: 1'in üstü kırpılmaz.
      expect(back.pageInk.single.points.last, closeTo(1.8, 1e-6));
    });

    test('yalnız el yazılı not boş sayılmaz (temizlik silmesin)', () {
      expect(_note(ink: const [_stroke]).isEmpty, isFalse);
      expect(_note().isEmpty, isTrue);
    });

    test('ağır belgeye bölününce hafif not da "el yazısı var" der', () {
      final raw = (_note(ink: const [_stroke]).toMap()['attachments'] as List)
          .cast<Map<String, dynamic>>();
      final split = splitAttachmentMaps(raw);
      final light = Note.fromMap('n', {
        'heavyRef': true,
        'attachments': split.light,
      });
      expect(light.pageInk, isEmpty);
      expect(light.hasPageInk, isTrue);
      expect(light.isEmpty, isFalse);
      // Hafif not yazılsa da kayıt düşmez.
      expect(light.toMap()['attachments'], hasLength(1));
      final full = Note.fromMap(
        'n',
        mergeHeavy({'attachments': split.light}, {'attachments': split.heavy}),
      );
      expect(full.pageInk.single.points, hasLength(4));
    });

    test('silinince kayıt kalkar', () {
      final cleared = _note(ink: const [_stroke]).copyWith(pageInk: const []);
      expect(cleared.hasPageInk, isFalse);
      expect(cleared.toMap()['attachments'], isEmpty);
    });
  });

  group('PageInkStack', () {
    testWidgets('kalem sayfaya yazar, metne imleç koymaz', (tester) async {
      final t = await _pump(tester);
      final at = tester.getCenter(find.byType(TextField));
      final pen = await tester.startGesture(at, kind: PointerDeviceKind.stylus);
      await pen.moveBy(const Offset(40, 6));
      await pen.moveBy(const Offset(40, 6));
      await pen.up();
      await tester.pumpAndSettle();
      expect(t.ink.ink, hasLength(1));
      expect(t.focus.hasFocus, isFalse);
    });

    testWidgets('kalem kipi kapalıyken tek başına kalem tıkı metne gider', (
      tester,
    ) async {
      final t = await _pump(tester);
      t.ink.passStylusTaps = true;
      await tester.tapAt(
        tester.getCenter(find.byType(TextField)),
        kind: PointerDeviceKind.stylus,
      );
      await tester.pumpAndSettle();
      expect(t.ink.ink, isEmpty);
      expect(t.focus.hasFocus, isTrue);
    });

    testWidgets('kalemden sonra parmakla dokununca klavyeyle yazılır '
        '(yazı çizimin altında kalmaz)', (tester) async {
      final t = await _pump(tester);
      final at = tester.getCenter(find.byType(TextField));
      final pen = await tester.startGesture(at, kind: PointerDeviceKind.stylus);
      await pen.moveBy(const Offset(60, 0));
      await pen.up();
      await tester.pumpAndSettle();
      // Kalem kalktıktan hemen sonraki dokunuş avuç sayılır (avuç reddi).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 450)),
      );
      await tester.tapAt(at);
      await tester.pumpAndSettle();
      expect(t.focus.hasFocus, isTrue);
      tester.testTextInput.enterText('yazı devam');
      await tester.pump();
      expect(t.text.text, 'yazı devam');
      expect(t.ink.ink, hasLength(1));
    });

    testWidgets('yalnız kalem açıkken parmak çizmez', (tester) async {
      final t = await _pump(tester, penMode: true);
      final at = tester.getCenter(find.byType(TextField));
      final finger = await tester.startGesture(at);
      await finger.moveBy(const Offset(50, 0));
      await finger.up();
      await tester.pumpAndSettle();
      expect(t.ink.ink, isEmpty);
    });

    testWidgets('kalem aşağı yazdıkça sayfa uzar', (tester) async {
      final t = await _pump(tester, penMode: true);
      final before = tester.getSize(find.byType(PageInkStack)).height;
      t.ink.replaceAll(const [
        InkStroke(
          page: 1,
          color: 0xFF000000,
          width: 0.01,
          points: [0.1, 0.1, 0.1, 3],
        ),
      ]);
      await tester.pump();
      expect(
        tester.getSize(find.byType(PageInkStack)).height,
        greaterThan(before),
      );
    });
  });

  test('+ paneli dar liste panelinde sola taşmaz', () {
    // Ana-detay: düğmenin sağ kenarı 324 dp, panel 380 dp.
    final fit = quickAddPanelFit(
      screen: const Size(1200, 800),
      fabRight: 324,
      fabTop: 700,
    );
    expect(fit.width, 380);
    expect(324 + fit.dx - fit.width, greaterThanOrEqualTo(12));
    // Yeterli yer varken kaydırılmaz; kısa ekranda yükseklik sınırlanır.
    final wide = quickAddPanelFit(
      screen: const Size(800, 400),
      fabRight: 780,
      fabTop: 300,
      topInset: 24,
    );
    expect(wide.dx, 0);
    expect(wide.maxHeight, 252);
  });

  group('Gelen klasörü', () {
    test('şeritteki yerine girer, yer listeyi aşarsa sona', () {
      expect(withSharedHub(['a', 'b'], 'g', 0), ['g', 'a', 'b']);
      expect(withSharedHub(['a', 'b'], 'g', 1), ['a', 'g', 'b']);
      expect(withSharedHub(['a', 'b'], 'g', 9), ['a', 'b', 'g']);
    });

    test('yana çekişte durak olur', () {
      final stop = nextHomeSwipeStop(
        mode: SwipeMode.folders,
        notes: const [],
        folderIds: withSharedHub(['a'], kSharedHubFolderId, 0),
        folderId: null,
        filter: NoteFilter.all,
        tag: null,
        direction: 1,
      );
      expect(stop?.folderId, kSharedHubFolderId);
    });
  });

  test('Drive\'daki ek Storage kotasına sayılmaz (web yüklemesi)', () {
    const drive = Attachment(
      id: 'd',
      fileName: 'x.jpg',
      mimeType: 'image/jpeg',
      kind: AttachmentKind.image,
      sizeBytes: 900,
      driveId: 'gd',
    );
    const storage = Attachment(
      id: 's',
      fileName: 'y.jpg',
      mimeType: 'image/jpeg',
      kind: AttachmentKind.image,
      sizeBytes: 100,
      downloadUrl: 'https://x',
    );
    expect(
      cloudAttachmentBytes([
        const Note(id: 'n', type: NoteType.text, attachments: [drive, storage]),
      ]),
      100,
    );
  });
}
