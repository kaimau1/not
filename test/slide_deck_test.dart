import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/slide_deck.dart';

/// "dosya okuyucu" motoru buraya kopyalandığından (archive ^4 / xml ^7'ye
/// uyarlanmış), gerçek bir .pptx'in hâlâ çözülüp çizilebildiğini bir uçtan uca
/// örnekle doğrular — sürüm uyumu kırılırsa bu test düşer.
void main() {
  test('renders a real in-memory pptx to slides', () async {
    final archive = Archive();
    void add(String name, String xml) {
      final data = utf8.encode(xml);
      archive.addFile(ArchiveFile(name, data.length, data));
    }

    add(
      'ppt/presentation.xml',
      '<p:presentation xmlns:p="ppt"><p:sldSz cx="12192000" cy="6858000"/>'
          '</p:presentation>',
    );
    add('ppt/slides/slide1.xml', '''
<p:sld xmlns:p="ppt" xmlns:a="draw">
 <p:cSld><p:spTree>
  <p:sp>
   <p:nvSpPr><p:cNvPr id="2" name="Baslik"/><p:nvPr/></p:nvSpPr>
   <p:spPr>
    <a:xfrm><a:off x="914400" y="457200"/><a:ext cx="4572000" cy="1143000"/></a:xfrm>
    <a:prstGeom prst="rect"/>
    <a:solidFill><a:srgbClr val="FF0000"/></a:solidFill>
   </p:spPr>
   <p:txBody><a:bodyPr anchor="ctr"/>
    <a:p><a:pPr algn="ctr"/><a:r><a:rPr sz="3200" b="1"/><a:t>Merhaba</a:t></a:r></a:p>
   </p:txBody>
  </p:sp>
 </p:spTree></p:cSld>
</p:sld>''');

    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
    final slides = await SlideDeck.fromBytes(bytes);

    expect(slides, hasLength(1));
    final slide = slides.first;
    expect(slide.widthPt, greaterThan(0));
    expect(slide.heightPt, greaterThan(0));
    // Kırmızı dikdörtgen şekil + "Merhaba" metni çözülmeli.
    expect(slide.shapes, isNotEmpty);
    final texts = slide.shapes
        .expand((s) => s.paragraphs)
        .map((p) => p.plainText)
        .join(' ');
    expect(texts, contains('Merhaba'));
    expect(
      slide.shapes.any((s) => s.fill == const Color(0xFFFF0000)),
      isTrue,
    );
  });

  test('empty archive yields no slides', () async {
    final bytes = Uint8List.fromList(ZipEncoder().encode(Archive()));
    expect(await SlideDeck.fromBytes(bytes), isEmpty);
  });
}
