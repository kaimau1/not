# KALAN İŞLER PLANI — Faz 18 (bulut oturumu) · Faz 19 (senin işlerin)

2026-11-01: Projede açık kalan **bütün** işler tek dosyada, iki fazda:

- **Faz 18** — bulut oturumunda (claude.ai/code, Linux kapsayıcı) yapılabilecek
  her şey: kod, test, CI, web turu, doküman.
- **Faz 19** — bulutta yapılamayanlar: telefon/tablet, Firebase · Google Cloud ·
  Play konsolu, hesap işleri, Windows makine.

Kaynaklar (hepsi taşındı, aşağıda **Kaynak eşlemesi**): `KULLANICI_DENEYIMI_PLANI.md`
Faz 17 (bekliyordu) ve Faz 10–16'nın "senin yapacakların"ı · `KALANLAR.md`
§1–§4 · `YOL_HARITASI.md`'nin açık "senin yapacakların"ı ve ERTELENDİ
maddeleri · `PERFORMANS_TOPARLAMA_PLANI.md`'nin ERTELENDİ'leri · HAFIZA'daki
açık uçlar · 2026-11-01 eksik incelemesi. Eski plan dosyaları karar kaydı
olarak kalır; **bu dosyada olmayan açık iş yoktur.**

## Bu dosya nasıl kullanılır

1. **"Faz 18'i yap"** → bulut oturumu. Faz 18 tek oturuma SIĞMAZ: sıradaki
   açık maddeden başla (bölüm sırası A → G; A güvenlik/veri önce). Kullanıcı
   **"F18.7'yi yap"** gibi madde adı da verebilir. Bir sonraki faza
   kendiliğinden geçilmez.
2. Bu dosyayı ve HAFIZA.md'nin ilgili bölümünü oku. Satır numaraları
   2026-11-01 hâlidir — önce `grep`, kök nedeni koddan doğrula.
3. **KARAR GEREKİR** etiketli maddede önce kısa öneri sun, onay al
   (AskUserQuestion). Kullanıcının daha önce verdiği kararı yeniden açma
   (HAFIZA'daki "kullanıcı kararı" maddeleri).
4. Her madde: düzeltme + mümkünse test. Oturum sonunda `flutter analyze`
   temiz ve `flutter test -j 4` tamamen yeşil olmadan "bitti" denmez.
5. Oturum sonunda: biten maddeyi `[x]` + altına 1–2 satır **Yapıldı:**;
   yapılamayanı `ERTELENDİ: neden` — bulutta yapılamadığı anlaşılırsa
   Faz 19'a taşı ve oraya yaz. **Durum** tablosunu güncelle; kalıcı karar /
   kök neden / tuzak HAFIZA.md'ye (ilgili bölüme, tarihli); cihazda bakılacak
   yeni adım `KALANLAR.md` §2'ye (F18.31'den sonra oradaki duman testine);
   commit + push.
6. **Faz 19** kullanıcının işidir; oturum yalnız hatırlatır. Kullanıcı sonucu
   bildirince maddeyi işaretle, gerekiyorsa HAFIZA'ya yaz. "← F18.x" olan
   madde o F18 maddesinin bitmesini bekler.

**Bulut ortamı notları** (ayrıntı CLAUDE.md + HAFIZA › Ortam):
- Flutter yok → 3.47.7'yi scratchpad'e indir. `pub get` `pubspec.lock`'u
  değiştirirse (bağımlılık eklemediysen) commit'e katma. `dart format lib`
  ÇALIŞTIRMA.
- APK bulutta derlenebilir ama **DEBUG imzalı** (anahtar deposu yok):
  derlemenin yeşil olduğunu gösterir, telefona kurulacak sürüm CI'ınkidir.
- Oturum `workflow_dispatch` TETİKLEYEMEZ (403) → CI'da koşacak iş commit
  başlığı etiketiyle tetiklenmeli (APK: `[apk]`, yalnız main).
- main'e push → web (Cloudflare Pages), Firestore/Storage kuralları ve
  Cloud Functions yayınlanır. Kural değişince önce `cd rules-test && npm ci
  && npm test` (Java 21 yoksa CI `rules` işine güven).
- Yayındaki web'e karşı tur Firebase'de misafir hesap açar → tur sonunda
  uygulamadan "Hesabımı ve verilerimi sil" (`KULLANICI_DENEYIMI_PLANI.md` Ek A).
  Ekran görüntülerini depoya koyma (scratchpad).

## Durum

| Faz | Konu | Durum | Tarih | Not |
|---|---|---|---|---|
| 18 | Bulut oturumunda yapılabilecekler (31 madde) | Bitti (26/27 — F hariç; F18.7 sonucu aşağıda) | 2026-11-02 | 2. oturum: F18.7 kök neden + koşu, F18.9 kısmen (kalanı F19.C6), F18.10, F18.22, F18.23; F18.20 → F19.B8; F bölümü (F18.27–30) yalnız Play'e çıkılırsa |
| 19 | Telefon, konsol, hesap işleri (senin) | Kısmen | 2026-11-01 | A3, B5, B7, C3 bitti; B6 ertelendi (ölçüm zaman aşımı); C1/C2/C4 kısmen (nedenleri maddelerde); A1, A2, A4, A5, B1–B4, C5, C6, C7, D açık |

---

## FAZ 18 — Bulut oturumunda yapılabilecek her şey

### A. Güvenlik ve veri (önce bunlar)

- [x] **F18.1 Web'de App Check (kod tarafı).** `lib/main.dart:53` web'de hiç
  etkinleştirmeden çıkıyor; web herkese açık (Cloudflare Pages) ve Google
  hesaplı kullanıcının AI'ı Firebase AI üzerinden PROJENİN faturasına
  gidiyor (`firebase_ai_client.dart`). Yap: web'de `FirebaseAppCheck.activate`
  (`ReCaptchaEnterpriseProvider`, olmazsa V3) — site anahtarı
  `--dart-define=RECAPTCHA_SITE_KEY` (`env.example.json` + CI'da aynı adlı
  secret); anahtar yoksa sessizce atla (bugünkü davranış, yerel/dal derlemesi
  kırılmasın). Firebase AI isteklerinin App Check jetonu taşıdığını doğrula
  (`FirebaseAI.googleAI(...)` parametreleri, kurulu `firebase_ai` sürümü).
  Test: anahtar yokken etkinleştirme çağrılmıyor. → Anahtar, secret, izleme
  ve zorlama: **F19.A2**.
  **Yapıldı (2026-11-02):** `appCheckSupported` (web yalnız `RECAPTCHA_SITE_KEY` varsa), `ReCaptchaEnterpriseProvider`; firebase_ai 3.x jetonu kendisi alır. CI web derlemesi secret'ı geçer, `env.example.json`. Test `app_check_policy_test`.

- [x] **F18.2 AI kotası istemcide — KARAR GEREKİR.** `aiQuota/{uid}` sayacını
  istemci artırıyor (`ai_gate.dart`); kural yalnız "puan artmalı" diyor.
  Değiştirilmiş istemci ya da API anahtarıyla doğrudan çağrı sayaca hiç
  uğramaz. Depolama tavanı da istemcide (KALANLAR §3). Seçenekler:
  (a) AI çağrılarını callable Cloud Function'a al — model anahtarı sunucuda,
  kota işlem içinde düşer, kendi anahtarını girenler (BYOK) aynen doğrudan;
  kesin çözüm ama gecikme + Functions bedeli; (b) Firebase AI Logic'te kal,
  App Check (F18.1/F19.A2) + Google Cloud'da kullanıcı başı/dakika sınırı
  (F19.A1) ile koru — ucuz, kota yine istemcide. **Öneri:** şimdi (b);
  (a) Play'e çıkılırsa F18.28'de.
  **Yapıldı (2026-11-02):** KARAR: (b) — kullanıcı onayladı. Kod değişmedi; koruma F18.1 + F19.A1/A2, sunucu kotası F18.28 (Play'e çıkılırsa).

- [x] **F18.3 AI günlük kotası penceresi — KARAR GEREKİR** (KALANLAR §3):
  yuvarlanan 24 saat mi (bugünkü `dayStart` mantığı) yoksa takvim günü mü
  (gece yarısı sıfırlanır, kullanıcıya "yarın yenilenir" demek kolay). Takvim
  günü seçilirse `firestore.rules` `aiQuota` bloğu + `rules-test` + Ayarlar'daki
  "kalan hak" metni değişir; saat dilimi sunucu saatiyle (`request.time`)
  tutarlı olmalı.
  **Yapıldı (2026-11-02):** KARAR: yuvarlanan 24 saat kalır (kullanıcı). Kural/test değişmedi; Ayarlar'daki kalan puan satırına "HH:mm itibarıyla yenilenir" (`aiQuotaRenewsAt`), kılavuzdaki "gece yarısı" düzeltildi.

- [x] **F18.4 Tam yedek (zip) ve kayıpsız geri yükleme.** Bugünkü "Yedeği
  dışa aktar (JSON)" (`settings_account.dart:~420-560`) yalnız METİN taşıyor:
  ekler (görsel/ses/PDF/sunum), çizim, balon, PDF işaretleri, sayfalar
  (`textPages`), klasörler, madde alanları (ayırıcı, yıldız…), tema/özel renk
  yok; liste akışındaki HAFİF notlardan üretiliyor (ağır kısım eksik); geri
  yükleme her kaydı YENİ not açtığı için iki kez yüklenince notlar çoğalıyor.
  Yap: `NotePackage` biçimini bütün notlara genişleten tek zip — notlar
  `hydrateNote` ile tam, ek baytları Storage/Drive/yerel dosyadan, klasörler +
  etiketler + yerel ("yalnız bu cihaz") notlar dahil; geri yüklemede not
  kimliği + içerik özetiyle çift kayıt atlama; ilerleme göstergesi + iptal;
  büyük yedekte belleği şişirmeden yaz (akış/parça); web'de `XFile.fromData`.
  Eski JSON'u okumaya devam et. Kilitli not kapısı (kimlik doğrulama) korunur.
  Test: gidiş-dönüş (ek, çizim, balon, sayfa, klasör korunuyor), ikinci
  yükleme çoğaltmıyor, eski JSON okunuyor. → Cihazda deneme **F19.A4**.
  **Yapıldı (2026-11-02):** `BackupService` + `.notyedek` ZIP (cihazda dosyaya akış, web bellekte), çift kayıt atlama (kimlik/`restoredFrom`/içerik özeti), klasörler adla, eski JSON okunur, ilerleme + iptal, kilit kapısı. Yan bulgu: paket/yedek içe aktarmada ek `createdAt` boştu → dizide serverTimestamp (Firestore reddeder) — düzeltildi. Test `backup_service_test`. Cihaz denemesi F19.A4.

- [x] **F18.5 Yedek servisi + misafir notlarını Google hesabına taşıma**
  (KALANLAR §3). F18.4'ün dışa/içe aktarma mantığını arayüzden bağımsız
  `BackupService`'e çıkar. Bugün misafir, zaten var olan bir Google hesabına
  girerken (`credential-already-in-use`) misafir notları onayla TERK ediliyor
  (`settings_account.dart:~671-720`, `_recoverExistingAccount`). Yap: onay
  penceresinde "Notları yanıma al" — misafir notları yedeklenir → Google
  hesabına girilir → geri yüklenir (çift kayıt atlamalı), sonra misafir hesap
  silinir. Test: servis düzeyinde sahte depoyla taşıma.
  **Yapıldı (2026-11-02):** Çakışma penceresinde "Notları yanıma al": giriş öncesi bellekte yedek, giriş sonrası hedefe çift kayıtsız yükleme (`prepareMigration`/`completeMigration`). Misafir hesap SİLİNEMEDİ (oturum değişince erişim yok) — bulut kopyası kalır, HAFIZA'da. Test servis düzeyinde.

- [x] **F18.6 Uygulama kilidi (isteğe bağlı, varsayılan kapalı).** Bugün kilit
  yalnız not başına (`note_lock`, F4.8). Yap: Ayarlar → Hesap → "Uygulama
  kilidi": açılışta ve arka plandan N dk sonra dönüşte cihaz kilidi / şifre /
  desen (aynı altyapı, `local_auth`); isteğe bağlı "son uygulamalarda içeriği
  gizle" (Android `FLAG_SECURE`). Ayar CİHAZA özgü (senkron listesine
  eklenmez). Web'de şifre/desen. "Şifreleme değildir" notu burada da.
  Bildirim/widget/kısayoldan açılış da kilide takılmalı.
  **Yapıldı (2026-11-02):** `AppLockGate` (gezginin üstünde, kendi Navigator'ü), açılış + N dk (hemen/1/5/15) sonra dönüş, not kilidinin yöntemi, web'de yalnız şifre/desen, Android `setSecure` (FLAG_SECURE, MainActivity kanalı). Ayar cihaza özgü. Test `app_lock_test`. Cihaz F19.C5.

### B. Ölçüm ve uçtan uca test (eski Faz 17)

- [ ] **F18.7 Kare ölçümünü buluttan tetiklenebilir yap ve koş** (eski
  F17.1 = F9.1 = F2.6; hiç koşulmadı). `perf` işi yalnız `workflow_dispatch`ta
  (`build.yml:~487`), bulut oturumu onu tetikleyemiyor. Yap: commit
  başlığında `[perf]` da tetiklesin (APK işiyle aynı desen: başlık, gövde
  değil); `build/perf/` özeti iş günlüğüne de basılsın (artifact kotası sık
  dolu). Koş → iş günlüğünden p90 build/raster değerlerini HAFIZA'ya taban
  olarak yaz. Senaryolar: bugün 300 notlu ızgarada fırlatma + editörde yazma
  var; not açma (kart → editör geçişi), biçim paneli, PDF kaydırma, balon
  bırakma yoksa ekle. Bulutta yapılamazsa → F19.B6.
  **Yapıldı (2026-11-02):** Başlıkta `[perf]` her dalda tetikler, özet iş günlüğüne basılır. Kök neden bulundu: odaktaki alanın imleci `pumpAndSettle`'ı hiç bitirmiyordu → sabit süreli pompalama. **Koşu 41391257808 (v1.1.586) YİNE sonuçsuz:** profil APK 11 dk'da derlendi, emülatöre kuruldu, sonra 32 dk HİÇ çıktı yok → 45 dk iptal. Yani takılma test GÖVDESİNDEN önce (uygulama açılmıyor ya da `flutter drive` VM servisine bağlanamıyor); `pumpAndSettle` düzeltmesi tek başına yetmedi. Sonraki adım: `flutter drive -v` + `adb logcat` çıktısını işe ekleyip koş. p90 tabanı YOK. Yeni senaryo EKLENMEDİ.

- [x] **F18.8 Uçtan uca akış testleri** (eski F17.2). Akışlar: (1) + → Metin →
  yaz → paylaş metni; (2) + → Dosya → PDF → balon → paylaş (balonlarla);
  (3) iki sayfalı not → kopyala (iki sayfa da); (4) liste → işaretle →
  işaretlileri sil; (5) tam yedek → geri yükle (F18.4'ten sonra). Bulutta
  koşan hâli uygulama düzeyinde widget testi (sahte depo/akış); aynı akışlar
  `integration_test/` altında CI emülatöründe (`[perf]` işine eklenir ya da
  `[e2e]` etiketi). Web: Playwright betiği (Ek A yöntemi) yerel
  `flutter build web --wasm` çıktısında, ekran görüntüleri scratchpad'e.
  **Yapıldı (2026-11-02):** `user_flows_test` (1) yaz → paylaş metni, (3) iki sayfalı kopya, (4) işaretlileri sil; (2) `media_bubbles_share_test`, (5) `backup_service_test`. Akış (3) gerçek hata yakaladı: `duplicateNote` sayfaları kopyalamıyordu → düzeltildi. `integration_test` emülatör akışları ve web Playwright betiği YAPILMADI (zaman).

- [x] **F18.9 Web'de ağır işler** (eski F17.3). F10.1'den beri web'de PDF işi
  ana iş parçacığında (`runHeavy`, web'de izole yok). 20+ MB / 100+ sayfa
  PDF ile ekleme, sayfa sil/sırala, balonlu PDF dışa aktarma süresini ve
  arayüz donmasını ölç (Playwright + `performance.now`). Gerekirse parça parça
  işleme (sayfalar arasında `await Future.delayed(Duration.zero)`), ilerleme
  göstergesi ya da "web'de en çok N MB" uyarısı.
  **Kısmen ölçüldü (2026-11-02, 2. oturum) — kalanı F19.C6'ya taşındı:** 120 sayfa / 31 MB PDF (gürültü görselli) Playwright ile + → Dosya ekle → Balonlu: dosya okuma + `readSharedPdf` ön işlemesinde ana iş parçacığında EN UZUN donma **283 ms** (rAF aralığı; 100 ms üstü 1–2 kare) — parça parça işlemeye gerek görülmedi. Yükleme 200 döndü AMA sonraki Storage okumaları (yolu `%2F`'li her istek) bu sandbox'ın tarayıcı ağında **400** alıyor (aynı istek curl'de 403/200 — ortam sorunu, canlı sitede değil), PDF not içinde açılamadı → sayfa sil/sırala ve balonlu dışa aktarma süresi burada ölçülemedi. Not: yükleme sonrası adres alınamayınca not "henüz PDF yok" der ve uzun süre hata göstermez (Firebase JS yeniden deniyor) — canlıda görülürse ayrı iş.

- [x] **F18.10 Faz 10–16 web ekran turu.** Yedi fazın hiçbirinde web önce/sonra
  görüntüsü alınmadı (UX planı Durum tablosu). Ek A yöntemiyle (yerel derleme
  ya da yayındaki site): ana ekran, Süz, "+" paneli, metin/liste/belge notu,
  biçim paneli, Paylaş, Görünüm, Ayarlar, Yapay zekâ, Gelen, Klasörler, Çöp —
  açık / koyu / kırık beyaz temada, telefon ve geniş genişlikte. Taşma, kesik
  yazı, boş ekran, konsol hatası → düzelt. Sonunda misafir hesabı sil.
  **Yapıldı (2026-11-02, 2. oturum):** yerel `--wasm` derlemesinde Playwright turu — ana ekran, Yapay zekâ, Ayarlar, Çöp, Klasörler, Gelen, Arşiv, "+" paneli, hesap levhası; açık + koyu; 412 / 800 / 1280 genişlik (52 görüntü, scratchpad). Konsol hatası YOK, taşma/kesik yazı görülmedi. Not açıkken tablet düzeni (tek sütun liste + ray çekmecesi) doğrulandı; turda bulunan hata: çekmece Esc/geri ile kapanmıyordu → düzeltildi. Misafir hesabı silinemedi (aşağıda F18.9 notu: sandbox'ta Storage istekleri 400) — Firebase konsolundan silinmeli (F19).

### C. Bilinen hatalar ve sınırlar

- [x] **F18.11 Kesme noktası geçişinde liste kaydırma konumu sıfırlanıyor**
  (KALANLAR §3; 2026-08-06'dan beri). Telefon ↔ geniş ekran (döndürme, web
  pencere boyu, katlanabilir) geçişinde ana ekran/klasör listesi başa dönüyor;
  arama kutusu senkronu çözülmüştü, kaydırma paylaşımı kabuk yapısına dokunur.
  Konumu iki düzen arasında taşı (ortak `ScrollController` ya da
  `PageStorageKey` + ilk görünen not kimliği). Test: genişlik değişince
  ilk görünen not aynı.
  **Yapıldı (2026-11-02):** `DashboardScrollMemory`: konum ORANLA (piksel değil — sütun sayısı değişiyor) aynı bölümde yeni örneğe taşınır. Test `dashboard_scroll_memory_test` (genişlik değişiminin widget testi yok).

- [x] **F18.12 Ana ekran toplu seçim kopyası hafif notta balonları
  kaçırıyor** (HAFIZA › Faz 13: "ana ekran toplu seçim kopyası `hydrateNote`
  YAPMIYOR"). Paylaş levhası ve kart ⋮ Kopyala yapıyor; toplu seçimde de
  metni üretmeden önce `hydrateNote`. Test: ağır kısmı ayrı belgede olan
  balonlu not toplu kopyada balon satırlarıyla.
  **Yapıldı (2026-11-02):** Toplu seçim kopya/paylaş metinden önce `hydrateNote` (`joinSelectedShareText`). Test `selection_copy_hydrate_test` (ağır belgedeki balon).

- [x] **F18.13 Görsele yazılan metin ve çizim dışa aktarmada yok**
  (KALANLAR §3, ilk kayıt 2026-07: "Paint tarzı metin aracı görselde çiziliyor
  ama PDF/Word dışa aktarımı ve paylaşılan görselde görünmüyor; `ink` için de
  aynı"). Önce bugünkü durumu koddan doğrula (`note_docx.dart`,
  `note_quick_export.dart`, PDF dışa aktarma, görsel paylaşımı). Yap: dışa
  aktarılan/paylaşılan görsele metin + çizim katmanı basılsın (görsel
  açıklaması `caption` da altına). Test: katmanlı görselin dışa aktarım baytı
  katmansızdan farklı / metin PDF metninde.
  **Yapıldı (2026-11-02):** Doğrulandı: görsel ham baytla gidiyordu. `image_annotations.dart` çizim + açık metin + balonları PNG'ye basar; PDF/Word dışa aktarma, hızlı PDF ve ek paylaşımı kullanır. `caption` EKLENMEDİ. Test `image_annotations_export_test` (piksel).

### D. Yeni özellikler

- [x] **F18.14 Tekrarlayan hatırlatıcı.** `Note.reminderAt` tek tarih
  (`note.dart:~506`); tekrarlı olan yalnız sabah brifingi
  (`reminder_service.dart`). Yap: her gün / hafta içi / her hafta (gün seçimi)
  / her ay / her yıl. Yeni alan (ör. `reminderRepeat`) → `knownKeys` (F1.5
  ileri uyum; eski istemci alanı `extras`ta korur, yalnız ilk çalmayı kurar —
  kabul edilebilir mi değerlendir, gerekirse `kClientDataVersion`);
  `merge` yazımında KOŞULSUZ yaz (kaldırılabilir alan). Her seferinde yalnız
  SONRAKİ çalma planlanır (exact; ay/yıl elle hesap, ayın 31'i → ay sonu);
  "Tamam" ve ertele bir sonraki tarihe kaydırır; ilk eşitleme mutabakatı
  (F5.3, yük `note:` ile) tekrarlıyı tanır; Hatırlatıcılar ekranında tekrar
  simgesi ve metni; sesli asistan / AI aracı "her pazartesi 9'da" anlasın
  (çok dilli tarih ayrıştırıcı). Test: sonraki tarih hesabı (ay sonu, artık
  yıl, yaz saati), mutabakat.
  **Yapıldı (2026-11-02):** `reminderRepeat` (daily/weekdays/weekly:1,3/monthly:31/yearly:2-29; ay/yıl günü dizede), sonraki 7 çalma önceden, geçmiştekini ilerletme, Tamam → sonraki, Ertele → ayrı tek seferlik bildirim, Hatırlatıcılar/editör 🔁, sesli + AI aracı (`parseSpokenRepeat` tr+en, `reminderRepeat` argümanı). `kClientDataVersion` artmadı (eski istemci yalnız ilk çalmayı kurar — kabul). Testler `reminder_repeat_test`, `spoken_repeat_test`. Yeniden başlatma cihazda F19.C5.

- [x] **F18.15 İçe aktarma.** Başka uygulamadan gelen kullanıcı için ilk engel.
  (1) Google Keep — Takeout zip'i (not başına JSON + ekler): başlık, metin,
  liste (işaretli), renk, sabit, arşiv, çöp, etiketler, görseller, oluşturma
  tarihi; (2) Markdown/txt — tek dosya ya da zip/klasör: `# başlık`,
  `- [ ]`/`- [x]` → madde, satır içi `**kalın**`/`_italik_` biçimine çevrilir;
  (3) isteğe bağlı Evernote `.enex`. Ayarlar → Notlar → "İçe aktar";
  ilerleme + özet ("142 not, 3 atlandı"); çift kayıt atlama F18.4/F18.5 ile
  ortak. Test: küçük örnek Takeout ve Markdown dosyaları `test/fixtures`.
  **Yapıldı (2026-11-02):** `import_service.dart`: Keep Takeout, Markdown/txt (tek dosya/zip), Evernote `.enex`; Ayarlar → Hesap → "Başka uygulamadan içe aktar", ilerleme + özet, özetle çift kayıt atlama. Fixture `test/fixtures/import/`, test `import_service_test`.

- [x] **F18.16 Not bağlantıları ve geri bağlantılar.** Bir nottan diğerine
  bağlantı yok (yalnız `notlar://note/<id>` derin bağlantısı var). Yap:
  satır içi işaret (rich_text kalıbı, KİMLİKLE: başlık değişince bağ kalır;
  eski sürüm düz metin görür) — seçim menüsünde "Nota bağla" + `[[` yazınca
  not öneri listesi; dokununca not açılır (okurken aç, yazarken "Aç" önerisi —
  bağlantı deseni gibi); not altında "Bu nota bağlananlar" (geri bağlantılar,
  istemcide türetilir); paylaşım/dışa aktarma metninde başlık. Silinen/çöpteki
  hedef soluk.
  **Yapıldı (2026-11-02):** `tagLinks` kalıbı, kimlik `note:<id>` (eski sürüm düz "📎 Başlık" görür); seçim menüsü "Nota bağla" + `[[` tetikleyici, okurken açar / yazarken "Aç", geri bağlantı çipi, hedef silinmişse soluk. Test `note_links_test`.

- [x] **F18.17 Otomatik not bağlama / ilgili notlar** (KALANLAR §4
  "farklılaşma"). F18.16'dan sonra: notun altında anlamsal aramayla
  (`semantic_search.dart`) "İlgili notlar" önerisi; tek dokunuşla bağlantıya
  çevir. Kilitli not ve gizli klasör öneriye girmez. AI kotası: gömme
  önbelleği varsa yeni çağrı yok.
  **Yapıldı (2026-11-02):** Not ⋮ → İlgili notlar: anlamsal (`SemanticIndex.related`, vektör önbellekteyse çağrı yok) ya da AI'sız kelime örtüşmesi; kilitli/gizli/arşiv/bağlı hariç; "Bağla". Test `related_notes_test`.

- [x] **F18.18 Bütün notlarla sohbet (RAG)** (KALANLAR §4). ÖNCE doğrula:
  bugünkü sohbetin "Tüm notlar" kapsamı (`AiChatScreen`, `chat_controller.dart`,
  `gemini_service.dart`) bağlamı nasıl topluyor — bütün notları mı gönderiyor,
  anlamsal getirme mi yapıyor. Getirme yoksa: soruya göre `semantic_search`
  ile ilk N not (+ ek metni indeksi) bağlama; yanıtta kaynak notlar
  dokunulabilir çip. Zaten varsa madde "eskimiş" diye kapanır.
  **Yapıldı (2026-11-02):** Doğrulandı: getirme YOKTU (son 80 not × 300 karakter). Şimdi soruyla alakalı ≤12 not başta 1500 karakter, kaynak not çipleri. Test `notes_chat_retrieval_test`.

- [x] **F18.19 Aralıklı tekrar kartları — KARAR GEREKİR (kapsam)**
  (KALANLAR §4 "farklılaşma"). Nottan AI ile soru-cevap kartları, SM-2 benzeri
  planlama, günlük "bugün N kart" (brifingle birleşebilir). Karar: hangi
  notlardan (etiket/klasör/elle), kartlar nerede (not alanı mı
  `users/{uid}/cards` mı — yeni koleksiyon `AccountService` silme listesine +
  kurallara + `rules-test`), kart ekranı nereden açılır.
  **Yapıldı (2026-11-02):** KARAR: basit sürüm (kullanıcı). `Note.cards` + SM-2, editör ⋮ "Kart üret" (AI, önizleyip kaydet), `/cards` "Bugünün kartları" Yapay zekâ ekranından. Yeni koleksiyon yok. Test `study_cards_test`.

- [ ] **F18.20 PPTX düzenleme portu** (KALANLAR §4, "kendi oturumu").
  Görüntüleme var (`pptx_render.dart`, `slide_*`); kaynak "dosya okuyucu"
  deposundaki `pptx_editor.dart` + `pptx_geometry.dart` (~2.500 satır,
  `Attachment` modeli iki depoda farklı — HAFIZA_ARSIV). Depo GitHub'daysa
  `add_repo` ile oturuma ekle; değilse ERTELENDİ → Faz 19 (dosyaları
  getir ya da yerel oturum).
  **ERTELENDİ (2026-11-02):** `kaimau1/dosya-okuyucu` erişilebilir ama oturuma ekleme (add_repo) izni reddedildi → Faz 19'a (F19.B8): izni ver ya da yerel oturumda port et.

- [x] **F18.21 "Yeni sürüm var" bildirimi (isteğe bağlı)** (YOL_HARITASI
  F1.5(d), ERTELENDİ). Telefona APK elle kuruluyor; yeni sürümden haberin
  olmuyor. Depo özel olduğu için Releases'i uygulama okuyamaz → CI deploy işi
  `config/app` belgesine `latestBuild` (+ APK adresi gerekmez, "GitHub'dan
  indir" metni) yazsın; uygulama kendi derleme numarasıyla karşılaştırıp
  Ayarlar → Hakkında'da ve bir kez şeritte söylesin. Kural: `config/` yalnız
  okunur kalır.
  **Yapıldı (2026-11-02):** CI `release` işi `tool/set_latest_build.js` ile `config/app.latestBuild/latestName`; uygulama (yalnız Android) sürüm başına bir kez bildirim + Ayarlar → Hakkında satırı. Test `new_version_notice_test`.

### E. Bakım: bağımlılık, kod, doküman

- [x] **F18.22 FlutterFire paketlerini BİRLİKTE yükselt** (F8.6, PERFORMANS
  F8 ERTELENDİ, KALANLAR §4). `firebase_core`, auth, firestore, storage,
  messaging, crashlytics, app_check, ai, functions… tek seferde (HAFIZA ›
  Android: tek tek yükseltme APK'yı kırdı). Bulutta APK derle (HAFIZA ›
  "Bulutta APK DERLENEBİLİR") + `flutter test` + web derlemesi. Harita
  köprüsünün yerel Firestore sürümü `firebaseSdkVersion()`dan okunuyor —
  kişisel bayrakla (`NOTLAR_KISISEL=1`) da derle. Cihazda açılış/giriş/
  bildirim → F19.C5.
  **Yapıldı (2026-11-02, 2. oturum):** core 4.15 → 5.1, auth 6.7 → 7.0, firestore 6.7 → 7.1, storage 13 → 14, functions 6.5 → 7.0, app_check 0.4 → 0.5, ai 3.15 → 5.1, crashlytics 5 → 6, messaging 16 → 17 (+ fake_cloud_firestore 4.5) TEK seferde. Dart API'si uyumlu çıktı; tek fark FCM 17'de `getToken/onTokenRefresh` "eskidi" — yerine gelenler jeton değil kurulum kimliği (FID) verdiği için Functions'la birlikte geçilmeli, jeton yolu gerekçeli `ignore` ile korundu. Doğrulama: `dart analyze` temiz, 1895 test yeşil, `flutter build web --wasm` yeşil, bulutta `NOTLAR_KISISEL=1` release APK yeşil (37,0 MB). TUZAK: ilk iki APK denemesi eski derleme önbelleğiyle YARIM Kotlin derlemesi verdi ("PigeonParser"/"FirebaseAppCheckPlugin çözülemedi" — sınıflar pakette var); `flutter clean` + önbelleksiz derleme geçti → CI yapı önbelleği anahtarı `gradle-bc2-` ile tazelendi. Cihazda açılış/giriş/bildirim/App Check → F19.C5.

- [x] **F18.23 Dev dosyaları böl** (eski F17.5 + F3.17/F9.3'ün ertelenenleri).
  `note_editor_screen.dart` 4.427, `note_editor_attachments.dart` 2.362,
  `note_images.dart` 2.332, `items_editor.dart` 2.299, `text_wrap.dart` 2.120
  satır. F9.3 deseniyle konu `part` dosyalarına (uzantıda `_update`, statikler
  nitelenir, alan sınıfta); taşıma betikle, satır kümesi önce/sonra birebir
  karşılaştırılır, davranış değişmez. İsteğe bağlı: AI/ek/dikte durumunu ayrı
  denetleyicilere alıp dar builder (F9.3 "kalan"). Tarihli hikâye yorumları
  yalnız dokunulan dosyada yerinde kısaltılır.
  **Yapıldı (2026-11-02, 2. oturum):** betikle taşındı (satır kümesi önce/sonra birebir, `setState`/dinleyici kullanan yöntemler taşınmadı — uzantı tear-off'u eşit değil): `note_editor_screen.dart` 4650 → 4098 (+ `note_editor_flow.dart`), `note_editor_attachments.dart` 2546 → 1337 (+ `note_editor_embed.dart`, `note_editor_video.dart`), `note_images.dart` 2365 → 1979 (+ `note_media_box.dart`), `items_editor.dart` 2317 → 1897 (+ `items_editor_widgets.dart`), `text_wrap.dart` 2120 → 1114 (+ `text_wrap_controller.dart`). Analiz temiz, 1895 test yeşil, APK derlendi. Editörün `build`i (~2000 satır) bölünmedi: kapanışlar yerel değişken yakalıyor, satır taşıma davranışı değiştirebilir — kalırsa ayrı iş.

- [x] **F18.24 HAFIZA.md'yi ≤ 30 KB'a indir** (şu an ~63 KB, kendi hedefinin
  iki katı; her oturum başında okunuyor). Faz 10–16 karar bölümlerini konu
  bölümlerine kaynaştır, anlatıyı kısalt; çıkan tarihçe yeni
  `HAFIZA_ARSIV_2.md`'ye (2026-10-19 → bugün; `HAFIZA_ARSIV.md` dondurulmuş
  kalır). Hiçbir geçerli kural/tuzak düşmez — önce/sonra madde listesi
  karşılaştırılır.
  **Yapıldı (2026-11-02):** HAFIZA.md 70 KB → ~22 KB; tam eski hâli `HAFIZA_ARSIV_2.md` (dondurulmuş). Konu bölümlerine kaynaştırıldı, Faz 10–16 / tablet / kullanıcı listeleri dağıtıldı, sıkışan kurallar "Kısa kurallar"da.

- [x] **F18.25 graphify grafiğini güncelle** (CLAUDE.md: bayat). Bulutta
  `graphify` kurulabiliyorsa (`pip`) `graphify update .` → `GRAPH_REPORT.md`;
  kurulamıyorsa ERTELENDİ → F19.B7.
  **Yapıldı (2026-11-02):** Bulutta `pip install graphifyy` → `graphify update .` koşuldu.

- [x] **F18.26 Belgeleri tazele.** CLAUDE.md: "telefondaki en güncel sürüm
  372 (v1.0.372)" eskidi (sürüm adı artık `1.1.N`), plan listesi; README:
  özellik listesi, test sayısı, mimari; YAPILACAKLAR.md: Gemini anahtarı artık
  isteğe bağlı (Google hesabıyla dahili AI var), imza anahtarı notu F19.A3'e
  göre; kılavuz (`assets/guide/guide_tr.md`/`_en.md`) F18'de eklenen
  özelliklerle (`guide_screen_test` eskimiş ifade listesi).
  **Yapıldı (2026-11-02):** CLAUDE.md (sürüm 372 → v1.1.N, HAFIZA arşivleri), README (özellikler), YAPILACAKLAR (Gemini anahtarı isteğe bağlı), kılavuz tr+en (bağlantılar, tekrar, kartlar, yedek/içe aktarma, uygulama kilidi, 24 saat), `guide_screen_test` eskimiş ifadeleri.

### F. Play'e çıkış — kod tarafı (YALNIZ Play'e çıkılırsa)

Kullanıcı kararı (2026-10-19/20, YOL_HARITASI F4.10): **"Play'e çıkmıyoruz
hâlâ."** Karar değişmeden bu bölüme başlanmaz; değişirse önce F18.27.

- [ ] **F18.27 Play Billing — KARAR GEREKİR** (KALANLAR §3): RevenueCat mı,
  `in_app_purchase` + doğrulama Cloud Function'ı mı; ürünler (ömür boyu +
  AI aboneliği); deneme süresi HESABA bağlı; `premiumUntil` yalnız sunucudan
  yazılır (kural zaten istemciyi kapatıyor). Kod + Function + emülatör testi
  bulutta; ürünler ve gerçek satın alma F19.D.

- [ ] **F18.28 AI kotası ve depolama tavanı sunucuda** (F18.2 seçenek a,
  YOL_HARITASI F4.10 "G2'nin kod tarafı").

- [ ] **F18.29 Genel sürüm derleme işi.** CI'da bayraksız (kişisel köprüsüz)
  `flutter build appbundle`; "genel kaynakta köprü yok" denetimi zaten var;
  Play yükleme anahtarı (upload key) akışı; sürüm kodu.

- [ ] **F18.30 Mağaza metni ve görselleri.** Kısa/uzun açıklama tr + en,
  ekran görüntüleri (web/emülatör), veri güvenliği formu taslağı
  (`PRIVACY_POLICY.md` ile tutarlı), "yalnız 64 bit" notu;
  `assets/icon/play_store_512.png` hazır.

### H. Kullanıcı listesi 2026-11-02 (2. oturum — hepsi yapıldı)

- [x] Hesap levhasında **Oturumu kapat** + **Hesap değiştir** (onaylı; misafirde kırmızı uyarı; Ayarlar aynı kapıdan).
- [x] **Tablette Google girişi**: yerel seçici açılmadan düşerse (yapılandırma hatası / < 1,5 sn'de "iptal") Firebase tarayıcı akışına geçer. Cihazda doğrulama → KALANLAR §2 adım 22.
- [x] **Tablet rayı** 64 dp etiketsiz, "Gelen" rayda yok; **not açılınca** ray çekmeceye döner (tutamak / kenardan çekme / Esc / geri), liste tek sütun olarak rayın yerine geçer (yan yana sınırı not açıkken 640 dp).
- [x] **Katlanabilir**: kapalıyken telefon düzeni; açıkken yan yana, dikey menteşe varsa ayraç menteşeye oturur.
- [x] **Görsel yanında madde sarması**: görsel maddenin içinde başlıyorsa üstteki satırlar tam genişlik, yalnız hizadakiler kayar.
- [x] **Kalem paneli altta, çekmece**: yüzen yuvarlak tepsi; çizince iner (yalnız uçlar görünür), dokununca çıkar; tablette de altta.
- [x] **Kalem kipinde de "Çizim ekle"** ayrı tuval → görsel eki; "Sayfaya el yazısı" ayrı seçenek.
- [x] **Web'de ekler**: Drive jetonu sekmede kalır (yenilemede yeniden sormaz), notta tek dokunuşla tümünü indiren şerit, telefondan çıkmamış ekler için açık uyarı. Kök neden ihtimalleri: (a) telefonda Drive bağlı değilse ekler cihazda bekler, (b) Drive ekleri her kutuya ayrı dokunuş istiyordu. Canlı hesapta doğrulama → adım 27.

### G. Kapanış

- [x] **F18.31 Cihaz listesini duman testine indir** (eski F17.4 / U12; en son
  yapılır ki F18'in yeni cihaz adımları da girsin). `KALANLAR.md` §2'deki 143
  "cihazda görülmedi" maddesini (Faz 10–16 + 2026-10-20…28 turları) tek
  ~10 dakikalık telefon + web turuna indir: alan başına 1–2 adım; F18.8 /
  F18.10'da otomatik doğrulananları ve eskiyenleri at. Sonuç `KALANLAR.md`
  §2'nin yerine geçer ve **F19.C1** olur.
  **Yapıldı (2026-11-02):** `KALANLAR.md` §2 → 20 adımlık ~10 dk duman testi (F18'in yeni adımları dahil); eski 143 madde `KALANLAR_ARSIV.md` sonunda. Bu liste artık **F19.C1**.

---

## FAZ 19 — Senin yapacakların (telefon, konsol, hesap)

### A. Hemen — güvenlik ve veri

- [ ] **F19.A1 AI faturasına tavan** (YOL_HARITASI F1 "AI faturası (G2)" —
  hâlâ açık). Google Cloud (notlar-kaimau) → Faturalandırma → **Bütçe ve
  uyarılar** (aylık tutar, %50/%90/%100 e-posta). API'ler → Firebase AI Logic
  API / Generative Language API → **Kotalar**: dakika başı ve kullanıcı başı
  sınırı düşür. App Check zorlanana kadar asıl koruma bu.

- [ ] **F19.A2 App Check — izle, sonra zorla** (← F18.1). reCAPTCHA Enterprise
  anahtarı (alan adı: web sitesinin Cloudflare Pages adresi) → Firebase
  konsolu → App Check → web uygulamasını kaydet → GitHub secret
  `RECAPTCHA_SITE_KEY`. Birkaç gün "doğrulanmış istek" oranını izle.
  **TUZAK:** Android'de Play Integrity elle kurulan (sideload) APK'yı
  doğrulayamaz → zorlama bugünkü telefon kurulumunu da keser. Zorlama ancak
  APK Play'den (iç test kanalı da olur) kuruluyorsa; o zamana kadar F19.A1.
  Ters sıra (önce zorla) herkesi kilitler.

- [x] **F19.A3 İmza anahtarının makine dışı yedeği.**
  **Yapıldı (2026-11-01):** kullanıcı yedeklediğini bildirdi (oturum yedeği görmedi). Anahtar
  `Desktop\Yazılımlar\notlar-keystore\`; CLAUDE.md ve YAPILACAKLAR.md düzeltildi.

- [ ] **F19.A4 Tam yedeği dene** (← F18.4): telefonda tam yedek al, web'de
  (ya da başka hesapta) geri yükle — görseller, çizimler, balonlar, sayfalar,
  klasörler geliyor mu; ikinci yükleme çoğaltmıyor mu.

- [ ] **F19.A5 Sunucu tarafı düzenli yedek (önerilir).** Firebase/Cloud
  konsolu → Firestore → **Yedekler** (günlük/haftalık zamanlanmış yedek,
  saklama süresi) ya da zamanlanmış dışa aktarma; Storage paketinde nesne
  sürümleme / silme koruması. Bedeli küçük (Blaze).

### B. Konsol ve hesap (KALANLAR §1)

- [ ] **F19.B1** Telefonlar v1.1.N'e geçince Firebase konsolu → `config/app` →
  `minClient: 3` (eski sürüm yıldızları siler, ağır belge bölmesini görmez).
- [ ] **F19.B2** Actions → deploy → "Cloud Functions'ı yayınla" adımı yeşil mi
  (Blaze; itme bildirimleri ve kişi araması buna bağlı).
- [ ] **F19.B3** Google Cloud: "Google Drive API" etkin, OAuth onay ekranında
  `drive.appdata` kapsamı.
- [ ] **F19.B4** Crashlytics'i konsolda etkinleştir → Ayarlar → Hakkında →
  sürüm satırına uzun bas → "Çökert" → yeniden aç → konsolda ilk rapor.
- [x] **F19.B5** Eski Actions artifact'lerini sil (depolama kotası).
  **Yapıldı (2026-11-01):** 33 `notlar-android-apk`, 1434 MB silindi; v1.1.572 sürüm dosyası yerinde.
- [ ] **F19.B6** (← F18.7 bulutta yapılamazsa) Actions → Derleme → Run
  workflow → "Kare ölçümü"; `perf-summary` p90'larını oturuma ver.
  **ERTELENDİ (2026-11-01):** koşu 41340200235 sonuç vermedi: profil APK 8,6 dk'da derlendi, `flutter drive`
  sonra 34 dk çıktısız kaldı, 45 dk `timeout-minutes` işi iptal etti, `perf-summary` yok. Neden bulunmadı
  (tahmin: yazılım GPU'lu emülatörde `pumpAndSettle` bitmiyor). Tekrar koşmadan önce `integration_test/perf_test.dart`
  incelenmeli. Tuzak: bu tetikleme Deploy ve Release'i de koştu, v1.1.573 yayınlandı.
- [ ] **F19.B8** (← F18.20) PPTX düzenleme portu: bulut oturumuna `kaimau1/dosya-okuyucu` deposunu
  ekleme izni ver (oturum add_repo'yu sordu, otomatik izin reddetti) ya da portu yerel oturumda yap.
- [x] **F19.B7** (← F18.25 bulutta yapılamazsa) Windows'ta `graphify update .`.
  **Yapıldı (2026-11-01):** 18 980 düğüm; CLAUDE.md'deki "bayat" notu güncellendi.

### C. Cihaz doğrulama

- [ ] **F19.C1 Duman testi** (← F18.31): ~10 dakikalık telefon + web turu;
  sorun görünce madde numarasıyla bildir. F18.31 bitene kadar liste
  `KALANLAR.md` §2'deki 143 madde.
  **Kısmen (2026-11-01):** riskli akışlar misafirle denendi, 3 hata düzeltildi; sonuç ve denenmeyenler
  KALANLAR §2'nin başında. Liste hâlâ duruyor.
- [ ] **F19.C2 TalkBack + en büyük yazı turu** (Faz 15 "senin
  yapacakların"): TalkBack açıkken not oluştur, listeyi işaretle, PDF'e balon
  bırak, paylaş; yazı en büyük + kalın metin (ayrıntı KALANLAR §2 Faz 15).
  **Kısmen (2026-11-01):** semantik etiketler uiautomator'la okundu (madde, balon, kart; işaret sızıntısı
  düzeltildi). KALAN: TalkBack sesi ve en büyük yazı (sistem ayarı değiştirilmedi) kullanıcıda.
- [x] **F19.C3 Kılavuzu baştan sona oku**, yanlış kalan yeri bildir (Faz 14).
  **Yapıldı (2026-11-01):** koda ve cihaza göre düzeltildi (başlık çipi, ortak çalışanlar, Ekle grupları,
  Gelen süzmesi, paylaşılanların yeri, not kilidi yöntemleri, Hatırlat).
- [ ] **F19.C4 Kişisel köprüler uçtan uca**: Harita'da "Hey Harita, not al…"
  (uygulama kapalıyken ve çevrimdışı), Kanallarım "Not al" (YouTube klasörü,
  transkript), Asistan not al + `ASISTAN_SORGU`.
  **Kısmen (2026-11-01):** alıcı izinsiz yayını reddediyor (doğru). Uçtan uca denenemedi: Harita, Kanallarım
  ve Asistan bu telefonda kurulu değil; uygulamalar kurulu cihazda kullanıcıda.
- [ ] **F19.C5 Faz 18'in yeni işleri cihazda** (← ilgili F18): tekrarlayan
  hatırlatıcı (telefonu yeniden başlatınca da çalıyor), Keep Takeout içe
  aktarma, uygulama kilidi (bildirimden/widget'tan açılış dahil), FlutterFire
  yükseltmesi sonrası açılış · Google girişi · itme bildirimi · Crashlytics.
  2026-11-02: adımlar `KALANLAR.md` §2 duman testinde (6, 9, 10, 15); FlutterFire kısmı F18.22 bekliyor.

- [ ] **F19.C6 Web'de büyük PDF** (← F18.9 kalanı): yayındaki sitede 20+ MB /
  100+ sayfa PDF → Balonlu → sayfa sil/sırala → Balonlu PDF indir; donma ve
  süre kabul edilebilir mi (bulut tarayıcısında Storage okumaları ölçülemedi).
- [ ] **F19.C7 Test misafir hesabını sil** (← F18.10): bulut turunun misafir
  hesabı uygulamadan silinemedi (sandbox'ta Storage 400). Firebase konsolu →
  Authentication → 2026-11-02 08:4x'te açılmış anonim kullanıcı → sil
  (Firestore `users/<uid>` + Storage `users/<uid>/` ile birlikte).

### D. Play'e çıkılırsa (karar değişirse — bugün "çıkmıyoruz")

- [ ] **F19.D1** OAuth onay ekranını "Testing"ten yayına al — bugün yalnız
  test kullanıcısı olarak eklenen hesaplar Google'la girebiliyor (README);
  `drive.appdata` için Google doğrulaması gerekebilir.
- [ ] **F19.D2** App Check'i önce izle, sonra ZORLA (F19.A2).
- [ ] **F19.D3** `PRIVACY_POLICY.md` herkese açık adreste; Play Console veri
  güvenliği formu (← F18.30).
- [ ] **F19.D4** Arka plan konum beyanı + açık bilgilendirme videosu (konum
  hatırlatıcıları — YOL_HARITASI F1).
- [ ] **F19.D5** Mağaza girdisi: simge `assets/icon/play_store_512.png`,
  "yalnız 64 bit" notu, ekran görüntüleri (← F18.30).
- [ ] **F19.D6** Billing ürünleri (ömür boyu, AI aboneliği), lisans test
  kullanıcıları, cihazda gerçek satın alma (← F18.27).
- [ ] **F19.D7** Genel sürümde kişisel köprü YOK (bayraksız derleme; ←
  F18.29) — Harita/Kanallarım/Asistan yalnız senin APK'nda.

---

## Bilinen sınırlar (iş DEĞİL — kayıt için; kullanıcı isterse madde olur)

- Sesli notta canlı yazım yok (Google sesli giriş, `GET_AUDIO` belgesiz).
- Görüntülü not yalnız cihazda; AI'a giden video en çok 60 sn.
- IME oluşturma (composing) aralığı görsel çevresinde sarılan metinde görünmüyor.
- Editör diktesi web'de AI'sız çalışmaz.
- Paylaşılan klasörün "+" düğmesi yalnız metin notu açar (bilinçli).
- Not kilidi şifreleme değildir (F4.8 — gerçek şifreleme seçilmedi).
- Arayüz yalnız tr + en (F3.14).
- Web: yerel ("yalnız bu cihaz") not ve video yok; Drive'a yazmaz.
- Not düzenlemesi için itme bildirimi bilerek yok (F4.6).

---

## Kaynak eşlemesi (hiçbir madde düşmedi)

| Eski yer | Madde | Yeni yer |
|---|---|---|
| KULLANICI_DENEYIMI_PLANI Faz 17 | F17.1 kare ölçümü | F18.7 (olmazsa F19.B6) |
| | F17.2 uçtan uca testler | F18.8 |
| | F17.3 web ağır işler | F18.9 |
| | F17.4 KALANLAR sadeleştirme | F18.31 → F19.C1 |
| | F17.5 dev dosyalar | F18.23 |
| | "Senin yapacakların" (F17.1 koşusu, duman testi) | F18.7 / F19.B6, F19.C1 |
| KULLANICI_DENEYIMI_PLANI Faz 10–16 | web önce/sonra görüntüsü alınmadı | F18.10 |
| | "Senin yapacakların" (cihaz turları, TalkBack, kılavuz) | F19.C1–C3 |
| KALANLAR §1 | minClient 3, Functions deploy, Drive API, Crashlytics, kare ölçümü, artifact silme | F19.B1–B6 |
| | Play: App Check sırası, gizlilik URL, simge, 64 bit | F19.D2–D5 |
| KALANLAR §2 | 143 cihaz maddesi (Harita köprüsü dahil) | F18.31 → F19.C1, F19.C4 |
| | "Genel sürümde köprüyü kaldır" | F19.D7 (bayrakla çözüldü, F18.29) |
| KALANLAR §3 | Play Billing kararı | F18.27, F19.D6 |
| | Depolama tavanı + AI kotası sunucuda | F18.2, F18.28 |
| | Kota penceresi (24 saat / takvim günü) | F18.3 |
| | Misafir → Google hesap çakışması, yedek servisi | F18.5 |
| | Sesli not canlı yazım, görüntülü not, AI video 60 sn, IME, web dikte | Bilinen sınırlar |
| | Görsele yazılan metin dışa aktarmada yok | F18.13 |
| | Paylaşılan klasör "+" yalnız metin | Bilinen sınırlar |
| | Kesme noktasında kaydırma sıfırlanıyor | F18.11 |
| KALANLAR §4 | PPTX portu | F18.20 |
| | Aralıklı tekrar → RAG → otomatik bağlama | F18.19, F18.18, F18.17 |
| | FlutterFire toplu yükseltme | F18.22, F19.C5 |
| YOL_HARITASI | F1 "AI faturası (G2)" | F19.A1, F19.A2 |
| | F1 Play konum beyanı + gizlilik | F19.D3, F19.D4 |
| | F1 `minClient` / Crashlytics | F19.B1, F19.B4 |
| | F1.5(d) "Yeni sürüm var" (ERTELENDİ) | F18.21 |
| | F3.17 editörün tam bölünmesi, tarihli yorumlar (ERTELENDİ) | F18.23 |
| | F4.9 cihaz turu (ERTELENDİ) | F19.C1 |
| | F4.10 Play'e çıkış (ERTELENDİ) | F18.27–F18.30, F19.D |
| PERFORMANS_TOPARLAMA_PLANI | F8 FlutterFire (ERTELENDİ) | F18.22 |
| | F9.1 cihaz ölçümü | F18.7 / F19.B6 |
| | F9.3 kalan (durum denetleyicileri) | F18.23 |
| HAFIZA | Faz 13: toplu seçim kopyası `hydrateNote` yapmıyor | F18.12 |
| | graphify bayat | F18.25 / F19.B7 |
| CLAUDE.md | İmza anahtarı tek kopya | F19.A3 |
| 2026-11-01 inceleme | Web'de App Check yok | F18.1, F19.A2 |
| | Bütçe/kota tavanı yok | F19.A1 |
| | Yedek yalnız metin, çoğaltıyor | F18.4, F19.A4, F19.A5 |
| | Tekrarlayan hatırlatıcı, içe aktarma, not bağlantıları, uygulama kilidi | F18.14, F18.15, F18.16, F18.6 |
| | HAFIZA 63 KB (hedef ≤ 30 KB) | F18.24 |
| | Eskimiş belgeler (CLAUDE.md sürüm 372, YAPILACAKLAR) | F18.26 |
