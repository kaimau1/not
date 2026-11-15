import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/quick_drop.dart';
import 'package:notlar/features/notes/domain/quick_entry.dart';

/// "Şu nota ekle" hedef çözümü (kullanıcı isteği 2026-11-15), AI'sız.
void main() {
  const titles = [
    'Alışveriş listesi',
    'Market',
    'Yapılacaklar · 15 Kasım',
    'Kitap notları',
  ];
  QuickDropTarget p(String s) => parseDropTarget(s, titles);

  test('iki noktalı biçim', () {
    expect(p('market: süt, ekmek'), (index: 1, content: 'süt, ekmek'));
    expect(p('alışveriş: muz'), (index: 0, content: 'muz'));
    expect(p('yapılacaklar: faturayı öde'), (
      index: 2,
      content: 'faturayı öde',
    ));
  });

  test('yönelme ekiyle söylenen komut', () {
    expect(p('alışveriş listesine süt ekle'), (index: 0, content: 'süt'));
    expect(p('süt yumurta alışveriş listesine ekle'), (
      index: 0,
      content: 'süt yumurta',
    ));
    expect(p('markete ekmek ekle'), (index: 1, content: 'ekmek'));
    expect(p('yapılacaklara faturayı öde ekle'), (
      index: 2,
      content: 'faturayı öde',
    ));
    expect(p('kitap notlarına sayfa 40 ekle'), (index: 3, content: 'sayfa 40'));
  });

  test('İngilizce', () {
    expect(p('add milk to market'), (index: 1, content: 'milk'));
  });

  test('ad yoksa hedef null, komut kelimesi atılır', () {
    expect(p('süt ekmek ekle'), (index: null, content: 'süt ekmek'));
    expect(p('süt, ekmek'), (index: null, content: 'süt, ekmek'));
    // İçerikte geçen kelime (kanıtsız) hedef sayılmaz.
    expect(p('market poşeti al'), (index: null, content: 'market poşeti al'));
  });

  test('listeye ekleme planı: tekrar yok, işaretli olan yeniden açılır', () {
    final plan = planDropIntoList(
      [
        (text: 'Süt', checked: true),
        (text: 'Ekmek', checked: false),
        (text: 'Domates (1 kg)', checked: false),
      ],
      const [
        QuickItem(name: 'Süt'),
        QuickItem(name: 'Ekmek'),
        QuickItem(name: 'Domates', qty: '3 kg'),
        QuickItem(name: 'Muz'),
        QuickItem(name: 'Muz'),
      ],
    );
    expect(plan.texts, ['Muz']);
    expect(plan.uncheck, [0]);
    expect(plan.requantify, {2: 'Domates (3 kg)'});
  });
}
