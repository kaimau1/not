# DEVIR — oto/konfor (yürütücüye bırakılan konfor kararları, 2026-11-15)
## Yapılanlar
1. Tablet çekmecesi eşiği %22 → %30 (`AppSwipe.drawerCommitFraction`, app_frame.dart edge onHorizontalDragEnd; diğer yana çekişler %22 kaldı). Test: test/fullscreen_pull_test.dart "çekmece:" (60 dp açmaz — 0.22 ile KIRMIZI, 0.30 ile yeşil; 80 dp açar; fiske açar).
2. Düzen şeridi başlığı küçük telefonda kesilmesin: KÖK NEDEN customizable.dart _CustomizeStrip Row'unda Flexible(başlık)+Spacer boş alanı YARI YARIYA bölüşüyordu → başlık+hap Expanded'a alındı; yine sığmazsa `customizeModeTitleShort` ("Düzen"/"Edit"), tam ad Semantics'te. Test customize_strip_test "küçük telefonda" (360 dp, SDK Roboto yüklü; eski kodla KIRMIZI). S40 aynı (1/3/3/0/0/0/0/0).
   NOT (sabah bakılacak): testte şeridin tamamı (Bitti dahil) semantik ağaçta YOK — eski sorun mu test düzeneği mi bakılmadı.
## Sıradaki
3. "+" eski düzenleyicisi → customize_hub panosu; quick_add_edit_test kuralları panoya.
## Test
flutter test test/fullscreen_pull_test.dart --reporter failures-only
