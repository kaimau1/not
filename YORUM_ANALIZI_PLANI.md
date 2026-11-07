# Google Play yorum analizi → yapılacaklar (2026-11-07)

**Kaynak:** Google Play'de 4 uygulamanın "Tüm yorumlar" penceresi, uygulama içi tarayıcıda okundu (~230 yorum).
- Samsung Notes (TR, ~140 yorum)
- Google Keep (TR, 20)
- Notein (TR, 31; el yazısı + PDF, tablete odaklı)
- Squid (EN, 33; kalemle not)

Okunan yorumlar Play'in "en alakalı" sıralamasıydı, yıldıza göre süzülmedi. Sayılar örnek büyüklüğünü gösterir, oran değildir.

**Protokol:** Diğer planlar gibi. "Faz 54'ü yap" denince yalnız o faz yapılır. KARAR maddesinde önce kullanıcıya sorulur. Bitince madde `[x]`, HAFIZA güncellenir, commit atılır. Akıcılık bütçesi (AKICILIK Faz 21/23) bağlayıcıdır.

## 1. İnsanlar neden memnun?

| Tema | Yorumlarda nasıl geçiyor | Bizde durum |
|---|---|---|
| Hepsi bir arada | Yazı, el yazısı, çizim, foto, ses ve PDF aynı notta; "kalem kâğıdı hayatımdan çıkardım" | Var (sayfa üstü el yazısı, ekler, sesli not) |
| Kalem hissi | "Gerçek defterde yazıyormuş gibi", "en akıcı yazan uygulama" | Var; gecikme ölçülmedi (bkz. F54.1) |
| Kalemle ve parmakla ayrı iş | Squid: "S Pen yazar, parmak siler" övülüyor | "Yalnız kalem" ve yan düğmeyle silgi var. Parmağa silgi atama yok |
| Hızlı açılış | "Hızlıca açıp not alıyorum", "hiç kasmıyor" | Akıcılık planı (Faz 20–27) |
| Ücretsiz, reklamsız | Samsung Notes'un en çok övülen yanı | Var |
| Kilitli not, favoriler, yedek | "Şifre koyabilmek süper" | Uygulama kilidi var; not başına kilit bakılacak |
| PDF'e yazma | Akademik kullanım | Var |

## 2. İnsanlar nelerden şikâyetçi? (önem sırasıyla)

1. **Veri kaybı ve güvensiz yedek (en ağır yorumlar, hepsi 1★):** "Güncellemeden sonra notlar açılmıyor", "yedek hiçbir şey kaydetmemiş", "yeni tablete geçince yıllık işim silindi" (Samsung Notes ve Squid'de çok sayıda).
2. **Güncelleme alışkanlığı bozuyor:** Kaydet düğmesi kalktı, PDF ekleme düğmesi kaldırıldı, düzen değişti. İstek hep aynı: "eski hâli geri getirin".
3. **Kalem gecikmesi ve takılma:** "S Pen ile yazı gecikmeli geliyor", "son güncellemeden sonra donma", "otomatik kayıt 10 sn'de bir ekranı donduruyor".
4. **Avuç ve jest karışması:** "Yazdıktan sonra elle kaydırınca tam algılamıyor". Kalem kutusu yanlışlıkla kapanıyor, geri açması zor.
5. **i/ö/ü noktaları ve kısa işaretler çizilmiyor** (Notein, basınçlı kalemde).
6. **Not içinde arama zayıf (Keep'in 1 numaralı isteği):** Arama sonucuna basınca kelimenin yerine gitmiyor, vurgulamıyor.
7. **Hatırlatıcı bildirimi gelmiyor** (Keep, güncellemeden sonra).
8. **Yazı biçimi eksik:** Tek yazı tipi, metin rengi yok, iki yana yaslama yok. Yazı boyutu her seferinde baştan ayarlanıyor.
9. **Senkron yok, platformlar arası değil:** "Telefonda başlayıp bilgisayarda devam edemiyorum", Windows'ta yok.
10. **PDF yakınlaşınca pikselleşiyor; uzun notta karakter sınırı** (Samsung Notes'ta 30 000 kelime).
11. **Kalem çeşidi ve şekil:** Dolma kalem ve kaligrafi isteniyor. Şekil tanıma 6 köşeden sonra her şeyi daire sayıyor. Düz çizgi çizildikten sonra ucu taşınamıyor.
12. **Ses kaydı yazıya dökülsün** (Samsung Notes isteği).

## 3. Bizim için çıkan dersler

- Bizim en güçlü kozumuz **web + Android senkronu, ücretsiz olmak ve AI**. Rakiplerde bu üçü birlikte yok. Bunu bozacak bir şey yapmayalım.
- 1★ yorumları özellik eksikliği değil, **güven kaybı** getiriyor (veri kaybı, bozan güncelleme). Önce güven.
- Tablet kullanıcısının üç beklentisi var: kalemin anında yazması, avucun hiçbir şey yapmaması, menünün yolu kapatmaması. Bu oturumda üçüne de dokunduk (avuç reddi, kalemle tek tık, kalem kapsülü).

## Faz 54 — Güven (veri kaybı yaşanmasın)

- [ ] **F54.1 Kalem gecikmesini ölç.** Tabletin kalemiyle dokunuştan ilk boyamaya kadar geçen süre (`tool/perf/`). Hedef: ≤ 1 kare (~16 ms) ek gecikme. Fazlaysa sonraki adım: Android'in düşük gecikmeli çizim yolu (`androidx.graphics:graphics-core`, ön tamponda çizim). **KARAR:** Yerel kod ekleneceği için önce ölçüm sonucu kullanıcıya gösterilir.
- [ ] **F54.2 "Yedeğim gerçekten var mı?" göstergesi.** Ayarlar'da son başarılı senkron ve son yerel yedek tarihi, not sayısıyla birlikte. Rakiplerde en çok "yedek alındı sanıyordum" şikâyeti var.
- [ ] **F54.3 Göç öncesi otomatik yerel yedek.** Şema değiştiren her sürüm açılışında bir kez çalışır ve geri yüklenebilir (F22.4 / F28.2 kuralıyla aynı).
- [ ] **F54.4 Yeni cihaza geçiş denemesi.** Duman testi: girişten sonra bütün notların, el yazısının ve eklerin geldiği doğrulanır (`KALANLAR.md` §2'ye adım olarak).

## Faz 55 — Tablet ve kalem (bu oturumun devamı)

- [ ] **F55.1 Parmağa araç ata** (Squid övgüsü): "Parmak: kaydır / sil / çiz" seçeneği, "yalnız kalem"in yanında.
- [ ] **F55.2 Düz çizgi ucunu taşı:** Bekleyip düzleşen çizgide kalem kalkmadan uç sürüklenebilsin. Şekil tanıma zaten var, yalnız uç serbest kalacak.
- [ ] **F55.3 Çokgen tanıma:** 5–8 köşe düzgün çokgen (bugün daire sayılıyor olabilir, test et).
- [ ] **F55.4 Dolma kalem (basınca duyarlı, uçtan inceltme):** i/ö/ü noktası basınç 0'da da görünmeli. Notein'deki hataya düşmemek için en ince çizgiye taban konur.
- [ ] **F55.5 Kalem kapsülü cihaz turu:** Yeni kapsül tablette ve telefonda elle denenir. Hızlı renkler ve hap ↔ kapsül geçişi kontrol edilir.

## Faz 56 — Bulma ve hatırlatma

- [ ] **F56.1 Arama sonucundan kelimeye git:** Arama sonucundaki nota basınca o kelimeye kaydırılsın ve vurgulansın. Notta ara özelliğinin var olan parçaları yeniden kullanılır.
- [ ] **F56.2 Hatırlatıcı güvenilirliği:** Pil iyileştirme ve tam zamanlı alarm izni yoksa uyarı çıksın. Telefonda kanıtla.
- [ ] **F56.3 Son kullanılan yazı boyutu/biçimi hatırlansın** (Keep şikâyeti: her seferinde baştan ayarlanıyor).

## Faz 57 — Değişikliği nazik yap (güncelleme alışkanlığı bozmasın)

- [ ] **F57.1 Kaldırılan ya da taşınan her düğme için bir sürümlük ipucu:** "X artık şurada" diye. Kural olarak `HAFIZA.md`'ye yazılır.
- [ ] **F57.2 Sürüm notu uygulama içinde:** Yalnız kullanıcıya görünen değişiklikler, Türkçe, en çok 3 madde.

## İsteğe bağlı (talep çok ama bizde öncelik düşük)

- Ses kaydını yazıya dökme: canlı dikte zaten var. Kayıttan sonra döküm AI ile yapılabilir. Maliyeti var, KARAR gerekir.
- El yazısı matematiği LaTeX'e çevirme (Notein isteği).
- Kalem sesi (Notein isteği): eğlenceli ama YAGNI.
