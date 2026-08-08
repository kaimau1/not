import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/pdf/selection_rects.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:pdfrx/pdfrx.dart';

/// Not balonlari: kayit bicimi, secimden vurguya cevrim ve denetleyicinin
/// ac/kapa mantigi. Jest davranisi (uzun basis + surukleme) cihazin isi;
/// burada VERI dogru mu diye bakiliyor.
void main() {
  group('PageBubble kayit', () {
    test('gidis-donus butun alanlari korur (vurgu ve yildiz dahil)', () {
      const source = PageBubble(
        id: 'b1',
        page: 3,
        x: 0.25,
        y: 0.75,
        title: 'Duzelt',
        text: 'burayi duzelt',
        color: 0xFFEF5350,
        collapsed: true,
        starred: true,
        urgent: true,
        rects: [PageBubbleRect(0.1, 0.2, 0.9, 0.24)],
      );
      final back = PageBubble.fromMap(source.toMap());
      expect(back.id, 'b1');
      expect(back.page, 3);
      expect(back.text, 'burayi duzelt');
      expect(back.color, 0xFFEF5350);
      expect(back.collapsed, isTrue);
      expect(back.starred, isTrue);
      expect(back.title, 'Duzelt');
      expect(back.urgent, isTrue);
      expect(back.rects.single.left, 0.1);
      expect(back.rects.single.bottom, 0.24);
      expect(back.isHighlight, isTrue);
    });

    test('vurgu dikdortgenleri DUZ liste yazilir (Firestore ic ice dizi almaz)',
        () {
      // KOK NEDEN (2026-08-08): dikdortgenler [[l,t,r,b]] olarak yaziliyordu;
      // Firestore ic ice dizi kabul etmez ve o notun YAZIMI TUMUYLE
      // reddediliyordu — kullanici "metin secip balon koyunca kaydolmuyor,
      // geri gidince kayboluyor" dedi. Artik duz liste yaziliyor.
      const bubble = PageBubble(
        id: 'b',
        page: 1,
        x: 0.5,
        y: 0.5,
        rects: [
          PageBubbleRect(0.1, 0.2, 0.9, 0.24),
          PageBubbleRect(0.1, 0.26, 0.6, 0.30),
        ],
      );
      final raw = bubble.toMap()['r'] as List;
      expect(raw.every((v) => v is num), isTrue, reason: 'ic ice dizi olmamali');
      expect(raw, hasLength(8));
      final back = PageBubble.fromMap(bubble.toMap());
      expect(back.rects, hasLength(2));
      expect(back.rects.first.left, 0.1);
      expect(back.rects.last.bottom, 0.30);
    });

    test('ESKI ic ice bicim de okunur (eski kayitlar kaybolmasin)', () {
      final back = PageBubble.fromMap({
        'i': 'b',
        'p': 2,
        'x': 0.3,
        'y': 0.4,
        'r': [
          [0.1, 0.2, 0.9, 0.24],
        ],
      });
      expect(back.rects.single.right, 0.9);
      expect(back.isHighlight, isTrue);
    });

    test('varsayilan alanlar kayda YAZILMAZ — eski sema buyumesin', () {
      const plain = PageBubble(id: 'b', page: 1, x: 0, y: 0);
      final map = plain.toMap();
      expect(map.containsKey('k'), isFalse); // collapsed
      expect(map.containsKey('s'), isFalse); // starred
      expect(map.containsKey('h'), isFalse); // title
      expect(map.containsKey('u'), isFalse); // urgent
      expect(map.containsKey('r'), isFalse); // rects
      expect(PageBubble.fromMap(map).isHighlight, isFalse);
    });

    test('bozuk dikdortgen kaydi coken deger degil sifir verir', () {
      expect(PageBubbleRect.fromList(const [1, 2]).right, 0);
    });
  });

  group('normalizedPageRects', () {
    test('PDF puntosunu sayfa oranina cevirir ve y eksenini ters dondurur', () {
      // PDF koordinati: sol-ALT orijin, top > bottom.
      final out = normalizedPageRects(
        [PdfRect(100, 800, 300, 780)],
        pageWidth: 400,
        pageHeight: 1000,
      );
      final r = out.single;
      expect(r.left, 0.25); // 100/400
      expect(r.right, 0.75); // 300/400
      // Ekran uzayinda top KUCUK olmali (yukari), bottom buyuk.
      expect(r.top, closeTo(0.2, 1e-9)); // 1 - 800/1000
      expect(r.bottom, closeTo(0.22, 1e-9)); // 1 - 780/1000
      expect(r.top, lessThan(r.bottom));
    });

    test('sayfa disina tasan deger 0-1 araligina kistirilir', () {
      final r = normalizedPageRects(
        [PdfRect(-50, 1200, 900, -20)],
        pageWidth: 400,
        pageHeight: 1000,
      ).single;
      expect(r.left, 0);
      expect(r.right, 1);
      expect(r.top, 0);
      expect(r.bottom, 1);
    });

    test('gecersiz sayfa boyutu bos liste verir — sifira bolme yok', () {
      expect(
        normalizedPageRects(
          [PdfRect(0, 10, 10, 0)],
          pageWidth: 0,
          pageHeight: 100,
        ),
        isEmpty,
      );
    });
  });

  group('BubbleController', () {
    BubbleController build({List<PageBubble> initial = const []}) {
      final saved = <List<PageBubble>>[];
      return BubbleController(initial: initial, onChanged: saved.add);
    }

    test('vurgu ekleme: ucu son satirin altina oturur', () {
      final c = build();
      c.addHighlight(
        page: 2,
        rects: const [
          PageBubbleRect(0.1, 0.2, 0.9, 0.24),
          PageBubbleRect(0.1, 0.26, 0.5, 0.30),
        ],
        open: true,
      );
      final bubble = c.bubbles.single;
      expect(bubble.page, 2);
      expect(bubble.isHighlight, isTrue);
      expect(bubble.collapsed, isFalse);
      expect(bubble.y, 0.30); // son satirin ALTI
      expect(bubble.x, closeTo(0.3, 1e-9)); // son satirin ortasi
    });

    test('vurgu "acma" kapali istenirse klavye acilmaz', () {
      final c = build();
      c.addHighlight(
        page: 1,
        rects: const [PageBubbleRect(0, 0, 1, 0.1)],
        open: false,
      );
      expect(c.bubbles.single.collapsed, isTrue);
      expect(c.justAdded, isNull);
    });

    test('bos dikdortgen listesi balon URETMEZ', () {
      final c = build();
      c.addHighlight(page: 1, rects: const [], open: true);
      expect(c.bubbles, isEmpty);
    });

    test('collapseAll acik balonlari kapatir, kapaliya dokunmaz', () {
      final c = build(
        initial: const [
          PageBubble(id: 'a', page: 1, x: 0, y: 0),
          PageBubble(id: 'b', page: 1, x: 0, y: 0, collapsed: true),
        ],
      );
      expect(c.collapseAll(), isTrue);
      expect(c.bubbles.every((b) => b.collapsed), isTrue);
      // Ikinci cagri "kapatacak bir sey yok" der: dokunus tuketilmemeli.
      expect(c.collapseAll(), isFalse);
    });

    test('openOnly yalnizca hedefi acar', () {
      final c = build(
        initial: const [
          PageBubble(id: 'a', page: 1, x: 0, y: 0),
          PageBubble(id: 'b', page: 1, x: 0, y: 0, collapsed: true),
        ],
      );
      c.openOnly('b');
      expect(c.byId('a')!.collapsed, isTrue);
      expect(c.byId('b')!.collapsed, isFalse);
      expect(c.justAdded, 'b');
    });

    test('dropEmpty bos SERBEST balonu atar, bos VURGUYU korur', () {
      final c = build(
        initial: const [
          PageBubble(id: 'bos', page: 1, x: 0, y: 0),
          PageBubble(
            id: 'vurgu',
            page: 1,
            x: 0,
            y: 0,
            rects: [PageBubbleRect(0, 0, 1, 0.1)],
          ),
          PageBubble(id: 'yazili', page: 1, x: 0, y: 0, text: 'not'),
        ],
      );
      c.dropEmpty();
      expect(c.bubbles.map((b) => b.id), ['vurgu', 'yazili']);
    });

    test('forPage yalniz o sayfanin balonlarini verir', () {
      final c = build(
        initial: const [
          PageBubble(id: 'a', page: 1, x: 0, y: 0),
          PageBubble(id: 'b', page: 2, x: 0, y: 0),
        ],
      );
      expect(c.forPage(2).single.id, 'b');
    });

    test('updateText dinleyicileri UYANDIRMAZ (yazarken kasma olmasin)', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0)],
      );
      var notified = 0;
      c.addListener(() => notified++);
      c.updateText('a', 'yeni metin');
      expect(c.byId('a')!.text, 'yeni metin');
      expect(notified, 0);
      // Kaydetme yine de yapilabilmeli.
      c.save();
    });

    test('baslik 12 karaktere KIRPILIR — etiket sayfayi kapatmasin', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0)],
      );
      c.updateTitle('a', 'cok uzun bir baslik yazdim');
      expect(c.byId('a')!.title.length, PageBubble.maxTitle);
      expect(c.byId('a')!.title, 'cok uzun bir');
    });

    test('updateTitle de dinleyicileri UYANDIRMAZ (yazarken kasma)', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0)],
      );
      var notified = 0;
      c.addListener(() => notified++);
      c.updateTitle('a', 'Not');
      expect(c.byId('a')!.title, 'Not');
      expect(notified, 0);
    });

    test('openBubble tek acik balonu verir, yoksa null', () {
      final c = build(
        initial: const [
          PageBubble(id: 'a', page: 1, x: 0, y: 0, collapsed: true),
          PageBubble(id: 'b', page: 2, x: 0, y: 0, collapsed: true),
        ],
      );
      expect(c.openBubble, isNull);
      c.openOnly('b');
      expect(c.openBubble!.id, 'b');
      // Ustteki kart hangi balonu duzenledigini buradan biliyor: iki balon
      // ayni anda ACIK OLAMAZ.
      c.openOnly('a');
      expect(c.openBubble!.id, 'a');
      c.collapseAll();
      expect(c.openBubble, isNull);
    });

    test('YAZILI balona dokunmak OKUMA kipinde acar — klavye gelmez', () {
      final c = build(
        initial: const [
          PageBubble(id: 'a', page: 1, x: 0, y: 0, text: 'yazili', collapsed: true),
        ],
      );
      c.openOnly('a');
      expect(c.openBubble!.id, 'a');
      expect(c.editMode, isFalse);
      // "Duzenle" denince yazmaya gecilir.
      c.beginEdit();
      expect(c.editMode, isTrue);
    });

    test('BOS balonda okunacak sey yok — dogrudan yazmaya acilir', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0, collapsed: true)],
      );
      c.openOnly('a');
      expect(c.editMode, isTrue);
    });

    test('yeni balon yazmaya acilir, kapaninca duzenleme biter', () {
      final c = build();
      c.add(1, 0.5, 0.5);
      expect(c.editMode, isTrue);
      c.collapseAll();
      expect(c.editMode, isFalse);
    });

    test('acilan balon bildirilir — goruntuleyici onu ortalayabilsin', () {
      final opened = <String>[];
      final c = build(
        initial: const [
          PageBubble(id: 'a', page: 4, x: 0, y: 0, text: 'x', collapsed: true),
        ],
      )..onOpened = (b) => opened.add(b.id);
      c.openOnly('a');
      c.beginEdit();
      expect(opened, ['a', 'a']);
    });

    test('yazarken revision artar — sayfadaki etiket CANLI degissin', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0)],
      );
      final before = c.revision.value;
      c.updateTitle('a', 'Not');
      c.updateText('a', 'metin');
      expect(c.revision.value, before + 2);
    });

    test('unlem (acil) ac/kapa', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0)],
      );
      c.toggleUrgent('a');
      expect(c.byId('a')!.urgent, isTrue);
      c.toggleUrgent('a');
      expect(c.byId('a')!.urgent, isFalse);
    });

    test('vurgu FOSFORLU renkle dogar, balon rengiyle degil', () {
      final c = build()
        ..setColor(BubbleController.palette[3])
        ..addHighlight(
          page: 1,
          rects: const [PageBubbleRect(0, 0, 1, 0.1)],
          open: false,
        );
      expect(c.bubbles.single.color, BubbleController.highlightPalette.first);
    });

    test('yildiz ac/kapa', () {
      final c = build(
        initial: const [PageBubble(id: 'a', page: 1, x: 0, y: 0)],
      );
      c.toggleStar('a');
      expect(c.byId('a')!.starred, isTrue);
      c.toggleStar('a');
      expect(c.byId('a')!.starred, isFalse);
    });

    test('tasima bildirimi yalniz DURUM degisince gider', () {
      final c = build();
      final events = <bool>[];
      c.onDragChanged = events.add;
      c
        ..setDragging('a')
        ..setDragging('a')
        ..setDragging(null);
      expect(events, [true, false]);
    });
  });
}
