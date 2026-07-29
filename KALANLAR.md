# KALANLAR — canlı kalan iş / plan listesi

(Biten madde silinir. Karar/neden bilgisi buraya değil HAFIZA.md'ye yazılır.)

- **GitHub Actions ödeme sorunu**: 2026-07-21'den beri tüm CI run'ları
  "recent account payments have failed or your spending limit needs to be
  increased" hatasıyla başlamıyor → analiz/test ve imzalı APK/Release üretimi
  duruyor. GitHub → Settings → Billing & plans'ten çözülmeli; sonra `[apk]`
  içeren bir commit ya da Actions → Run workflow ile Release tazelenmeli.
- **PDF çizimini dışa aktarılan/paylaşılan PDF'e gömme** (bilinçli ertelendi,
  bkz. 2026-07-23 kararı): şu an çizim yalnız uygulama içinde görünüyor.

## Bilinen eksik / risk
- [ ] **Sesli notta canlı yazım yok** — kayıt+döküm aynı anda mikrofonu
  paylaşamadığı için Google'ın sesli giriş ekranına geçildi (bkz. 2026-07-25
  kararı): metin bitişte düşer, ses AMR (telefon kalitesi), duraklayınca
  oturum biter. Keep'in sınırlarıyla aynı. Canlı yazım + ses dosyası ikisini
  birden isteyen tek yol tek PCM akışını ikiye bölmek (Gemini Live, BYOK şart).
- [ ] **`GET_AUDIO` belgesiz ekstra** — Google ileride sesi vermeyi keserse
  sesli not yalnız metin üretir (çökmez). Kırılırsa üstteki maddedeki
  seçeneklere dönülür.
- [ ] **Word (.docx) dışa aktarımında görseller hâlâ metnin sonunda** — PDF
  nottaki yerleşimi izliyor, docx henüz izlemiyor (2026-07-24).
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
- [ ] **Sohbet asistanında hatırlatıcı emniyet ağı yok** — ayrıştırıcı hazır,
  yalnız sesli asistana bağlandı; `assistantChat` hâlâ modele bağımlı
  (2026-07-26).
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
- [ ] **Çevrimdışıyken ek eklenemiyor** — `appendAttachment` ve
  `patchAttachment` `runTransaction` kullanıyor, transaction ise ağ turu
  gerektiriyor. Uçakta/metroda nota ek eklemek sessizce çalışmıyor. Düz bir
  bug; düzeltmesi küçük (merge'lü yazım ya da yeniden deneme) (2026-07-27).
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
- [ ] **RTL hazırlığı → Arapça** (kullanıcı 2026-07-28'de erteledi: "sonra
  yaparız"; İngilizce bitti, Arapça beklemede) — `text_wrap.dart` ve görsel tuvali
  baştan sona soldan-sağa varsayımıyla yazılı (çapalar, float bantları, sağ
  kenar dolgusu). Arapça bunlardan ÖNCE eklenirse editör bozuk görünür.
  Yapılacak: `planTextWrap`'e yön geçir (parametre var, `WrapTextController`
  hiç vermiyor), sol/sağ → satır başı/sonu eşlemesini yöne göre çevir,
  `_FloatRowState`'te yöne duyarlı dolgu. Sonra `app_ar.arb` (388 anahtar).
  ⚠ Arapça çeviriyi kullanıcı doğrulayamaz — yayına çıkmadan Arapça bilen
  birine gösterilmeli.
- [ ] **Farklılaşma özellikleri** (kullanıcı 2026-07-24'te sordu, ayrı oturum):
  1) notlardan otomatik aralıklı tekrar/kart üretimi, 2) tüm defterle sohbet
  (RAG), 3) otomatik not bağlama. Sırayla 1 → 2 → 3 önerildi.

- [ ] **⚠ CI ÖLÜ — GitHub Actions koşmuyor** (2026-07-23'ten beri, `main` dahil).
  `Derleme` iş akışının her koşusu ~3 saniyede logsuz kırmızı; runner hiç
  başlamıyor (`runner_name` boş, log indirme 404). Son yeşil koşu #111
  (2026-07-22). Bu bir derleme hatası DEĞİL — büyük olasılıkla Actions
  dakikası/faturalandırma (repo private). Bakılacak: GitHub → Settings →
  Billing → Actions kullanımı. Düzelene kadar her değişiklik YERELDE
  doğrulanmalı (`flutter analyze` + `flutter test`, APK için Android SDK).
