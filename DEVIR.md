# DEVIR — P20 Editör çekirdeği (dal `oto/P20-editor-cekirdek`)

**Yapılan:**
- 1. evre (Fable): plan `KUYRUK_AYRINTI.md` §P20 "Uygulama planı (Fable, 2026-11-14)" (288ee1b6).
- Adım 1 (991967bb): `test/editor_rebuild_map_test.dart` + OTURTMA Ek A "F64.1 haritası". Öngörü tuttu:
  işaretle/Enter kök 1/tuval 1/liste 1/satır 23 · sabitle ve yıldız 1/1/0/0 · biçim aç-kapa 2/2 · ilk harf 1/1 · arama aç 1/1.
  BULGU: metin geri alınınca kök kurulmuyor (`_sameVisual` gövdeye bakmaz) → yinele düğmesi `onPressed: null` bayat kalıyor.
- Adım 2 (a865ef1b): S3 satır 23→1, S4 23→1, S2 ItemsEditor/satır 5/15→1/1 (`budgets.json` mandallandı).
  Kök neden iki katlı: (1) `reorderIndex`/`orderNumber` satır önbelleği anahtarındaydı (`items_editor.dart` `_cachedItemRow`)
  → `_RowSlot` (`items_editor_widgets.dart` sonu); (2) `SliverReorderableList` satırı dizinli `_ReorderableItemGlobalKey`
  ile sarıyor (flutter `widgets/reorderable_list.dart`:1150, 1737) → tutamaç yokken düz `ListView` (`items_editor.dart` "TUTAMAÇ YOKKEN DÜZ LİSTE").

**İşe yaramayan:** yalnız anahtar düzeltmesi (1) → S3/S4 hâlâ 23 (GlobalKey dizin içerdiği için). `findChildIndexCallback` de çözmez (anahtar değişiyor).

**Şu anki adım / sıradaki:** adım 1–2 bitti. **Sıradaki: adım 3** (`_noteN` + `NoteSlice` + `_undoN`; yinele bayat düğme bulgusu da burada çözülür — test ekle).

**Açık (sabah bakılacak):** tutamaçlı kipte (tablet/web, Seç) S3/S4 benzeri 23 kalır; Seç kipine girişte liste türü değişir
(satır öğeleri yeniden kurulur); erişilebilirlik "taşı" eylemleri yalnız tutamaçlı kipte. `items_selection_back_package_test` tap uyarısı (yeşil).

**Bilerek yapılmayan:** M2 (tuval çıkarma), M6 tam silme, M7 CLAUDE.md, M8 yerinde sürükle, S2 ayrı iş değil (adım 2 ile düştü).

**Test komutları:**
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart test/editor_rebuild_map_test.dart test/items_editor_row_cache_test.dart --reporter failures-only`
- Cihaz (adım 10): `python -u tool/perf/ab_hepsi.py <A.apk> <B.apk> --altin` (`ab-olcum` skill'i)
