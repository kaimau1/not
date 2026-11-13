import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **SABİT GÖRSELE KALEM** (OTURTMA F63.3, KALEM K2): çizgi görselin `contain`
/// dikdörtgeninde, yakınlaştırma dönüşümünün İÇİNDE — 2,5× yakınken çizilen
/// çizgi 1×'te aynı yerde; var olan çizim de o dikdörtgende boyanır.
void main() {
  // 2:1 görsel, bölme 400×120 → görsel 240×120, x 80…320 (yanlarda boşluk).
  const image = Attachment(
    id: 'g',
    kind: AttachmentKind.image,
    fileName: 'g.jpg',
    mimeType: 'image/jpeg',
    width: 200,
    height: 100,
    pinHeight: 120,
  );
  const rect = Rect.fromLTWH(80, 0, 240, 120);

  setUp(() {
    InkToolMemory.reset();
    InkToolMemory.stylusEver = true;
  });
  tearDown(InkToolMemory.reset);

  Future<List<Attachment>> pump(
    WidgetTester tester,
    Attachment media, {
    bool penActive = false,
    VoidCallback? onOpen,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saved = <Attachment>[];
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
              penActive: penActive,
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
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return saved;
  }

  /// [from]'dan sağa 20 dp'lik çizgi; ilk noktanın oranlı konumu.
  Future<void> draw(
    WidgetTester tester,
    Offset from, {
    PointerDeviceKind kind = PointerDeviceKind.stylus,
  }) async {
    final g = await tester.startGesture(from, kind: kind);
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(5, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    // Kayıt gecikmeli olabilir.
    await tester.pump(const Duration(seconds: 2));
  }

  Offset first(Attachment a) =>
      Offset(a.ink.last.points[0], a.ink.last.points[1]);

  testWidgets('kalem görselin dikdörtgenine yazar; 2,5× yakınken çizilen '
      '1×\'te aynı yerde', (tester) async {
    final saved = await pump(tester, image);
    final origin = tester.getTopLeft(find.byType(PinnedMediaPane));
    // 1×: görselin ortası.
    await draw(tester, origin + rect.center);
    expect(saved, isNotEmpty, reason: 'sabit görsele kalem yazmadı');
    expect(saved.last.ink.single.page, 1);
    expect(first(saved.last).dx, closeTo(0.5, 0.01));
    expect(first(saved.last).dy, closeTo(0.5, 0.01));
    // Parmakla çift dokunuş: ortaya 2,5× yakınlaşır (orta sabit nokta).
    final c = origin + rect.center;
    // Avuç reddi GERÇEK saate bakar (kalemden sonraki 400 ms parmak yutulur).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 500)),
    );
    await tester.tapAt(c);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(c);
    await tester.pump(const Duration(milliseconds: 400));
    final zoom = tester
        .widget<InteractiveViewer>(find.byType(InteractiveViewer))
        .transformationController!
        .value
        .getMaxScaleOnAxis();
    expect(zoom, closeTo(2.5, 0.01));
    // Ekranda ortadan 60 dp sağ = görselde 24 dp sağ = 0,5 + 24/240.
    await draw(tester, c + const Offset(60, 0));
    expect(saved.last.ink, hasLength(2));
    expect(first(saved.last).dx, closeTo(0.6, 0.01));
    expect(first(saved.last).dy, closeTo(0.5, 0.01));
  });

  testWidgets('var olan çizim görselin dikdörtgeninde boyanır (bölmenin '
      'tamamında değil)', (tester) async {
    await pump(
      tester,
      image.copyWith(
        ink: const [
          InkStroke(
            page: 1,
            color: 0xFF000000,
            width: 0.01,
            points: [0.1, 0.1, 0.9, 0.9],
          ),
        ],
      ),
    );
    final painters = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          (w.painter is InkPainter || w.painter is CommittedInkPainter),
    );
    expect(painters, findsOneWidget, reason: 'çizim tam bir kez boyanmalı');
    final origin = tester.getTopLeft(find.byType(PinnedMediaPane));
    final layer = find.ancestor(
      of: painters,
      matching: find.byType(Positioned),
    );
    expect(tester.getRect(layer.first), rect.shift(origin));
  });

  testWidgets('kalem kipinde (kalemsiz cihaz) parmak çizer, görüntüleyici '
      'açılmaz; kip kapalıyken parmak dokunuşu açar', (tester) async {
    InkToolMemory.stylusEver = false;
    var opened = 0;
    final saved = await pump(
      tester,
      image,
      penActive: true,
      onOpen: () => opened++,
    );
    final origin = tester.getTopLeft(find.byType(PinnedMediaPane));
    await draw(tester, origin + rect.center, kind: PointerDeviceKind.touch);
    expect(saved.last.ink, hasLength(1));
    await tester.tapAt(origin + rect.center + const Offset(0, 30));
    await tester.pump(const Duration(seconds: 2));
    expect(opened, 0);
  });

  testWidgets('kalemsiz cihazda kip kapalıyken katman yok: dokunuş '
      'görüntüleyiciyi açar', (tester) async {
    InkToolMemory.stylusEver = false;
    var opened = 0;
    final saved = await pump(tester, image, onOpen: () => opened++);
    final origin = tester.getTopLeft(find.byType(PinnedMediaPane));
    await tester.tapAt(origin + rect.center);
    await tester.pump(const Duration(seconds: 1));
    expect(opened, 1);
    expect(saved, isEmpty);
  });

  testWidgets('editör kökü kurmasa da (bayat ek) yeniden çizim çizgileri '
      'silmez — "silgiye basınca yazılar kayboluyor"', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final saved = <Attachment>[];
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              // Editör gibi: mürekkep kaydı ebeveyni KURMAZ, ek eski kalır.
              return PinnedMediaPane(
                media: image,
                onHeightChanged: (_) {},
                onUnpin: () {},
                onOpen: () {},
                onChanged: saved.add,
                onInkChanged: saved.add,
                child: const Text('not gövdesi'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final origin = tester.getTopLeft(find.byType(PinnedMediaPane));
    await draw(tester, origin + rect.center);
    expect(saved.last.ink, hasLength(1));
    // Silgi düğmesi / kalem düğmesi gibi: bölme eski ekle yeniden çizilir.
    InkToolMemory.eraser = true;
    InkToolMemory.toolChanged();
    rebuild(() {});
    await tester.pump();
    InkToolMemory.eraser = false;
    InkToolMemory.toolChanged();
    rebuild(() {});
    await tester.pump();
    await draw(tester, origin + rect.center + const Offset(0, 30));
    expect(
      saved.last.ink,
      hasLength(2),
      reason: 'yeniden çizimde eski liste geri yazıldı, ilk çizgi silindi',
    );
  });
}
