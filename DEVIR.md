# DEVIR — oto/P65-telefonsuz-kod (P65: T15, T14, T3, T5, T7)

Bulut işçisi, push YOK (yürütücü birleştirip tek push yapar). Cihaz yok.

## Yapılanlar
- T15 (commit "T15 ..."): ölü liste önizlemesi silindi. Kanıt: `grep showNoteTemplateSheet lib` → yalnız tanım; `pickTemplate` levhayı hep `quickLists: true` kuruyordu → liste şablonu composer'a hiç gelmiyordu. S48: klavye 396/258 → 294/156 (yazı şablonu senaryosu), kutu/çip ölçümleri silindi.

## Şu anki adım
- T14

## Kanıt / ölçüm ham sayıları
- S41: {cip_fazla_kart 0, harf_fazla_kart 0, acilis_text 37}; S48: {klavye 294, dizilme 156, galeri 330, duzenleyici 191}

## Test komutu
- `flutter test test/note_templates_test.dart test/template_sheet_layout_test.dart test/quick_list_screen_test.dart --reporter failures-only`
- `flutter test test/perf_budget_test.dart --name "S4[18]:"`
