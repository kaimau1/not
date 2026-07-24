import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/features/notes/data/note_pdf.dart';

/// PDF üretiminin uçtan uca çalıştığını doğrular: font varlık paketinden
/// yüklenebiliyor mu, `pdf` paketi onu kabul ediyor mu, Türkçe karakterler
/// çizim sırasında patlatıyor mu. Gömülü Helvetica ile bu adımların üçü de
/// sessizce yanlış sonuç veriyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Uygulamada bu veriyi flutter_localizations yüklüyor (diğer ekranlar da
  // 'tr' biçimlendirmesini bu sayede kullanabiliyor); test ortamında elle.
  setUpAll(() => initializeDateFormatting('tr'));

  test('Türkçe içerikli not PDF üretir', () async {
    final bytes = await NotePdf.build(
      title: 'Işıklı Ağaçlar — Şubat notu',
      content: '[x] çığır açan iş bitti\n'
          '[ ] ıhlamur ağacı budanacak\n'
          '1. şubat\n'
          '- ğ ü ö ç ş ı İ Ğ Ü Ö Ç Ş\n'
          '\n'
          'Düz paragraf: yağmurlu bir günde ısınmak güzeldir.',
      date: DateTime(2026, 2, 14),
    );

    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    // Font gömülmezse dosya birkaç KB'da kalır; PT Sans altkümesiyle
    // onlarca KB olması gliflerin gerçekten yazıldığını gösterir.
    expect(bytes.length, greaterThan(10000));

    // ELLE BAKMAK İÇİN: PDF_DUMP=<klasör> flutter test test/note_pdf_build_test.dart
    final dump = Platform.environment['PDF_DUMP'];
    if (dump != null && dump.isNotEmpty) {
      File('$dump/ornek-not.pdf').writeAsBytesSync(bytes);
    }
  });

  test('boş içerik de geçerli PDF verir', () async {
    final bytes = await NotePdf.build(title: '', content: '');
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });

  test('görsel nottaki satırına girer, metnin sonuna atılmaz', () async {
    // 1x1 saydam PNG — içeriği önemsiz, yerleşimi ölçülüyor.
    final png = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmM'
      'IQAAAABJRU5ErkJggg==',
    );
    const content = 'birinci satir\nikinci satir\nucuncu satir\ndorduncu satir';
    final ortada = await NotePdf.build(
      title: 'Yerlesim',
      content: content,
      images: [
        ExportImage(
          bytes: png,
          width: 100,
          height: 100,
          mimeType: 'image/png',
          line: 2,
          widthFraction: 0.3,
          align: ExportAlign.right,
        ),
      ],
    );
    final sonda = await NotePdf.build(
      title: 'Yerlesim',
      content: content,
      images: [
        ExportImage(bytes: png, width: 100, height: 100, mimeType: 'image/png'),
      ],
    );
    expect(String.fromCharCodes(ortada.take(5)), '%PDF-');
    // Aynı içerik + aynı görsel farklı YERE konduğunda belge de farklı olur;
    // birebir aynıysa satır bilgisi yok sayılmış demektir.
    expect(ortada.length == sonda.length && ortada[900] == sonda[900], isFalse);
  });
}
