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
      expect(stripRichMarkers('==vurgu=='), 'vurgu');
      expect(stripRichMarkers('%%2:renkli%%'), 'renkli');
    });

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

    test('kalın parçası kalın çizilir, işaretler sönük', () {
      final spans = _spans('**kalın**');
      final texts = <String, TextSpan>{};
      for (final s in spans) {
        s.visitChildren((span) {
          if (span is TextSpan && span.text != null) texts[span.text!] = span;
          return true;
        });
      }
      expect(texts['kalın']?.style?.fontWeight, FontWeight.w700);
      expect(texts['**']?.style?.color, const Color(0xFF888888));
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

    test('seçim yokken imlece boş biçim kutusu açılır', () {
      // Biçim düğmesine seçim olmadan basmak: kullanıcı yazmaya devam edince
      // yazdığı biçimli çıksın diye işaretler açılır, imleç ARAYA konur.
      final r = toggleFormat('merhaba ', 8, 8, RichFormat.bold);
      expect(r.text, 'merhaba ****');
      expect(r.start, 10);
      expect(r.end, 10);
      // İmlecin iki yanında işaretin yarısı kalır.
      expect(r.text.substring(0, r.start), 'merhaba **');
      expect(r.text.substring(r.end), '**');
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
      expect(r.text, 'not: ==3:==');
      expect(r.text.substring(0, r.start), 'not: ==3:');
    });
  });
}
