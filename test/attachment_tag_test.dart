import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/attachment_tag.dart';
import 'package:notlar/core/utils/link_text.dart';

/// Metin içi ek etiketinin tek sınavı: neyi ek sayıyor, neyi saymıyor ve
/// çizilen metin ham metinle aynı uzunlukta kalıyor mu (imleç kaymasın).
void main() {
  test('yalnız GERÇEKTEN var olan ek adları etiket sayılır', () {
    const text = 'bak 📎 rapor.pdf ve 📎 olmayan.pdf sonu';
    final tags = findAttachmentTags(text, ['rapor.pdf']);
    expect(tags.length, 1);
    expect(tags.single.fileName, 'rapor.pdf');
    expect(text.substring(tags.single.start, tags.single.end), '📎 rapor.pdf');
  });

  test('ataçsız dosya adı etiket DEĞİLDİR', () {
    expect(findAttachmentTags('rapor.pdf dosyası', ['rapor.pdf']), isEmpty);
  });

  test('uzun ad kısa adın önüne geçer', () {
    final tags = findAttachmentTags('📎 rapor.pdf.bak', [
      'rapor.pdf',
      'rapor.pdf.bak',
    ]);
    expect(tags.single.fileName, 'rapor.pdf.bak');
  });

  test('attachmentTagAt imlecin üzerindeki eki verir', () {
    const text = 'önce 📎 a.jpg sonra';
    // "📎" tek bir kod noktası değil (U+1F4CE, çift birim) — konumlar
    // metnin KENDİ indeksleriyle hesaplanmalı.
    final tag = findAttachmentTags(text, ['a.jpg']).single;
    expect(attachmentTagAt(text, tag.start, ['a.jpg']), 'a.jpg');
    expect(attachmentTagAt(text, tag.end, ['a.jpg']), 'a.jpg');
    expect(attachmentTagAt(text, 0, ['a.jpg']), isNull);
    expect(attachmentTagAt(text, text.length, ['a.jpg']), isNull);
  });

  test('etiket ayrı bir span olarak çizilir ve metin bütünlüğü bozulmaz', () {
    const text = 'önce 📎 a.jpg sonra';
    final spans = linkSpans(
      text,
      null,
      const Color(0xFF0000FF),
      attachmentNames: const ['a.jpg'],
    );
    expect(spans.length, 3);
    // ÇİZİLEN metin ham metinle birebir aynı olmalı: aksi hâlde
    // WrapTextController'da imleç ve seçim konumları kayar.
    final drawn = spans
        .map((s) => (s as TextSpan).text ?? '')
        .join();
    expect(drawn, text);
  });

  test('etiketsiz metinde renk yolu bağlantı davranışını korur', () {
    expect(
      linkSpans('bak https://a.com', null, const Color(0xFF0000FF)).length,
      2,
    );
  });
}
