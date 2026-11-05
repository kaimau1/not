import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/pdf/ocr_page_text.dart';
import 'package:notlar/features/notes/data/pdf/pdf_page_ocr.dart';
import 'package:pdfrx/pdfrx.dart';

class _FakeDocument implements PdfDocument {
  _FakeDocument(this.sourceName);

  @override
  final String sourceName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePage implements PdfPage {
  _FakePage(this.document, this.pageNumber);

  @override
  final PdfDocument document;

  @override
  final int pageNumber;

  @override
  double get width => 100;

  @override
  double get height => 100;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// "Metin tanınıyor" çipi takılmasın (kullanıcı bulgusu 2026-11-05): sonuç
/// önbelleğe girince dinleyen katmanlar haber alır ve [PdfPageOcr.peek] ile
/// sonucu okur — beklediği iş zaman aşımına düşmüş olsa da.
void main() {
  tearDown(() => PdfPageOcr.debugOcrOverride = null);

  test('sonuç önbelleğe girince completed artar, peek bulur', () async {
    final page = _FakePage(_FakeDocument('notify-a.pdf'), 1);
    final done = Completer<OcrPageText?>();
    PdfPageOcr.debugOcrOverride = (_) => done.future;
    expect(PdfPageOcr.peek(page).found, isFalse);
    final before = PdfPageOcr.completed.value;
    final future = PdfPageOcr.forPage(page);
    await Future<void>.delayed(Duration.zero);
    expect(PdfPageOcr.completed.value, before);
    expect(PdfPageOcr.peek(page).found, isFalse);
    done.complete(null);
    await future;
    expect(PdfPageOcr.completed.value, before + 1);
    final hit = PdfPageOcr.peek(page);
    expect(hit.found, isTrue);
    expect(hit.text, isNull);
  });

  test('başka sayfanın sonucu bu sayfada bulunmaz', () async {
    final doc = _FakeDocument('notify-b.pdf');
    PdfPageOcr.debugOcrOverride = (_) async => null;
    await PdfPageOcr.forPage(_FakePage(doc, 1));
    expect(PdfPageOcr.peek(_FakePage(doc, 1)).found, isTrue);
    expect(PdfPageOcr.peek(_FakePage(doc, 2)).found, isFalse);
  });
}
