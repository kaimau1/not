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

  // ————————————————————————————————— GERİYE GİTMEYEN YAZIM
  //
  // Kullanıcı bulgusu 2026-09-02 (üç ekran görüntüsüyle): "önce yazıyor,
  // sonra alt satıra yazıyor, sonra geri birleştiriyor gibi düzgün olmayan
  // bir yazma biçimi var; Android'in kendi sesle yazma tuşu gibi basit
  // olmalı." Kural: satır sonları boşluğa iner, kısalan sonuç yok sayılır.

  test('SATIR SONU boşluğa iner — dikte paragraf yazar, liste değil', () {
    // Köprü, duraklamada segmentleri `\n` ile birleştiriyor (bkz.
    // MainActivity.joined); ekranda cümle ikiye bölünmüş görünüyordu.
    expect(
      dictationMerge('', 'söylediklerim\nburaya yaz'),
      'söylediklerim buraya yaz',
    );
    expect(dictationMerge('', 'iki   boşluk'), 'iki boşluk');
  });

  test('KISALAN sonuç yok sayılır — yazılan cümle geri gitmez', () {
    const shown = 'söylediklerim buraya yaz';
    expect(dictationMerge(shown, 'söylediklerim'), shown);
    expect(dictationMerge(shown, 'söylediklerim buraya'), shown);
    // Boş olay da metni silmez.
    expect(dictationMerge(shown, '   '), shown);
  });

  test('UZAYAN ve KUYRUĞU DÜZELTİLEN sonuç yazılır', () {
    expect(dictationMerge('bir', 'bir iki'), 'bir iki');
    // "iki" → "ikizi": kuyruk düzeltmesi kabul edilir.
    expect(dictationMerge('bir iki', 'bir ikizi'), 'bir ikizi');
  });

  test('ilk olay: yazılan yokken gelen metin olduğu gibi girer', () {
    expect(dictationMerge('', 'merhaba'), 'merhaba');
  });

  test('dikte akışı uçtan uca: metin yalnız SONUNDAN uzar', () {
    // Tanıyıcının gerçek dizisi (ekran görüntülerindeki sıra).
    var shown = '';
    var text = '';
    var length = 0;
    for (final spoken in [
      'söylediklerim',
      'söylediklerim buraya yaz',
      'söylediklerim\nburaya yaz',
      'söylediklerim',
    ]) {
      final merged = dictationMerge(shown, spoken);
      if (merged == shown) continue;
      shown = merged;
      final result = dictationReplace(text, 0, length, merged);
      text = result.text;
      length = result.length;
    }
    expect(text, 'söylediklerim buraya yaz');
    expect(text.contains('\n'), isFalse);
  });
}
