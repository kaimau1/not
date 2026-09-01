import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// **CANLI DİKTE** ("sesle yazma", kullanıcı isteği 2026-09-01: "sesle yazma
/// çok pratik ve doğru olmalı, kişinin imlecinin olduğu yere yazmalı").
///
/// Sınanan asıl tuzak: cihazın tanıyıcısı her olayda o ana kadarki TAM metni
/// gönderir ve önceki bir kelimeyi SONRADAN düzeltebilir. Gelen parça imlece
/// EKLENSEYDİ metin ikizlenirdi; bu yüzden yazılan aralık her olayda
/// değiştiriliyor.
void main() {
  test('boş tampon: söz imlece yazılır, imleç sözün sonunda kalır', () {
    final first = dictationReplace('', 0, 0, 'merhaba');
    expect(first.text, 'merhaba');
    expect(first.caret, 7);
    expect(first.length, 7);
  });

  test('ardışık olaylar metni İKİZLEMEZ, aralığı değiştirir', () {
    var text = '';
    var length = 0;
    for (final spoken in ['bir', 'bir iki', 'bir iki üç']) {
      final result = dictationReplace(text, 0, length, spoken);
      text = result.text;
      length = result.length;
    }
    expect(text, 'bir iki üç');
  });

  test('tanıyıcı kelimeyi DÜZELTİRSE eski hâli metinde kalmaz', () {
    final first = dictationReplace('', 0, 0, 'bir');
    final second = dictationReplace(first.text, 0, first.length, 'birkaç');
    expect(second.text, 'birkaç');
  });

  test('cümlenin ORTASINA konuşmak kelimeye yapışmaz', () {
    // İmleç "Bugün" ile "geldim" arasında (5. karakter, boşluğun solunda).
    final result = dictationReplace('Bugün geldim', 5, 0, 'sabah');
    expect(result.text, 'Bugün sabah geldim');
    // İmleç eklenen sözün sonunda: kullanıcı oradan devam eder.
    expect(result.text.substring(0, result.caret), 'Bugün sabah');
  });

  test('dikte aralığının DIŞI korunur (kullanıcı elle yazmış olabilir)', () {
    // Kullanıcı diktenin solunda "Not: " yazdı; dikte 5. karakterden başlıyor.
    const logical = 'Not: bir';
    final result = dictationReplace(logical, 5, 3, 'bir iki');
    expect(result.text, 'Not: bir iki');
  });

  test('boş tanıma olayı metni SİLMEZ', () {
    final result = dictationReplace('merhaba', 0, 7, '   ');
    expect(result.text, 'merhaba');
    expect(result.length, 7);
  });

  test('taşan aralık kırpılır (metin dışarıdan kısalmış olabilir)', () {
    final result = dictationReplace('kısa', 0, 99, 'yeni');
    expect(result.text, 'yeni');
  });
}
