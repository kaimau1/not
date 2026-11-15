# DEVIR — oto/G4-kalem-ses (P63 G4 = PB3 + PB5)

Yapılanlar:
- PB3 önce üret: S42 bütçesi (taban 0/0/PenTray 3/_DockTool 77/_Options 7), tur sahneleri
  `kalem-hap/-kapsul/-panel/-sekil-panel/-sutun`, `cizim-serit` ("önce" build/tour_p63_once),
  kırmızı `test/pen_tray_tools_pref_test.dart` (5 kırmızı, PB3 commit'iyle girer).
- grep (pen_tray.dart, PB3 öncesi): easeOutBack 3 · AnimatedSize 2 · AnimatedPositioned 1 ·
  blurRadius 3 · Colors.black 3 · Duration(milliseconds: 11.
- Hipotez (§3.1 bulgu 2): alt şerit drawing_screen'de gövdeyle aynı Flex'te, pdf/slayt/görsel
  görüntüleyicide Scaffold.bottomNavigationBar → panel AnimatedSize'ı gövdeyi HER KAREDE yeniden
  diziyor (4/6 çağrı yeri); pdf_note_pane/slide_note_pane Positioned (etkisiz). DOĞRULANDI.
- Bulgu (tur): matepad-yatay bölünmüşte kapsül Row'u 150 px TAŞIYOR (pen_tray.dart:586) — `wide`
  pencere eninden (MediaQuery) hesaplanıyor, bölme eni değil.

Şu an: PB3 uygulaması.
Sıradaki: PB3 kod → testler → commit; PB5 önce üret (S43, dikte tur sahneleri) → kod.
Test: `flutter test test/pen_tray_tools_pref_test.dart test/perf_budget_test.dart --plain-name S42`.
