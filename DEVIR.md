# DEVIR — oto/alt-panel-kalici

Yapılanlar:
- Kip c kalıcı (`lib/core/widgets/keyboard_snap.dart` `_KeyboardSlideState`): anında gizleme, odak sinyali (EditableText'e giriş/çıkış geçişi), `KeyboardSlide.quiet` 60 ms sessizlikte belirme; CurvedAnimation/Tween kalktı (`animateTo`).
- Test: `test/perf_budget_test.dart` "S47 kip c: odak…" (eski kodda kırmızı: odak kazanımında alpha 1). `test/support/keyboard_track.dart` `panelAlpha` açıldı.
- Bütçe S47 c_*: takılma 6→0, sarsıntı 46→0, maks sapma 46→0, ort 16→0 (gizli kare 162→210, görünür 84→36).
- Belge: akicilik.md notu, sürüm notu 16 Kasım (tr/en), KONTROL_LISTEM "Telefonda bak".

Kök neden: klavye değeri 1-2 kare geç geliyor + eski solma 67 ms (ilk kareler opak) → kapanış başında panel klavyeden ayrık.
İşe yaramayan: metin→metin odak geçişini sinyal saymak S50 enter_kurulum +2 (566→568) → yalnız geçiş.
Sınır: geri tuşuyla kapanışta odak değişmez (yalnız anında gizleme); daha erken sinyal yerel onStart ister.
Sıradaki: CI yeşil → yürütücü birleştirir; cihazda `tool/perf/panel_kayit.py`.
Test: `flutter test test/perf_budget_test.dart --plain-name S47`
