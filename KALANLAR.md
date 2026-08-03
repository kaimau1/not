# KALANLAR — canlı kalan iş / plan listesi

(Biten madde silinir. Karar/neden bilgisi buraya değil HAFIZA.md'ye yazılır.)

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
- [ ] **Çevirileri anadili konuşana göstert** — 2026-08-03'te 11 dil eklendi
  (fr, it, pt, ru, hi, ja, ko, zh, id, nl, pl); toplam 15 dil. Hiçbiri anadili
  konuşan biri tarafından okunmadı. Aynısı de/es için de geçerli. Yayına
  çıkmadan önce en azından en çok kullanılacak dillerde göz gezdirilmeli.
  ⚠ Arapça BİLEREK dışarıda: `app_ar.arb` oluşur oluşmaz dil listesinde
  seçilebilir hâle gelir ve RTL işi bitmeden editör bozuk görünür
  (bkz. aşağıdaki "RTL hazırlığı → Arapça" maddesi).
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
- [ ] **Paket sınırları uygulanmadı** — kararlaştırılan yapı: ücretsizde ek
  (görsel/PDF/ses/video) yok ya da ~50 MB tavan, lifetime'da 2 GB tavan.
  `AppConstants.maxFree/PremiumAttachmentBytes` var ama depolama TAVANI yok;
  lifetime'ın maliyeti ancak tavanla öngörülebilir olur.
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
- [ ] **Liste modunda sürükleyerek sıralarken kenarda otomatik kaydırma yok**
  — liste artık serbest görsel tuvalinin içinde `shrinkWrap` ile duruyor, dış
  kaydırıcıyı sürükleme sırasında elle sürmek gerekir (2026-07-24).
- [ ] **Sarma sırasında IME oluşturma aralığı (altı çizili tahmin metni)
  gösterilmiyor** — çapalar aralığın konumunu kaydırdığı için atlanıyor.
  Yalnız görselli metin notunda; harf girişi etkilenmiyor (2026-07-24).
- [ ] **Editör diktesi Windows'ta AI'sız çalışamaz** — dikte METİN döndürmek
  zorunda, sesli asistandaki "eke düş" yedeği burada uygulanamıyor. Android'de
  cihaz tanıması olduğu için etkilenmiyor (2026-07-26).
- [ ] **Sesli asistan hatırlatıcısı cihazda denenmedi** — yerel zaman
  ayrıştırıcısı (`tr_datetime.dart`) ve emniyet ağı testlerle doğrulandı ama
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
- [ ] **Çakışma çözümü BİLEREK yapılmadı** — iki cihazda aynı notu aynı anda
  düzenlersen son yazan sessizce kazanır. Kullanıcı kararı (2026-07-27):
  tek kullanıcılı uygulamada sıklığı düşük, Keep'in birleştirme makinesi
  paylaşılan notlar için var. Gerçek bir not kaybı yaşanırsa bu madde açılır;
  o zaman ilk adım `items` dizisini map'e taşımaktır (Firestore map'i eleman
  eleman birleştirir, diziyi birleştiremez).
- [ ] **AI notu baştan yazınca geri dönüş yok** — "Notu düzelt/geliştir"
  içeriği değiştiriyor, geri alma yalnız o anki şeritte. Uygulama kapanınca
  orijinal metin gider. Sürüm deposu/geri alma noktası bilerek yapılmadı
  (kullanıcı kararı 2026-07-27) (2026-07-27).

## Sonra yapılacak
Sıra kullanıcı tarafından 2026-07-27'de belirlendi; 1. madde (çeviri + Gmail
silme) tamamlandı, kalanlar sırayla:
- [ ] **Çakışma çözümü + sürüm geçmişi (TEK paket)** — ikisi de notun geçmiş
  hâllerini saklamayı gerektiriyor; ayrı ayrı yapılırsa aynı veri iki kez
  modellenir. Şu an alan bazlı `merge: true` ile son yazan sessizce kazanıyor
  (`notes_repository.dart:150`), kullanıcı uyarı görmüyor. En yüksek risk.
- [ ] **PPTX'i `Desktop\dosya okuyucu` reposundan al** — orada `pptx_render.dart`
  1321 satır + 4 test dosyası (~900 satır), buradaki 921 satır ve testsiz.
  `pptx_editor.dart`, `slide_canvas.dart`, `slideshow_screen.dart` de var.
  Port işi: `Attachment` modeli ve depolama katmanı iki repoda farklı.
- [ ] **RTL hazırlığı → Arapça** (kullanıcı 2026-07-28'de erteledi, 2026-07-30'da
  "iki tur" kararıyla yine ayrı tura bırakıldı; İngilizce + Almanca + İspanyolca
  bitti, Arapça beklemede) — `text_wrap.dart` ve görsel tuvali baştan sona
  soldan-sağa varsayımıyla yazılı (çapalar, float bantları, sağ kenar dolgusu).
  Arapça bunlardan ÖNCE eklenirse editör bozuk görünür.
  Yapılacak: `planTextWrap`'e yön geçir (parametre var, `WrapTextController`
  hiç vermiyor), sol/sağ → satır başı/sonu eşlemesini yöne göre çevir,
  `_FloatRowState`'te yöne duyarlı dolgu. Sonra `app_ar.arb` (**406** anahtar),
  `supportedLanguages`'a `'ar': 'العربية'`.
  ⚠ Arapça çeviriyi kullanıcı doğrulayamaz — yayına çıkmadan Arapça bilen
  birine gösterilmeli. (Aynısı Almanca/İspanyolca için de kısmen geçerli:
  çeviriler AI üretimi, anadili konuşanı görmedi.)
- [ ] **Sesli asistanın tarih ayrıştırıcısı yalnız Türkçe** (`tr_datetime.dart`)
  — de/es/en'de "yarın saat 3'te" yerel olarak çözülmez, emniyet ağı yok,
  model'e düşer. Dil eklerken kapsam dışı bırakıldı (2026-07-30).
- [ ] **Farklılaşma özellikleri** (kullanıcı 2026-07-24'te sordu, ayrı oturum):
  1) notlardan otomatik aralıklı tekrar/kart üretimi, 2) tüm defterle sohbet
  (RAG), 3) otomatik not bağlama. Sırayla 1 → 2 → 3 önerildi.
