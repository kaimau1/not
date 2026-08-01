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
