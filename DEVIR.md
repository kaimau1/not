# DEVIR — oto/alt-panel-klavye (S47, alt panel klavye zıplaması)

Yapılanlar:
- c0dda006 S47 önce üret (test/support/keyboard_track.dart + perf_budget_test S47): taban 2/26/65/65/31/1/0
- a) API<35 birleşen bitiş karesi (`_trackEngine` kuyruk ≤ 2×önceki adım+3): oturma sıçraması 1→0
- 4e152c5f b/c kipleri `KeyboardSlide.mode` / `--dart-define=ALT_PANEL_KIP=a|b|c` (varsayılan a)
- tool/perf/panel_kayit.py (cihaz: screenrecord + şablon SAD), README "Alt panel kipleri"; hafıza/kontrol/regresyon/sürüm notu

Kök neden: widget katmanı birebir (S8 0, boy 0); zıplama = onProgress değerlerinin Flutter karelerine 0/1/2 düşmesi (faz kayması). Cihazda doğrulanmadı.
S47 (a/b/c): a 2/26/65/65/29/0/0 · b 0/0/43/85/138/4/0 · c 0/6/46/46/16/0/0 (165 kare gizli)
(geri / takılma / sarsıntı px / maks sapma px / ort sapma px×10 / oturma / boy)
İşe yaramayan: koşulsuz AnimatedOpacity → S17 +1 kurulum/kare (yalnız c'de sarıldı).
Sıradaki: cihazda üç APK + panel_kayit.py (yürütücü) → kip seçimi (sabah bakılacak).
Test: flutter test test/perf_budget_test.dart --plain-name S47
