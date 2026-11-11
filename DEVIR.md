# DEVİR — P19 Liste yükü (oto/P19-liste-yuku)

**Durum (2026-11-12):** F68.1 bitti; F68.2 kısmen (kanıtı üretilen kısım), gövde bölme yazılmadı.

## Yapılan
- F68.1: `heldNotePreviewProvider` (notes_providers.dart) — editör `_mutate`'ten `touch`,
  3 sn sonra / kapanışta / anında kayıtta `release`; `filteredNotesProvider` tutulan örneği verir.
  Bütçe S12: 1/13 → yazarken+kayıt 0/0, durunca 1/1. Birim testi `test/sort_hold_test.dart`.
- F68.2 (kısmen): `DashboardPaneScope.updateShouldNotify` yalnız `singleColumn`
  (split_shell.dart, tek satır). Yeni bütçe S12b (nottan nota geçiş): 1/13/2 → 0/0/2.

## Yapılmayan / sabah bakılacak
- F68.2 gövdeyi üçe bölme: cihazsız kanıt üretilemedi (girdisi değişmeyen pano kurulumu
  kalmadı). Kapı: tablette `tool/perf/ab_klavye.py` not kapanış karesi > 33 ms ise ayrı iş.
- Cihaz A/B (ÖLÇÜM KAPISI) yapılmadı: F68.1/F68.2 "cihazda doğrulanmadı".
- Sürüm notu eklenmedi ([apk] birleştirmesinde yürütücü ekler): "Tablette yan yana
  görünümde yazarken liste takılmıyor; kart yazma durunca güncellenir."

## Doğrulama
- `flutter test test/perf_budget_test.dart test/sort_hold_test.dart test/keyboard_jank_guard_test.dart` yeşil;
  ilgili 15 dosya (104 test) yeşil; `flutter analyze` temiz. Tam takım CI'da.

## Çakışma notu (P18)
- `lib/app/split_shell.dart`'ta yalnız `DashboardPaneScope.updateShouldNotify` değişti.
- `dashboard_screen.dart` / `dashboard_slivers.dart`'a DOKUNULMADI.
