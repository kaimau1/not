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

**2026-10-28 görünüm + medya turu (APK'da HİÇ derlenmedi — Actions kotası
doluydu; ilk `[apk]` koşusunda önce derlemenin yeşil olduğuna bak:
`NotKisayolu.kt` yeni Kotlin)**
- [ ] Ana ekrandan bir nota dokun → not KARTIN YERİNDEN genişleyerek açılıyor,
  geri → karta küçülerek dönüyor (not ızgarada yer değiştirdiyse yeni yerine).
  Klasör listesinden ve liste görünümünden de; geniş ekranda eskisi gibi.
- [ ] Editörde ⋮ → "Ana ekrana yerleştir" → başlatıcı onayı → simge notun
  renginde, baş harfli; dokununca not açılıyor (kilitli not kilitli).
- [ ] Alt çubuktaki dalga düğmesi (ya da Ekle → Ses kaydı) → alt şeritte
  kırmızı hap, canlı dalga; kayıt sürerken yazılabiliyor; ⏸/✕/■ çalışıyor;
  bitince ses YAZILAN SATIRA dalgalı hap olarak giriyor, dokununca çalıyor,
  dalgaya dokununca/sürükleyince sarıyor. Kayıtta geri tuşu kaydı ekleyip
  çıkıyor.
- [ ] Üst çubukta palet → altta tema şeridi (Palmiye, Lagün, Gece…) dokunulan
  anında uygulanıyor; kartta da aynı tema; Zemin rengi seçince tema kalkıyor;
  koyu temada okunur.
- [ ] Görsele dokun → araç panelinde "Açıklama ekle" → görselin altına yazılıyor,
  metin görselle açıklamanın etrafından akıyor; açıklamaya dokunup düzenleme.
- [ ] Çizim ekranı (Ekle → El yazısı): kalem tepsisi; seçili kalem kalkıyor,
  ikinci dokunuşta renk/kalınlık paneli; ✓ ve geri çizimi nota ekliyor.
- [ ] Metin notunda ☑: imlecin satırı kutulu madde oluyor, maddede ☑ kutuyu
  kaldırıp metne döndürüyor. Biçim paneli açılıp kapanırken alt çubukla
  zıplamadan yer değiştiriyor; yazı boyutu −/+ yumuşak.

**2026-10-28 ikinci tur**
- [ ] Biçim paneli açıkken geri → yalnız panel kapanıyor. Panelde "Tümüne
  uygula" (maddede "Maddeye uygula"): imleçte kalın+kırmızı varken basınca
  bütün metin kalın+kırmızı, metin seçili kalıyor.
- [ ] Ana ekranda bir klasöre dokun → ayrı sayfa değil, ana ekran klasöre
  süzülüyor (Süz düğmesinde klasör adı ×); "+" klasöre not açıyor; geri →
  süzgeç kalkıyor. Paylaşılan klasör eski sayfada.
- [ ] Notu okurken bağlantıya dokun → tarayıcıda açılıyor; yazarken dokununca
  altta "Aç" önerisi. YouTube adresini gövdeye yapıştır → video imlecin
  satırına gömülüyor ("Geri al" kaldırıyor).
- [ ] Madde ortasında Enter ile bölünen maddenin başında Backspace → üst
  maddeyle birleşiyor (Gboard'da ve Samsung klavyede).
- [ ] Kart ⋮ → "Görsel önizlemesini gizle" → kartta görsel yok, editörde var.

**2026-10-28 Harita köprüsü (kişisel)**
- [ ] Harita'da navigasyondayken "Hey Harita, not al …" → Notlar öne
  gelmeden "Haritalar" klasöründe not (uygulama kapalıyken de); çevrimdışı
  söylenen not ağ gelince buluta gidiyor mu; Harita "Not alındı" diyor mu.
- [ ] Genel sürüm çıkarken köprüyü kaldır (HAFIZA › Android › Harita köprüsü).

**2026-10-28 madde + biçim + giriş turu**
- [ ] Çok işaretli maddeli notta işaretlemek / yazmak / görsel eklemek
  akıcı (eskiden donma-kasma).
- [ ] Madde ortasında Enter → madde imleçten bölünüyor, imleç yeni maddenin
  başında. Maddeye uzun bas → iki sıralı sade menü (yıldız·seç·taşı·sil /
  çizgi türleri + ⚙).
- [ ] Biçim paneli: üç sıra; başlık hapı, renk tonu tek dokunuş; yazı/vurgu
  anahtarı; boyut −/+; Aa tepsisinde yazı tipi + kaydırıcılar.
- [ ] Paylaş → Notlar'a ekle → Var olan nota: ana ekran kartlarıyla ızgara,
  karta dokununca o nota ekliyor (not açılmıyor).
- [ ] Web: videolu notta başka sekmeye geç / uygulamada başka sayfa aç →
  video duruyor.
- [ ] Misafir hesapta ana ekranın tepesinde "Google ile giriş yap" kartı;
  Ayarlar'ın en üstünde düğme; giriş sonrası kart sayfa yenilemeden kalkıyor.
- [ ] Klasör: Süz düğmesi (durum, etiket, görünüm, sıralama), liste
  görünümü, uzun basışla seçim + çubuk (taşı/arşivle/sil).

**2026-10-23 kalem + ses + kart turu**
- [ ] Ayarlar → Ses: Türkçe sesi denerken yapay zekâ denemesine geç (ya da
  tersi) — iki ses ÜST ÜSTE çalmıyor; motor değişince süren deneme susuyor.
- [ ] APK boyutu ~45 MB civarı (eski 73 MB); Türkçe ses hâlâ çalışıyor.
- [ ] Tablette kalem: ilk kalem dokunuşunda "yalnız kalem" açılıyor; parmak
  çizmiyor, kaydırıyor; iki parmak yakınlaştırıyor; avuç içi iz bırakmıyor.
- [ ] Kalem basıncı: hafif/sert bastırınca kalınlık değişiyor. Yan düğme
  ya da ters uç siliyor. Şekiller (düz çizgi, dikdörtgen, daire, ok).
- [ ] Kalem ayarları (⚙): şeffaflık, son renkler, basınç aç/kapa; uygulama
  kapanıp açılınca kalem/renk/kalınlık hatırlanıyor. Geri al + yinele.
- [ ] El yazısı ekranında iki parmakla yakınlaştır/kaydır; "tam görünüm".
- [ ] Ayarlar → Kartlar → "Paylaşılan notlar ana ekranda" açınca ortak
  notlar ana ekranın üstünde ayrı bölümde; karta dokununca not açılıyor.
- [ ] Madde uzun bas → Çizgi ayarları: tür (çift/dalgalı dahil), renk,
  kalınlık, "Tüm çizgilere"; kartta da aynı görünüyor.
- [ ] Görsel/PDF/sunum/video görüntüleyicide "Eki kopyala" → başka notta
  + → yapıştır.
- [ ] Süz levhası: "Kartta görseller" / "Kartta ekler" ayrı ayrı kapanıyor.

**2026-10-20 geliştirme raporu + kullanıcı turu 2**
- [ ] Madde uzun bas → Alta çizgi çek: çizgi ANINDA görünüyor (çıkıp girmeden).
- [ ] Biçim paneli açıkken alt çubuk gizli; "Tt" düğmesi boyut satırını
  açıp kapatıyor; boyut sürüklerken kasma yok. Panel kapalıyken Biçim
  düğmesinin yanında B/I/U/renk rozetleri.
- [ ] Başlıkta Kalın açılıp kapanınca fark görünüyor.
- [ ] Renk paleti (🎨): yazı rengi, vurgu, not zemini, çerçeve, balon,
  kalem, ana ekran zemini — hazır ton + Özel (ton/doygunluk/açıklık).
- [ ] Sayfalı notta sola/sağa hızlı çekiş sayfa çeviriyor; yazarken/seçerken
  yanlışlıkla çevirmiyor. Madde menüsü → Başka sayfaya taşı.
- [ ] Ayarlar: bir alanı açınca o alan ekranın tepesine geliyor.
- [ ] Ana ekran: ✨ yüzen düğme yok (⋮ → Yapay Zekâ), mikrofon "+"nın solunda;
  boş klasörler şeridin sonunda ve soluk. "Şifreler" notu kartta gizli +
  Kilitle; IBAN/kart no örtülü. Kartta kutucuğa dokununca madde işaretleniyor.
- [ ] Arşiv/çöp/klasör aramasında ✨; Arşiv → 📊 "Arşivimde neler var?".
- [ ] Defter → Kâğıt levhası → Satır aralığı (Normal/Geniş/Çok geniş);
  düz metinde tek başına `---` satırı çizgi. Tümü → klasör başlıkları.

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

**Defter + menü turu (2026-10-20, bkz. `GELISTIRME_RAPORU.md` E)**
- [ ] Defter (çizgili/kesikli/bloknot): yazı çizgide; büyük yazı ölçeği,
  başlık + etiket + sayfa çubuğu; kartta da aynı kâğıt.
- [ ] Madde uzun bas → alta düz/kesikli/noktalı çizgi; kartta görünüyor.
- [ ] Ekle → tek "Dosya ekle" (görsel/ses/video soru levhası); "Tümü"
  çipi; aramada klasör rozeti; arşivde ✨; çöpte 📊 Akıllı analiz.

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
- [ ] Açık balon: sayfanın boş yerine dokununca ANINDA kapanıyor; kaydırma,
  iki parmak yakınlaştırma ve basılı tutma onu kapatmıyor.
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
