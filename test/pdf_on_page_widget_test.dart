import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_box.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// PDF'in NOT SAYFASINDAKİ kutusu (kullanıcı isteği 2026-09-06: "PDF'yi
/// sayfaya entegre etme, aynı görsel gibi sayfaya yerleşir").
///
/// Belgeyi ÇİZDİRMEK pdfium ister (testler Linux'ta, oradaki eklenti yok);
/// ölçülen şey kutunun tuvalde YER ALMASI: sayfaya konmuş PDF görselle aynı
/// yoldan yerleşiyor mu, şeritte kalan PDF tuvale sızıyor mu, dosyası
/// olmayan ek çökmek yerine yer tutucu mu gösteriyor.
void main() {
  Attachment pdf({bool onPage = true, int w = 600, int h = 800}) => Attachment(
    id: 'p1',
    kind: AttachmentKind.pdf,
    fileName: 'sozlesme.pdf',
    mimeType: 'application/pdf',
    onPage: onPage,
    width: w,
    height: h,
  );

  Future<void> pumpCanvas(
    WidgetTester tester,
    List<Attachment> attachments,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 800,
            child: NotePageCanvas(
              images: attachments,
              minHeight: 800,
              onRemove: (_) {},
              onChanged: (_) {},
              child: const SizedBox(width: 400, height: 400),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('sayfaya konmuş PDF tuvalde bir KUTU olarak durur', (
    tester,
  ) async {
    await pumpCanvas(tester, [pdf()]);
    expect(find.byType(PdfPageBox), findsOneWidget);
    final box = tester.getRect(find.byKey(const ValueKey('page-image-p1')));
    // Kutu sayfanın oranını alır: 600×800 belge dik durur (ezilmiş kare
    // değil). Genişlik varsayılanı sütunun yarısı.
    expect(box.width, greaterThan(0));
    expect(box.height / box.width, closeTo(800 / 600, 0.01));
  });

  testWidgets('dosyası olmayan PDF çökmez, yer tutucu gösterir', (
    tester,
  ) async {
    await pumpCanvas(tester, [pdf()]);
    // Ne cihazda ne bulutta kopyası var: "henüz senkronlanmadı" yazar.
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
  });

  testWidgets('döndürülmüş kutu YAN YATAR (en-boy takas olur)', (
    tester,
  ) async {
    await pumpCanvas(tester, [pdf().copyWith(pdfTurns: 1)]);
    final box = tester.getRect(find.byKey(const ValueKey('page-image-p1')));
    expect(box.width / box.height, closeTo(800 / 600, 0.01));
  });

  testWidgets('şeritte duran PDF tuvale çıkmaz', (tester) async {
    // Tuval yalnız `floatsOnPage` ekleri alır; bu test o süzgecin PDF
    // tarafını kilitler (eski notların PDF'i sayfanın ortasına düşmesin).
    expect(pdf(onPage: false).floatsOnPage, isFalse);
    await pumpCanvas(tester, const []);
    expect(find.byType(PdfPageBox), findsNothing);
  });
}
