# DEVIR — oto/G4-kalem-ses (P63 G4 = PB3 + PB5)

Yapılanlar:
- PB3 önce üret (commit 1): S42 tabanı 0/0/PenTray 3/_DockTool 77/_Options 7; tur `kalem-*`, `cizim-serit`.
- PB3 (commit 2): pen_tray.dart görünüş+hareket (plan §7.5 Durum). grep önce 3/2/1/3/3/11 → 0/0/0/0/0/0.
  S42 sonra 0/0/3/77/7 (artmadı; çıkışta panelin son örneği korunuyor, yuvayı ValueListenableBuilder boşaltıyor).
  `pen_tray_tools_pref_test` 5 kırmızı → yeşil; pen testleri (43) değişmeden yeşil; design_tokens bütçesi düştü.
  ab_hepsi.py `kalem` evresi (sona; hazırlık yoksa atlanır) — cihazda DENENMEDİ.
- Hipotez §3.1/2 doğrulandı (4/6 çağrı yerinde şerit gövdeyle aynı sütunda/bottomNavigationBar).
- Bulunan hata: tablet bölünmüşte kapsül 150 px taşıyordu (`wide` pencereden) → bölme eninden.
- Sapma SB13: panel iğnesi önizlemenin başında (sağ uçta yüzen kalem düğmesi örtüyordu).

Şu an: PB5 önce üret (S43, dikte tur sahneleri, kırmızı testler).
Test: `flutter test test/pen_tray_tools_pref_test.dart`; `flutter test test/perf_budget_test.dart --plain-name S42`.
