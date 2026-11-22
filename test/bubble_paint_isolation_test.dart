import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-11-22: "görsel veya PDF üzerine metin notu
/// yazarken ve yerini sürüklerken inanılmaz kasma". KÖK NEDEN: balon katmanı
/// görsel + çizim katmanıyla aynı `RepaintBoundary`'deydi; her tuşta / her
/// sürükleme karesinde görsel ve bütün kalem çizgileri baştan çiziliyordu
/// (ölçüm: 10 tuş = 70, 10 kare = 50 medya boyaması). Bekçi: balon katmanı
/// kendi katmanında, medya alt ağacı yeniden boyanmaz.
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

  Future<void> pump(WidgetTester tester, Attachment media) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var current = media;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PinnedMediaPane(
              media: current,
              onHeightChanged: (_) {},
              onUnpin: () {},
              onOpen: () {},
              onChanged: (a) => setState(() => current = a),
              child: const Text('not gövdesi'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
  }

  /// Medya alt ağacında (balon katmanı DIŞINDA) boyanan render nesneleri.
  var mediaPaints = 0;
  void startCounting() {
    mediaPaints = 0;
    debugProfilePaintsEnabled = true;
    debugOnProfilePaint = (r) {
      final chain = r.debugCreator?.toString() ?? '';
      if (chain.contains('_FitWidthBox') &&
          !chain.contains('BubblePageLayer') &&
          !chain.contains('_BubblePin')) {
        mediaPaints++;
      }
    };
  }

  void stopCounting() {
    debugProfilePaintsEnabled = false;
    debugOnProfilePaint = null;
  }

  testWidgets('açık metin yazılırken görsel/çizim yeniden boyanmaz', (
    tester,
  ) async {
    await pump(tester, image);
    await tester.tap(find.byKey(const ValueKey('pinned-add-bubble')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: find.byIcon(Icons.text_fields),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tapAt(
      tester.getCenter(find.byType(PinnedMediaPane)) - const Offset(0, 250),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.showKeyboard(find.byKey(const ValueKey('bubble-dock-text')));
    await tester.pump(const Duration(milliseconds: 400));
    startCounting();
    var text = '';
    for (var i = 0; i < 10; i++) {
      text += 'a';
      tester.testTextInput.enterText(text);
      await tester.pump();
    }
    stopCounting();
    // Yalnız kaydırma kutusu + sınırı (tuş başına ≤ 2, eskiden 7).
    expect(mediaPaints, lessThanOrEqualTo(20));
  });

  testWidgets('metin taşınırken görsel/çizim yeniden boyanmaz', (
    tester,
  ) async {
    await pump(
      tester,
      image.copyWith(
        bubbles: const [
          PageBubble(
            id: 'b',
            page: 1,
            x: 0.3,
            y: 0.3,
            text: 'merhaba',
            plain: true,
            collapsed: true,
          ),
        ],
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('b'))),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump(const Duration(milliseconds: 16));
    startCounting();
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(5, 3));
      await tester.pump(const Duration(milliseconds: 16));
    }
    stopCounting();
    expect(mediaPaints, 0);
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
  });
}
