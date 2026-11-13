import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Tablet bulgusu 2026-11-13: "yüzen ek menüsü çok büyük ve yüksek", "ses
/// kaydının yüzen görünümü çok büyük ve yüksek". Geniş sayfada panel TEK
/// SATIR ve sınırlı genişlikte; ses hapı sınırlı genişlik/boyda. Dar
/// sayfada (telefon) eski iki satırlık tam genişlik panel aynen kalır.
void main() {
  Attachment image(String id) => Attachment(
    id: id,
    kind: AttachmentKind.image,
    fileName: '$id.jpg',
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
  );

  Attachment audio(String id) => Attachment(
    id: id,
    kind: AttachmentKind.audio,
    fileName: 'kayit_12s.m4a',
    mimeType: 'audio/mp4',
  );

  Future<void> pumpCanvas(
    WidgetTester tester,
    List<Attachment> images, {
    required double width,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: 900,
            child: NotePageCanvas(
              images: images,
              minHeight: 900,
              onRemove: (_) {},
              onChanged: (_) {},
              onViewChange: (_, _) {},
              child: SizedBox(width: width, height: 400),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> select(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(ValueKey('page-image-$id')));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  testWidgets('tablette ses hapı dar ve alçak', (tester) async {
    await pumpCanvas(tester, [audio('s')], width: 1100);
    final box = tester.getRect(find.byKey(const ValueKey('page-image-s')));
    expect(box.width, lessThanOrEqualTo(kAudioFloatMaxWidth));
    expect(box.height, lessThanOrEqualTo(60));
    expect(box.height, greaterThanOrEqualTo(48));
  });

  testWidgets('tablette yüzen ek paneli tek satır ve sınırlı', (tester) async {
    await pumpCanvas(tester, [image('a')], width: 1100);
    await select(tester, 'a');
    final panel = tester.getRect(find.byKey(const ValueKey('tools-a')));
    expect(panel.width, lessThanOrEqualTo(kWideToolsMaxWidth));
    // Tek satır: kaydırıcı sabit genişlikte, panel bir düğme satırı boyunda.
    expect(panel.height, lessThan(72));
    final slider = tester.getRect(find.byType(Slider));
    expect(slider.width, 160);
    expect(tester.takeException(), isNull);
  });

  testWidgets('telefonda panel iki satır, tam genişlik (değişmedi)', (
    tester,
  ) async {
    await pumpCanvas(tester, [image('a')], width: 400);
    await select(tester, 'a');
    final panel = tester.getRect(find.byKey(const ValueKey('tools-a')));
    expect(panel.width, 384);
    expect(panel.height, greaterThan(72));
  });
}
