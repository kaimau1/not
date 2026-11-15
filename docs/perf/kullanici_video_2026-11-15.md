# Kullanıcı ekran kayıtları — kare analizi (2026-11-15)

Kaynak: kullanıcının kendi telefonu (Xiaomi 23078PND5G, Android 16 / API 36, 1220x2712, 120/144 Hz), uygulama 1.2.80 release.
Videolar `Desktop/ab_apk/kullanici/k1.mp4` (118 s), `k2.mp4` (120 s), `k3.mp4` (150 s, "şu an tekrar bak çok kasıyor").
Kareler: `Desktop/ab_apk/kullanici/kareler/` (repoda PNG yok). Betikler oturum scratchpad'inde (pass1/pass2/an/trend), yöntem aşağıda.

## 0. Zamanla kötüleşme var mı? (önce bu)

**Hayır — ne video içinde ne k1→k2→k3 arasında birikme/sızıntı ya da ısınma izi yok.**

| Ölçü (dilim) | k1 | k2 | k3 |
|---|---|---|---|
| Klavye animasyonunda kare aralığı > 17,5 ms, 20 sn dilimler | 14 · 12 · 14 · 17 · 13 · 15 % | 11 · 10 · 16 · 16 · 16 · 17 % | 14 · 13 · 11 · 10 · 7 · 8 · 10 % |
| Klavye animasyonunda en uzun kare (ms), 20 sn dilimler | 33 · 27 · 26 · 40 · 33 · 26 | 33 · 33 · 33 · 26 · 27 · 26 | 33 · 34 · 43 · 50 · 58 · 25 · 33 |
| Gerçek donma (ekran güncellenirken > 40 ms boşluk), 30 sn dilimler | 2 · 3 · 2 · 2 · 0 | 3 · 0 · 1 · 0 | 0 · 4 · 4 · 0 · 1 · 0 |
| Kapanışta panelin klavyeden kopma oranı (bkz. §1), 30 sn dilimler | 18 · 16 · 14 · 13 % | 13 · 19 · 13 % | 18 · 22 · 22 · 23 · 5 % |

k3'te 60–100 sn arasında tek tük 50–58 ms kare var ama k3'ün sonu (100–150 sn) en temiz dilim. "Sonda daha çok oldu" algısını veri desteklemiyor; aynı tür olay her dilimde aynı dağılımda. Şikâyet edilen titreme her olayda yapısal (bkz. §1), birikmeyle ilgili değil. Tek istisna: kapanış zikzağının SIKLIĞI videolar arasında artıyor (≥ 40 px kapanış %43 → %72 → %83, ≥ 100 px 1 → 3 → 11; ayrıntı K3 bölümü) — zayıf ısınma/oturum işareti, cihazda doğrulanmalı.

## 1. Klavye açılış/kapanışında alt panel (asıl şikâyet)

Yöntem: her kare 305x1356 (yatay 1/4, dikey 1/2) gri; panel bandı (settled açık karede y 1470–1600) ve Gboard araç çubuğu bandı (1622–1700) şablon, her karede SAD ile aranır (`panel_kayit.py` kalıbı). Tam çözünürlükte 2 px kesinlik. Aralık = klavye üstü − panel altı (> 0: panel ile klavye arasında editör görünüyor, < 0: klavye paneli örtüyor). Panelin kapalı dinlenme yeri (y 2432, gezinme alanının üstü) hesap dışı.

### Sayılar (yalnız editörde, alt paneli görünen olaylar)

| | k1 aç | k1 kapa | k2 aç | k2 kapa | k3 aç | k3 kapa |
|---|---|---|---|---|---|---|
| olay | 33 | 28 | 28 | 25 | 75 | 70 |
| olay başına en büyük aralık, medyan (px) | 4 | 18 | 4 | 76 | 4 | 76 |
| aralık ≥ 40 px olan olay | 8 | 12 | 2 | 18 | 13 | 58 |
| aralık ≥ 100 px olan olay | 1 | 1 | 0 | 3 | 2 | 11 |
| takılma (klavye > 3 px kayarken panel < 1 px), olay başına ort / maks kare | 0,6 / 7 | 2,7 / 10 | 0,5 / 3 | 2,7 / 11 | 1,6 / 9 | 3,5 / 12 |
| geri sıçrama (panelin ters yöne > 2 px) | 0 | 3 olay | 0 | 2 olay | 0 | 3 olay |
| klavye oturduktan sonra son sıçrama | yok (son aralık 2–4 px, normal yerleşme) | – | yok | – | yok | – |

### Ne oluyor (karelere bakılarak)

- **Temiz açılış (çoğunluk, ör. k2 8,13 s, `kareler/k2_8.1_acilis_temiz.png`):** klavye ve panel ~17 ms aralıklarla birlikte geliyor, her karede aralık 2–4 px. Sorun yok.
- **Kapanışta zikzak (en sık, ör. k2 40,10 s, `kareler/k2_40.1_kapanis_zigzag.png`):** klavye **her 8,3 ms'de** (120 Hz) yeni yerde, panel **yalnız her ikinci karede** (60 Hz) güncelleniyor. Aralık kare kare 2 → 58 → 2 → 74 → 4 → 76 → 2 → 68 → **130** → 60 → 4 … px. Panel bir kare duruyor, sonra 120–140 px'lik adımla klavyeye yetişiyor; aradaki şeritte arkadaki madde satırları görünüyor. Kullanıcının "zıplaya zıplaya" dediği tam bu.
- **Kapanışta bir kare geride (ör. k2 9,80 s):** panel her karede güncelleniyor ama sürekli klavyenin 58–78 px üstünde (≈ bir 8 ms karesi geride) kalıyor, aralık klavye yavaşlayınca 4 px'e iniyor.
- **Açılışta panel önde (en kötü açılış, k1 17,54 s, `kareler/k1_17.5_acilis_panel_onde.png`):** panel klavyeden 128–140 px YUKARIDA gidiyor, arada editör içeriği görünüyor; yine 60/120 Hz ritmi (aralık 140 → 132 → 66 → 60 → 102 → 88 → 70 → 34 …), klavye yavaşladığı son 150 ms'de kapanıyor.
- Gövde (madde listesi) panelle birlikte kayıyor; ayrı bir gövde sıçraması görülmedi. Bitişte panel klavyeye 2–4 px ile oturuyor — **bitiş sıçraması yok**.

**En kötü 3 olay:** (1) k2 16,75 s kapanış — aralık 148 px, 6 takılma karesi; (2) k1 17,54 s açılış — panel 140 px önde, 5 takılma; (3) k2 40,10 s kapanış — 11 takılma karesi, aralık 130 px'e çıkan zikzak. k3'te daha kötüsü var: k3 61,43 s kapanış — 234 px (bkz. K3 bölümü).

### Kök neden ve kipler

- P55'teki "gezinme payı düşülmesi" (API < 35) burada YOK: API 36, panel bitişte doğru yere oturuyor.
- Davranış: klavye (IME, ayrı süreç) 120 Hz'de çiziliyor, uygulamanın paneli klavye konumunu her karede ya bir kare gecikmeli ya da her ikinci karede (60 Hz) yansıtıyor. Kapanışta panel her iki durumda da klavyenin gerisinde (yukarıda) kalıyor, açılışta bazen önde. Uygulama kareleri bu anlarda ağır değil (aynı anda klavye animasyonu kareleri 8–17 ms); sorun kare ritmi/gecikmesi, kasma değil.
- **Kip a (yalnız bitiş sıçraması düzeltmesi): gidermez** — ölçülen bitiş sıçraması zaten yok.
- **Kip b (yumuşatma): gidermez, büyük olasılıkla kötüleştirir** — yumuşatma gecikmeyi artırır; 60 Hz'de güncellenen bir değeri yumuşatmak 120 Hz klavyeyle aradaki boşluğu kapatmaz, sadece zikzağı sabit bir boşluğa çevirir.
- **Kip c (hareket boyunca gizleme): gideren tek kip** — ~0,25 s'lik animasyonda panel görünmezse zikzak/aralık görünmez; bitişte panel zaten doğru yerde (2–4 px).
- Kök düzeltme (ayrı iş): panelin konumunu Flutter karesine bağlı olmadan klavyeyle aynı karede güncellemek (yerel `WindowInsetsAnimation` ile pencere/yüzey kaydırma) ya da uygulamanın 120 Hz'de çizdiğinden emin olmak; panel 60 Hz kalırsa yalnız gizleme işe yarar.

## 2. Madde (yapılacaklar) notları ve düz metin

Videolardaki notların neredeyse hepsi madde notu (Dosya okuyucu, Bütçe, site, Not uygulaması geliştirme hataları, ezan vakti); düz metin bölümü yalnız k1 ~103–110 s (resimli "Belirsizlik ve Rezilyans" notu) ve k3 120–150 s (resimli dua notu). Klavye olayları zaten madde notlarında (§1).

Kare aralığı (yalnız ekranın arka arkaya değiştiği kesitler, "patlama" bölütleri):

| Kategori | olay | aralık sayısı | > 17,5 ms | > 25 ms | > 34 ms | > 50 ms | en uzun |
|---|---|---|---|---|---|---|---|
| Klavye olayı (madde notu) | 111 | 10189 | 14,0 % | 247 | 27 | 9 | 87 ms (k3 13,9 s, tuşa basma sırası) |
| Madde işlemi (dokunma/işaretleme/Enter, küçük değişim) | 4 | 45 | 6,7 % | 2 | 2 | 0 | 41 ms |
| Editörde kaydırma/geçiş | 11 | 447 | 15,4 % | 11 | 1 | 0 | 42 ms |
| Ana ekran kaydırma / not aç-kapa / sekme | 79 | 4703 | 14,6 % | 118 | 17 | 8 | 95 ms (k3 35,9 s) |
| Şablon akışı | 15 | 1349 | 18,2 % | 53 | 6 | 1 | 61 ms (+ açılışta 247 ms donma) |

- Madde işlemleri (yeni madde, işaretleme) seyrek ve ucuz göründü: en uzun 41 ms, > 34 ms yalnız 2 kare. Madde notunda kaydırma 15 % > 17,5 ms, en uzun 42 ms. Düz metin/resimli notta kaydırma (k3 110 s, k1 110–118 s) aynı dağılımda (8–21 %, en uzun 42 ms) — madde notu düz nottan belirgin kötü değil.
- Sınıflama kaba: panelin yerine bakarak editör sayıldı; panelin alt profili farklı olan notlar "ana ekran/geçiş"e düşmüş olabilir. Madde işlemi örnekleri az (4) — kullanıcının "normal madde notunda kasma" dediği his büyük olasılıkla §1'deki klavye zikzağı.

## 3. Kaydırma, geçiş ve şablon

- Kayıt 120/144 Hz'de kare alıyor (aralık tepeleri 7 ve 8,3 ms); hareket sırasında aralıkların ~%40'ı 16–17 ms (bir vsync kaçırma = 60 Hz'e düşme). > 25 ms yaklaşık %2–3.
- En uzun takılmalar (`kareler/en_uzun_takilmalar.png`, üst sıra önce, alt sıra sonra): k3 35,9 s 95 ms (klavye açıkken tuş basımı), k1 96,1 s 86 ms (ana ekran listesi kaydırma), k3 72,5 s 86 ms ve k2 52,7 s 85 ms (ana ekran sekme/filtre geçişi), k2 84,6 s 76 ms (madde notunda yazma). Not: değişken kare hızlı kayıtta "hiçbir şey değişmedi" ile "donma" ayırt edilemez; klavye animasyonu içinde (sürekli hareket) en uzun kare 25–58 ms.
- **Şablon:** k1 60,25 s'de "Alışveriş listesi" şablonuna dokunuşun ardından ekran **247 ms donuk** kalıp şablon düzenleyicisi tek karede beliriyor (önceki kareler 8–17 ms aralıkla gelirken). k2'de aynı geçiş 44 ms. Şablon düzenleyicide yazarken (k1 61–78 s) > 17,5 ms oranı %19, en uzun 61 ms — akışın en ağır yeri. `kareler/k1_sablon_59-62.png`, `k2_sablon_65-72.png`.

## K3 (kullanıcı "çok kasıyor" dediği kayıt)

- 150 sn'de 84 açılış + 82 kapanış (≥ 5 karelik); kullanıcı çoğunlukla Dosya okuyucu notunda klavyeyi art arda aç/kapa yapıyor, 26–29 s'de uygulamadan çıkıp dönüyor, 120–150 s resimli dua notu.
- **Kapanış zikzağı k3'te en sık:** aralığı ≥ 40 px olan kapanış k1 %43 (12/28) → k2 %72 (18/25) → **k3 %83 (58/70)**; ≥ 100 px k1 1 → k2 3 → **k3 11**; kapanış başına takılma karesi 2,7 → 2,7 → 3,5; kapanışın ilk karesinde panelin yerinde kalması %24 → %26 → %34. Video içinde artış yok (dilimler 18 · 22 · 22 · 23 %); k1'in bir kısmı başka notlarda olduğundan kıyas kısmen not farkı olabilir, ama aynı Dosya okuyucu notunda k2→k3 farkı var. Isınma/oturum etkisi için zayıf bir işaret — cihazda soğuk vs. 10 dk kullanım sonrası aynı notta `panel_kayit.py` ile doğrulanmalı.
- **En kötü olay, k3 61,43 s kapanış** (`kareler/k3_61.4_kapanis_en_kotu.png`): klavye 3 karede (≈ 25 ms) 250 px inerken panel yerinde kalıyor (aralık 42 → 164 → 234 px, arada madde satırları görünüyor), sonra panel 2 karede 570 px atlıyor; ardından 42 ms hiç kare yok (61,510 → 61,552) — burada uygulama karesi de geç kalmış (kapanışın başında ağır kare). Diğer k3 kötüleri: 34,38 s / 57,92 s / 8,18 s kapanışları 146–148 px.
- Açılışlar k3'te de temiz: medyan en büyük aralık 4 px, geri sıçrama 0, bitiş sıçraması yok; ≥ 40 px 13/75.
- Kare süreleri: klavye animasyonunda en uzun 58 ms (89,5 s açılış), 50 ms (61,0 s), 49 ms (88,6 s) — "çok kasıyor" anına en uygun aralık 58–90 s (klavye animasyonunda > 40 ms karelerin hepsi burada). Ana ekranda en uzun 95 ms (35,9 s) ve 86 ms (72,5 s sekme geçişi). Gerçek donma (> 40 ms) k3'te 9 kez, hiçbiri > 50 ms değil.

## Yöntem notları
- `ffprobe -show_entries frame=pts_time` → kare zamanları; her kare 305x678 gri, satır ortalaması profili + önceki kareyle fark.
- Klavye olayı: alt bölgede koyu (< 150) bandın tepesi kapalı ↔ settled (y≈1604) geçişi; ≥ 5 karelik geçişler.
- Panel/klavye kenarı: şablon SAD (yukarıda). Pencere: olay başı − 30 ms … bitiş + 350 ms (bir sonraki olaya taşmadan).
- Kısıt: VFR kayıtta boşta kare gelmez; boşlukları yalnız sürekli hareketin içinde (klavye animasyonu) güvenle donma sayabiliriz.
