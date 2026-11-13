# DEVIR — P46 Hız: ölçümün bulduğu yavaşlıkları düzelt (dal `oto/P46-hiz-duzelt`)

Kaynak: KUYRUK_AYRINTI.md §P46 (6 cihazsız bekçi bulgusu) + HIZ_PLANI F84 + OTURTMA F60.S2/F60.5/F68.3.
`pinned_media_pane.dart`'a DOKUNMA (P49). Cihaz A/B'yi yürütücü yaptırır.

## Yapılanlar
- Bulgu 2 (S25): `note_card_media.dart` `_image` thumbUrl dalı + PDF kapağı thumbUrl dalına `memCacheWidth: 480`. S25 sinirsiz_cozum 21 → 0, mandal 0.

## Şu anki adım
- Bulgu 1 (S21 arama): kök neden bulundu, düzeltme çalışma ağacında (aşağıda).

## Kök neden / kanıt
- S21: `dashboard_slivers.dart` `cell` kart önbelleğini ANLIK sorguyla (`searchQueryProvider`), hücre sarmalayıcısını GECİKTİRİLMİŞ `searchActive` ile seçiyordu → ilk harfte kartlar 2 dalga kuruluyordu (57 + 57). Önbellek anahtarı `searchActive` olunca 114 → 56. Kalan 56 = 1600 px kaydırma payındaki canlı kartlar (yapısal değişim, yerinde güncellenir; sonra pay 250'ye iner, 26 canlı kalır).

## İşe yaramayanlar
- Izgaraya `ValueKey(searchActive)` verip taze kurdurmak (26 kart): YAPILMADI — taze `SliverList` kaydırılmış konumda 0'dan o konuma kadar bütün kartları kurar (derinde daha kötü).

## Sıradaki
- Bulgu 3 (S22 takvim), 4 (S23 süzgeç), 6 (S18 ikinci kare), 5 (3 AnimatedSize, mandal 4).

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart --plain-name "S2" --reporter failures-only`
