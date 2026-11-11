# DEVİR — P23 (F60.S5) + P25 (F60.S7)

Geçici dosya: iş bitince silinir.

## P23 — klavye açılırken alt panel titriyor/kasıyor

### Kanıt (cihazsız, `test/keyboard_jank_guard_test.dart` S17; 412×915, 18 karelik klavye)
- **Konum doğru:** alt çubuğun alt kenarı HER karede `ekran − max(gezinme payı, klavye)`;
  tekdüze, geri sıçrama yok (metin / liste / sabit PDF). Yani titreme konum hesabından
  değil, pahalı karelerden (kare düşünce klavye ilerler, çubuk bir kare geride kalır).
- **Kare başı yük (önce):** hareket karesinde 84–87 widget kurulumu + 1 yerleşim sınırı
  (Scaffold'ın `RenderCustomMultiChildLayoutBox`'ı) her karede; ilk açılışın ilk karesi
  320 kurulum (hızlı satır o karede sıfırdan kuruluyor); 2. turda bir karede 280.

### Kök neden
1. `note_editor_screen.dart` editör `Scaffold`'ı (`resizeToAvoidBottomInset: false`
   olsa da) `MediaQuery`'ye bağlı: klavyenin HER karesinde Scaffold kendi iskeletini
   (Material, AppBar yuvası, FAB geçişi, her yuvaya yeni `MediaQuery`) yeniden kurar,
   altındaki `SafeArea`'lar ve `KeyboardSwitch` ×3 de. ≈ 75 kurulum / kare boşa.
2. `editor_quick_row.dart` `_KeyboardSwitchState._pick`: hızlı satır İLK klavye
   karesinde kuruluyor (≈ 230 widget) — animasyonun tam başında tek pahalı kare.
3. Yan bulgu (TEST ARTIĞI, klavye değil): `ItemsEditor._growBudget` (16 → hepsi, kare
   başına 2 satır, açılıştan 500 ms sonra) `pumpEditor`'ın 2 karesinden sonra sürüyor;
   `perf_budget_test` S8'in "govde_kurulum 15"i bu (ItemsEditor 5 karede 5 kez).

### Plan
- `lib/core/widgets/keyboard_snap.dart`: `KeyboardInsetScope` — Scaffold'ın ÜSTÜNDE;
  canlı klavye boşluğunu ayrı dar kanaldan (`KeyboardInset.liveOf`) verir, alt ağaca
  KARARLI `MediaQuery` (viewInsets/padding yalnız oturunca değişir) geçirir.
  `KeyboardSnap/Slide/PhaseListener/Switch`, `AttachmentStrip`, seçim çubukları canlı
  kanalı okur.
- Hızlı satır klavyeden ÖNCE (boşta) kurulur.
- Bekçi: S17 (budgets.json) + konum tekdüzeliği.

### Durum
- [x] kırmızı bekçi yazıldı (S17: 320 / 280 / 2 sınır)
- [x] KeyboardInsetScope (S17: ilk kare 320 → 45, hareket 87–96 → 54, editör içi 49 → 7, dizilen 1 → 0)
- [x] hızlı satır ön kurulum + parlama yalnız boyamada
- [x] S8 test artığı → bütçe 0/0; sabit medya bölmesi evreyi bildiriciyle alır
- [x] kabuk ölçüldü: SplitShell/AppFrame Scaffold klavye karesinde kurulmuyor (+≈ 6 / kare, MediaQuery sarmalayıcıları)
- Kalan ≈ 45 / kare çerçevenin: metin seçim tutamağı katmanı (EditableText.didChangeMetrics → updateForScroll)

## P25 — yazarken alt panel gizleme ayarı
- [ ] sıradaki: ayar + kaydırıcılar + TypingBarHide gecikmeleri
