# DEVİR — P06 (F65.8 sabit PDF sürekli dikey kaydırma)

- Yapıldı: F65.8 — `editor/pdf_page_column.dart` (yeni: `PdfPageColumn` tembel dikey liste,
  `pdfColumnOffset`/`pdfColumnPageAt`, `PdfPagePill`); `editor/pdf_page_box.dart` fitWidth kipi
  PageView+sayfa başı SingleChildScrollView yerine sütun; `_onPageScroll`/`_turnVertically` silindi;
  `_externalControls`'tan ‹ n/N › çıktı; hap sağ altta, dokununca atlama levhası.
- Kanıt: `test/pdf_page_column_test.dart` önce derlenmedi (kırmızı), şimdi yeşil (300 sayfada canlı ≤ 5,
  `onPageSettled` her duruşta bir, atlama, hap Opacity'siz, kaynak bekçisi).
- Bekçiler yeşil: pinned_pdf_bar, pdf_on_page_widget, pdf_page_box, ink_editing_guard, pen_single_tool,
  pen_policy, perf_budget (S6/S7 kök kurulum 1), note_screen_chrome, keyboard_jank_guard, pinned_bubbles,
  pinned_keyboard. `flutter analyze` sıfır.
- Belgeler: OTURTMA F65.8 [x], regresyon_listesi satırı, docs/hafiza/ekler_pdf.md, KALEM_PLANI K1 notu.
- Bilinen sınır: ilerlemeli yüklemede üstteki sayfanın boyu sonradan değişirse ofset kayar.
- Kalan: cihazda A/B (`tool/perf/ab_klavye.py`) + 300 sayfalık PDF fırlatma ölçümü — yürütücüde.
- Test: `flutter test test/pdf_page_column_test.dart --reporter failures-only`
