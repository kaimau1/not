import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/scan/scan_pdf.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/editor/view_mode_switch.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: child),
);

/// "Sabit, yüzen ve balonlu arasında kolay geçiş TÜM ekler için"
/// (kullanıcı isteği 2026-10-16).
void main() {
  const image = Attachment(
    id: 'g',
    kind: AttachmentKind.image,
    fileName: 'g.jpg',
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
    x: 0.3,
    pageY: 300,
    displayWidth: 0.3,
  );

  test('her ek türü kendi görünümlerini sunar', () {
    // 2026-10-17: dördüncü kip "Ek" (alt şerit) her dosyalı ekte var.
    expect(availableViews(image), {
      AttachmentView.pinned,
      AttachmentView.floating,
      AttachmentView.bubbles,
      AttachmentView.attached,
    });
    const pdf = Attachment(
      id: 'p',
      kind: AttachmentKind.pdf,
      fileName: 'a.pdf',
      mimeType: 'application/pdf',
    );
    expect(availableViews(pdf), contains(AttachmentView.pinned));
    expect(availableViews(pdf), contains(AttachmentView.bubbles));
    const video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'v.mp4',
      mimeType: 'video/mp4',
    );
    // Videonun sayfası yok: balon olmaz (zaman damgası onun karşılığı).
    expect(availableViews(video), {
      AttachmentView.pinned,
      AttachmentView.floating,
      AttachmentView.attached,
    });
    // YouTube'un dosyası yok: şeride inmez.
    const youtube = Attachment(
      id: 'y',
      kind: AttachmentKind.video,
      fileName: 'y',
      mimeType: 'video/youtube',
      webUrl: 'https://youtu.be/x',
    );
    expect(availableViews(youtube), {
      AttachmentView.pinned,
      AttachmentView.floating,
    });
    // SES 2026-10-17'de katıldı: sayfada ve tepede oynatıcı kartı.
    const audio = Attachment(
      id: 'a',
      kind: AttachmentKind.audio,
      fileName: 'a.m4a',
      mimeType: 'audio/mp4',
    );
    expect(availableViews(audio), {
      AttachmentView.pinned,
      AttachmentView.floating,
      AttachmentView.attached,
    });
    // METİN: dört kipin hepsi (balonlu = A4 belge).
    const text = Attachment(
      id: 't',
      kind: AttachmentKind.text,
      fileName: 't.txt',
      mimeType: 'text/plain',
      text: 'merhaba',
    );
    expect(availableViews(text), {
      AttachmentView.pinned,
      AttachmentView.floating,
      AttachmentView.bubbles,
      AttachmentView.attached,
    });
    const slide = Attachment(
      id: 's',
      kind: AttachmentKind.slide,
      fileName: 's.pptx',
      mimeType: 'application/vnd.ms-powerpoint',
    );
    // SUNUM 2026-10-17'de dört kipe katıldı (kullanıcı isteği: "sunum
    // gibi diğer tipteki dosyalarda gömülü, Sabit, Balonlu, Ek seçeneklerinin
    // hepsi olmalı").
    expect(availableViews(slide), {
      AttachmentView.pinned,
      AttachmentView.floating,
      AttachmentView.bubbles,
      AttachmentView.attached,
    });
  });

  testWidgets('anahtar seçili kipi gösterir, öbürüne tek dokunuşla geçer', (
    tester,
  ) async {
    final picked = <AttachmentView>[];
    await tester.pumpWidget(
      _app(
        Center(
          child: AttachmentViewSwitch(
            current: AttachmentView.floating,
            available: availableViews(image),
            onChanged: picked.add,
          ),
        ),
      ),
    );
    expect(find.text('Sabit'), findsOneWidget);
    expect(find.text('Yüzen'), findsOneWidget);
    expect(find.text('Balonlu'), findsOneWidget);
    // Seçili olana dokunmak hiçbir şey yapmaz.
    await tester.tap(find.text('Yüzen'));
    await tester.tap(find.text('Balonlu'));
    expect(picked, [AttachmentView.bubbles]);
  });

  testWidgets('dar kip yalnız simge çizer ve 360 dp ekrana sığar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        Align(
          alignment: Alignment.topLeft,
          child: AttachmentViewSwitch(
            current: AttachmentView.pinned,
            available: availableViews(image),
            dense: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Sabit'), findsNothing);
    final size = tester.getSize(
      find.byKey(const ValueKey('attachment-view-switch')),
    );
    expect(size.width, lessThan(140));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sayfada seçili görselin panelinde görünüm anahtarı var', (
    tester,
  ) async {
    final changes = <(String, AttachmentView)>[];
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: NotePageCanvas(
              images: const [image],
              minHeight: 800,
              onRemove: (_) {},
              onChanged: (_) {},
              onViewChange: (a, v) => changes.add((a.id, v)),
              child: const SizedBox(width: 400, height: 400),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('page-image-g')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('attachment-view-switch')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('view-pinned')));
    await tester.pump();
    expect(changes.single, ('g', AttachmentView.pinned));
  });

  testWidgets('SÜRÜKLERKEN bantlar her karede bildirilmez, bırakınca gelir', (
    tester,
  ) async {
    // KÖK NEDEN (kullanıcı 2026-10-16: "görseller sürüklenirken aşırı
    // kasma"): her taşıma karesi editörü yeniden kurup metni yeniden
    // sarıyordu.
    final reports = <List<FloatBox>>[];
    await tester.pumpWidget(
      _app(
        SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: NotePageCanvas(
              images: const [image],
              minHeight: 800,
              onRemove: (_) {},
              onChanged: (_) {},
              onFloats: reports.add,
              child: const SizedBox(width: 400, height: 400),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final initial = reports.length;
    final start = tester.getCenter(find.byKey(const ValueKey('page-image-g')));
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    for (var i = 0; i < 12; i++) {
      await gesture.moveBy(const Offset(0, 8));
      await tester.pump(const Duration(milliseconds: 16));
    }
    // Parmak hareket ederken (160 ms dolmadan) hiç bildirim yok.
    expect(reports.length, initial);
    // Parmak DURUNCA metin yeni yere akar.
    await tester.pump(const Duration(milliseconds: 200));
    expect(reports.length, initial + 1);
    expect(reports.last.single.top, greaterThan(300));
    await gesture.up();
    await tester.pump();
  });

  testWidgets('sabit bölmenin çubuğu DAR ekranda taşmaz (video: not al + '
      'bağlantı + anahtar)', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'Video',
      mimeType: 'video/youtube',
      webUrl: 'https://youtu.be/dQw4w9WgXcQ',
      pinHeight: 180,
    );
    var noted = 0;
    await tester.pumpWidget(
      _app(
        PinnedMediaPane(
          media: video,
          onHeightChanged: (_) {},
          onUnpin: () {},
          onOpen: () {},
          onCopyLink: () {},
          onNoteAt: () => noted++,
          viewSwitch: AttachmentViewSwitch(
            current: AttachmentView.pinned,
            available: availableViews(video),
            dense: true,
            onChanged: (_) {},
          ),
          child: const Text('not gövdesi'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('attachment-view-switch')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('pinned-note-at')));
    expect(noted, 1);
  });

  group('görsel → balonlu belge', () {
    test('A4 sayfada görselin çerçevesi (dikey görsel ortalanır)', () {
      final frame = ScanPdf.imageFrameOnPage(1000, 2000);
      expect(frame.top, closeTo(0, 0.001));
      expect(frame.bottom, closeTo(1, 0.001));
      expect(frame.left, greaterThan(0));
      expect(frame.left + frame.right, closeTo(1, 0.001));
    });

    test('çizim ve balonlar sayfanın uzayına taşınır', () {
      const frame = PageBubbleRect(0.1, 0.2, 0.9, 0.6);
      final ink = placeInk(const [
        InkStroke(
          page: 0,
          color: 0xFF000000,
          width: 0.01,
          points: [0, 0, 1, 1],
        ),
      ], frame);
      expect(ink.single.page, 1);
      expect(ink.single.points, [0.1, 0.2, 0.9, 0.6]);
      expect(ink.single.width, closeTo(0.008, 1e-9));
      final bubbles = placeBubbles(const [
        PageBubble(id: 'b', page: 0, x: 0.5, y: 0.5),
      ], frame);
      expect(bubbles.single.page, 1);
      expect(bubbles.single.x, closeTo(0.5, 1e-9));
      expect(bubbles.single.y, closeTo(0.4, 1e-9));
    });

    test('türetilmiş belge klasikte gizlenir, balonluda görünür', () {
      const derived = Attachment(
        id: 'd',
        kind: AttachmentKind.pdf,
        fileName: 'g.pdf',
        mimeType: 'application/pdf',
        sourceId: 'g',
      );
      final classic = Note(
        id: 'n',
        title: '',
        body: '',
        type: NoteType.text,
        attachments: const [image, derived],
      );
      expect(classic.hidesDerivedDocument(derived), isTrue);
      expect(classic.hidesDerivedDocument(image), isFalse);
      expect(
        classic.copyWith(type: NoteType.pdf).hidesDerivedDocument(derived),
        isFalse,
      );
      // Kaynak görsel silinince belge sıradan ek gibi görünür.
      expect(
        classic
            .copyWith(attachments: const [derived])
            .hidesDerivedDocument(derived),
        isFalse,
      );
      // Kayıtta da kalır.
      final back = Attachment.fromMap(derived.toMap()..remove('createdAt'));
      expect(back.sourceId, 'g');
    });
  });
}
