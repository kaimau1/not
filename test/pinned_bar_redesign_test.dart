import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **SABİT EK ÇUBUĞU BAŞTAN** (P49; OTURTMA F65.1, K-O6):
/// (g) 360/393 dp × 1,3 yazıda çubuk taşmaz; (b) ✏ editörün kalem kipi
/// açıkken de görünür ve kapatınca editöre haber verir; (c) bölmenin kendi
/// kalemi açılınca çubukta silgili hızlı kalem.
void main() {
  const image = Attachment(
    id: 'g',
    kind: AttachmentKind.image,
    fileName: 'g.jpg',
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
    pinHeight: 220,
  );
  const video = Attachment(
    id: 'v',
    kind: AttachmentKind.video,
    fileName: 'Video',
    mimeType: 'video/youtube',
    webUrl: 'https://youtu.be/dQw4w9WgXcQ',
    pinHeight: 180,
  );

  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  Future<void> pump(
    WidgetTester tester,
    Attachment media, {
    double width = 393,
    double textScale = 1,
    bool penActive = false,
    VoidCallback? onPenOff,
  }) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: PinnedMediaPane(
            media: media,
            onHeightChanged: (_) {},
            onUnpin: () {},
            onOpen: () {},
            onChanged: (_) {},
            onNoteAt: () {},
            onCopyLink: () {},
            onRemove: () {},
            penActive: penActive,
            onPenOff: onPenOff,
            child: const Text('not gövdesi'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  for (final width in [360.0, 393.0]) {
    for (final media in [image, video]) {
      testWidgets('${media.kind.name} çubuğu $width dp × 1,3 yazıda taşmaz', (
        tester,
      ) async {
        await pump(tester, media, width: width, textScale: 1.3);
        expect(tester.takeException(), isNull);
        // Dar çubuk: ek işleri, balon ve anahtar tek ⋮ levhasında.
        expect(find.byKey(const ValueKey('pinned-media-menu')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('pinned-media-menu')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('pinned-action-remove')),
          findsOneWidget,
        );
      });
    }
  }

  testWidgets('✏ editörün kalem kipi açıkken de görünür, kapatınca haber '
      'verir', (tester) async {
    var off = 0;
    await pump(tester, image, penActive: true, onPenOff: () => off++);
    final pen = find.byKey(const ValueKey('pinned-pen'));
    expect(pen, findsOneWidget);
    await tester.tap(pen);
    await tester.pump();
    expect(off, 1);
  });

  testWidgets('bölmenin kalemi açılınca çubukta hızlı kalem (silgi, geri al)', (
    tester,
  ) async {
    await pump(tester, image);
    final eraser = find.byKey(const ValueKey('pinned-pen-eraser'));
    expect(eraser, findsNothing);
    await tester.tap(find.byKey(const ValueKey('pinned-pen')));
    await tester.pump();
    expect(eraser, findsOneWidget);
    expect(find.byKey(const ValueKey('pinned-pen-undo')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Kapatınca çubuk eski hâline döner.
    await tester.tap(find.byKey(const ValueKey('pinned-pen')));
    await tester.pump();
    expect(eraser, findsNothing);
    expect(find.byKey(const ValueKey('pinned-note-at')), findsOneWidget);
  });
}
