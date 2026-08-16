import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/link_text.dart';

/// Bağlantı bulucunun tek sınavı: neyi link sayıyor, neyi saymıyor.
/// Yanlış pozitif (dosya adını, sürüm numarasını maviye boyamak) burada
/// yakalanır — kalıp gevşetilirse bu testler düşer.
void main() {
  test('şemalı ve www ile başlayan adresler bulunur', () {
    expect(findLinks('bak https://ornek.com/a?b=1 burada').single.url,
        'https://ornek.com/a?b=1');
    expect(findLinks('www.ornek.com.tr sitesi').single.url, 'www.ornek.com.tr');
  });

  test('çıplak alan adı tanınır, cümle sonu noktası adrese katılmaz', () {
    expect(findLinks('adres ornek.com.').single.url, 'ornek.com');
    expect(findLinks('(bkz. ornek.org)').single.url, 'ornek.org');
  });

  test('link olmayan noktalı metinler link sayılmaz', () {
    for (final text in [
      'rapor.txt',
      'sürüm 1.2.3',
      'Ahmet.Yilmaz',
      'saat 14.30',
      // Noktadan sonra boşluk unutulmuş cümle: iki harfli ülke kodlarıyla
      // çakışan kelimeler linke düşmemeli (bkz. _tldPattern yorumu).
      'bitti.It happens',
      'geldi.At the door',
    ]) {
      expect(findLinks(text), isEmpty, reason: text);
    }
  });

  test('e-posta tümüyle tek parça bulunur, web adresi sanılmaz', () {
    final mail = findLinks('yaz ali.veli@ornek.com.tr bana').single;
    expect(mail.url, 'ali.veli@ornek.com.tr');
    expect(mail.kind, LinkKind.email);
    // KÖK NEDEN sınavı: eskiden yalnız "ornek.com" yakalanıyordu.
    expect(findLinks('info@ornek.com').single.url, 'info@ornek.com');
  });

  test('genişletilen uzantılar ve tr alt alanları tanınır', () {
    for (final entry in {
      'ornek.com.tr': 'ornek.com.tr',
      'kurum.gov.tr': 'kurum.gov.tr',
      'okul.k12.tr': 'okul.k12.tr',
      'magaza.store': 'magaza.store',
      'blog.online/yazi': 'blog.online/yazi',
    }.entries) {
      expect(findLinks(entry.key).single.url, entry.value, reason: entry.key);
    }
  });

  test('soleLink yalnızca metnin tamamı tek adresse döner', () {
    expect(soleLink('  https://a.com  '), 'https://a.com');
    expect(soleLink('site: https://a.com'), isNull);
    expect(soleLink('merhaba'), isNull);
  });

  test('linkAt imlecin üzerindeki adresi verir, dışında null döner', () {
    const text = 'bak https://a.com sonra';
    expect(linkAt(text, 6), 'https://a.com');
    expect(linkAt(text, 17), 'https://a.com'); // adresin bitiş sınırı
    expect(linkAt(text, 1), isNull);
    expect(linkAt(text, 20), isNull);
  });

  test('linkSpans renk verilmezse metni bölmez (ölçüm yolu)', () {
    expect(linkSpans('bak https://a.com', null, null).length, 1);
    expect(linkSpans('bak https://a.com', null, const Color(0xFF0000FF)).length, 2);
  });
}
