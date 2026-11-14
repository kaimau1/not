# KALEM VE EKLERE YAZMA PLANI (2026-11-10)

> **2026-11-09:** K2–K7 `OTURTMA_PLANI.md`'ye taşındı (K2 → F63.3, K3 → F63.4, K4 → F63.2,
> K5 → F63.5, K6 → F65.1–F65.3, K7 → F65.6). "Kurallar 1–4" ve cihaz bulguları burada
> geçerli kalır; kalemin depolama ve çizim maliyeti (yeni bulgu) orada Faz 61–62.

Kullanıcı isteği (2026-11-10): "çok iyi bir kalem deneyimi, parmakla kalem
karışmadan profesyonel, rahat, hatasız; eklere (PDF, görsel) rahatça yazılıp
kaydedilebilmeli; telefonda da elle yazma düzgün olmalı; eklerin yerleşimi
baştan tasarlanabilir, sabitleme üzerine çalışılabilir." Önceki liste
(2026-11-09): sabit eklerde kalem akışı karışık (kalem varken parmak yazmamalı,
kalem yokken düğmeyle parmak yazabilmeli, yüzen kalem düğmesi orada olmalı ve
çalışmalı); sabit PDF aşağı kaydırılarak sayfa sayfa geçilmeli; tam ekranda
sayfa korunmalı.

Protokol: maddeler sırayla; her faz cihazda (HUAWEI MatePad 11, M-Pencil,
`adb shell input stylus …` = kalem, `input touchscreen …` = parmak) önce
yeniden üretilir, sonra düzeltilir, sonra yine cihazda doğrulanır. Akıcılık
kapısı (CLAUDE.md ÖLÇÜM KAPISI) bağlayıcı.

## Cihazda doğrulanmış bulgular (2026-11-10, profil uygulaması, dikey tablet)

| # | Senaryo | Beklenen | Görülen |
|---|---|---|---|
| B1 | Sabit PDF 5. sayfa → tam ekran (⛶) | 5. sayfada açılır | **1. sayfadan açılıyor** |
| B2 | Sabit PDF'te parmakla aşağı kaydır | sonraki sayfaya akar | sayfanın dibinde duruyor; sayfa yalnız yana kaydırınca geçiyor |
| B3 | Kalem kipi kapalı, sabit PDF'e kalemle çiz | kalem kipi açılır, iz PDF'te | kalem kipi açılıyor (ipucu + yüzen kalem düğmesi), **iz yok** |
| B4 | Kalem kipindeyken sabit PDF'e kalemle/parmakla çiz | kalem çizer, parmak kaydırır | **ikisi de çizmiyor**; aynı kalem not gövdesinde çiziyor (kalem kipi gövdeye bağlı) |

| B5 | Kalem görüldükten sonra parmakla gövdeye/PDF'e çiz | parmak çizmez (kaydırır) | doğru (çizmiyor) — ama ipucu "parmak da yazar" diyordu |

Kod haritası (keşif, 2026-11-10): sabit PDF denetleyicisi (`pinned_media_pane._inkFor`) ve gömülü
PDF denetleyicisi (`note_images._docInkFor`) `setEditing(true)` almıyordu → `InkPageLayer`
`IgnorePointer` ile her şeyi yok sayıyordu (B3/B4 kökü). `penOnly` kurulumdaki kopyadan
okunuyordu; tam ekranda/geri alda değişen çizgiler alınmıyordu (sonraki çizgi eski listeyi
kaydedip onları silebiliyordu — veri kaybı); yüzen düğme kapanınca bölmenin kendi kalemi açık
kalıyordu; sabit PDF'te avuç sayfayı kaydırıyordu; tam ekran `initialPage` almıyordu.

## Kurallar (hedef davranış — her faz buna uyar)

1. Kalem kipi açıkken ve cihazda kalem görülmüşse PARMAK ÇİZMEZ (kaydırır/yakınlaştırır);
   kalem yazarken değen avuç yutulur. (`penOnly`, ilk kalem dokunuşunda kendiliğinden açık;
   kullanıcı Ayarlar → Kalem, yazım ve ekran'dan kapatabilir.)
2. Kalem hiç görülmemiş cihazda (telefon) kalem düğmesi PARMAĞI çizdirir; iki parmak kaydırır.
3. Yüzen kalem düğmesi kalem görülmüş cihazda not ekranında ve sabit eklerde görünür; "kalem
   dokunur"a geçince hiçbir yüzeyde kalem çizmez.
4. Çizgiler eke kaydedilir (`Attachment.ink`), tam ekran ↔ sabit ↔ gömülü arasında kaybolmaz.

## Fazlar

### K1 — Sabit/gömülü PDF'e yazma çalışır (bu oturum, 2026-11-10)
- [x] Denetleyiciler düzenleme kipinde (`setEditing(true)`) — B3/B4.
- [x] `penOnly` her kurulumda canlı; kalem gövdede görülünce bölme de bilir.
- [x] Dışarıdan değişen çizgiler alınır (kimlik + içerik karşılaştırması; çizim sürerken değil).
- [x] Yüzen düğme "dokunur"a geçince bölmenin kendi kalemi kapanır.
- [x] Kalemsiz cihazda otomatik kalem katmanı yok → basılı tut + "Not al" parmakta çalışır.
- [x] Sabit/gömülü PDF'te avuç reddi (`InkClaim`, gövdedeki yakalayıcının aynısı).
- [x] Tam ekran kaldığı sayfadan açılır, dönüşte sayfa sabite yansır — B1.
- [x] Sayfanın dibinde aşağı çekince sonraki sayfa, tepesinde yukarı çekince önceki sayfa — B2. **Geçersiz (2026-11-10, OTURTMA F65.8):** sabit bölmede sayfalar artık sürekli dikey listede (`PdfPageColumn`); dikey çekişle geçiş kalktı.
- [x] Kalem kipi ipucu "yalnız kalem"in gerçek durumunu söyler — B5.
- [x] Cihazda doğrulandı (2026-11-10, profil uygulaması): kalem sabit PDF'e çizer, ipucu "yalnız kalem: açık"; parmak çizmez, kaydırır; dikey çekişle 6→7→8; tam ekran 8. sayfadan açılır, dönüş 8; tam ekranda çizilen çizgi sabite gelir, sabitte çizilen ikincisi ilkini silmez; yüzen düğme "dokunur"da kalem çizmez. Avuç reddi adb ile üretilemedi (tek dokunuş türü) — telefonda/tablette elle bakılacak.
- [x] Not paketinde kalem düğmesi de aynı kökten çalışmıyordu → düzeltildi (bekçi `test/ink_editing_guard_test.dart`).

### K2 — Sabit GÖRSELE kalemle yazma
Sabit görselde mürekkep katmanı hiç yok (yalnız balon). Görselin üstüne `InkPageLayer`
(`Attachment.ink`, sayfa 1, `uniform: false`), yakınlaştırmayla birlikte dönüşen koordinat;
kurallar 1–4. Görüntüleyicide (tam ekran görsel) aynı katman.

### K3 — Tam ekran görüntüleyicilerde kalem düğmesi
PDF/görsel/slayt tam ekranı ayrı rota: yüzen kalem düğmesi yok. Aynı `StylusToggleOverlay`
ve kurallar; `stylusEver` her ink katmanında işaretlensin (yalnız editör içeriğinde değil).

### K4 — Tek kalem tepsisi, tek etkin yüzey
Kalem tepsisi yalnız sayfa mürekkebini sürüyor; sabit ekteki denetleyici renk/silgi/kalınlık
değişikliğini görmüyor. "Etkin yüzey" (son kalem dokunuşu: gövde mi sabit ek mi) tepsiye
bağlanır; araç seçimi `InkToolMemory` üzerinden her denetleyiciye yayılır.

### K5 — Telefonda elle yazma
Kalem düğmesi yalnız klavye açıkken hızlı satırda; klavye kapalıyken alt çubukta da görünür
olmalı. Parmakla yazarken iki parmak kaydırma ipucu; sayfa sonunda yazmaya devam alanı.
Cihaz: tablette telefon düzeni (`wm size 1080x2400; wm density 420`) + `input touchscreen`.

### K6 — Eklerin yerleşimi (tasarım)
Yeni ek eklenince "nerede dursun?" seçicisi var (Sabit/Yüzen/Ek). İstenen: notu açarken
yerleşimi baştan tasarlayabilmek (sabit ek üstte/solda/sağda — `pinned_side` var — oranı,
birden çok sabit ek arasında geçiş). KARAR GEREKİR: çoklu sabit ek sekmeli mi, yan yana mı.

### K7 — Web'de ek görünmüyor / paylaşılan notta ek senkronu
Önceki listeden. Kod tek başına yetmiyor: gerçek kayıtta ekin `downloadUrl`/`driveId`/
`thumbUrl` alanları görülmeli. Gereken: bu bilgisayarda `firebase login` (kullanıcı) ya da
uygulama içi tarayıcıda web'e Google ile giriş. Ekran görüntüsündeki kutu "telefondan
çıkmamış" durum simgesi gibi — paylaşılan notta yükleme yolu (`_isShared` → Storage,
`_processForeign`) ilk şüpheli.
