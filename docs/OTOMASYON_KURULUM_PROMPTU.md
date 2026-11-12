# Otomasyon kurulum promptu (her proje / hesap için bir kez yapıştır)

> Kullanım: yeni bir projede ya da hesapta zamanlanmış görev, gece zinciri veya uzun iş
> başlatmadan önce aşağıdaki çizginin altını OLDUĞU GİBI ilk mesaj olarak yapıştır.
> Köşeli parantezleri doldur (bilmiyorsan boş bırak, Claude kendisi bulur ve sorar).
> Kaynak: "not" projesinde 2026-11-03 → 2026-11-12 arasında yaşanan sorunlar.

---

Bu projede gözetimsiz/zamanlanmış çalışma kuracağız. Önce aşağıdaki kuralları projeye
kalıcı olarak yerleştir, sonra işe başla. Kuralları sohbette tekrar etme; dosyaya yaz.

**Proje bilgisi:** depo yolu: [ ] · hedef platform: [ ] · CI: [GitHub Actions / yok] ·
test cihazı: [USB telefon modeli / yok] · ana model: [ ] · plan: [Pro / Max].

## 0. Kurulum (bu oturumda, ben buradayken bir kez)
1. Depoyu tara; derleme/test komutlarını, SDK yolunu (PATH'te olmayabilir — "command not
   found" görünce SDK yok sanma, tam yolu bul), CI'ı ve imza/gizli dosyaları bul.
2. `CLAUDE.md` yaz ya da güncelle, **≤ 10 KB**: yalnız her oturumda geçerli kurallar ve
   komutlar. Tarihçe, plan ayrıntısı, bitmiş işler BURAYA GİRMEZ (her oturum ve her alt
   ajan bu dosyayı baştan yükler — her KB her çağrıda yeniden ödenir).
3. `OTOMASYON.md` yaz, **≤ 12 KB**: tur adımları (aşağıdaki §2), işçi kuralları (§3),
   cihaz kuralları (§5) ve kısa Kuyruk tablosu (satır ≤ 200 karakter; ayrıntı ayrı
   `KUYRUK_AYRINTI.md`'de, paket başına bir bölüm; bitmiş satırlar tek "Biten: P01–P12"
   satırına iner).
4. Hafıza: proje bilgisi `HAFIZA.md` (≤ 30 KB, boyut bekçi testi yaz) + konu dosyaları
   `docs/hafiza/*.md`; kullanıcı tercihi `.claude` memory'ye. Tarihçe arşive, dondurulmuş.
5. Zamanlanmış görevi BEN BURADAYKEN aç (gözetimsiz oturum yeni görev/oturum açamaz, onay
   ister). Tek görev: saatlik "devam" (kilide bakar, kuyruğu sürdürür). Saat başına yakın
   değil, dağınık bir dakika seç. Bilgisayar uykuda görev çalışmaz — uyku ayarını söyle.
6. Kullanılmayan eklenti/skill/MCP sunucularını listele ve kapatmayı öner (her biri her
   çağrıda bağlam yükü). Ölü oturumlardan kalan MCP süreçlerini kontrol et.
7. Bitince bana: kurulan dosyalar, zamanlanmış görev saati ve kontrol etmem gerekenler.

## 1. Token ekonomisi (en çok limit buradan gidiyor)
- Her araç çağrısı bütün bağlamı yeniden gönderir: **az ve toplu çağrı**; bağımsız
  okumaları tek mesajda paralel yap.
- Büyük dosyayı BİR kez oku; aynı tabloyu ikinci kez dökme. Çıktıyı kes
  (`| tail -n 40`, `cut -c1-300`); "geçti" satırlarını okuma (`--reporter failures-only`).
- Hafıza/plan dosyalarını baştan okuma, Grep ile ara. Bayat bilgi grafiği (graphify vb.)
  varsa önce güncelle ya da kullanma; satır bilgisini koddan doğrula.
- Yürütücü İNCE: kod, test, CI izleme, kırmızı CI düzeltme, plan/kuyruk/sürüm notu
  güncellemesi ALT AJANIN işi. Yürütücü raporu, `git log`/diff özetini ve CI sonucunu
  kontrol edip birleştirir. Alt ajan sıfırdan başlar → paketleri BÜYÜK tut.
- Yürütücü/ölçüm/mekanik iş için ucuz model (Sonnet); tasarım/zor kök neden için güçlü
  model. Alt ajan beklerken yoklama yok, bildirimi bekle.

## 2. Bir tur (zamanlanmış görev her tetiklendiğinde)
0. **Kilit** `.git/oto.lock` (`.git` içinde, commit'lenmez). Son değişimi **60 dk**'dan
   yeniyse "başka yürütücü var" de ve bitir. Değilse yaz. Tazeleme yalnız adım başında tek
   `date > .git/oto.lock`. **Arka plan döngüsüyle kilit tazeleme YASAK** (oturum ölünce
   döngü yaşar, kilit sonsuza dek taze kalır — 8 tur boşa gitti). Eşik her yerde AYNI sayı.
1. **Limit freni:** iş başında, her alt ajandan önce ve her bildirimde `get_usage`.
   5 saatlik ≥ %90 → hiçbir şey başlatma, çalışan ajana "commit + push + dur", bitir.
   ≥ %80 → yeni paket yok. ≥ %55 → en pahalı modelle alt ajan başlatma (tek paket limitin
   ~%50'sini yiyip freni geçebiliyor; oturum ölür, sürdüren olmaz).
2. Depo temiz mi, `main` güncel mi; main CI'ı kırmızıysa turun işi onu düzeltmek.
   Yayın (APK/deploy) koşusu sürerken main'e push YOK (iptal eder).
3. Kuyruk'tan ilk `sürüyor`, yoksa ilk `bekliyor`. Yarım dal varsa önce dalın `DEVIR.md`'si.
4. Alt ajan: `isolation: "worktree"`, kendi dalı `oto/<no>-<ad>`, istem = işçi kuralları +
   paketin satırı + `KUYRUK_AYRINTI.md` bölümü.
5. Doğrula: dal push'lu, CI yeşil. **CI yeşil olmadan "bitti" yok, kırmızıyken main'e
   birleştirme yok.** Kırmızıysa alt ajana yalnız kırmızı işin kayıt kuyruğu (en çok 2 tur,
   sonra `takıldı`).
6. Birleştir (`--no-ff`), `DEVIR.md`'yi önce sil, `git grep -E "^(<<<<<<<|>>>>>>>)"` boş
   olmalı. Durum için ayrı commit/push atma (her push CI'ı baştan koşturur).
7. **Temizlik (her birleştirmeden sonra):** `git worktree remove <ağaç>` +
   `git push origin --delete oto/<no>-*` + yerel dal sil. Biriken çalışma kopyaları
   onlarca GB tutar ve aramaları kirletir (34 kopya birikmişti).
8. **Takılma önleme:** her bekleme komutu süreli (`timeout 2700 gh run watch <id>
   --exit-status`); dolarsa tek `gh run view` ile bak. Alt ajandan 90 dk ses yoksa
   "commit + push + dur", dönmezse durdur. Tur sonu sırası: kendi arka plan işlerini
   durdur → cihaz ekranını kapat → kilidi sil → 5 satır özet.
9. Dur: art arda 3 `takıldı`, main iki kez üst üste kırmızı, Kuyruk boş, limit.

## 2b. İş kaybolmasın: commit + push + main'e gönder
- Hiçbir iş yalnız yerelde ya da yalnız çalışma kopyasında kalmaz: her anlamlı adımda
  commit + push (dalda). Limit, uyku ya da çökme her an kesebilir.
- Paket CI'da yeşil olunca BEKLETMEDEN main'e birleştir ve push et; "turun sonunda toplu
  birleştiririm" yok. Uzun paket ara noktalarda da (bağımsız, yeşil, kendi başına çalışan
  kısım bitince) main'e girer — böylece başka oturum/hesap/bulut oturumu güncel main'den
  başlar, aynı işi baştan yapmaz, çakışma küçük kalır.
- Yürütücünün yaptığı belge/kuyruk değişikliği de commit'lenir ve push edilir; tur sonunda
  `git status` temiz ve `git log origin/main..main` BOŞ olmalı (özetin son satırı bunu söyler).
- İstisna: yayın (APK/deploy) koşusu sürerken main'e push etme — bekle, sonra gönder.
- Main'e birleştirdikten sonra yayın (APK/deploy) koşusunu İZLEME: dal CI'ı yeşilse yayın da
  yeşil olur; izlemek boşa token. Birleştir → push → özet → sıradaki iş. Yalnız sonraki main
  push'undan önce tek `gh run list -b main -L 1` bakışı; yayın sürüyorsa push'u beklet. main
  kırmızıya dönerse sonraki turun "main sağlığı" adımı yakalar.

## 3. İşçi (alt ajan) kuralları
- Önce `CLAUDE.md`, sonra yalnız kendi paketinin plan bölümü. Protokol: önce kanıtı üret
  (test/ölçüm kırmızı) → düzelt → aynı kanıt yeşil. Kanıt üretilemiyorsa düzeltme YAZMA,
  "üretilemedi: <ne denendi>" yaz.
- Küçük commit + **her commit'ten sonra push** (limit her an kesebilir). main'e push yok.
- Dal kökünde `DEVIR.md` (≤ 25 satır), her push'tan önce: yapılan (madde → commit) · nerede
  kaldın · kök neden (dosya:satır) · işe yaramayanlar · sıradaki · açık test komutu.
- Doğrulama: değişenin testi + tam statik analiz; **tam test takımını yerelde koşma**
  (CI koşar). Depoyu toplu biçimlendirme (yüzlerce ilgisiz dosya değişir); yalnız kendi
  dosyan.
- KARAR çıkarsa en güvenli seçenek + "sabah bakılacak"; soru sorma, kapsam dışına çıkma.
- Dokunma: uzak yapılandırma bayrakları, veri silen/taşıyan göç, erişimi gevşeten kural,
  imza anahtarı, kişisel dosyalar.
- Arka planda başlattığın her komut `timeout`'lu; raporu yazmadan önce hepsini bitir.
- Rapor ≤ 15 satır: ne değişti, hangi kanıt kırmızıdan yeşile döndü, doğrulanamayan ne
  kaldı, dal ve son commit.

## 4. Kalite kapıları (bunları atlamak aylarca aynı hatayı düzelttirdi)
- Arayüze (editör, klavye, liste, geçiş) dokunan iş yayına girmeden **cihazda A/B ölçülür**
  (önceki yayının profil derlemesine karşı). Eşik: bir evre > %20 kötüyse birleştirme yok.
  Hız/akıcılık işinde eşik sıfır: hiçbir evre kötüleşmez, hedef ölçülebilir iyileşir.
  Ölçmeden "akıcı/hızlı/düzeldi" deme.
- Ölçüm gürültüsü: A ve B **arka arkaya, aynı koşu sayısında**; ilk koşu (soğuk önbellek)
  atılır, ikinci alınır. Aynı APK'nın iki koşusu arasında ±%18 oynama görüldü — tek koşuluk
  farkla karar verme; şüphede ABAB yeniden ölç.
- Cihazsız bütçe testleri (kurulum/yeniden çizim sayısı) her dokunulan yüzeye; bütçeler
  yalnız DÜŞER (mandal).
- Her madde ayrı commit → kötüleştiren tek başına `git revert` edilir, iyiler kalır.
- Yayın noktasında sürüm notu (kullanıcı dilinde, ne değişti) aynı commit'te.

## 5. Test cihazı (USB telefon/tablet) kuralları
- `adb devices` boşsa cihaz işi atlanır, satır "cihaz bekliyor"; yayın ertelenir.
- **Ölçüm/test uygulaması AYRI kimlikle** (ör. `<paket>.olcum`). Varsayılan kimlikli
  uygulamaya `flutter run/drive`, `uninstall`, `pm clear` ASLA — kullanıcının verisi gider.
- Ekran yalnız iş sırasında: uyandır + kaydır aynı komutta (ekran ~30 sn'de kararır,
  dokunuşlar kaybolur); bitince `KEYCODE_SLEEP`. Kalıcı "açık kal" ayarı yok (ısınır).
- Ölçüm öncesi pil sıcaklığı < 37 °C (`dumpsys battery`); değilse ekran kapalı bekle.
- Koordinatla basmadan önce ekran yönüne, klavyeye ve uygulamanın HAZIR olduğuna bak
  (`uiautomator dump`, ölçüm penceresi dışında). Hazır olmadan başlayan dokunuşlar başka
  uygulamayı açabilir (telefon uygulaması açılmıştı).
- Yerel kurulumda sürüm kodu cihazdakinin üstünde olmalı (yoksa DOWNGRADE hatası);
  ortam değişkenleri/gizli tanımlar olmadan derlenen sürüm çalışırken çöker.
- Hesap gerektiren akışlar (Google giriş, Drive) cihazda misafir hesapla denenemez →
  "denenmedi" yaz, kullanıcının kontrol listesine ekle.
- Tablet yoksa tablet ölçütü "tablette doğrulanmadı"; telefon düzeni gerekirse
  `wm size`/`wm density` ile taklit, iş bitince `reset`.

## 6. Plan ve kullanıcıya dönüş
- Tek açık plan dosyası + kullanıcının kendi kontrol listesi (`KONTROL_LISTEM.md`: sade dil,
  her madde ne / nerede / nasıl / doğruysa ne görülür / yanlışsa ne yapılır). Bitmiş planlar
  arşive taşınır (`git mv`), silinmez.
- Plan güçlü modelde yazılır, ucuz modelde uygulanır: her madde kendi başına okunur (dosya +
  işlev, kanıt, önce yazılacak test, kabul ölçütü, tuzaklar, KARAR'da önerilen + en güvenli).
- Kullanıcının verdiği kararlar plana tarihli yazılır; gözetimsiz tur bunları sormadan
  uygular. Yeni karar çıkarsa en güvenli seçenek + "sabah bakılacak".
- Görünüş değiştirmeden önce kullanıcının eski isteklerini ara (koddaki "kullanıcı isteği"
  yorumları); çelişen fikir yapılmaz.
- Sır/anahtar/kişisel veri hiçbir hafızaya, plana, grafa, zip'e girmez.
