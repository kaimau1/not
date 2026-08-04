import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';

/// Ayar aramasi ALAN degil SATIR duzeyinde suzer: "hiz" arayan kullanici
/// Ses alaninin tamamini degil iki hiz kaydiricisini gormeli.
void main() {
  final area = settingsAreaForTest(
    id: 'sound',
    title: 'Ses',
    summary: '',
    keywords: 'mikrofon okuma dil',
    rows: [
      settingsRowForTest(const SizedBox(key: ValueKey('mode')), title: 'Düğme kipi'),
      settingsRowForTest(const SizedBox(key: ValueKey('rate')), title: 'Okuma hızı'),
      settingsRowForTest(
        const SizedBox(key: ValueKey('foreign')),
        title: 'Yabancı dil hızı',
      ),
      settingsRowForTest(
        const SizedBox(key: ValueKey('lang')),
        title: 'Uygulama dili',
        keywords: 'language',
      ),
    ],
  );

  test('sorgu yokken tüm satırlar görünür', () {
    expect(area.visibleRows(''), hasLength(4));
    expect(area.visible(''), isTrue);
  });

  test('satır başlığı eşleşince YALNIZ o satırlar kalır', () {
    final rows = area.visibleRows('hız');
    expect(rows, hasLength(2));
    expect(
      rows.map((w) => (w.key as ValueKey<String>).value),
      containsAll(['rate', 'foreign']),
    );
  });

  test('ALAN adı arandığında bölümün tamamı gelir', () {
    // "ses" alanın kendi başlığı; kullanıcı bölümü arıyor demektir.
    expect(area.visibleRows('ses'), hasLength(4));
  });

  test('alanın anahtar kelimesi de bölümün tamamını açar', () {
    expect(area.visibleRows('mikrofon'), hasLength(4));
  });

  test('satırın anahtar kelimesinden eşleşme', () {
    final rows = area.visibleRows('language');
    expect(rows, hasLength(1));
    expect((rows.single.key as ValueKey<String>).value, 'lang');
  });

  test('hiçbir şey eşleşmezse alan hiç çizilmez', () {
    expect(area.visible('kriptografi'), isFalse);
    expect(area.visibleRows('kriptografi'), isEmpty);
  });
}
