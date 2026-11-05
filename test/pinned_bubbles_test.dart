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
/// taşınamıyor, düzenlenemiyor; uzun basış metin tanıma yapıyor").
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

  testWidgets('basılı tutmak görsele balon bırakır (kip açmadan)', (
    tester,
  ) async {
    final saved = await pump(tester, image);
    final center =
        tester.getCenter(find.byType(PinnedMediaPane)) - const Offset(0, 250);
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pump();
    expect(saved, isNotEmpty);
    expect(saved.last.bubbles, hasLength(1));
    expect(saved.last.bubbles.single.page, 1);
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
