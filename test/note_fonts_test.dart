import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/note_fonts.dart';

void main() {
  const base = TextStyle(fontSize: 16);

  test('varsayılan stil değişmeden döner', () {
    expect(applyNoteFont(base, null), base);
    expect(applyNoteFont(base, ''), base);
  });

  test('genel aileler doğrudan uygulanır (çevrimdışı da çalışır)', () {
    expect(applyNoteFont(base, 'serif').fontFamily, 'serif');
    expect(applyNoteFont(base, 'monospace').fontFamily, 'monospace');
    // Taban özellikleri korunur.
    expect(applyNoteFont(base, 'serif').fontSize, 16);
  });

  test('bilinmeyen ad metni yok etmez, stil olduğu gibi kalır', () {
    // Eski bir notta duran ya da elle bozulmuş bir değer geldiğinde metin
    // yine çizilmeli.
    expect(applyNoteFont(base, 'Bu Yazı Tipi Yok 123').fontSize, 16);
  });

  test('listedeki her katalog yazı tipinin çağrısı yazılmış', () {
    // Regresyon kapısı: applyNoteFont ada göre ARAMA yapmaz (o yol APK'yi
    // 8 MB büyütüyordu), her yazı tipini tek tek çağırır. Listeye eklenip
    // çağrısı yazılmayan bir yazı tipi seçicide görünür ama varsayılanla
    // çizilirdi — burada yakalanır. Yazı tipi YÜKLENMEZ: test ağ istemez.
    final listed = kNoteFonts
        .where((f) => f.google)
        .map((f) => f.id)
        .whereType<String>()
        .toSet();
    expect(googleNoteFontIds, containsAll(listed));
    expect(listed, containsAll(googleNoteFontIds),
        reason: 'çağrısı yazılmış ama listede olmayan yazı tipi var');
  });

  test('katalog kısa ve yinelemesiz', () {
    final ids = kNoteFonts.map((f) => f.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'yinelenen yazı tipi');
    expect(ids.first, isNull, reason: 'ilk seçenek varsayılan olmalı');
    // İlk üçü çevrimdışı garanti olanlar.
    expect(ids.take(3), [null, 'serif', 'monospace']);
  });

  test('etiketler: genel aileler çeviriden, katalog kendi adıyla', () {
    expect(
      noteFontLabel(
        null,
        defaultLabel: 'Varsayılan',
        serifLabel: 'Kitap',
        monoLabel: 'Daktilo',
      ),
      'Varsayılan',
    );
    expect(
      noteFontLabel(
        'serif',
        defaultLabel: 'Varsayılan',
        serifLabel: 'Kitap',
        monoLabel: 'Daktilo',
      ),
      'Kitap',
    );
    expect(
      noteFontLabel(
        'Lora',
        defaultLabel: 'Varsayılan',
        serifLabel: 'Kitap',
        monoLabel: 'Daktilo',
      ),
      'Lora',
    );
  });
}
