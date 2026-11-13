# DEVIR — P46 bitti (cihazsız) → P55 devralır (dal `oto/P46-hiz-duzelt`)

`pinned_media_pane.dart`'a DOKUNMA (P49). P46'nın HİÇBİR commit'i cihazda ölçülmedi.

## P46'da yapılanlar (madde başı ayrı commit; geri alınabilir)
- S25 `note_card_media.dart` thumbUrl `memCacheWidth: 480` (21 → 0)
- S21 `dashboard_slivers.dart` `_cachedCard(searching: searchActive)` (114 → 56)
- S22 `calendar_screen.dart` `_weekPage` önbelleği (979 → 509)
- S23 `dashboard_screen.dart` `_GridScrollView` + `_holdNarrowCache` (en ağır kare 2941 → 2361)
- S9 `note_editor_screen.dart` iki `AnimatedSize` kalktı, `_barReturn` (gövde boy karesi 34 → 2; jank mandalı 4 → 2)
- S18 `note_editor_screen.dart` `_bodyTopN` (ikinci kare 788 → 285)

## P55 için bilinenler (cihaz maddeleri — hiçbiri başlanmadı)
- Önce A/B: taban önceki `[apk]` (519672b7) profil derlemesi, B bu dal: `python -u tool/perf/ab_hepsi.py <A.apk> <B.apk> --altin`. KALDI veren evrenin commit'i tek başına geri alınır. His bakılacak: arama vurgusu 350 ms gecikmeli; biçim paneli/alt çubuk boyu anında.
- F84.1 (altın tabanın en kötü 3 evresi): `tool/perf/vmsvc.py` CPU örnekleri; P43 notu: liste kaydırmada %2,3–3,3 kare > 16 ms (F68.4). Cihazsız ipucu: S23'te kalan 9 kart pay genişleyince tek karede (413–668 kurulum); S24 kartlara dek 4019 kurulum; S19 kapanış karesi 523.
- F84.2 (yazmada en uzun kare 29 → 42 ms): `tool/perf/prof_type.py`; şüpheliler plana göre yazım düzeltici / kayıt / kart önbelleği. S1/S2 cihazsız temiz (kök 1, satır 1) — kurulum değil, Dart bloğu aranmalı.
- F84.3 (soğuk açılış ≤ 600 ms): `tool/perf/prof_cold.py`; S24 ilk kare 930 kurulum.
- F60.5 (yazma ana bloğu 148 → 229 ms): `prof_type.py` iki sürüm; en pahalı 5 çerçeveyi maddeye yaz.
- F60.S2 (birikim): cihazsız üretilemedi; bekçi `test/editor_leak_test.dart` 'uzun oturum' yeşil. Cihazda: taze açılış ile 30 gir-çık SONRA klavye evresi (`ab_klavye.py`) karşılaştır.
- F68.3 (K-O13): kullanıcının GERÇEK hesabında `tool/perf/prof_save.py`; ≤ 12 ms → kapat.
- Açık cihazsız kalan: ses hapı `AnimatedSize` (`note_editor_screen.dart`, `VoiceRecordPanel` çevresi) — testte kayıt eklentisi yok; S21 kalan 56 kart; S2 mandalı 5/15 ama ölçüm 1/1 (düşürülebilir).

## İşe yaramayanlar
- S21: ızgaraya `ValueKey(searchActive)` — taze `SliverList` kaydırılmış konumda 0'dan o konuma dek her kartı kurar.
- S23: `ValueListenableBuilder` sarmalayıcı S24 ilk kareyi 930 → 931 yaptı; öğe kendisi dinliyor.
- Yerelde `folder_strip_fixed_test` 2. test CRLF yüzünden kırmızı (CI Linux'ta yeşil).

## Komut
`"C:/src/flutter/bin/flutter.bat" test test/perf_budget_test.dart test/jank_patterns_guard_test.dart test/keyboard_jank_guard_test.dart --reporter failures-only`
