# DEVIR — P39 Hız hissi (DENEYIM F78.1–F78.5) · dal `oto/P39-hiz-hissi`

Kural (kullanıcı, 2026-11-12): kötüleşme kabul edilmez; kötüleşen maddenin YALNIZ kendi
commit'leri geri alınır (yeniden eskiye sırayla `git revert`). Maddeler birbirine bağımsız.

| Madde | Commit | Önce → sonra (kanıt) | Cihazda A/B (yürütücü) |
|---|---|---|---|
| F78.1 açılış (K-D8) | `0144b28f` | beyaz ~0,6 sn (`arayuz.md`) → ölçülmedi; debug APK derlendi | `screenrecord` + `python tool/perf/video.py` beyaz kare sayısı; `python -u taban.py p39` açılış `total_ms` tabandan kötü olmasın. Kalıyorsa/kötüyse geri al |
| F78.3 yükleme hâlleri | `f7f6f65a` + `52709fe7` | < 300 ms işte halka: görünür → görünmez (20 yer; `design_components_test` DelayedSpinner); PDF açılırken F2F2F2 kutu + halka → küçük resim (`loading_states_test`); görüntüleyici ağ görseli 500 → 150 ms. Bütçe: `perf_budget_test` S1–S16 aynı | `python -u prof_oc.py pdf <x> <y>` (sabit PDF'li not) AÇILIŞ kareleri; `ab_liste.py`, `ab_klavye.py` |
| F78.4 basma tepkisi | `18be8e6e` + `a5e24028` | hedef seçici / paylaşım hedefi kartı: ölçek 1 → basılıyken < 1 (`note_target_picker_test`) | gerekmez (ana ekran dışı iki levha) |
| F78.5 iyimser işlemler | `4161052d` | yalnız test; kod yok (zaten iyimser) | gerekmez |
| F78.2 yeni not süresi | `15dc01b7` | yalnız araç; sayı yok → **iyileşme kanıtlanamadı**, kod yok | `cd tool/perf && python -u prof_new.py taban` (hedef ortanca ≤ 450 ms) → sayıyı plana yaz |
| Plan/HAFIZA/KALANLAR | `352e4c58` + son commit | belge | — |

## İyileşme kanıtlanamadı — YAPILMADI (denendi, geri alındı: `52709fe7`)
- Yerel görsele 150 ms solma (kart + görüntüleyici): tam görünürlüğü geciktirir, listede katman ekler.
- Rota geçişi yer tutucusunda küçük resim (sabit PDF/video): geçiş karelerine iş ekler
  (`AfterRouteTransition` kök nedeni 2026-10-20).
- Editör kökü halkaları ve editör içi dokunuş yüzeyleri: Ek D çiti (P20/P36).

## Kök neden / kanıt
- İyimserlik: UI `updateFields`/`batchUpdate`'i beklemiyor (`dashboard_selection.dart`,
  `note_actions_sheet.dart`). Gri kutu: `pdf_page_box.dart` `_document(null)`.
- F78.1: Flutter zaten ilk Android çizimini geciktiriyor; kazanç MIUI'de ancak cihazda görülür.
  Emniyet: açılış ekranı en çok 3 sn tutulur (`MainActivity.onCreate`).

## Açık test komutu
`flutter test test/loading_states_test.dart test/optimistic_actions_test.dart test/note_target_picker_test.dart test/perf_budget_test.dart test/design_tokens_guard_test.dart --reporter failures-only`

## Kullanıcıya görünen (sürüm notu için; F78.1 cihazda geçerse)
- Açılışta beyaz parlama yerine uygulama simgeli açılış ekranı.
- Kısa süren yüklemelerde dönen halka görünmez (0,3 sn'den uzun sürerse belirir).
- PDF açılırken gri kutu yerine belgenin küçük resmi.
