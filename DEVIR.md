# DEVIR — P20 Editör çekirdeği (dal `oto/P20-editor-cekirdek`)

**Yapılan (1. evre, Fable, 2026-11-14):** yalnız plan — `KUYRUK_AYRINTI.md` §P20 "Uygulama planı (Fable, 2026-11-14)":
9 mimari karar (M1–M9), 10 adım, alt ajan bölümlemesi, riskler. Ürün kodu ve test DEĞİŞMEDİ.

**Şu anki adım:** 2. evre başlamadı. Sıradaki: **adım 1** (kök kurulum haritası, yalnız test).

**Kök neden / kanıt (ayrıntı planda):**
- S3/S4 satır 23: satır önbelleği anahtarında `reorderIndex`/`orderNumber` (`items_editor.dart`:1985–1986) — kök `setState` değil.
- S1 kök 1, S14 tuval 1: `pureTyping` geri al durumuna ve `pinned/starred`'a bakıyor (`note_editor_screen.dart`:1971–1973, 1857–1858).
- S9 tuval 2: `_formatBarOpen` kök `setState` ile değişiyor (932, 4326, 4575, 4969); `_canvasCache` her kök kurulumda sıfırlanıyor (3018).
- Başlama kapısı tuttu: `budgets.json` S3 23 / S4 23 / S9 2 / S14 1, hepsi hedefin üstünde.

**Bilerek yapılmayan:** tuval bölgesini dosyaya çıkarma (M2), `_sameVisual`'ı tümden silme (M6 — sabah bakılacak),
CLAUDE.md/skill düzenleme (M7 — sabah bakılacak), düzenleme modunda yerinde sürükle-sırala (M8), S2.

**Alt ajanlar:** Tur 1 A: adım 1–2 · Tur 2 B: 3–6 ∥ C (alt dal `oto/P20-artik`): 7–8 · Tur 3: 9–10.

**Test/ölçüm komutları:**
- `"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --reporter failures-only`
- `"C:/src/flutter/bin/flutter.bat" test test/items_editor_row_cache_test.dart --reporter failures-only`
- Cihaz (adım 10): `python -u tool/perf/ab_hepsi.py <A.apk> <B.apk> --altin` (`ab-olcum` skill'i)

**Ölçüm ham sayıları:** henüz yok (adım 1 üretecek).
