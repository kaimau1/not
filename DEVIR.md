# DEVIR — P84 hızlı ekle HE-2 + HE-3 (dal oto/P84-hizli-ekle)

**Ortam:** bu makinede Flutter SDK YOK (`C:/src/flutter` yok, PATH'te yok) → yerel test/analiz
koşulamadı; doğrulama yalnız CI. Android: dalda APK işi koşmaz → `gh workflow run build.yml
--ref oto/P84-hizli-ekle` (workflow_dispatch) ile derlenir.

Yapılanlar:
1. HE-2 önizleme satırı + ⚙ + AI bekleme (commit 1): `quick_drop_sheet.dart` — `quickDropListParser`,
   `quickDropPreview` (saf), durum satırı boştayken önizleme (`quick-drop-preview`), Ekle düğmesinde
   içerik YOK (tuşta kurulmaz), üç anahtar `PopupMenuButton` (`quick-drop-settings`), düşünürken
   `DelayedSpinner` (300 ms) + "Ben seçeyim" (`quick-drop-pick-myself`). l10n 5 yeni anahtar
   (.arb + generated elle, gen-l10n biçimi). Testler `quick_list_screen_test` (HE-2 ×3, 2 beklenti).

Sıradaki: (2) çip araması (`showNotePicker` yeniden kullanılır, 12 sınırı kalkar) → (3) HE-3
`notlar://ekle` + kısayol + karo + PROCESS_TEXT + paylaş "Nota ekle" (Kotlin aktarma etkinliği
`NotaEkle`) → (4) 1×1/4×1 ana ekran aracı → belgeler, S56 bütçesini CI kaydından düşür.

Kanıt/ölçüm: S56 `yazma_kurulum` 415 (önce); sonrası CI kaydından ("S56: {...}").
Test: `flutter test test/quick_list_screen_test.dart test/perf_budget_test.dart --plain-name S56`.
