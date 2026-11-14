# DEVIR — P20 Editör çekirdeği (dal `oto/P20-editor-cekirdek`)

**Yapılan:**
- 1. evre (Fable): plan `KUYRUK_AYRINTI.md` §P20 "Uygulama planı (Fable, 2026-11-14)" (288ee1b6).
- Adım 1 (991967bb): kök kurulum haritası `test/editor_rebuild_map_test.dart` + OTURTMA Ek A.
- Adım 2 (a865ef1b): S3/S4 satır 23→1 (`_RowSlot` + tutamaçsız düz `ListView`).
- Adım 3 (8c4c9a44): `note_slice.dart` (`NoteSlice`, `LateSafeValue`), `_noteN`, `_undoN` + `_syncUndoN` (EKRAN `_undo`/`_redo`/`_mutate`). S1 kök 1→0, S2 1/1→0/0; geri al → yinele bayat düğme çözüldü (test expect'e çevrildi).
- Adım 4 (63987bd5): yıldız/iğne `NoteSlice` + `TogglePop`, `_sameVisual`'dan pinned/starred çıktı. S14 tuval 1→0. Dilimler S18 ilk kareye +6 → `Customizable` tek StatefulWidget (−11 editör, −3 ana ekran): S18 876→871, S24 930→927.
- Adım 5 (627a4da6): `_formatOpenN` + `_formatPanelL` (kip+hedef); panel/alt çubuk/PopScope dar dinler, 1077/1126 setState'leri kalktı. S9 tuval 2→0 (boy karesi 2). S18 874 (main 876 altında).
- Adım 6: `test/editor_core_guard_test.dart`, kural `docs/hafiza/editor.md`, OTURTMA F64 işaretleri.

**İşe yaramayan:** düz `ValueNotifier` `_noteN`: dispose edilmezse `editor_leak_test` (ChangeNotifier 14→38) kırmızı; edilirse geç yazımda assert → `LateSafeValue`.
Test notunda `updatedAt` yoksa tarih şeridi (yıldız) hiç çizilmez — testte ver.

**Sıradaki: adım 9** (adım 7–8 `oto/P20-artik`'te — titreşim göçü + üst çubuk sırası modeli; birleşince adım 9). Adım 10 cihaz A/B.

**Açık (sabah bakılacak):** M6 `_sameVisual` silinmedi, daraldı; M7 kural CLAUDE.md'ye işlensin mi; tutamaçlı kipte S3/S4 23 kalır; Seç kipine girişte liste türü değişir.
`Customizable` değişikliği (lib/core/widgets) P20-artik ile çakışabilir: yalnız sınıf iç yapısı, API aynı.

**Test komutları:**
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart test/editor_rebuild_map_test.dart test/note_slice_test.dart test/editor_star_pin_slice_test.dart test/format_panel_back_test.dart test/editor_core_guard_test.dart test/editor_leak_test.dart --reporter failures-only`
- Cihaz (adım 10): `python -u tool/perf/ab_hepsi.py <A.apk> <B.apk> --altin` (`ab-olcum` skill'i)
