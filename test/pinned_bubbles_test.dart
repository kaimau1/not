import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: child),
);

/// Sabit kipin tek davranışı (kullanıcı bulgusu 2026-11-05: "balonlar
/// taşınamıyor, düzenlenemiyor") ve jest kuralı (kullanıcı kararı
/// 2026-11-05): basılı tut = metin seçimi, çift dokunuş = yakınlaştırma,
/// balon YALNIZ "Balon ekle" düğmesiyle; yazarken alttaki not gizlenir.
void main() {
  const image = Attachment(
    id: 'g',
    kind: AttachmentKind.image,
    fileName: 'g.jpg',
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
    pinHeight: 300,
  );

  Future<List<Attachment>> pump(
    WidgetTester tester,
    Attachment media, {
    VoidCallback? onOpen,
    VoidCallback? onExtractText,
    ValueChanged<bool>? onImmersive,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saved = <Attachment>[];
    var current = media;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => PinnedMediaPane(
            media: current,
            onHeightChanged: (_) {},
            onUnpin: () {},
            onOpen: onOpen ?? () {},
            onExtractText: onExtractText,
            onImmersiveChanged: onImmersive,
            onChanged: (a) {
              saved.add(a);
              setState(() => current = a);
            },
            child: const Text('not gövdesi'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return saved;
  }

  Offset imageCenter(WidgetTester tester) =>
      tester.getCenter(find.byType(PinnedMediaPane)) - const Offset(0, 250);

  testWidgets('basılı tutmak balon BIRAKMAZ, metin seçimini açar', (
    tester,
  ) async {
    var extracted = 0;
    final saved = await pump(tester, image, onExtractText: () => extracted++);
    final gesture = await tester.startGesture(imageCenter(tester));
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    expect(saved.where((a) => a.bubbles.isNotEmpty), isEmpty);
    expect(extracted, 1);
  });

  Future<void> startAdding(WidgetTester tester, {required bool plain}) async {
    // P49 (K-O6): dar çubukta balon seçenekleri TEK ⋮ levhasında; geniş
    // çubukta balon menü düğmesi çubukta.
    final button = find.byKey(const ValueKey('pinned-add-bubble'));
    await tester.tap(
      button.evaluate().isNotEmpty
          ? button
          : find.byKey(const ValueKey('pinned-media-menu')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        ValueKey(plain ? 'pinned-add-bubble-plain' : 'pinned-add-bubble-note'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Balon ekle → Balon: dokunulan yere balon, yazma kartı açılır', (
    tester,
  ) async {
    final saved = await pump(tester, image);
    await startAdding(tester, plain: false);
    // Bırakma kipinin araç kartı görünür.
    expect(find.byKey(const ValueKey('bubble-toolbar-done')), findsOneWidget);
    await tester.tapAt(imageCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(saved.last.bubbles, hasLength(1));
    expect(saved.last.bubbles.single.plain, isFalse);
    expect(find.byKey(const ValueKey('bubble-dock-text')), findsOneWidget);
  });

  testWidgets('Balon ekle → Açık metin: sayfaya doğrudan yazı bırakır', (
    tester,
  ) async {
    final saved = await pump(tester, image);
    await startAdding(tester, plain: true);
    await tester.tapAt(imageCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    expect(saved.last.bubbles.single.plain, isTrue);
  });

  testWidgets('balon yazılırken alttaki not ve çubuk gizlenir, Bitti geri '
      'getirir', (tester) async {
    final immersive = <bool>[];
    await pump(tester, image, onImmersive: immersive.add);
    await startAdding(tester, plain: false);
    await tester.tapAt(imageCenter(tester));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('not gövdesi'), findsNothing);
    expect(find.byKey(const ValueKey('pinned-media-bar')), findsNothing);
    expect(immersive, [true]);
    // Not ağaçta kalır (durumu korunur), yalnız görünmez.
    expect(find.text('not gövdesi', skipOffstage: false), findsOneWidget);
    // Kart bölmenin dibinde (klavyenin üstü) — ekranın alt yarısında.
    final dock = tester.getRect(find.byKey(const ValueKey('bubble-dock-text')));
    expect(dock.center.dy, greaterThan(400));
    await tester.tap(find.byKey(const ValueKey('bubble-dock-done')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.text('not gövdesi'), findsOneWidget);
    expect(find.byKey(const ValueKey('pinned-media-bar')), findsOneWidget);
    expect(immersive, [true, false]);
  });

  testWidgets('çift dokunuş görseli yakınlaştırır, ikincisi geri sığdırır', (
    tester,
  ) async {
    await pump(tester, image);
    double scale() => tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(scale(), closeTo(1, 0.01));
    Future<void> doubleTap() async {
      await tester.tapAt(imageCenter(tester));
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(imageCenter(tester));
      await tester.pump(const Duration(milliseconds: 400));
    }

    await doubleTap();
    expect(scale(), greaterThan(2));
    await doubleTap();
    expect(scale(), closeTo(1, 0.01));
  });

  testWidgets('var olan balon basılı tutulup taşınır', (tester) async {
    final media = image.copyWith(
      bubbles: const [
        PageBubble(
          id: 'b',
          page: 1,
          x: 0.5,
          y: 0.5,
          text: 'merhaba',
          collapsed: true,
        ),
      ],
    );
    final saved = await pump(tester, media);
    final pin = find.byKey(const ValueKey('b'));
    expect(pin, findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(pin));
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();
    expect(saved, isNotEmpty);
    expect(saved.last.bubbles.single.x, greaterThan(0.55));
  });

  testWidgets('açık balon varken dokunuş görüntüleyiciyi açmaz', (
    tester,
  ) async {
    var opened = 0;
    final media = image.copyWith(
      bubbles: const [
        PageBubble(
          id: 'b',
          page: 1,
          x: 0.5,
          y: 0.5,
          text: 'merhaba',
          collapsed: true,
        ),
      ],
    );
    await pump(tester, media, onOpen: () => opened++);
    await tester.tap(find.byKey(const ValueKey('b')));
    await tester.pump(const Duration(milliseconds: 400));
    // Okuma kartında Düzenle var (salt okunur değil).
    expect(find.byKey(const ValueKey('bubble-read-edit')), findsOneWidget);
    // Boşluğa dokunmak kartı kapatır; görüntüleyici açılmaz.
    await tester.tapAt(const Offset(30, 30));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 0);
    // Kapalıyken dokunuş görüntüleyiciyi açar.
    await tester.tapAt(const Offset(30, 30));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opened, 1);
  });
}
