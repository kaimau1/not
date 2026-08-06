# KALANLAR — canlı kalan iş / plan listesi

(Biten madde silinir. Karar/neden bilgisi buraya değil HAFIZA.md'ye yazılır.)

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

- **PDF çizimini dışa aktarılan/paylaşılan PDF'e gömme** (bilinçli ertelendi,
  bkz. 2026-07-23 kararı): şu an çizim yalnız uygulama içinde görünüyor.

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
- [ ] **PPTX'i `Desktop\dosya okuyucu` reposundan al** — orada `pptx_render.dart`
  1321 satır + 4 test dosyası (~900 satır), buradaki 921 satır ve testsiz.
  `pptx_editor.dart`, `slide_canvas.dart`, `slideshow_screen.dart` de var.
  Port işi: `Attachment` modeli ve depolama katmanı iki repoda farklı.
- [ ] **Farklılaşma özellikleri** (kullanıcı 2026-07-24'te sordu, ayrı oturum):
  1) notlardan otomatik aralıklı tekrar/kart üretimi, 2) tüm defterle sohbet
  (RAG), 3) otomatik not bağlama. Sırayla 1 → 2 → 3 önerildi.
