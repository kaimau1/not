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
  ({int? index, String content}) p(String s) {
    final r = parseDropTarget(s, titles);
    return (index: r.index, content: r.content);
  }

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

  // Kullanıcı isteği 2026-11-16: hedef SONDA, kökten eşlenir; baştaki ad
  // içeriktir; başa baş kalan sorulur; art arda maddeler ayrılır.
  group('hedef sonda, kökten', () {
    const notes = [
      'Notlar',
      'Dosyalarımdaki hatalar',
      'Hesaplar Claude',
      'site',
      'ezan vakti',
      'Kanallarım',
    ];
    QuickDropTarget q(String s) => parseDropTarget(s, notes);

    test('"… dosyalara ekle" → Dosyalarımdaki hatalar', () {
      final r = q('dosyalar geliştirme yapılması lazım dosyalara ekle');
      expect(r.index, 1);
      expect(r.content, 'dosyalar geliştirme yapılması lazım');
      expect(r.command, isTrue);
    });

    test('baştaki ad içeriktir (komutsuz)', () {
      final r = q('dosyalar geliştirme yapılması lazım');
      expect(r.index, isNull);
      expect(r.ties, isEmpty);
      expect(r.content, 'dosyalar geliştirme yapılması lazım');
    });

    test('ortada geçen ad içeriktir', () {
      final r = q('siteye bakmak lazım yarın ekle');
      // Başta ekli ad + komut: hedef (Türkçede "markete ekmek ekle" gibi).
      expect(r.index, 3);
      expect(q('yarın siteye bakmak lazım ekle').index, isNull);
    });

    test('iyelik ve yönelme ekleri', () {
      expect(q('yeni video fikri kanallarıma ekle').index, 5);
      expect(q('akşam namazı vaktine ezan vaktine ekle').index, 4);
      expect(q('şifreyi değiştir hesaplara ekle').index, 2);
    });

    test('başa baş kalan sorulur', () {
      final r = parseDropTarget('logo hazırla projeye ekle', const [
        'Proje A',
        'Proje B',
        'Market',
      ]);
      expect(r.index, isNull);
      expect(r.ties, [0, 1]);
      expect(r.content, 'logo hazırla');
    });

    test('art arda maddeler ayrılır, düz "ve" bölmez', () {
      expect(
        quickDropSeparate('süt al bir de faturayı öde ayrıca kargoyu sor'),
        'süt al, faturayı öde, kargoyu sor',
      );
      expect(quickDropSeparate('kaydet ve raporla'), 'kaydet ve raporla');
    });

    test('yapay zekâ yanıtı', () {
      expect(parseAiDropAnswer('2 | süt ekmek', 6), (
        index: 2,
        content: 'süt ekmek',
      ));
      expect(parseAiDropAnswer('yok', 6), isNull);
      expect(parseAiDropAnswer('-1 | x', 6), isNull);
      expect(parseAiDropAnswer('9 | x', 6), isNull);
    });
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
