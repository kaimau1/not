# KALANLAR — canlı kalan iş / plan listesi

(Biten madde silinir. Karar/neden bilgisi buraya değil HAFIZA.md'ye yazılır.)

## 2026-08-23 turundan kalan (CİHAZDA HİÇ ÇALIŞTIRILMADI)

Bu tur Flutter SDK'sı OLMAYAN bir ortamda yazıldı: `flutter analyze` ve
`flutter test` koşmadı, doğrulama CI'a bırakıldı. Hepsi elle gözden geçirildi
ama hiçbiri cihazda görülmedi.

- [ ] **Alan seçimi (PDF/sunum/görsel)** — yakalama `RepaintBoundary.toImage`
  ile. Bakılacaklar: pdfrx'in çizdiği sayfa gerçekten yakalanıyor mu, seçim
  çerçevesi görüntüye karışıyor mu, panoya yazılan PNG WhatsApp/Word'e
  yapışıyor mu, "yapay zekâya sor" formülü doğru okuyor mu.
- [ ] **Alan seçimi NOT BÖLMESİNDE yok**: yalnız tam ekran görüntüleyicilerde
  (PDF/sunum/görsel). Balonlu notta bölmedeki tam ekran düğmesiyle
  erişiliyor — bir dokunuş fazla. İstenirse `pdf_note_pane`/`slide_note_pane`
  araç çubuğuna da konabilir.
- [ ] **Syncfusion `PdfTrueTypeFont(multiStyle:)` + `PdfStringFormat`**
  (metin kutusunun kalın/italik/hizasını PAYLAŞILAN PDF'e taşıyor) derlenmedi.
  API adları yanlışsa `pdf_edit.dart` derleme hatası verir.
- [ ] **Yerli `videoDuration` köprüsü** (MainActivity) derlenmedi; görüntülü
  notta balonlu kip kaç sayfa üreteceğini buna göre seçiyor. Köprü dönmezse
  `VideoFrame.sample` tek kareye (eski davranışa) düşer — güvenli, ama
  çoklu kare hiç çalışmaz.
- [ ] **Yeni l10n anahtarları (28)** ELLE yazıldı (`flutter gen-l10n`
  koşturulamadı): `app_tr.arb` + `app_en.arb` + 17 üretilmiş dosya. Kalan 14
  dil Türkçe metne düşüyor (mevcut kural). Bir sonraki gen-l10n koşusunda
  sıralama değişebilir, içerik aynı kalmalı.
- [ ] **Madde kutucuğu hizası** hesaba dayanıyor (`10 + satırYüksekliği/2 −
  kutuYüksekliği/2`); satır yüksekliği yazı tipinin kendi metriğinden gelirse
  1-2 px sapabilir. Farklı yazı tipi + büyük yazı ölçeğiyle bakılmalı.

## 2026-08-16 turundan kalan (cihazda doğrulanmadı)
- [ ] **Klavye kasması: iki turda düzeltildi, CİHAZDA ÖLÇÜLMEDİ.** Alt çubuk
  Scaffold yuvasından çıkarılıp gövdenin dibine alındı (bkz. HAFIZA 36. tur).
  Kazanç mekanizmadan biliniyor; gerçek kare süresi ölçülmedi.
- [ ] **Görsele yazılan metin dışa aktarmada YOK.** Paint tarzı metin aracı
  görsel görüntüleyiciye eklendi ve not sayfasındaki küçük halde çiziliyor,
  ama PDF/Word dışa aktarımı ile paylaşılan görselde henüz görünmüyor
  (çizim/`ink` için de aynı sınır geçerli).
- [ ] **R8 küçültmeli release APK'yı CİHAZDA dene.** minify + shrinkResources
  ilk kez açıldı. R8 hatası derlemede değil, o kod yolu ilk kez çalıştığında
  patlar — özellikle bakılacaklar: ana ekran widget'larının güncellenmesi
  (`home_widget` sınıf adını METİN olarak taşıyor), zamanlanmış
  hatırlatıcıların yeniden başlatmadan sonra da durması (Gson yansıması),
  Google girişi, Firestore senkronu, ML Kit metin tanıma.
- [ ] **32 bit cihaz desteği KALKTI** (`abiFilters = arm64-v8a`). 2015 öncesi
  telefonlar ve bazı ucuz tabletler uygulamayı artık kuramaz — bilinçli karar,
  Play'e çıkarken mağaza listesinde belirtilmeli.
- [ ] **Podcast WAV dışa aktarımı** metnin TAMAMINI yeniden seslendirir
  (dinlerken üretilen parçalar okuma bitince siliniyor). Uzun belgede kota
  bedeli yüksek; kullanıcıya soruluyor ama ölçülmedi.
- [ ] Yeni l10n anahtarları (~50) yalnız TR ve EN'de; kalan 14 dil şablona
  (Türkçe) düşüyor. `Çeviri üret` iş akışı elle tetiklenmeli.
- [ ] **GitHub Actions artifact DEPOLAMA kotası dolu** ("Artifact storage
  quota has been hit"). APK artık Release olarak yayınlandığı için teslimat
  etkilenmiyor (artifact adımı zorunlu değil), ama eski artifact'ler
  Actions → sağdaki "Artifacts" bölümünden silinmezse kota dolu kalır.

## 2026-08-06 genel kullanım denetiminden kalan (bilinçli ertelenen küçük uçlar)
- [ ] **Kesme noktası geçişinde liste kaydırma konumu sıfırlanıyor** (arama
  kutusu senkronu çözüldü; scroll paylaşımı split-shell refaktörü ister).
- [ ] **Cihazda doğrulanmadı**: temiz Kes/Kopyala (özellikle donanım Ctrl+C
  override'ı), FileProvider'lı "Eki kopyala"nın WhatsApp'a yapışması, geri
  tuşunun ses kaydını/çizimi kaydederek çıkması, Süz levhasının yeni görünümü,
  klavye açılış kasmasının azalması.

- [ ] **firestore.rules'u YAYINLA** (`firebase deploy --only firestore:rules`):
  2026-08-05 denetimi `aiQuota` kurallarını sıkılaştırdı (katı artış + alan
  beyaz listesi + tavan); depoda hazır ama sunucuda eski kural duruyor.

## 2026-08-05 denetiminden kalan (bkz. HAFIZA aynı tarih)
- [ ] storage.rules kullanıcı başına TOPLAM kota zorlayamıyor (kurallar bucket
  kullanımını sayamaz; istemci tavanı var). Sunucu zorlaması Cloud Function
  (finalize tetikleyicisi + Firestore sayaç) ister — Play Billing'den önce.

- [ ] **PDF çizimini dışa aktarılan/paylaşılan PDF'e gömme** — çizim yalnız
  uygulama içinde görünüyor. **2026-08-06 incelemesi: mevcut bağımlılıklarla
  YAPILAMIYOR.** `pdfrx` yalnız görüntüler, `pdf` yalnız sıfırdan üretir; var
  olan bir PDF'i ayrıştırıp içerik akışına yazan kütüphane yok. KULLANICI
  KARARI BEKLİYOR: (a) sayfaları rasterleştirip PDF'i yeniden kur — yeni
  bağımlılık yok ama uygulamanın taradığı PDF'lerdeki görünmez OCR metin
  katmanı yok olur (yalnız paylaşılan kopyada, orijinal ek bozulmaz);
  (b) `syncfusion_flutter_pdf` ekle — metin korunur, bedeli ağır bağımlılık +
  Play lisans denetimi.

## Play'e çıkış — kalan iş (2026-08-02)

Sıra bilerek böyle: önce senin tarafındaki konsol işleri (kodu bekletmiyor),
sonra çeviri dalgası (mekanizma hazır), en son Play Billing (en büyük iş).

### Senin yapman gerekenler (kod tarafı hazır)
- [ ] **App Check zorlamasını AÇ** (Firebase konsolu → App Check → APIs).
  Uygulama token üretiyor (`main.dart` `_activateAppCheck`), Play Integrity
  hazır. Kapalı kaldığı sürece APK'dan Firebase yapılandırmasını çıkaran biri
  Gemini faturasını yakabilir. Sıra: Play'de yayınla → sonra zorlamayı aç
  (sideload APK attestation'dan geçemez, bkz. HAFIZA 2026-07-18).
- [ ] **Çevirileri anadili konuşana göstert** — 2026-08-03'te 12 dil eklendi
  (fr, it, pt, ru, hi, ja, ko, zh, id, nl, pl, **ar**); toplam 16 dil. Hiçbiri
  anadili konuşan biri tarafından okunmadı. Aynısı de/es için de geçerli.
  Yayına çıkmadan önce en azından en çok kullanılacak dillerde göz gezdirilmeli.
  **Arapça en öncelikli**: hem çeviri hem RTL yerleşimi doğrulanmamış.
- [ ] **Arapça'yı CİHAZDA gör** — RTL sarma motoru düzeltildi ve
  `rtl_text_wrap_test` (5 test) dolgunun doğru tarafa gittiğini doğruluyor,
  ama gerçek ekranda kimse bakmadı. Bakılacak yerler: görselli metin notunda
  metnin görselin yanından akışı, not kartı, sohbet balonları, ek şeridi.
- [ ] **PRIVACY_POLICY.md'yi herkese açık bir URL'e koy** (alınan domain ya da
  GitHub Pages). Play mağaza listesi şart koşuyor.

### Kod tarafında kalanlar
- [ ] **Play Billing** — lifetime (tek ödeme) + AI aboneliği. Karar bekliyor:
  RevenueCat (`purchases_flutter`, makbuz doğrulama/iptal/iade hazır) mı,
  `in_app_purchase` + Cloud Function (üçüncü taraf yok ama Play Developer API
  servis hesabı + RTDN Pub/Sub sıfırdan kurulacak) mı. `users/{uid}.premiumUntil`
  kurallarda istemciye zaten kapalı; satın alma doğrulaması onu SUNUCUdan
  yazacak. NOT: projede henüz `functions/` dizini yok.
- [ ] **Deneme süresi (1 ay)** — abonelikte Play Console'un kendi ücretsiz
  denemesi kullanılır (kod gerekmez). Lifetime'ın Play'de denemesi YOK; kendi
  `trialUntil` alanımız gerekir ve CİHAZA değil hesaba bağlanmalı (yoksa
  sil-kur = sınırsız deneme). Deneme kotası "5 istek" değil PUAN olmalı —
  `AiGate` zaten puan bazlı, düz istek sayısı 200 sayfalık PDF'te sömürülür.
- [ ] **Depolama tavanı SUNUCUda zorlanmıyor** — tavanın kendisi kondu
  (2026-08-05: ücretsiz 50 MB, premium 2 GB; sayım notlardaki `sizeBytes`
  toplamı, gösterge Ayarlar > Senkron'da). Sayaç İSTEMCİde: APK'yı değiştiren
  biri tavanı aşabilir. Play Billing'le birlikte Cloud Function/Storage kuralı
  gerekir (aynı sorun AI kota sayacında da var, aşağıya bak).
- [ ] **RTL cihazda denenmedi** — 35 yerleşim yönlü karşılığına çevrildi ve
  `rtl_layout_test` geri sızmayı engelliyor, ama Arapça bir çeviri henüz yok
  (bilerek, üstteki maddeye bak); gerçek ekranda kimse bakmadı. Arapça
  eklenince not kartı, sohbet balonları ve ek şeridine bakılmalı.
- [ ] **Semantik arama ve ses/video girişi yalnız Gemini'de** — embedding
  vektör boyutu sağlayıcılar arası uyuşmuyor (aynı dizinde karışık vektör
  aramayı bozar). Diğer sağlayıcıda açık hata veriliyor, sessiz yanlış sonuç
  yok (2026-08-02).
- [ ] **100 dil, Flutter'ın kapsamıyla sınırlı** — `GlobalMaterialLocalizations`
  çevirisi olmayan yerel ayar uygulamayı o dilde ÇALIŞMA ANINDA hataya düşürür;
  Flutter ~78 taban dil destekliyor. 100+ sayısına bölge varyantlarıyla
  (pt-BR, zh-Hans/Hant, es-419) ulaşılır. Ötesi = Material/Cupertino için elle
  `LocalizationsDelegate` yazmak. `locale_fallback_test` bunu CI'da doğruluyor.
- [ ] **Anonim hesaptan Google'a geçişte hesap ÇAKIŞMASI** — seçilen Google
  hesabı başka bir uid'e bağlıysa `credential-already-in-use` gelir ve
  birleştirme yapılamaz (Firebase iki uid'i birleştiremez). Şu an hata
  gösteriliyor; istenirse "yerel notları o hesaba kopyala" akışı yazılabilir.
  **2026-08-06 incelemesi:** doğrudan kopyalama TEHLİKELİ — anonim hesaba bir
  kez çıkılınca geri girilemez, yarıda kalan kopyanın kalanı kalıcı kayıptır.
  Güvenli tasarım: önce yerel yedek al → Google'a gir → yedeği geri yükle
  (bir şey giderse dosya diskte durur). Ön koşul: yedekle/geri yükle mantığı
  şu an `settings_screen.dart` içindeki widget'lara gömülü, servise
  çıkarılmalı. Uçtan uca sınamak iki ayrı Google hesabı + gerçek cihaz ister.

## Bilinen eksik / risk
- [ ] **Sesli notta canlı yazım yok** — kayıt+döküm aynı anda mikrofonu
  paylaşamadığı için Google'ın sesli giriş ekranına geçildi (bkz. 2026-07-25
  kararı): metin bitişte düşer, ses AMR (telefon kalitesi), duraklayınca
  oturum biter. Keep'in sınırlarıyla aynı. Canlı yazım + ses dosyası ikisini
  birden isteyen tek yol tek PCM akışını ikiye bölmek (Gemini Live, BYOK şart).
- [ ] **`GET_AUDIO` belgesiz ekstra** — Google ileride sesi vermeyi keserse
  sesli not yalnız metin üretir (çökmez). Kırılırsa üstteki maddedeki
  seçeneklere dönülür.
- [ ] **Görüntülü not yalnız cihazda** — bilinçli karar (buluta yüklenmez):
  uygulama silinirse ya da başka cihaza geçilirse video kaybolur; metadata
  senkronlandığı için diğer cihazda "senkronlanmadı" görünür (2026-07-24).
- [ ] **AI videoyu 60 sn ile sınırlı alıyor** — satır içi gönderim boyutu
  sınırı; daha uzun video için Files API / parçalama gerekir (2026-07-24).
- [ ] **Sarma sırasında IME oluşturma aralığı (altı çizili tahmin metni)
  gösterilmiyor** — çapalar aralığın konumunu kaydırdığı için atlanıyor.
  Yalnız görselli metin notunda; harf girişi etkilenmiyor (2026-07-24).
- [ ] **Editör diktesi Windows'ta AI'sız çalışamaz** — dikte METİN döndürmek
  zorunda, sesli asistandaki "eke düş" yedeği burada uygulanamıyor. Android'de
  cihaz tanıması olduğu için etkilenmiyor (2026-07-26).
- [ ] **Sesli asistan hatırlatıcısı cihazda denenmedi** — yerel zaman
  ayrıştırıcısı (`spoken_datetime.dart`) ve emniyet ağı testlerle doğrulandı ama
  gerçek konuşmayla uçtan uca bakılmadı; ayrıca bildirim izni verili değilse
  hatırlatıcı kaydolur, bildirim gelmez (2026-07-26).
- [ ] **Kesin alarm cihazda ölçülmedi** — `USE_EXACT_ALARM` + `exactAllowWhileIdle`
  yazıldı ve telefona kuruldu, ama bildirimin gerçekten dakikasında geldiği
  gözle doğrulanmadı (emülatör/test alarm zamanlamasını ölçemez). Kontrol:
  1-2 dk sonrasına hatırlatıcı kur, saate bak (2026-07-27).
- [ ] **Klavyeden görsel yapıştırma cihazda denenmedi** —
  `contentInsertionConfiguration` gövdeye ve liste öğelerine verildi; Gboard'ın
  pano çubuğundan görsel yapıştırma gerçek klavyeyle denenmedi. Üçüncü taraf
  klavyeler bu yolu desteklemeyebilir, onlarda "+" menüsündeki "Görsel yapıştır"
  yedek kalıyor (2026-07-27).
- [ ] **Widget'ların cihazdaki görünümü doğrulanmadı** — Material You renkleri,
  4 satırlık kart düzeni ve yeni çizgi ikonları (`ic_widget_checklist`,
  `ic_widget_ordered`) yalnız kodda; ana ekranda gözle bakılması gerekiyor
  (2026-07-26).
- [ ] **App Check ZORLAMASI açılmadı** — uygulama artık token üretiyor
  (`main.dart` `_activateAppCheck`), ama Firebase konsolunda "Enforce"
  KAPALI, yani hiçbir istek reddedilmiyor. Doğru sıra: konsolda uygulamayı
  Play Integrity ile kaydet → birkaç gün "doğrulanmamış istek" oranını izle →
  sıfıra yaklaşınca zorlamayı aç. Ters sırada açılırsa tüm kullanıcılar hata
  alır. Not: Play Integrity uygulamanın Play'den dağıtılmasını bekler, elle
  kurulan APK "doğrulanmamış" görünebilir (2026-07-27).
- [ ] **AI kota sayacı istemci tarafında** — kural aynı gün puanın azalmasını
  engelliyor ama gerçek zorlama için sunucu (Cloud Functions) gerekiyor
  (2026-07-24).
- [ ] **Çakışma çözümü ve sürüm geçmişi YAPILMAYACAK** — iki cihazda aynı notu
  aynı anda düzenlersen son yazan sessizce kazanır, geri dönüş yok. Kullanıcı
  kararı 2026-07-27'de verildi, **2026-08-06'da tasarım sunulduktan sonra
  yeniden onaylandı** ("sürüm geçmişine gerek yok, en son neyse o"). Gerçek bir
  not kaybı yaşanırsa madde açılır; o zaman ilk adım `items` dizisini map'e
  taşımaktır (Firestore map'i eleman eleman birleştirir, diziyi birleştiremez).
- [ ] **AI notu baştan yazınca geri dönüş yok** — "Notu düzelt/geliştir"
  içeriği değiştiriyor, geri alma yalnız o anki şeritte. Uygulama kapanınca
  orijinal metin gider. Sürüm deposu/geri alma noktası bilerek yapılmadı
  (kullanıcı kararı 2026-07-27) (2026-07-27).
- [ ] **Sesli nottaki "çift not" koruması testsiz** — `voice_assistant.dart
  finish()` içindeki `resultNoteId == null` kapısı yalnız muhakemeyle
  doğrulandı; testi Firestore + mikrofon sahtesi ister, projede öyle bir
  altyapı yok. Kontrol: sesli notu ağ kesikken bitir, tek not oluşmalı
  (2026-08-04). Denetimin diğer yarısı (semantik aramanın boş vektör yedeği)
  2026-08-05'te `test/embed_texts_test.dart` ile kapandı.


## Devir paketi (2026-08-04) — uygulandı, kalan uçlar

- [ ] **Widget'ın YENİ tema davranışı cihazda görülmedi** — uygulamada
  seçilen tema artık widget'a yazılıyor ve Kotlin sağlayıcı renkleri çalışma
  anında uyguluyor; derleniyor ama gerçek ana ekranda kimse bakmadı.
  Kontrol: telefonu AÇIK moda al, uygulamada Koyu seç, dört widget'a da bak
  (2026-08-05).
- [ ] **Web ikonları güncellenmedi** — `web/` hâlâ Flutter şablonunun stok
  ikonlarını taşıyor (eski çivit simge de oraya hiç işlenmemişti). Proje
  hedefi Android + Windows olduğu için atlandı. YAPILMAYACAK: `web/`
  derlenmiyor bile; madde kayıt olarak duruyor.
- [ ] **Yeni çeviriler (44 + 12 anahtar × 15 dil) makine üretimi**, gözden
  geçirilmedi — yukarıdaki "Çevirileri anadili konuşana göstert" maddesinin
  kapsamına girer.

## Sonra yapılacak
Sıra kullanıcı tarafından 2026-07-27'de belirlendi; 1. madde (çeviri + Gmail
silme) tamamlandı, kalanlar sırayla:
- [ ] **PPTX'i `Desktop\dosya okuyucu` reposundan al** — buradaki
  `pptx_render.dart` testsiz. Kaynak depoda `pptx_render.dart` 61 KB +
  `pptx_editor.dart` 18 KB + `pptx_geometry.dart` 25 KB (~2500 satır) ve ~60 KB
  test. Port işi: `Attachment` modeli ve depolama katmanı iki repoda farklı.
  **KENDİ OTURUMUNU İSTER** (2026-08-06 ölçümü): tek oturumda yarısı yapılıp
  bırakılırsa en kötü sonuç çıkar.
- [ ] **Farklılaşma özellikleri** (kullanıcı 2026-07-24'te sordu, ayrı oturum):
  1) notlardan otomatik aralıklı tekrar/kart üretimi, 2) tüm defterle sohbet
  (RAG), 3) otomatik not bağlama. Sırayla 1 → 2 → 3 önerildi.
