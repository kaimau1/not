import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/pdf_copy_text.dart';

/// PDF seciminden panoya giden metnin temizlenmesi. Kurallarin tamami
/// kullanici bulgusundan dogdu (bkz. `pdf_copy_text.dart`).
void main() {
  test('CR+LF tek satir sonuna iner', () {
    expect(cleanPdfCopyText('bir\r\niki'), 'bir iki');
  });

  test('tek satir sonu bosluk olur — satira bolunmus baslik tek satir', () {
    expect(cleanPdfCopyText('Fizik\nMuayene'), 'Fizik Muayene');
  });

  test('paragraf sinirini (2+ satir sonu) korur', () {
    expect(cleanPdfCopyText('Birinci\n\nIkinci'), 'Birinci\nIkinci');
  });

  test('gorunmez karakterler atilir (pdfium tofusu)', () {
    expect(cleanPdfCopyText('a\uFFFEb\u200Bc'), 'abc');
  });

  test('satir sonundaki tireli kelime birlesir', () {
    expect(cleanPdfCopyText('muaye-\nne'), 'muayene');
  });

  test('gercek tireli ad bozulmaz (devam BUYUK harf)', () {
    expect(cleanPdfCopyText('Is-\nKur'), 'Is- Kur');
  });

  test('bosluk kosusu teke iner, kenarlar kirpilir', () {
    expect(cleanPdfCopyText('  a \t  b  '), 'a b');
  });

  test('bos metin oldugu gibi doner', () {
    expect(cleanPdfCopyText(''), '');
  });
}
