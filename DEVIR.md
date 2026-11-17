# DEVIR — oto/P65-telefonsuz-kod (P65: T15, T14, T3, T5, T7)

Bulut işçisi, push YOK (yürütücü birleştirip tek push yapar). Cihaz yok.

## Yapılanlar
- T15 (commit "T15 ..."): ölü liste önizlemesi silindi. Kanıt: `grep showNoteTemplateSheet lib` → yalnız tanım; `pickTemplate` levhayı hep `quickLists: true` kuruyordu → liste şablonu composer'a hiç gelmiyordu. S48: klavye 396/258 → 294/156 (yazı şablonu senaryosu), kutu/çip ölçümleri silindi.

- T14 (commit "T14 ..."): kök `semantic_search.dart` ana arama `pruneTo` yalnız aktif notlar → çöp vektörleri silinip yeniden gömülüyordu. Kanıt `test/semantic_trash_cache_test.dart`: önce 2 gömme, sonra 1.

- T3 (commit "T3 ..."): indirme kapalı bekçide yalnız Merriweather-Medium eksikti (kalın istenmiyor) → dosya + `disableFontRuntimeFetching()` + `applyNoteFont` >500 → 500 ile yükler. assets+pubspec değişti → CI tam takım (gerekçe: eksik font dosyası).

- T5 (commit "T5 ..."): AL-1 — sık eklenenler `smart:market`/`smart:bavul`, kalanlar türe göre, boş ipucu `smartListHint` (.arb), S49 açılış ilk karesi 634 / akıllı 688 (önce=sonra). Eski kodda yeni 3 test kırmızıydı.

- T7 kısmen (commit T7a/b/c): sürüm geçmişi tek okuma (4→1), hesap makinesi (84→≤8), paylaşım araması (üst levha 1→0/tuş). Kalan liste `docs/hafiza/akicilik.md` 2026-11-17 T7.

## Şu anki adım
- Paket bitti; yürütücü birleştirir (assets + pubspec + .arb değişti → CI tam takım).

## Kanıt / ölçüm ham sayıları
- S41: {cip_fazla_kart 0, harf_fazla_kart 0, acilis_text 37}; S48: {klavye 294, dizilme 156, galeri 330, duzenleyici 191}

## Test komutu
- `flutter test test/note_templates_test.dart test/template_sheet_layout_test.dart test/quick_list_screen_test.dart --reporter failures-only`
- `flutter test test/perf_budget_test.dart --name "S4[18]:"`
