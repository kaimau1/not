# KALANLAR — canlı kalan iş

Biten madde silinir; karar/neden bilgisi HAFIZA.md'ye yazılır. 2026-10-20
(F8.7): 20+ turun "CİHAZDA GÖRÜLMEDİ" listeleri TEK cihaz doğrulama turuna
indirildi, sonradan geri alınan/eskiyen maddeler atıldı. Eski hâli
`KALANLAR_ARSIV.md` (dondurulmuş).

## 1. Senin yapacakların (konsol / hesap)
- [ ] Telefonlar v1.1.N'e geçince Firebase konsolu → `config/app` →
  `minClient: 3` (eski sürüm yıldızları siler; ağır belge bölmesini görmez).
- [ ] Actions → deploy → "Cloud Functions'ı yayınla" adımı yeşil mi (Blaze
  plan; itme bildirimleri ve kişi araması buna bağlı).
- [ ] Google Cloud (notlar-kaimau): "Google Drive API" etkin, OAuth onay
  ekranında `drive.appdata` kapsamı.
- [ ] Crashlytics'i konsolda etkinleştir → Ayarlar → Hakkında → sürüm
  satırına uzun bas → "Çökert" → yeniden aç → konsolda ilk rapor.
- [ ] Actions → Derleme → Run workflow → "Kare ölçümü"; `perf-summary`
  p90 değerleri HAFIZA'ya taban olarak (F2.6). Ölçüm protokolü: F9.1
  (`PERFORMANS_TOPARLAMA_PLANI.md`).
- [ ] Eski Actions artifact'lerini sil (depolama kotası).
- [ ] **Play'e çıkarken:** App Check'i önce izle, sonra ZORLA (ters sıra
  herkesi kilitler; sideload APK doğrulanmaz) · `PRIVACY_POLICY.md` herkese
  açık URL'de · mağaza simgesi `assets/icon/play_store_512.png` · listede
  "yalnız 64 bit" notu.

## 2. Cihaz doğrulama turu
Hepsi testlerle korunuyor; risk "gözle görülmedi". Sorun görünce madde
numarasıyla bildir.

**Ana ekran ve menüler**
- [ ] 100+ notla açılış ve hızlı kaydırma akıcı; boş kart / sıçrama yok;
  klasör ve arşiv ızgarası aynı. Editörden dönüşte kart güncel, takılma yok.
- [ ] Tek mikrofon: dokun = doğrudan yazdır; basılı tut = AI sesli not.
  Yapay Zekâ ekranının en üstündeki "Sesli not" aynı kartı açar.
- [ ] "+" tek panel (Diğer · Kamera · Dosya · Metin/Liste/Sıralı); büyük
  yazı ölçeğinde taşmıyor. Dosya ekle → tek levha (ses: ek / metne dök;
  HEIC tek seçimde).
- [ ] Süz düğmesi arama kutusunda; seçili süzgeç adı + ×. Görünüm Süz
  levhasında. Yıldız (Süz → Yıldızlı) ve çerçeve (yalnız kartta) ayrı.
- [ ] Toplu seçim → sil/arşivle/taşı/renk + "Geri al" (yerel notlarda da).
- [ ] Menüler kompakt ızgara; Paylaş levhası: Birlikte düzenle + Kopya gönder;
  PDF/PNG/ek çıktıları okunur, çip seçimi hatırlanıyor.
- [ ] Ana ekran widget'ları (açık/koyu tema, 4 satır kart).

**Editör ve klavye**
- [ ] Görselli/PDF'li not açılışı takılmasız; sabit medya geçiş bitince yerine.
- [ ] Klavye açılınca sabit görsel/video/PDF zıplamıyor, alt kısmı örtülüyor;
  balonlu PDF'te sayfa notuna yazarken belge yeniden ölçeklenmiyor.
- [ ] 10.000+ karakterlik ve görselli notta yazarken takılma yok; imleç ve
  "Not…" ipucu aynı satırda.
- [ ] Madde seçimi (kutunun kenarı, satırın sağı); seçince klavye kapanıyor.
- [ ] Defter kâğıdı seçimi anında değişiyor (bloknot/milimetrik/izometrik).
- [ ] Dikte: yalnız İLK bip, bitince müzik/bildirim sesi geri geliyor;
  dikte sırasında uygulamayı kapat-aç → ses açık.
- [ ] Görsel sürükleme / PDF kutusu boyutlandırma akıcı; Sabit/Yüzen/Balonlu
  geçişleri geri dönüşte yerinde.
- [ ] Video zaman damgası "1:23" (yerel + YouTube) sarıyor, klavye açmıyor;
  video çubuğu ⏪/▶/⏩/hız 360 dp'de taşmıyor.
- [ ] Sürüm geçmişi: "Açıldığı hâli", "AI değiştirmeden önce", "Bu sürüme dön".
- [ ] Not kilidi (şifre/desen, 5 yanlışta bekleme, "Unuttum").

**PDF, balon, görsel**
- [ ] Uzun bas → balon; ekran grileşmiyor, klavye açık kalıyor, yazma kartı
  gezinme düğmelerinin üstünde; uzun PDF'te fırlatma liste gibi akıyor.
- [ ] Balona dokununca belge kaymıyor; Düzenle/Bitti'de sayfa başına sıçrama
  yok (bölme, slayt, tam ekran).
- [ ] Çok sayfalı PDF'e yoğun çizim/balon → başka cihazda geliyor (ağır belge);
  ≥900 KB'ta "Not çok büyüdü" uyarısı. Çizimden sonra yazmaya devam → çizim
  kaybolmuyor (F6.1).
- [ ] Taranmış PDF: OCR bir kez, sonra çift dokunuş beklemeden seçim; dışa
  aktarılan PDF'te Türkçe karakter, kalın/italik doğru.
- [ ] Tam ekran görsel galerisi: yakınlaştırılmışken kaydırma kilitli.
- [ ] Alan seçimi (PDF/sunum/görsel) panoya PNG; "AI'ya sor".

**Ses, AI, transkript**
- [ ] Ses/video transkripti (Kotlin `extractAudio`), .opus/.amr ekleri,
  15 MB üstü kayıt (kendi anahtarla), görsel OCR "internet harcanmadı".
- [ ] Sohbet kapsamları (Tüm notlar / Bu not / Bu belge) + Beyin fırtınası.
- [ ] Sesli asistan hatırlatıcısı uçtan uca; ağ kesikken sesli not tek not.

**Paylaşım ve senkron (iki hesap)**
- [ ] Ortak not: "X düzenliyor", iki taraf farklı paragrafa yazar → ikisi de
  kalır; aynı satır → iki hâl + uyarı.
- [ ] Paylaşılan notta "Yeni" izi ve bildirim; uygulama KAPALIYKEN itme
  bildirimi (klasör sohbeti / ortak not / gelen not).
- [ ] Klasör 'write' rolü yalnız kendi notunu düzenler.
- [ ] Kişi araması: misafirde uyarı, ≥3 harf ad, TAM e-posta, dakikada 10.
- [ ] Hesap silme: paylaşımlar, `userSearch`, sohbet dosyaları, Drive verisi
  gidiyor.
- [ ] Drive iki cihazda (yükle/indir), web'de "Drive'a bağlan"; "Yalnız bu
  cihaz"a alınca ekler açılıyor, Drive kopyası ve sürüm geçmişi siliniyor.
- [ ] Ayar senkronu: telefonda tema/yazı tipi → web'de ≤20 sn.
- [ ] Senkronu kapat/aç (yerel not) ikinci cihazda kaybolur/geri gelir.

**Hatırlatıcı ve Android**
- [ ] Kesin alarm izni yokken hatırlatıcı yine çalıyor (inexact); izinle
  dakikasında. "Tamam / 1 saat ertele" düğmeleri.
- [ ] Web'de kaldırılan hatırlatıcı, uygulama KAPALIYKEN çalmıyor (F5.3).
- [ ] R8'li APK: widget güncellemesi, yeniden başlatmada hatırlatıcı,
  Google girişi, ML Kit (QR/OCR Play Hizmetleri modeli).
- [ ] Simge (başlatıcı maskeleri, Android 13+ temalı, bildirim beyaz "N").
- [ ] Tablet: gezinme rayı ve ana-detay; yatay telefonda ray yok.
- [ ] Web: geri tuşu gerçek sitede, Drive eki.
- [ ] **Web WASM (F9.4)**: Chrome/Edge'de site açılıyor, giriş penceresi,
  not yazma, PDF görüntüleme, YouTube kapağı, yazı tipleri çalışıyor;
  Safari/Firefox (eski) JS yedeğiyle açılıyor. Sorun olursa CI'daki
  `--wasm` bayrağını kaldırmak yeterli.

**Performans (Faz 5–7)**
- [ ] 20-30 not aç-kapat, sonra yerel notta 2 dk yaz — ısınma/yavaşlama yok.
- [ ] Galeriden 10 büyük fotoğraf (küçük resim şeridi) — çökme yok; büyük
  fotoğraflı PPTX net.
- [ ] "Ek içeriğinde ara" açıkken büyük PDF — donma yok; indeks kapat-aç
  sonrası duruyor. Çöp kutusu listeleniyor, geri yükle/kalıcı sil.
- [ ] Çok PDF'li ana ekranda kaydırma; PDF kart kapakları geliyor (artık
  JPEG, F7.1 — eski kapaklar bir kez yeniden üretilir).
- [ ] Çizimli eski bir notu aç, bir çizgi ekle → kaydet → başka cihazda
  çizimler yerinde (F7.2 float32; F7.3 16 KB'ı aşan ağır kısım ayrı belgeye
  taşınır).
- [ ] Düşük RAM'li (≤4 GB) telefonda görselli notlar arasında gezinme (F7.6).
- [ ] Editör (F9.3 bölündü): ekler, ⋮ menüsü, sayfalar/görünüm kipleri,
  renk/kâğıt/zemin, not içi arama, dikte — her biri bir kez denensin
  (kod satır satır taşındı, davranış değişmemeli).

## 3. Açık kararlar / bilinen sınırlar
- Play Billing (lifetime + AI aboneliği): RevenueCat mı `in_app_purchase` +
  Function mı — karar bekliyor. Deneme süresi hesaba bağlı olmalı.
- Depolama tavanı ve AI kota sayacı istemcide; sunucu zorlaması (Function)
  Play Billing'le birlikte.
- AI günlük kotası yuvarlanan 24 saat mi, takvim günü mü — karar kullanıcıda
  (kural tavanını gevşetmek gerekir).
- Anonim → Google geçişinde hesap çakışması: güvenli yol "yedek al → gir →
  geri yükle" (yedekleme mantığı servise çıkarılmalı).
- Sesli notta canlı yazım yok (Google sesli giriş, `GET_AUDIO` belgesiz);
  görüntülü not yalnız cihazda; AI videosu 60 sn; IME oluşturma aralığı
  sarmada gizli; editör diktesi web'de AI'sız çalışmaz.
- Görsele yazılan metin dışa aktarmada yok; paylaşılan klasörün "+"
  düğmesi yalnız metin notu açar (bilinçli).
- Kesme noktası geçişinde liste kaydırma konumu sıfırlanıyor.

## 4. Sonra yapılacak
- PPTX'i "dosya okuyucu" reposundan port (kendi oturumu).
- Farklılaşma: aralıklı tekrar kartları → tüm defterle sohbet (RAG) →
  otomatik not bağlama.
- FlutterFire paketlerini BİRLİKTE yükselt (F8.6; ayrı oturum, APK ile
  doğrula).
