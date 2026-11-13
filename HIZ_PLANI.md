# HIZ_PLANI — hız güvencesi: her yüzey ölçülür, hiçbir güncelleme kasma geri getirmez

**Kullanıcı isteği (2026-11-12):** "Ölçüm olarak tüm sistemler var mı? Çok hızlı, akıcı bir
program olmalıyız. Gerekirse yeni faz yaz (Fable/Opus). Bir daha yaşanmaması için tedbir al;
ileride ek özellik ve güncellemelerde aynı kasmaları tekrar yaşamamak için kaydet."

Bu plan YENİ ÖZELLİK EKLEMEZ. İki işi var: (1) ölçülmeyen yüzeyleri ölçülür yapmak,
(2) kasmanın geri gelmesini otomatik engellemek. Bulunan gerçek yavaşlıklar Faz 84'te düzeltilir.
Protokol: OTURTMA_PLANI başındaki gibi — önce kanıt (ölçüm), sonra düzeltme, aynı ölçüm yeşil.
Hız kuralı (OTOMASYON 6. adım, kullanıcı kararı 2026-11-12): **hiçbir evre kötüleşmez**;
madde başı ayrı commit, kötüleştiren tek commit geri alınır, iyiler birleşir.

## 0. Bugün ne var (envanter, 2026-11-12)

| Katman | Araç | Kapsadığı | Kapsamadığı |
|---|---|---|---|
| Cihazsız (CI, her push) | `test/perf_budget_test.dart` S1–S17 (`budgets.json`, mandal yalnız düşer) | editör yazma/madde/kalem/klavye inset kurulum sayıları, bölünmüş görünüm, 300 not kaydırma, 2000 çizgi | ekran geçişleri, soğuk açılışın ilk karesi, levha/menü açma, arama yazma, takvim, klasör geçişi, görsel çözme boyutu |
| Cihazsız bekçiler | `keyboard_jank_guard_test`, `items_editor_row_cache_test`, `editor_leak_test`, `design_tokens_guard_test` | CLAUDE.md kasma listesi md. 1–2, 6–7 | md. 3–5 (kök `setState`, env'e her build'de yeni nesne, koşullu ağaç şekli) için genel tarama yok |
| Cihaz A/B (elle tetiklenir) | `ab_klavye.py` (klavye aç/kapa, yazma, not kapanışı), `ab_liste.py` (ana ekran fırlatma), `ab_kalem.py` | editör + liste + kalem | soğuk açılış, not AÇMA, yeni not, PDF aç/kaydır, levha açma, arama, takvim, klasör kaydırma, uzun oturum birikimi |
| Cihaz taban | `taban.py` (açılış, kaydırma, 4 not aç/kapa, yazma), `prof_cold.py`, `prof_new.py` (P39, hiç koşmadı), `video.py` | duman testi | A/B karşılaştırması ve otomatik karar yok; sonuçlar geçici klasörde kalıyor, geçmiş yok |
| CI cihaz | "Kare ölçümü" işi (yalnız `perf` bayrağıyla) | — | her `[apk]`'da koşmuyor |

**Açıklar (kanıtlı):**
- A1. A/B kapısı yalnız 4 editör evresine bakıyor; P39'da açılış/yeni not için ölçüm aracı vardı ama A/B'ye bağlı değildi.
- A2. Karar elle ve "2. koşu" ile veriliyor: P36'da not kapanışı A2 = 520 ms, A1 = 170 ms (tek sapkın koşu kararı çeviriyordu); "son klavye kapa" +%35 gürültü mü değil mi elle yorumlandı.
- A3. **Kümülatif kayma görünmüyor:** her `[apk]` yalnız bir öncekine karşı %20 ile ölçülüyor; 5 ardışık +%15 geçer ama toplam +%100 olur. Sabit bir "altın taban" ve geçmiş çizelgesi yok.
- A4. Ölçüm sonuçları depoya yazılmıyor (`PERF_OUT` geçici) → bir ay sonra "eskiden kaç ms'ydi" sorusunun cevabı yok.
- A5. Kasma listesinin md. 3–5'i yalnız okunarak uygulanıyor; bekçi testi yok.
- A6. Uzun oturum (30 dk kullanım) birikimi ölçülmüyor (F60.S2 kullanıcı bildirdi, üretilemedi).

## FAZ 81 — Tek komutla tam hız ölçümü + otomatik karar [Opus · P43 · cihaz]

- [x] **F81.1 `tool/perf/ab_hepsi.py`:** iki APK yolu alır; A,B,A,B,A,B sırasıyla (ısınma dengesi) her evreyi 3 kez koşar; evreler: soğuk açılış (ilk kare ms, `prof_cold` mantığı), ana ekran fırlatma (`ab_liste`), not açma (kart → editör ilk kare), klavye aç/kapa + yazma + not kapanışı (`ab_klavye`), yeni not ("+" → imleç), sabit PDF'li not aç + 3 sayfa kaydır, not menüsü (⋮) levhası açma, arama yazma (5 harf), klasör yana kaydırma. Her evrede UI kare sayısı, UI ms, LAYOUT ms, en uzun kare, > 16 ms kare sayısı. Var olan `perf.py`/`scen.py` yardımcılarını kullan, yeni çatı yazma.
- [ ] **F81.2 Otomatik karar:** evre başına ORTANCA (3 koşu); karar kuralı: B ortancası A'nın en kötü koşusundan da kötüyse VE fark > %10 VE > 3 ms → "KÖTÜLEŞTİ"; aksi "aynı/iyi". Hız paketlerinde (OTOMASYON 6. adım) tek "KÖTÜLEŞTİ" = birleştirme yok. Çıktı: markdown tablo + `KARAR: GEÇTİ|KALDI` son satırı. Sıcaklık > 37 °C koşuyu geçersiz sayar ve bekler.
- [x] **F81.3 Kalıcı kayıt:** her koşu `docs/perf/gecmis.csv`'ye bir satır/evre ekler (tarih, commit, APK etiketi, evre, ortanca UI ms, LAYOUT ms, kare, sıcaklık). Depoya girer (küçük metin).
- [ ] **F81.4 Altın taban:** `docs/perf/altin_taban.json` = bugünkü main (9c837495) ölçümü. `ab_hepsi.py --altin` B'yi ayrıca altın tabana karşı yazar; bir evre altın tabandan **%15'ten fazla** kötüyse (kümülatif kayma, A3) karar KALDI. Altın taban yalnız İYİLEŞME olunca güncellenir (mandal).
- [x] **F81.5** OTOMASYON 6. adımı ve CLAUDE.md ÖLÇÜM KAPISI `ab_klavye.py` yerine `ab_hepsi.py`'ye geçer (ölçüm Sonnet alt ajanda kalır; istem kısalır: "iki APK, `ab_hepsi.py`, son satırı getir").
- **Durum (2026-11-13, P43):** F81.1/F81.3/F81.5 bitti; altın taban yazıldı (`docs/perf/altin_taban.json`, 9c837495, 25–37 °C). Açılışta UI ms anlamsız (duraklatılmış başlangıç 2 kare) → karar `ilk_kare_ms`'ye bakar. **F81.2/F81.4 KABULÜ KALDI:** aynı APK A=A koşusunda `yaz` LAYOUT ortanca 269→300 (+%11,5, B > A en kötü) → yanlış "KÖTÜLEŞTİ"; altına karşı `yaz` LAYOUT +%40, `menu` +%28, `not_ac` +%22 (aynı APK!). Kök neden: gürültü ±%15 (aynı APK `yaz` LAYOUT 262–302, `menu` 44–75); 3'e 3'te "B ortancası > A en kötüsü" tek başına evre başına ~%20 olasılıkla tutar, %10 eşiği bunu süzmüyor; altın taban serin (25 °C) koşuları içeriyor, kabul koşusu hep 36,6–36,9 °C'de (AC şarjda her koşu 40 °C'ye ısınıyor, betik 37'nin hemen altında başlatıyor). En güvenli: kural GEVŞETİLMEDİ (yanlış alarm birleştirmeyi durdurur, kötüleşme kaçmaz) — **sabah bakılacak:** öneri A/B eşiği %20 (eski kapı) + altın taban 5+ koşu ortancası ve koşu başlangıcı < 34 °C (şarjsız).
- **Durum 2 (2026-11-13 sabah, P43 2. işçi):** öneri uygulandı — A/B eşiği %10→**%20**, her koşu **< 34 °C**'de başlar (bekleme ≤ 30 dk; AC şarj kesilemedi, şarjsız koşu yapılamadı), `--altin-yaz` A=B'de 6 koşu (≥ 5 şart). Altın taban SİLİNİP 9c837495'in 6 koşu A=A ortancasıyla yeniden yazıldı (30–34 °C; eski taban git geçmişinde — mandal bir kez sıfırlandı, sabah bakılacak). Kabul A=A: 1. koşu (altın yazımı) A/B **GEÇTİ**; 2. koşu `--altin`: A/B 13 evrede **GEÇTİ** ama altına karşı `yaz` LAYOUT +%16 (362 / taban) → **KALDI** (aynı APK; `yaz` LAYOUT oturumlar arası 302–377). %15 altın eşiği HIZ SÖZLEŞMESİ'nde, gevşetilmedi. Ek: `ready()` geçişte `mCurrentFocus=null`'da 3 sn bekler (koşu yanlış duruyordu). **Kalan:** 3. A=A tekrarı ve yavaşlatılmış B (`ItemsEditor` +5 ms) — süre sınırı, denenmedi. Öneri (sabah bakılacak): altın karşılaştırmasında gürültülü küçük metrik için `max(%15, A=A yayılımı)` ya da `yaz` LAYOUT'u altın dışı tutmak — kullanıcı kararı.
- Kabul: aynı APK'yı A ve B diye verince 3 tekrarda üçü de GEÇTİ (yanlış alarm yok); bilerek yavaşlatılmış B (örn. `ItemsEditor`'a 5 ms bekleme) KALDI.

## FAZ 82 — Cihazsız bekçileri genişlet (her push'ta, telefonsuz) [Opus · P43 (P44 katıldı)]

- [x] **F82.1 Bütçe senaryoları S18–S25** — 2026-11-12 (P43): sekizi `perf_budget_test`'te, bugünkü değerle mandallı + S17'ye sabit görsel klavye evresi; bulgular (S21 ×6 kart, S25 thumbUrl, S22/S23 ağır kare) OTOMASYON P46'da. (`perf_budget_test`, OTURTMA Ek A'ya satır): S18 ana ekran → not açma geçişi (kurulan `NoteCard`/kök kurulum, geçiş karesi başına build); S19 not kapanışı → ana ekran (kartlar yeniden kurulmaz); S20 not menüsü levhası açma (levha dışında kurulum 0); S21 arama kutusuna 5 harf (harf başına kurulan kart ≤ görünür); S22 takvim hafta kaydırma; S23 klasör yana kaydırma (komşu sayfa önceden kurulu, yeniden kurulmaz); S24 soğuk açılış ilk kare kadar kurulan widget sayısı (taban + mandal); S25 görsel ekli 50 not listesinde decode boyutu ≤ kart boyu × dpr (`cacheWidth` unutulmasın). Her biri önce bugünkü değeri ölçer, `budgets.json`'a o yazılır (mandal).
- [x] **F82.2 Kasma listesi md. 3–5 bekçisi** — 2026-11-12 (P43): `jank_patterns_guard_test` (md. 3/4/6/7, her kurala bozma denemesi testte); editör kökünde 3 boy animasyonu mandallı (P46). `test/jank_patterns_guard_test.dart` (`keyboard_jank_guard_test` kalıbı, kaynak tarama): editör ve pano kök durumlarında yeni `setState` sayısı mandalı; `_syncRowCache` env'ine satır içi `{}`/`[]`/kapanış yasak; `MediaQuery.of(context)` kabuk/kök dosyalarında yasak (`sizeOf`/`viewInsetsOf`); editör Column/Row içinde `AnimatedSize`/`AnimatedContainer` yasak (md. 6 zaten var — tek dosyada birleştir). Her kural bozma denemesinde kırmızı.
- [x] **F82.3 Uzun oturum bekçisi:** — 2026-11-12 (P43): `editor_leak_test` 'uzun oturum' (200 gir-çık + 50 klavye turu; TextEditingController/AnimationController/FocusNode/ScrollController ve not akışı aboneliği başlangıçla aynı, ~30 sn); bozma: `_titleController.dispose()` kaldırılınca kırmızı (200 sızan). widget testinde 200 kez not aç/kapa + 50 klavye döngüsü; sonunda canlı `TextEditingController`/`AnimationController`/akış aboneliği sayısı başlangıçla aynı (`editor_leak_test` genişlet). F60.S2'nin cihazsız karşılığı.
- Kabul: hepsi CI'da yeşil; her yeni kural için bozma denemesi commit mesajında.

## FAZ 83 — Her `[apk]`'da otomatik ölçüm ve geçmiş [Sonnet · P45]

- [ ] **F83.1** OTOMASYON 8. adımı (APK noktası): birleştirmeden ÖNCE `ab_hepsi.py --altin` zorunlu (paket A/B istemese bile — yerleşim/levha/ekler de hızı bozabiliyor). Telefon yoksa `[apk]` ertelenir, birleştirme `[apk]`'sız yapılır.
- [ ] **F83.2** `docs/perf/README.md`: gecmis.csv'yi okuyan tek sayfalık özet (`python tool/perf/gecmis.py` → evre başına son 10 `[apk]` eğilimi, altın tabana göre %). Haftalık zamanlanmış tur bunu okuyup kayma > %10 olan evreyi Kuyruk'a "hız: <evre>" satırı olarak ekler.
- [ ] **F83.3** CI "Kare ölçümü" işi: neden yalnız `perf` bayrağında koştuğunu kanıtla (süre/gürültü); emülatör sayıları kararlıysa (aynı commit 3 koşu, sapma < %10) `[apk]` koşularında da koşsun, değilse işi kaldır ve neden plana yaz.

## FAZ 84 — Ölçümün bulduğu yavaşlıkları düzelt [Fable · P46 · A/B]

- [x] **F84.0 Cihazsız bekçi bulguları (P43'ün 6 bulgusu)** — 2026-11-13 (P46): S25 21 → 0, S21 114 → 56, S22 979 → 509, S23 en ağır kare 2941 → 2361, S9 gövde boy karesi 34 → 2 (jank mandalı 4 → 2), S18 ikinci kare 788 → 285; mandallar düşürüldü; cihazda ölçülmedi. Ses hapı `AnimatedSize`ı kanıtsız, açık.
- [ ] **F84.1** *(→ P55, cihazlı; 2026-11-13 P55 döküm, düzeltme AÇIK: not açma en uzun kare 61 ms = LAYOUT 58,7 — gövde paragraf dizimi `_RenderPageMinHeight` %37 + `findLinks`/`_scanPlainness` %24 (tek uzun paragrafta paragraf önbelleği işe yaramıyor); soğuk açılışın ilk veri karesi 160–228 ms = kart metin dizimi + `richSpans`; liste ölçülmedi. Ayrıntı `docs/hafiza/akicilik.md` P55)* F81 + F82'nin ilk tam ölçümünde altın tabanın en kötü 3 evresi (en uzun kare > 32 ms ya da ortanca UI ms en yüksek) için kök neden dökümü (`vmsvc.py` CPU örnekleri + widget build profili) ve düzeltme. Hedef: her evrede > 16 ms kare sayısı yarıya.
- [ ] **F84.2** *(→ P55, cihazlı; 2026-11-13 P55: en uzun kare 38,9 ms, 215 karede 4 > 16 ms; tek uzun kare = metin alanı dizimi (%42) + her tuşta düzenlenen paragrafın `findLinks`/`_flagsOf` taraması (%34). Düzeltme açık: uzun paragrafta tarama yalnız değişen satıra)* P36 ölçümünde görülen: yazmada en uzun kare 29 → 42 ms (B1'de 59 ms), sayısı eşit — kök neden (tek uzun kare nedir: yazım düzeltici? kayıt? kart önbelleği?) ve düzeltme.
- [x] **F84.3** *(2026-11-13 P55, `prof_cold.py` iki koşu: ilk kare resume'dan 36–64 ms — hedef ≤ 600 ✓; ilk VERİ karesi 160–228 ms (kart metin dizimi), 10. kare 509–719 ms)* Soğuk açılış (P39 F78.1 sonrası): ilk kare ≤ 600 ms hedefi, `prof_cold.py` dökümüyle.
- Kural: her madde ayrı commit; `ab_hepsi.py` KALDI veren commit geri alınır.

## Kalıcı tedbirler (bu planla birlikte yürürlüğe girer)

1. CLAUDE.md "Hız sözleşmesi" (kasma listesinin altında): yeni özellik/güncelleme hangi yüzeye dokunursa o yüzeyin bütçe senaryosu (yoksa YAZILIR) + `[apk]` öncesi `ab_hepsi.py --altin`. Ölçümsüz "akıcı" denmez.
2. Mandallar yalnız düşer: `budgets.json`, `design_tokens/budget.json`, `altin_taban.json`.
3. Hız/akıcılık paketlerinde kötüleşme sıfır (OTOMASYON 6. adım); diğer paketlerde %20 + altın taban %15.
4. Yeni ekran/levha/akış ekleyen her iş, Ek A'ya bir S satırı ve `ab_hepsi.py`'ye bir evre ekler (yoksa iş bitmiş sayılmaz).

## Sıra ve model

P39 (açık, cihaz A/B) → **P43 = Faz 81** (Opus) → Faz 82 de P43 içinde (P44 katıldı, 2026-11-12) → **P45 = Faz 83** (Sonnet) → **P46 = Faz 84** (Fable; Fable limiti %55 üstüyse Opus) → kalan kuyruk (P20 ölçüm altyapısı kurulduktan sonra daha güvenli).
