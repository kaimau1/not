import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';

const _palette = [
  Color(0xFFE57373),
  Color(0xFFFFC94D),
  Color(0xFF81C784),
  Color(0xFF64A5F5),
  Color(0xFFB39DDB),
];

List<InlineSpan> _spans(String text) => richSpans(
  text,
  const TextStyle(fontSize: 16),
  palette: _palette,
  markerColor: const Color(0xFF888888),
);

/// Bir span dizisindeki metinlerin birleşimi — çizilen metin, kaynak metinle
/// BİREBİR aynı uzunlukta olmalı (yoksa imleç kayar).
String _plain(List<InlineSpan> spans) {
  final buffer = StringBuffer();
  for (final s in spans) {
    s.visitChildren((span) {
      if (span is TextSpan) buffer.write(span.text ?? '');
      return true;
    });
  }
  return buffer.toString();
}

void main() {
  group('stripRichMarkers', () {
    test('işaretleri söker, metni korur', () {
      expect(stripRichMarkers('**kalın** ve _italik_'), 'kalın ve italik');
      expect(stripRichMarkers('~altı çizili~'), 'altı çizili');
      expect(stripRichMarkers('==2:vurgu=='), 'vurgu');
      expect(stripRichMarkers('%%2:renkli%%'), 'renkli');
    });

    test(
      'ÖNEKSİZ == biçim değildir — kullanıcının yazdığı eşittirler kalır',
      () {
        // KÖK NEDEN (2026-08-07 / 14. tur): işaretler görünmez çizildiği için
        // öneksiz `==` biçim sanılınca kullanıcının yazdığı eşittirler EKRANDAN
        // kayboluyordu ("if (a == b && c == d)" → "if (a  b  c  d)").
        // Uygulama vurguyu her zaman önekle yazar (`==2:`), yani şart hiçbir
        // gerçek vurguyu kırmaz.
        const code = 'if (a == b && c == d)';
        expect(stripRichMarkers(code), code);
        expect(stripRichMarkers('2**3**4'), '234');
      },
    );

    test('işaretsiz metne dokunmaz', () {
      const text = 'sıradan bir not, 2 * 3 = 6';
      expect(stripRichMarkers(text), text);
    });

    test('kelime içindeki alt çizgi biçim değildir', () {
      const text = 'dosya_adi_uzun.txt';
      expect(stripRichMarkers(text), text);
    });
  });

  group('richSpans', () {
    test('çizilen metin kaynak metinle aynı uzunlukta (imleç kaymaz)', () {
      const text = 'bu **kalın** ve ==2:vurgu== içerir';
      expect(_plain(_spans(text)), text);
    });

    test('kalın parçası kalın çizilir, işaretler GÖRÜNMEZ', () {
      final spans = _spans('**kalın**');
      final texts = <String, TextSpan>{};
      for (final s in spans) {
        s.visitChildren((span) {
          if (span is TextSpan && span.text != null) texts[span.text!] = span;
          return true;
        });
      }
      expect(texts['kalın']?.style?.fontWeight, FontWeight.w700);
      // İşaret karakterleri metinde DURUR (imleç kaymasın) ama saydam ve
      // neredeyse sıfır boyutta çizilir: kullanıcı yalnız biçimli metni görür.
      expect(texts['**']?.style?.color?.a, 0);
      expect(texts['**']?.style?.fontSize, lessThan(1));
    });

    test('renk indeksi paletten seçilir', () {
      final spans = _spans('%%3:yeşil%%');
      Color? found;
      for (final s in spans) {
        s.visitChildren((span) {
          if (span is TextSpan && span.text == 'yeşil') {
            found = span.style?.color;
          }
          return true;
        });
      }
      expect(found, _palette[2]);
    });

    test('biçimsiz metin tek parça döner', () {
      expect(_plain(_spans('düz metin')), 'düz metin');
    });
  });

  group('toggleFormat', () {
    test('seçime işaret ekler ve seçimi içeriğin üstünde tutar', () {
      final r = toggleFormat('merhaba dünya', 8, 13, RichFormat.bold);
      expect(r.text, 'merhaba **dünya**');
      expect(r.text.substring(r.start, r.end), 'dünya');
    });

    test('renkli biçimde indeks öneki yazılır', () {
      final r = toggleFormat(
        'merhaba dünya',
        8,
        13,
        RichFormat.highlight,
        colorIndex: 4,
      );
      expect(r.text, 'merhaba ==4:dünya==');
      expect(r.text.substring(r.start, r.end), 'dünya');
    });

    test('işaretlerle birlikte seçilirse biçim kalkar', () {
      final r = toggleFormat('merhaba **dünya**', 8, 17, RichFormat.bold);
      expect(r.text, 'merhaba dünya');
      expect(r.text.substring(r.start, r.end), 'dünya');
    });

    test('yalnız içerik seçilse de biçim kalkar', () {
      final r = toggleFormat('merhaba **dünya**', 10, 15, RichFormat.bold);
      expect(r.text, 'merhaba dünya');
      expect(r.text.substring(r.start, r.end), 'dünya');
    });

    test('renkli biçim kaldırılırken önek de gider', () {
      final r = toggleFormat('==2:not==', 0, 9, RichFormat.highlight);
      expect(r.text, 'not');
    });

    test('seçim yokken METNE DOKUNULMAZ, biçim bekler', () {
      // 2026-08-06: eskiden buraya boş kutu (`****`) yazılıyordu. Kullanıcı
      // içine bir şey yazmazsa o işaretler notta ham markdown olarak kalıyor,
      // italik/altı çizili kutuları gizleme kalıbında olmadığı için ekranda da
      // görünüyordu. Artık biçim denetleyicide bekler, bir sonraki yazılan
      // metin işaretlerin içine girer.
      final r = toggleFormat('merhaba ', 8, 8, RichFormat.bold);
      expect(r.text, 'merhaba ');
      expect(r.pending, RichFormat.bold);
      expect(r.start, 8);
      expect(r.end, 8);
    });

    test('imleç kalın bir parçanın İÇİNDEYKEN aynı düğme biçimi kaldırır', () {
      // Word davranışı (kullanıcı isteği): "tekrar aynı yere kalınlaştırmaya
      // bastığımda kalkmalı". Seçim gerekmez.
      final r = toggleFormat('merhaba **dünya**', 12, 12, RichFormat.bold);
      expect(r.text, 'merhaba dünya');
      expect(r.start, 10);
    });

    test('iki biçim üst üste binebilir (kalın + renk)', () {
      final bold = toggleFormat('merhaba dünya', 8, 13, RichFormat.bold);
      expect(bold.text, 'merhaba **dünya**');
      // Seçim biçimden SONRA da içeriğin üstünde: ikinci biçim doğrudan
      // verilebilir (eskiden imleç sona toplanıyordu).
      final colored = toggleFormat(
        bold.text,
        bold.start,
        bold.end,
        RichFormat.color,
        colorIndex: 3,
      );
      expect(stripRichMarkers(colored.text), 'merhaba dünya');
      expect(colored.text, contains('%%3:'));
      expect(colored.text, contains('**'));
      // İç içe biçim çizimde de birikir.
      final spans = _spans(colored.text);
      expect(_plain(spans), colored.text);
      TextSpan? content;
      for (final s in spans) {
        s.visitChildren((span) {
          if (span is TextSpan && span.text == 'dünya') content = span;
          return true;
        });
      }
      expect(content?.style?.fontWeight, FontWeight.w700);
      expect(content?.style?.color, _palette[2]);
    });

    test('iki biçimden yalnız biri kaldırılır, diğeri kalır', () {
      final r = toggleFormat('%%3:**dünya**%%', 6, 11, RichFormat.bold);
      expect(stripRichMarkers(r.text), 'dünya');
      expect(r.text.contains('**'), isFalse);
      expect(r.text.contains('%%3:'), isTrue);
    });

    test('seçim işaretin ORTASINDA bitse de biçim doğru aralığa uygulanır', () {
      // Kullanıcı işaretin yarısını da seçmiş olabilir; konum en yakın gerçek
      // karaktere hizalanır (eski kodun "yarım işaret" hatalarının kaynağı).
      final r = toggleFormat('**dünya**', 1, 8, RichFormat.italic);
      expect(stripRichMarkers(r.text), 'dünya');
      expect(r.text, contains('_'));
    });

    test('biçimi temizle: seçimdeki tüm işaretler gider', () {
      final r = clearFormat('a **b** ==2:c== d', 0, 17);
      expect(r.text, 'a b c d');
      expect(r.start, 0);
      expect(r.end, 7);
    });

    test('biçimi temizle: seçim yokken imlecin parçası temizlenir', () {
      final r = clearFormat('a **b** c', 5, 5);
      expect(r.text, 'a b c');
    });

    test('boş biçim kutusu dışa aktarılan metinde görünmez', () {
      expect(stripRichMarkers('not ****'), 'not ');
      expect(stripRichMarkers('not ==3:=='), 'not ');
    });

    test('renkli biçimde imleç kutusu renk önekini taşır', () {
      final r = toggleFormat(
        'not: ',
        5,
        5,
        RichFormat.highlight,
        colorIndex: 3,
      );
      // Kademeli biçimde de metin değişmez; indeks bekleyen biçimle taşınır.
      expect(r.text, 'not: ');
      expect(r.pending, RichFormat.highlight);
      expect(r.pendingIndex, 3);
    });
  });

  group('boyut ve opaklık (satır içi kademe)', () {
    test('seçime kademe yazılır, null kaldırır', () {
      final r = setRangeFormat('merhaba dünya', 8, 13, RichFormat.size, 6);
      expect(r.text, 'merhaba ##6:dünya##');
      expect(r.text.substring(r.start, r.end), 'dünya');
      final back = setRangeFormat(
        r.text,
        r.start,
        r.end,
        RichFormat.size,
        null,
      );
      expect(back.text, 'merhaba dünya');
    });

    test('kademe çizimde boyutu ve alfayı değiştirir', () {
      final spans = richSpans(
        '##9:büyük## ve &&3:solgun&&',
        const TextStyle(fontSize: 16, color: Color(0xFF000000)),
        palette: _palette,
        markerColor: const Color(0xFF888888),
      );
      TextSpan? big;
      TextSpan? faded;
      for (final s in spans) {
        s.visitChildren((span) {
          if (span is TextSpan && span.text == 'büyük') big = span;
          if (span is TextSpan && span.text == 'solgun') faded = span;
          return true;
        });
      }
      expect(big?.style?.fontSize, 16 * kRichSizeSteps.last);
      expect(faded?.style?.color?.a, closeTo(kRichOpacitySteps[2], 0.01));
    });

    test('önek olmadan ## ve && biçim SAYILMAZ (metin kaybolmasın)', () {
      const text = 'a ## b ## c && d && e';
      expect(stripRichMarkers(text), text);
    });

    test('en yakın kademe seçilir', () {
      expect(richStepIndex(kRichSizeSteps, 1.0), kRichSizeDefault);
      expect(richStepIndex(kRichSizeSteps, 1.95), kRichSizeSteps.length);
      expect(richStepIndex(kRichOpacitySteps, 1.0), kRichOpacityDefault);
    });

    test('aralığın ortak kademesi okunur', () {
      expect(rangeFormatIndex('##6:dünya##', 4, 9, RichFormat.size), 6);
      expect(rangeFormatIndex('dünya', 0, 5, RichFormat.size), isNull);
    });
  });

  group('görünmez işaretler', () {
    test('imleç işaretin ortasına düşerse gerçek karaktere çekilir', () {
      // "**dünya**": 0-1 açılış, 2-6 içerik, 7-8 kapanış.
      expect(snapOutOfMarkers('**dünya**', 1), 2);
      expect(snapOutOfMarkers('**dünya**', 1, backward: true), 0);
      expect(snapOutOfMarkers('**dünya**', 8, backward: true), 7);
      // İçerikteki konum olduğu gibi kalır.
      expect(snapOutOfMarkers('**dünya**', 4), 4);
    });

    test('boş biçim kutusunun içi korunur (yazmaya devam edilebilsin)', () {
      // "****" biçim olarak çözümlenmez; imleç ortada kalmalı.
      expect(snapOutOfMarkers('a****', 3), 3);
    });

    test('işaretsiz metne dokunulmaz', () {
      expect(snapOutOfMarkers('sıradan metin', 4), 4);
    });
  });

  group('görünmez işaretlerin üstünde geri silme', () {
    test('işaret yerine gerçek karakter silinir, biçim korunur', () {
      // İmleç kapanış işaretinin ARDINDA: "%%1:merhaba%%" (uzunluk 13),
      // imleç 13. Geri silme bir "%" silerdi ve biçim bozulup işaretler
      // ekranda belirirdi.
      final r = deleteThroughMarkers('%%1:merhaba%%', 13);
      expect(r, isNotNull);
      expect(stripRichMarkers(r!.text), 'merhab');
      expect(r.text, '%%1:merhab%%');
    });

    test('son harf de silinince işaret çifti kendiliğinden düşer', () {
      final r = deleteThroughMarkers('%%1:a%%', 7);
      expect(r!.text, '');
    });

    test('işaret konumu doğru bulunur', () {
      expect(isMarkerOffset('**ab**', 0), isTrue);
      expect(isMarkerOffset('**ab**', 2), isFalse);
      expect(isMarkerOffset('**ab**', 4), isTrue);
      expect(isMarkerOffset('düz metin', 3), isFalse);
    });

    test('boş işaret kutusu GÖRÜNMEZ çizilir', () {
      final spans = _spans('not ****');
      TextSpan? box;
      for (final s in spans) {
        s.visitChildren((span) {
          if (span is TextSpan && span.text == '****') box = span;
          return true;
        });
      }
      expect(box, isNotNull);
      expect(box!.style?.color?.a, 0);
      // Çizilen metin kaynakla aynı uzunlukta kalmalı (imleç kaymasın).
      expect(_plain(spans), 'not ****');
    });
  });

  group('boş kalan işaret çiftleri', () {
    test('iç içe boş işaretler imleçte toplanır', () {
      // "%%1:**_merhaba_**%%" içinden tüm harfler silinince geriye yalnız
      // işaretler kalır; hiçbiri eşleşmediği için DÜZ METİN olarak çizilirdi.
      const left = '%%1:**_';
      const right = '_**%%';
      final r = collapseEmptyMarkersAt('$left$right', left.length);
      expect(r.text, '');
      expect(r.caret, 0);
    });

    test('çevredeki gerçek metne dokunulmaz', () {
      final r = collapseEmptyMarkersAt('a**b**c', 3);
      expect(r.text, 'a**b**c');
      expect(r.caret, 3);
    });

    test('imleç çiftin arasında değilse metne dokunulmaz', () {
      // İmleç "not" kelimesinin içinde: metnin başka yerindeki `__` dizisi
      // (kullanıcının yazdığı olabilir) korunur.
      const text = 'not __ burada **';
      final r = collapseEmptyMarkersAt(text, 2);
      expect(r.text, text);
      expect(r.caret, 2);
    });
  });

  group('kelime sınırı — YAZAN ile OKUYAN aynı dilbilgisi', () {
    // KÖK NEDEN (2026-08-07 / 14. tur): `_` ve `~` kalıpta "iki yanında
    // harf/rakam olmasın" şartı taşıyor ama yazan taraf bunu gözetmiyordu.
    // Kelimenin ORTASINDAN seçip italik yapmak `mer_haba` üretiyor, kalıp
    // eşleştiremiyor ve alt çizgi EKRANDA HAM görünüyordu.
    test('kelime ortasından seçilen italik kelimeye genişler', () {
      final r = toggleFormat('merhaba dunya', 3, 10, RichFormat.italic);
      expect(stripRichMarkers(r.text), 'merhaba dunya');
      expect(r.text.contains('mer_'), isFalse);
      expect(activeFormats(r.text, r.start + 1, r.end - 1).italic, isTrue);
    });

    test('altı çizili de genişler', () {
      final r = toggleFormat('merhaba', 2, 5, RichFormat.underline);
      expect(stripRichMarkers(r.text), 'merhaba');
      expect(r.text, '~merhaba~');
    });

    test('kalın genişlemez (sınır şartı yok)', () {
      final r = toggleFormat('merhaba', 2, 5, RichFormat.bold);
      expect(r.text, 'me**rha**ba');
      expect(stripRichMarkers(r.text), 'merhaba');
    });

    test('zaten sınırda olan seçim büyümez', () {
      final r = toggleFormat('bir iki', 0, 3, RichFormat.italic);
      expect(r.text, '_bir_ iki');
    });
  });
}
