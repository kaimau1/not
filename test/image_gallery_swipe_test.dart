import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/image_viewer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Tam ekran görüntüleyicide GALERİ: birden çok görselde yana kaydırarak
/// geçiş (kullanıcı isteği 2026-09-05).
void main() {
  Attachment image(String id) => Attachment(
    id: id,
    kind: AttachmentKind.image,
    fileName: '$id.jpg',
    mimeType: 'image/jpeg',
    width: 100,
    height: 100,
  );

  Future<void> pump(
    WidgetTester tester,
    Attachment open, {
    List<Attachment> gallery = const [],
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ImageViewerScreen(attachment: open, gallery: gallery),
      ),
    );
    await tester.pump();
  }

  testWidgets('tek görselde kaydırma kurulmaz', (tester) async {
    await pump(tester, image('a'));
    expect(find.byType(PageView), findsNothing);
    expect(find.text('1/1'), findsNothing);
  });

  testWidgets('galeri boşsa yine tek sayfa açılır', (tester) async {
    await pump(tester, image('a'), gallery: [image('a')]);
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('açılan ek galeride yoksa tek sayfa açılır', (tester) async {
    // Şeritteki bir PDF'in yanında duran görsel listesi gibi: açılan ek
    // listede yoksa kaydırma kurulmamalı (yoksa yanlış görsel açılırdı).
    await pump(tester, image('x'), gallery: [image('a'), image('b')]);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('x.jpg'), findsOneWidget);
  });

  testWidgets('birden çok görselde kaydırma açılır ve konum yazar', (
    tester,
  ) async {
    final gallery = [image('a'), image('b'), image('c')];
    await pump(tester, gallery[1], gallery: gallery);
    expect(find.byType(PageView), findsOneWidget);
    // Açılış SEÇİLEN görselde: ikinci sayfa.
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('b.jpg'), findsOneWidget);
  });

  testWidgets('yana kaydırınca sonraki görsele geçer', (tester) async {
    final gallery = [image('a'), image('b'), image('c')];
    await pump(tester, gallery[0], gallery: gallery);
    expect(find.text('1/3'), findsOneWidget);
    // Yarım ekranlık sürükleme sayfayı geri yaslardı (PageScrollPhysics en
    // yakın sayfaya oturur): tam sayfa kaydırılır.
    await tester.drag(find.byType(PageView), const Offset(-700, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('b.jpg'), findsOneWidget);
  });

  testWidgets('video ekleri galeriye girmez', (tester) async {
    final video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'v.mp4',
      mimeType: 'video/mp4',
    );
    await pump(tester, image('a'), gallery: [image('a'), video]);
    // Geriye tek görsel kalır → kaydırma yok.
    expect(find.byType(PageView), findsNothing);
  });
}
