import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/widgets/delayed_spinner.dart';
import 'package:notlar/core/widgets/fade_in_frame.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/media_loading_cover.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';

/// Yükleme hâlleri (DENEYIM F78.3): gri kutu + anında halka yerine küçük
/// resim + gecikmeli halka; görsel solarak gelir, kutu boyu oynamaz.
void main() {
  Widget host(Widget child) => MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(child: SizedBox(width: 300, height: 200, child: child)),
    ),
  );

  const pdf = Attachment(
    id: 'p',
    kind: AttachmentKind.pdf,
    fileName: 'a.pdf',
    mimeType: 'application/pdf',
  );

  group('MediaLoadingCover (F78.3b)', () {
    testWidgets('küçük resim yok: surfaceContainer + tür simgesi, perde yok, '
        'halka 300 ms sonra', (tester) async {
      await tester.pumpWidget(host(const MediaLoadingCover(attachment: pdf)));
      final scheme = AppTheme.light().colorScheme;
      final boxes = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(MediaLoadingCover),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color);
      expect(boxes, [scheme.surfaceContainer]); // gri kutu / perde yok
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);

      double ring() => tester
          .widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(DelayedSpinner),
              matching: find.byType(AnimatedOpacity),
            ),
          )
          .opacity;
      expect(ring(), 0);
      await tester.pump(const Duration(milliseconds: 301));
      expect(ring(), 1);
      // Bölmeyi doldurur, boyunu kendisi belirlemez.
      expect(
        tester.getSize(find.byType(MediaLoadingCover)),
        const Size(300, 200),
      );
    });

    test('perde yalnız küçük resim varken', () {
      expect(MediaLoadingCover.hasThumb(pdf), isFalse);
      expect(
        MediaLoadingCover.hasThumb(pdf.copyWith(thumbUrl: 'https://x/t.jpg')),
        isTrue,
      );
    });
  });

  group('fadeInFrame (F78.3c)', () {
    testWidgets('eşzamanlı gelen solmaz; geç gelen 0 → 1', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      const child = SizedBox();
      expect(fadeInFrame(ctx, child, 0, true), same(child));
      expect(
        (fadeInFrame(ctx, child, null, false) as AnimatedOpacity).opacity,
        0,
      );
      expect((fadeInFrame(ctx, child, 0, false) as AnimatedOpacity).opacity, 1);
    });
  });

  testWidgets('kart kapağı: görsel gelmeden ve geldikten sonra boy aynı, '
      'görselin en/boy oranında (F78.3c)', (tester) async {
    late File file;
    await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      Canvas(rec).drawRect(
        const Rect.fromLTWH(0, 0, 40, 20),
        Paint()..color = Colors.red,
      );
      final img = await rec.endRecording().toImage(40, 20);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      file = File('${Directory.systemTemp.createTempSync('kapak').path}/a.png')
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
    addTearDown(() {
      try {
        file.parent.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows: çözücü dosyayı hâlâ tutuyor olabilir; geçici klasörde kalır.
      }
    });
    final a = Attachment(
      id: 'i',
      kind: AttachmentKind.image,
      fileName: 'a.png',
      mimeType: 'image/png',
      localPath: file.path,
      width: 40,
      height: 20,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 200, child: CardHeroMedia(attachment: a)),
          ),
        ),
      ),
    );
    final before = tester.getSize(find.byType(CardHeroMedia));
    expect(before.height, 100); // 200 / (40/20)
    // Görsel henüz çözülmedi: görünmez (solarak gelecek).
    expect(
      tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
    );
    double shown() =>
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;
    for (var i = 0; i < 40 && shown() == 0; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    expect(shown(), 1);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getSize(find.byType(CardHeroMedia)), before);
  });
}
