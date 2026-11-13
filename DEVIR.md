# DEVIR — P46 Hız: ölçümün bulduğu yavaşlıkları düzelt (dal `oto/P46-hiz-duzelt`)

Kaynak: KUYRUK_AYRINTI.md §P46 (6 cihazsız bekçi bulgusu) + HIZ_PLANI F84 + OTURTMA F60.S2/F60.5/F68.3.
`pinned_media_pane.dart`'a DOKUNMA (P49). Cihaz A/B'yi yürütücü yaptırır (HİÇBİRİ cihazda ölçülmedi).

## Yapılanlar (her biri ayrı commit, bütçe mandalı düşürüldü)
- Bulgu 2 / S25: `note_card_media.dart` thumbUrl dalları `memCacheWidth: 480` — sınırsız çözüm 21 → 0.
- Bulgu 1 / S21: kart önbelleği anahtarı geciktirilmiş `searchActive` (`dashboard_slivers.dart` `cell`) — harf başına 114 → 56.
- Bulgu 3 / S22: `calendar_screen.dart` `_weekPage` önbelleği — WeekPage 3 → 1, toplam 979 → 509.
- Bulgu 4 / S23: `_GridScrollView` + `_holdNarrowCache` (`dashboard_screen.dart`) — en ağır kare 2941 → 2361.
- Bulgu 5 / S9 + jank mandalı 4 → 2: biçim paneli ↔ alt çubuk takasındaki iki `AnimatedSize` kalktı (`note_editor_screen.dart` `_barReturn`); yeni ölçü `govde_boy_karesi` 34 → 2.

## Kök neden / kanıt
- S21 kalan 56: ilk harfte 1600 px kaydırma payındaki canlı kartlar yerinde güncellenir (aramada kart yapısı değişir).
- S23: toplam kart 30 aynı (pay 500 ms sonra boşta genişler, ölçüm penceresi içinde); düşen EN AĞIR KARE.
- Yerelde `folder_strip_fixed_test` 2. test CRLF yüzünden kırmızı (Windows checkout; CI Linux'ta yeşil) — benim değişikliğim değil.

## İşe yaramayanlar
- S21: ızgaraya `ValueKey(searchActive)` (taze kurulum 26 kart) — taze `SliverList` kaydırılmış konumda 0'dan o konuma kadar her kartı kurar; yapılmadı.
- S23: ızgarayı `ValueListenableBuilder`'a sarmak S24 ilk kareyi 930 → 931 yaptı (mandal); öğenin kendisi dinliyor.
- Bulgu 5 ses hapı `AnimatedSize`: testte kayıt eklentisi yok, kanıt üretilemedi → dokunulmadı.

## Şu anki adım (çalışma ağacında, commit'lenmedi)
- Bulgu 6 / S18: kök neden `_measureBodyTop` (note_editor_screen.dart) — başlık ölçümü ilk kareden sonra kök `setState` yapıyor, editör 2. karede baştan kuruluyor (786). Düzeltme: `_bodyTopN` ValueNotifier + tuvalin çevresinde `ValueListenableBuilder` (yalnız NotePageCanvas kurulur). Ölçülecek: S18 gecis_karesi; S17/S18 ilk kare +1 katman mandalı aşmasın.

## Sıradaki
- Sonra belgeler (Kuyruk, plan, regresyon, hafıza, sürüm notu), tam `flutter analyze`, CI.
- F84.1–3, F60.S2, F60.5, F68.3: cihaz/profil ister — bu oturumda YAPILMADI.

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart test/jank_patterns_guard_test.dart --reporter failures-only`
