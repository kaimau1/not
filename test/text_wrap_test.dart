import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontSize: 14, height: 1.4);
  const long =
      'Bir iki uc dort bes alti yedi sekiz dokuz on onbir oniki onuc '
      'ondort onbes onalti onyedi onsekiz ondokuz yirmi yirmibir '
      'yirmiiki yirmiuc yirmidort yirmibes yirmialti yirmiyedi';

  /// Satır BAŞI dolgusu: çapanın önünde birleştirici yoktur.
  int startAnchors(String display) {
    var n = 0;
    for (var i = 0; i < display.length; i++) {
      if (display[i] == kWrapAnchorChar &&
          (i == 0 || display[i - 1] != kWrapGlueChar)) {
        n++;
      }
    }
    return n;
  }

  /// Satır SONU dolgusu: her zaman birleştiriciyle gelir.
  int endAnchors(String display) => kWrapGlueChar.allMatches(display).length;

  test('gorsel yokken plan kimliktir', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [],
    );
    expect(plan.display, long);
    expect(plan.widths, isEmpty);
  });

  test('soldaki gorselin yanindan metin akar, alt satirlar tam genislikte', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 0, right: 120, height: 40)],
    );
    // Kesilen satirlarin basina dolgu konur; metnin kendisi degismez.
    expect(plan.widths, isNotEmpty);
    expect(stripWrapAnchors(plan.display), long);
    expect(plan.widths.every((w) => w == 120), isTrue);
    // Dolgu yalnizca gorselin bandindaki satirlara girer, her satira degil.
    expect(plan.widths.length, lessThanOrEqualTo(4));
    expect(endAnchors(plan.display), 0);
  });

  test('sagdaki gorselin yanindan da metin akar (satir sonu dolgusu)', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 180, right: 300, height: 40)],
    );
    expect(stripWrapAnchors(plan.display), long);
    // Sag kenardaki gorsel satir SONUNA dolgu koydurur, basina degil.
    expect(endAnchors(plan.display), greaterThan(0));
    expect(startAnchors(plan.display), 0);
    expect(plan.widths.every((w) => w == 120), isTrue);
    // Dolgu son kelimeye yapisir: capadan hemen once birlestirici gelir.
    expect(plan.display.contains('$kWrapGlueChar$kWrapAnchorChar'), isTrue);
  });

  test('sagdaki gorselin yani gercekten daralir', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 180, right: 300, height: 40)],
    );
    // Dolgulu ilk satirin metni dar sutuna (180 dp) sigmali.
    final firstLine = plan.display.split(kWrapGlueChar).first;
    final painter = TextPainter(
      text: TextSpan(text: firstLine, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    expect(painter.width, lessThanOrEqualTo(180.0));
    painter.dispose();
  });

  test('sutunu kaplayan gorsel metni altina iter, yanina sikistirmaz', () {
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 0, right: 300, height: 30)],
    );
    // Dolgu satirin tamamini yer -> o satirlara kelime sigmaz, metin altta.
    expect(plan.widths, isNotEmpty);
    expect(plan.widths.every((w) => w == 300), isTrue);
    expect(stripWrapAnchors(plan.display), long);
    // Sonsuz dongu korumasi: gorsel yuksekligi kadar satir, daha fazlasi degil.
    expect(plan.widths.length, lessThanOrEqualTo(4));
  });

  test('sagdaki gorselin altina giren tek uzun kelime asagi iner', () {
    // Satirda kirilacak bosluk yok: saga dolgu konamiyordu ve kelime
    // gorselin ALTINDAN gecip uzerine biniyordu. Beklenen: satir bosaltilir,
    // kelime gorselin altina iner (%25 kuralinin yaptiginin aynisi).
    const tekKelime =
        'olaganustuyuksekcozunurluklugorsellestirmesistemidokumantasyonu';
    final plan = planTextWrap(
      logical: tekKelime,
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 180, right: 300, height: 40)],
    );
    expect(stripWrapAnchors(plan.display), tekKelime);
    expect(
      plan.widths.any((w) => w == 300),
      isTrue,
      reason: 'satir bosaltilmadi, kelime gorselin altinda kaldi',
    );
    expect(startAnchors(plan.display), greaterThan(0));
  });

  test('dar sutuna sigan kisa satir bosuna asagi itilmez', () {
    // Yukaridaki duzeltmenin yan etkisi olmamali: gorselin yanina RAHAT
    // sigan metin yerinde kalir.
    final plan = planTextWrap(
      logical: 'kisa',
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 180, right: 300, height: 40)],
    );
    expect(plan.widths.any((w) => w == 300), isFalse);
  });

  test('bos metinde de soldaki gorsel imleci saga iter', () {
    // Imlec bug'i: metin bosken hic capa yoksa imlec sutunun solunda,
    // gorselin ustunde yanip soner.
    final plan = planTextWrap(
      logical: '',
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 0, right: 120, height: 40)],
    );
    expect(plan.display, kWrapAnchorChar);
    expect(plan.widths, [120]);
    expect(wrapToDisplayOffset(plan.display, 0), 1);
    expect(stripWrapAnchors(plan.display), '');
  });

  /// PLANIN GARANTİSİ: hiçbir görünür karakter görselin bandına giremez.
  ///
  /// Kullanıcı bulgusu 2026-08-10 ("metin modunda görselin altında kalıyor"):
  /// görseller metnin ÜSTÜNE çizildiği için banda giren satır okunmaz olur.
  /// Plan ne yaparsa yapsın (yana kaydırma, satır boşaltma) sonuç bu koşulu
  /// sağlamalı; burada plan ölçülüp harf harf denetleniyor.
  void expectNoOverlap(
    WrapPlan plan,
    List<FloatBox> floats,
    double columnWidth,
  ) {
    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = buildWrapSpan(plan.display, plan.widths, style)
      ..setPlaceholderDimensions([
        for (final w in plan.widths)
          PlaceholderDimensions(
            size: Size(w, wrapAnchorHeight(style)),
            alignment: PlaceholderAlignment.middle,
          ),
      ])
      ..layout(maxWidth: columnWidth);
    for (var i = 0; i < plan.display.length; i++) {
      final ch = plan.display[i];
      // Görünmezler denetim dışı: çapa/birleştirici çizilmez, satır sonundaki
      // BOŞLUK ise sarma sınırının ötesine yerleşir (ekranda bir şey yok).
      if (ch == kWrapAnchorChar ||
          ch == kWrapGlueChar ||
          ch.trim().isEmpty) {
        continue;
      }
      final boxes = painter.getBoxesForSelection(
        TextSelection(baseOffset: i, extentOffset: i + 1),
      );
      for (final box in boxes) {
        for (final f in floats) {
          final vertical = f.top < box.bottom && box.top < f.bottom;
          final horizontal = box.right > f.left + 1 && box.left < f.right - 1;
          expect(
            vertical && horizontal,
            isFalse,
            reason:
                '"$ch" (${box.left.toStringAsFixed(1)}..'
                '${box.right.toStringAsFixed(1)} @ '
                '${box.top.toStringAsFixed(1)}) gorselin bandinda kaldi',
          );
        }
      }
    }
    painter.dispose();
  }

  test('ortadaki gorsel metni yanina sikistirmaz, altina iter', () {
    // Sayfanın ORTASINDAKİ görsel iki yanında da sütunun üçte birinden az yer
    // bırakıyor. Eski eşikte (dörtte bir) metin o şeride sıkışıp
    // "NLDESB/" · "270726/0050/01" gibi parçalara bölünüyordu.
    const orta = FloatBox(top: 0, left: 95, right: 205, height: 40);
    final plan = planTextWrap(
      logical: long,
      style: style,
      columnWidth: 300,
      floats: const [orta],
    );
    expect(stripWrapAnchors(plan.display), long);
    expect(
      plan.widths.any((w) => w == 300),
      isTrue,
      reason: 'satir bosaltilmadi, metin dar seride sikisti',
    );
    expectNoOverlap(plan, const [orta], 300);
  });

  test('hicbir satir gorselin ustune binmez (sol/sag/orta)', () {
    const cases = <List<FloatBox>>[
      [FloatBox(top: 0, left: 0, right: 120, height: 400)],
      [FloatBox(top: 0, left: 180, right: 300, height: 400)],
      [FloatBox(top: 0, left: 95, right: 205, height: 400)],
      [FloatBox(top: 20, left: 0, right: 200, height: 60)],
      [
        FloatBox(top: 0, left: 0, right: 110, height: 60),
        FloatBox(top: 70, left: 190, right: 300, height: 60),
      ],
    ];
    for (final floats in cases) {
      for (final text in [long, 'NLDESB/270726/0050/01', 'kisa bir satir']) {
        final plan = planTextWrap(
          logical: text,
          style: style,
          columnWidth: 300,
          floats: floats,
        );
        expect(stripWrapAnchors(plan.display), text);
        expectNoOverlap(plan, floats, 300);
      }
    }
  });

  test('bos metinde sagdaki gorsel imleci yerinden oynatmaz', () {
    final plan = planTextWrap(
      logical: '',
      style: style,
      columnWidth: 300,
      floats: const [FloatBox(top: 0, left: 180, right: 300, height: 40)],
    );
    expect(plan.display, '');
    expect(plan.widths, isEmpty);
  });

  test('imlec konumu capalar arasinda gidip gelirken korunur', () {
    for (final floats in [
      const [FloatBox(top: 0, left: 0, right: 120, height: 40)],
      const [FloatBox(top: 0, left: 180, right: 300, height: 40)],
    ]) {
      final plan = planTextWrap(
        logical: long,
        style: style,
        columnWidth: 300,
        floats: floats,
      );
      for (final logicalOffset in [0, 1, 25, 60, long.length]) {
        final d = wrapToDisplayOffset(plan.display, logicalOffset);
        expect(
          wrapToLogicalOffset(plan.display, d),
          logicalOffset,
          reason: 'offset $logicalOffset gidis-donus bozuldu',
        );
      }
    }
  });

  test('imlec satir sonu dolgusunun ONUNDE kalir', () {
    const display = 'abc$kWrapGlueChar${kWrapAnchorChar}def';
    // 'abc' bitiminde (mantiksal 3) imlec dolguya atlamamali.
    expect(wrapToDisplayOffset(display, 3), 3);
    // Satir basi dolgusunda ise imlec dolgunun ARDINA gecer.
    expect(wrapToDisplayOffset('${kWrapAnchorChar}abc', 0), 1);
  });

  test('satir basinda geri silme ust satira gecer (dolguyu yemez)', () {
    final c = WrapTextController()
      ..updateLayout(
        floats: const [FloatBox(top: 0, left: 0, right: 120, height: 400)],
        style: style,
        columnWidth: 300,
      );
    c.text = 'birinci\nikinci';
    // Imleci ikinci satirin basina koy (mantiksal 8 = '\n' sonrasi).
    final caret = wrapToDisplayOffset(c.text, 8);
    c.selection = TextSelection.collapsed(offset: caret);
    expect(c.logicalText, 'birinci\nikinci');

    // Geri silme: duzenleyici, imlecin SOLUNDAKI karakteri (satir basi
    // dolgusunu) silen bir deger gonderir.
    final display = c.text;
    c.value = TextEditingValue(
      text: display.replaceRange(caret - 1, caret, ''),
      selection: TextSelection.collapsed(offset: caret - 1),
    );
    // Beklenen: satir sonu silinir, iki satir birlesir.
    expect(c.logicalText, 'birinciikinci');
  });

  test('capa temizleme nota giden govdeyi bozmadan birakir', () {
    const withAnchors =
        'a${kWrapAnchorChar}bc$kWrapGlueChar${kWrapAnchorChar}d';
    expect(stripWrapAnchors(withAnchors), 'abcd');
    expect(stripWrapAnchors('temiz metin'), 'temiz metin');
  });

  test('yeniden dizgi SECIMI korur (yazi tipi degisince secim silinmesin)', () {
    // KOK NEDEN: _reflow her cagrildiginda imleci topluyordu; yazi tipi/boyut
    // degisimi ya da bir gorselin tasinmasi dizgiyi tazeledigi icin kullanici
    // metni seçemiyordu ("yazi tipi degistiginde sayfada yazilari secemiyorum").
    const style = TextStyle(fontSize: 14);
    final c = WrapTextController()
      ..updateLayout(
        floats: const [FloatBox(top: 0, left: 0, right: 120, height: 400)],
        style: style,
        columnWidth: 300,
      );
    c.text = 'birinci satir ve devami';
    // Kullanici 'satir' kelimesini seciyor (mantiksal 8..13).
    c.selection = TextSelection(
      baseOffset: wrapToDisplayOffset(c.text, 8),
      extentOffset: wrapToDisplayOffset(c.text, 13),
    );
    expect(c.selection.isCollapsed, isFalse);

    // Yazi tipi degisti: ayni metin, YENI stil.
    c.updateLayout(
      floats: const [FloatBox(top: 0, left: 0, right: 120, height: 400)],
      style: const TextStyle(fontSize: 18),
      columnWidth: 300,
    );
    expect(c.selection.isCollapsed, isFalse, reason: 'secim silinmemeli');
    final display = c.text;
    expect(
      wrapToLogicalOffset(display, c.selection.start),
      8,
    );
    expect(wrapToLogicalOffset(display, c.selection.end), 13);
  });

  test('setLogical secimi verilen araliga tasir (bicim uygulandiktan sonra)', () {
    const style = TextStyle(fontSize: 14);
    final c = WrapTextController()
      ..updateLayout(
        floats: const [FloatBox(top: 0, left: 0, right: 120, height: 400)],
        style: style,
        columnWidth: 300,
      );
    c.text = 'merhaba dunya';
    c.setLogical('merhaba **dunya**', 10, 15);
    expect(c.logicalText, 'merhaba **dunya**');
    final display = c.text;
    expect(wrapToLogicalOffset(display, c.selection.start), 10);
    expect(wrapToLogicalOffset(display, c.selection.end), 15);
  });

  /// KÖK NEDEN (kullanıcı 2026-08-09: "imleç resim varken sorunlu, resmin
  /// solunda ama yazmaya başlayınca sağa yazdı"): dolgu kutuları yüksekliği
  /// SIFIR kuruluyordu; imleç ölçümü dejenere kutuyu atlayıp satır başına,
  /// yani görselin üstüne düşüyordu. İmleç, harfin gerçekten gideceği yerde
  /// (dolgunun SAĞINDA) çizilmeli.
  test('imlec soldaki gorselin YANINDA cizilir, ustunde degil', () {
    const style = TextStyle(fontSize: 14, height: 1.4);
    const floats = [FloatBox(top: 0, left: 0, right: 120, height: 400)];
    for (final logical in ['', 'abc']) {
      final plan = planTextWrap(
        logical: logical,
        style: style,
        columnWidth: 300,
        floats: floats,
      );
      expect(plan.widths, isNotEmpty, reason: 'dolgu konmali ($logical)');
      final painter = TextPainter(
        text: buildWrapSpan(plan.display, plan.widths, style),
        textDirection: TextDirection.ltr,
      )..setPlaceholderDimensions([
          for (final w in plan.widths)
            PlaceholderDimensions(
              size: Size(w, wrapAnchorHeight(style)),
              alignment: PlaceholderAlignment.middle,
            ),
        ]);
      painter.layout(maxWidth: 300);
      // Metnin ilk harfinin (ya da bos alanda imlecin) mantiksal 0 konumu.
      final caret = painter.getOffsetForCaret(
        TextPosition(offset: wrapToDisplayOffset(plan.display, 0)),
        Rect.zero,
      );
      painter.dispose();
      expect(
        caret.dx,
        greaterThanOrEqualTo(120),
        reason: 'imlec gorselin ustunde kaliyor ($logical)',
      );
    }
  });

  test('dolgu kutusunun yuksekligi satiri buyutmez', () {
    const style = TextStyle(fontSize: 14, height: 1.4);
    // Ayni metin, dolgulu ve dolgusuz: satir yuksekligi degismemeli.
    TextPainter build(List<FloatBox> floats) {
      final plan = planTextWrap(
        logical: 'abc',
        style: style,
        columnWidth: 300,
        floats: floats,
      );
      final painter = TextPainter(
        text: buildWrapSpan(plan.display, plan.widths, style),
        textDirection: TextDirection.ltr,
      )..setPlaceholderDimensions([
          for (final w in plan.widths)
            PlaceholderDimensions(
              size: Size(w, wrapAnchorHeight(style)),
              alignment: PlaceholderAlignment.middle,
            ),
        ]);
      painter.layout(maxWidth: 300);
      return painter;
    }

    final plain = build(const []);
    final padded = build(const [
      FloatBox(top: 0, left: 0, right: 120, height: 400),
    ]);
    expect(padded.height, plain.height);
    plain.dispose();
    padded.dispose();
  });
}
