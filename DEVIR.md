# DEVIR — oto/konfor (yürütücüye bırakılan konfor kararları, 2026-11-15)
## Yapılanlar
1. Tablet çekmecesi eşiği %22 → %30 (`AppSwipe.drawerCommitFraction`, app_frame.dart edge onHorizontalDragEnd; diğer yana çekişler %22 kaldı). Test: test/fullscreen_pull_test.dart "çekmece:" (60 dp açmaz — 0.22 ile KIRMIZI, 0.30 ile yeşil; 80 dp açar; fiske açar).
2. Düzen şeridi başlığı küçük telefonda kesilmesin: KÖK NEDEN customizable.dart _CustomizeStrip Row'unda Flexible(başlık)+Spacer boş alanı YARI YARIYA bölüşüyordu → başlık+hap Expanded'a alındı; yine sığmazsa `customizeModeTitleShort` ("Düzen"/"Edit"), tam ad Semantics'te. Test customize_strip_test "küçük telefonda" (360 dp, SDK Roboto yüklü; eski kodla KIRMIZI). S40 aynı (1/3/3/0/0/0/0/0).
   NOT (sabah bakılacak): testte şeridin tamamı (Bitti dahil) semantik ağaçta YOK — eski sorun mu test düzeneği mi bakılmadı.
3. "+" eski düzenleyicisi (`_QuickAddArranger`) kaldırıldı; "Düzenle" → `showCustomizeHub(addPanel)`. `_AddPanelBoard`: son görünür kilidi (showAppMessage quickAddKeepOne), grup içi sıra, Varsayılana dön, favori şablonlar. quick_add_edit_test panoya taşındı (5 test). `quickAddEditHint` arb'den silindi. Token bütçesi düştü (fontSize 175, alpha 157, iconSize 387, radius 193).
## Kalan
CI yeşili bekleniyor. Main'e birleştirme YOK (yürütücü).
## Test
flutter test test/fullscreen_pull_test.dart test/customize_strip_test.dart test/quick_add_edit_test.dart test/customize_hub_test.dart --reporter failures-only
