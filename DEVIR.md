# DEVIR — P02 (F60.S2 klavye/alt panel birikim kasması) · dal `oto/P02-klavye-birikim`

**Durum:** cihazsız kanıt ÜRETİLEMEDİ → kasma düzeltmesi yazılmadı (kural). Bekçi testi + sayım + tek zararsız düzeltme var. Madde AÇIK; cihaz ölçümü yürütücüde.

**Yapılanlar**
- `test/editor_leak_test.dart` (yeni, 2 sahne, yeşil): çıplak editör 20 aç-kapa; gerçek kabuk (AppFrame+SplitShell+ana ekran+NoteOpenPage) 28 aç-kapa, 6 not türü, her açılışta odak+yazma+klavye turu. Ölçer: atılmamış nesne büyümesi (`FlutterMemoryAllocations`), genel dinleyiciler (`_globals`), klavye turu kurulum sayıları.
- `test/support/editor_harness.dart`: `pumpEditor(home:)` (editörü rota olarak açan testler için).
- `lib/.../editor/page_swipe.dart`: `PageTurn` `CurvedAnimation` dispose (bekçide 5 → 15 kırmızıydı; zararsız, kasmanın kökü DEĞİL).
- `OTURTMA_PLANI.md` F60.S2 "Durum" notu, `docs/regresyon_listesi.md` satırı, `HAFIZA.md` satırı.

**Kanıt / kök neden:** widget katmanında birikim yok (sayım: bütün genel kayıtların karşılığı var — ayrıntı plan maddesinde). Kök neden BULUNAMADI.

**Denenip işe yaramayan:** dinleyici sızıntısı varsayımı (statik sayım + iki sahne); not türü çeşitlemesi (PDF/görsel/sayfalı, kalemli cihaz).

**Yürütücü ölçecek (cihaz, ölçüm uygulaması `dev.kaimau.notlar.olcum`, bu dalın profil derlemesi):**
1. Uygulamayı öldür-aç (taze). `python -u ab_klavye.py taze <kart> <alan>` × 2 (ikinciyi al).
2. 30 kez: karta dokun → gövdeye dokun (klavye açılsın) → geri (klavye) → geri (not). Farklı 5-6 notu sırayla (biri sabit PDF'li, biri uzun liste). YAZMA YOK (madde uzamasın — `ab_klavye.py` TUZAK notu).
3. Aynı notta `ab_klavye.py otuz ...` × 2. Karşılaştır: klavye aç/kapa evresi UI ms ve LAYOUT ms.
4. Fark > %20 ise `prof_kb2.py` ile en pahalı 5 çerçeve + `adb shell dumpsys meminfo dev.kaimau.notlar.olcum` (taze ↔ 30 sonrası Dart yığını) → maddeye yaz. Fark yoksa madde "cihazda da üretilemedi" diye kapanır (bekçi kalır).

**Sıradaki adım (fark çıkarsa):** en pahalı çerçeveye göre; ilk bakılacak: sabit PDF'li notta klavye karesi başına ~180 widget kurulumu (`PinnedMediaPane`), sınırsız statik önbellekler (`note_card_media._cache`, `TextPagination._cache`, `pdf_page_ocr._cache`).

**Komutlar:** `flutter test test/editor_leak_test.dart --reporter failures-only` · tanı: `--dart-define=LEAK_TRACES=true` (büyüyen türlerin yaratıldığı yığın).
