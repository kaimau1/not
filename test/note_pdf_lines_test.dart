import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_pdf.dart';

void main() {
  List<String> kinds(String content) => NotePdf.parseLines(
    content,
  ).map((l) => l.kind.name).toList();

  test('onay kutusu işaretleri okunur', () {
    final lines = NotePdf.parseLines('[x] bitti\n[ ] duruyor\n[X] büyük harf');
    expect(
      lines.map((l) => l.kind).toList(),
      [PdfLineKind.checked, PdfLineKind.unchecked, PdfLineKind.checked],
    );
    expect(lines.map((l) => l.text).toList(), [
      'bitti',
      'duruyor',
      'büyük harf',
    ]);
  });

  test('numaralı ve madde imli satırlar ayrılır', () {
    final lines = NotePdf.parseLines('1. ilk\n2) ikinci\n- madde\n• madde2');
    expect(lines.map((l) => l.kind).toList(), [
      PdfLineKind.numbered,
      PdfLineKind.numbered,
      PdfLineKind.bullet,
      PdfLineKind.bullet,
    ]);
    expect(lines.first.marker, '1.');
    expect(lines[1].marker, '2.');
  });

  test('düz metin paragraf kalır', () {
    // "3 kişi geldi" numaralı liste sanılmamalı: rakamdan sonra nokta yok.
    expect(kinds('3 kişi geldi'), ['paragraph']);
    expect(kinds('Bugün hava güzel.'), ['paragraph']);
  });

  test('sondaki boş satırlar atılır, aradakiler durur', () {
    expect(kinds('bir\n\niki\n\n\n'), ['paragraph', 'blank', 'paragraph']);
  });

  test('CRLF satır sonları bölünmeyi bozmaz', () {
    expect(kinds('bir\r\n[x] iki'), ['paragraph', 'checked']);
  });

  test('dosya adı Windows\'ta yasak karakterlerden temizlenir', () {
    expect(NotePdf.safeFileName('Alış/Veriş: liste?'), 'Alış Veriş liste');
    expect(NotePdf.safeFileName('   '), 'not');
    expect(NotePdf.safeFileName('a' * 90).length, 60);
  });
}
