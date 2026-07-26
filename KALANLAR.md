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
- [ ] **Sağ sarmada tek uzun kelime**: satırda kırılacak boşluk yoksa (tek
  uzun kelime) sağ kenar dolgusu konamaz, o satır görselin altına girebilir.
  Tavanı kaldırmak kendi satır kırıcımızı yazmayı gerektirir (2026-07-24).
- [ ] **Sütunun dörtte üçünden fazlasını kaplayan görselin altında liste
  satırı kalıyor** — satır yana kaydırılamıyor (yer yok), altına itmek listenin
  dikey akışını değiştirmeyi gerektirir; kullanıcı görseli daraltarak çözüyor
  (2026-07-24).
- [ ] **Liste modunda sürükleyerek sıralarken kenarda otomatik kaydırma yok**
  — liste artık serbest görsel tuvalinin içinde `shrinkWrap` ile duruyor, dış
  kaydırıcıyı sürükleme sırasında elle sürmek gerekir (2026-07-24).
- [ ] **Sarma sırasında IME oluşturma aralığı (altı çizili tahmin metni)
  gösterilmiyor** — çapalar aralığın konumunu kaydırdığı için atlanıyor.
  Yalnız görselli metin notunda; harf girişi etkilenmiyor (2026-07-24).
- [ ] **Canlı çeviri anahtarsız çalışmıyor** — `firebase_ai 3.14.1` Live
  Translate'in `translationConfig`/`targetLanguageCode` alanını hiç sunmuyor
  (2026-07-26 ölçümü), o yüzden dahili AI'a taşınamadı; kullanıcı Gemini
  anahtarı girmek zorunda. Alternatif yol: cihaz tanıma + ML Kit çevrim dışı
  çeviri + TTS zinciri (parçaları zaten var: `device_speech`,
  `offline_translator`, `flutter_tts`) — ayrı oturum işi.
- [ ] **Editör diktesi Windows'ta AI'sız çalışamaz** — dikte METİN döndürmek
  zorunda, sesli asistandaki "eke düş" yedeği burada uygulanamıyor. Android'de
  cihaz tanıması olduğu için etkilenmiyor (2026-07-26).
- [ ] **Sesli asistan hatırlatıcısı cihazda denenmedi** — yerel zaman
  ayrıştırıcısı (`tr_datetime.dart`) ve emniyet ağı testlerle doğrulandı ama
  gerçek konuşmayla uçtan uca bakılmadı; ayrıca bildirim izni verili değilse
  hatırlatıcı kaydolur, bildirim gelmez (2026-07-26).
- [ ] **Sohbet asistanında hatırlatıcı emniyet ağı yok** — ayrıştırıcı hazır,
  yalnız sesli asistana bağlandı; `assistantChat` hâlâ modele bağımlı
  (2026-07-26).
- [ ] **Widget'ların cihazdaki görünümü doğrulanmadı** — Material You renkleri,
  4 satırlık kart düzeni ve yeni çizgi ikonları (`ic_widget_checklist`,
  `ic_widget_ordered`) yalnız kodda; ana ekranda gözle bakılması gerekiyor
  (2026-07-26).
- [ ] **AI kota sayacı istemci tarafında** — kural aynı gün puanın azalmasını
  engelliyor ama gerçek zorlama için sunucu (Cloud Functions + App Check)
  gerekiyor; App Check hiç aktive edilmemiş durumda (2026-07-24).

## Sonra yapılacak
- [ ] **Farklılaşma özellikleri** (kullanıcı 2026-07-24'te sordu, ayrı oturum):
  1) notlardan otomatik aralıklı tekrar/kart üretimi, 2) tüm defterle sohbet
  (RAG), 3) otomatik not bağlama. Sırayla 1 → 2 → 3 önerildi.
