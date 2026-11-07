import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_box.dart';

/// 2026-11-07 (kullanıcı: sabit bölmede belgenin üstündeki gri sayfa şeridini
/// "kaldır, özelliklerini bir alt satırla birleştir"). Bekçi: sabit bölme
/// kutuya dış çubuk verir, kutu o durumda kendi yüzen şeridini çizmez.
void main() {
  test('sabit bölme belge kutusuna dış çubuk verir', () {
    final pane = File(
      'lib/features/notes/presentation/editor/pinned_media_pane.dart',
    ).readAsStringSync();
    expect(pane.contains('externalBar: _pdfBar'), isTrue);
    expect(pane.contains('_pdfBar.buildControls(context, width)'), isTrue);
    final box = File('lib/features/notes/presentation/editor/pdf_page_box.dart')
        .readAsStringSync();
    expect(
      box.contains(
        'widget.controls && widget.fitWidth && widget.externalBar == null',
      ),
      isTrue,
    );
  });

  testWidgets('belge açılmadan dış çubuk boş (taşma/çökme yok)', (
    tester,
  ) async {
    final bar = PdfBoxBar();
    addTearDown(bar.dispose);
    late List<Widget> controls;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          controls = bar.buildControls(context, 400);
          return const SizedBox();
        },
      ),
    );
    expect(controls, isEmpty);
    expect(bar.ready, isFalse);
  });
}
