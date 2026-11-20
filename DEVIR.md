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

2. HE-2 çip araması (commit 2): şeridin başında `quick-drop-search` → `showNotePicker(title:)`
   (yeni isteğe bağlı başlık), 12 çip sınırı kalktı (şerit tembel). Test "çiplerde arama".

   CI 44739366997 YEŞİL (tam takım 3 parça). S56 yazma 415 → 335 (bütçe düşürüldü, commit 928d0e26).
3. HE-3 uygulama dışından (commit 3): `notlar://ekle?metin=` → router → `quickDropRequestProvider`
   → dashboard `_maybeOpenQuickDrop` → `showQuickDropSheet(text:)`; `QuickEntryBar.initialText`
   (elle yazılmış sayılır → kendiliğinden dinleme yok). Android `HizliEkle.kt`: `NotaEkle`
   (SEND text/plain + PROCESS_TEXT aktarıcı), `HizliEkleKarosu` (TileService); kısayol şablonu
   `src/main/kisayol/app_shortcuts.xml` + gradle `KisayolUret` (targetPackage = çeşit kimliği).
   `security_guard_test` listesi + `docs/guvenlik_denetimi.md` G-27.

4. HE-3 ana ekran aracı (commit 4): `QuickAddWidgetProvider` (1×1 "+") + `QuickAddBarWidgetProvider`
   (4×1 çubuk), ikisi `notlar://ekle`; `kHomeWidgetProviders`a eklendi (tema yenilemesi).

5. Dispatch koşusu 44740751793 YEŞİL: 3 test parçası + Android APK (36,9 MB; üretilen
   `xml/app_shortcuts` çözüldü). Belgeler (commit 8c62c664): sürüm notu 20 Kasım, PLAN 1.4/3 [~],
   KONTROL "Telefonda bak", regresyon, `docs/hafiza/editor.md`, Kuyruk P84 bitti.

Durum: BİTTİ, birleştirmeye hazır (yürütücü DEVIR'i siler). Cihazda hiçbiri denenmedi.
Test: `flutter test test/quick_list_screen_test.dart test/perf_budget_test.dart --plain-name S56`.
