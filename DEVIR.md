# DEVIR — oto/konfor (yürütücüye bırakılan konfor kararları, 2026-11-15)
## Yapılanlar
1. Tablet çekmecesi eşiği %22 → %30 (`AppSwipe.drawerCommitFraction`, app_frame.dart edge onHorizontalDragEnd; diğer yana çekişler %22 kaldı). Test: test/fullscreen_pull_test.dart "çekmece:" (60 dp açmaz — 0.22 ile KIRMIZI, 0.30 ile yeşil; 80 dp açar; fiske açar).
## Sıradaki
2. Küçük telefonda düzen şeridi "Düzenlem…" kısalması (lib/core/widgets/customizable.dart:474 customizeModeTitle).
3. "+" eski düzenleyicisi → customize_hub panosu; quick_add_edit_test kuralları panoya.
## Test
flutter test test/fullscreen_pull_test.dart --reporter failures-only
