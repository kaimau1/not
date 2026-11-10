import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/speech_segments.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

void main() {
  const x =
      'ana ekranda çıkan güncelleme şeyleri direkt indirmeye başlıyor '
      'tıklanmadan indirmesin';

  group('collapseRepeatedSegments', () {
    test('kısa kesilen klon (kullanıcı örneği) atılır', () {
      expect(collapseRepeatedSegments('$x\nana ekranda çıkan güncelleme ş'), x);
    });

    test('birebir klon atılır, noktalama/büyük harf farkı sayılmaz', () {
      expect(collapseRepeatedSegments('$x\nAna ekranda, çıkan güncelleme'), x);
      expect(collapseRepeatedSegments('$x\n$x'), x);
    });

    test('önceki cümleyi uzatan yeniden döküm öncekinin yerini alır', () {
      expect(
        collapseRepeatedSegments('$x\n$x ayrıca uygulama kapanıyor'),
        '$x ayrıca uygulama kapanıyor',
      );
    });

    test('bir kelimesi farklı yeniden döküm de klondur', () {
      expect(
        collapseRepeatedSegments(
          '$x\nana ekranda çıkan güncelleme şeylere direkt indirmeye',
        ),
        x,
      );
    });

    test('gerçek yeni cümle korunur', () {
      const t = '$x\nayrıca uygulama otomatik güncellendikten sonra kapanıyor';
      expect(collapseRepeatedSegments(t), t);
      expect(collapseRepeatedSegments('evet\nevet'), 'evet\nevet');
      expect(collapseRepeatedSegments('tek satır'), 'tek satır');
    });
  });

  group('dictationMerge klon geri alınınca', () {
    test('yerli taraf klonu geri alırsa ekrandan da gider', () {
      expect(dictationMerge('$x ana ekranda çıkan güncelleme', x), x);
    });

    test('tanıyıcının sıradan kısalması yine yok sayılır', () {
      expect(dictationMerge('$x ayrıca', x), '$x ayrıca');
    });
  });
}
