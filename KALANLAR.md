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
- [ ] **AI kota sayacı istemci tarafında** — kural aynı gün puanın azalmasını
  engelliyor ama gerçek zorlama için sunucu (Cloud Functions + App Check)
  gerekiyor; App Check hiç aktive edilmemiş durumda (2026-07-24).

## Sonra yapılacak
- [ ] **Farklılaşma özellikleri** (kullanıcı 2026-07-24'te sordu, ayrı oturum):
  1) notlardan otomatik aralıklı tekrar/kart üretimi, 2) tüm defterle sohbet
  (RAG), 3) otomatik not bağlama. Sırayla 1 → 2 → 3 önerildi.
