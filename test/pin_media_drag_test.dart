import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// "Üstte video/resim, altta not — görseli sürükleyerek" (2026-10-11):
/// sayfadaki görsel basılı tutulup ekranın TEPESİNE sürüklenince üste
/// sabitlenir; sayfa içinde başka yere bırakmak yalnız taşır.
void main() {
  const img = Attachment(
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

  final hoverItems = <Attachment?>[];

  Future<({List<Attachment> pinned, List<bool> hovers, List<Attachment> moved})>
  pump(WidgetTester tester, {double topLimit = 0}) async {
    final pinned = <Attachment>[];
    final hovers = <bool>[];
    final moved = <Attachment>[];
    hoverItems.clear();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: NotePageCanvas(
                images: const [img],
                minHeight: 800,
                topLimit: topLimit,
                onRemove: (_) {},
                onChanged: moved.add,
                onPinTop: pinned.add,
                onPinHover: hovers.add,
                onPinHoverItem: hoverItems.add,
                child: const SizedBox(width: 400, height: 400),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return (pinned: pinned, hovers: hovers, moved: moved);
  }

  Rect boxOf(WidgetTester tester) =>
      tester.getRect(find.byKey(const ValueKey('page-image-g')));

  testWidgets('tepeye sürüklenip bırakılan görsel üste sabitlenir', (
    tester,
  ) async {
    final r = await pump(tester);
    final start = boxOf(tester).center;
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    // Sayfa içinde yukarı: henüz sabitleme bölgesi değil, görsel taşınıyor.
    for (var i = 1; i <= 8; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    expect(boxOf(tester).top, lessThan(300));
    expect(r.hovers, isEmpty);
    // Ekranın tepesi: bölge.
    await gesture.moveTo(Offset(start.dx, 20));
    await tester.pump();
    expect(r.hovers, [true]);
    await gesture.up();
    await tester.pump();
    expect(r.pinned.single.id, 'g');
    expect(r.hovers.last, isFalse);
    // Editör sürüklenen EKİ de öğrenir (PDF'te şerit "balonlu görünüm"
    // yazar — 2026-10-15).
    expect(hoverItems.first?.id, 'g');
    expect(hoverItems.last, isNull);
    // Sabitlenen görsel ayrıca "taşındı" diye kaydedilmez.
    expect(r.moved, isEmpty);
  });

  testWidgets('sayfa içinde bırakmak yalnız taşır', (tester) async {
    final r = await pump(tester);
    final start = boxOf(tester).center;
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    for (var i = 1; i <= 6; i++) {
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    expect(r.pinned, isEmpty);
    expect(r.moved.single.pageY, greaterThan(300));
  });

  testWidgets('yukarı ZORLAMAK yeter: tepeye kadar gitmek gerekmez', (
    tester,
  ) async {
    // Başlık 200 dp'de bitiyor: görsel 200'ün üstüne çıkamaz.
    final r = await pump(tester, topLimit: 200);
    final start = boxOf(tester).center;
    final gesture = await tester.startGesture(start);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    // Görselin üstü 300'de: parmak 140 dp yukarı → görsel sınırın 40 dp
    // ötesine zorlanıyor; parmak ekranın ORTASINDA (y≈220), tepede değil.
    for (var i = 1; i <= 7; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    expect(r.hovers, [true]);
    await gesture.up();
    await tester.pump();
    expect(r.pinned.single.id, 'g');
  });
}
