# Hızlı ekle + Akıllı liste — beyin fırtınası ve oturum raporu (20 Kasım 2026)

Kaynaklar: 17K §4–5 (`docs/rapor_2026-11-17_senkron_lite_pro_yazim.md`), 16K §1.4/§3.3,
`PLAN.md` T4/T5 ve 1.4/3–4, `docs/hafiza/editor.md` (hızlı ekle bölümleri). Bulutta, cihazsız
oturum: aşağıdaki "yapıldı"ların hepsi **yazıldı, cihazda doğrulanmadı** (KONTROL "Telefonda bak").

## 1. Bu oturumda bulunan ve düzeltilen hatalar (kanıt → düzeltme → bekçi testi)

| # | Hata (kanıt) | Düzeltme | Bekçi |
|---|---|---|---|
| B1 | Alışverişin en doğal söyleyişi madde oluyordu: "süt al ekmek al" → Süt, **Al**, Ekmek, **Al**; "süt lazım", "deterjan kalmadı", yazılan "süt bitti" → **Lazım/Kalmadı/Bitti** maddesi | Alışveriş sözleri ayrıştırıcıda tek başına düşer (cümleli listede değil) | `quick_entry_test` |
| B2 | "süt x2", "2x süt", "ekmek ×3" → ayrı "X2" maddesi | Çarpı biçimli adet | `quick_entry_test` |
| B3 | Akıllı listenin kurduğu "Bavul listesi"ne hızlı ekleme cümleli kipe düşüyordu: "şort mayo şarj aleti" → TEK madde | Liste türü başlık + maddelerden; bavulda market + bavul sözlüğü | `quick_drop_list_kind_test` |
| B4 | Başlıktan alışveriş tanıma içerir-aramasıydı: "Pazartesi işleri" (paz**ar**), "Marketing planı" alışveriş sayılıyordu (kelimeler bölünür, "al" atılırdı) | Tür sözcüğü ya da ekli hâli (kök/ek listesi) | `quick_drop_list_kind_test` |
| B5 | Hızlı ekle: yapay zekâ "soruyorum…" derken yazılanlar, gelen yanıtla eziliyordu — yanıt ESKİ içerikle geri sayımı başlatıp onu ekliyordu | Yazınca karar kullanıcının; yanıt yok sayılır | `quick_list_screen_test` (eski kodda kırmızı) |
| B6 | "Hangi not olduğunu soruyorum…" satırı dar ekranda/büyük yazıda taşıyordu | Tek satır, üç nokta | aynı test |
| B7 | Hızlı ekle "Yeni not": klasör açıkken not klasörsüz düşüyordu; geri alınamıyordu | O anki klasöre doğar, bildirimde **Geri al** | `quick_list_screen_test` |
| H1 | Sesle "süt bitti" (= süt kalmadı) deyip devam eden kullanıcının listesi kapanıyordu | Yalın "bitti": önünde duraklama varsa hemen; yoksa ~1,4 sn konuşma gelmezse bitiş, gelirse içerik. "bu kadar / liste bitti" hep hemen | `quick_entry_done_word_test` (eski kodda kırmızı) |

## 2. Geliştirilenler

- **HE-2 önizleme satırı (ilk parça):** Ekle'ye basmadan "→ “Market listesi”: Domates, Süt";
  yazı notunda "→ “Fikirler” notunun sonuna", yeni notta "→ Yeni not", hepsi listedeyse "Hepsi
  zaten … notunda". Ayrıştırıcı önbellekte (her tuşta sözlük kurulmaz); S56 bütçesi aynı (yazma
  415 kurulum, çip 0).
- **AL-2 reyon yerleşimi (alansız ilk adım):** reyon sırasındaki alışveriş/bavul listesine hızlı
  eklenen madde sona değil kendi reyonuna girer ("elma" domatesin yanına, "kimlik" pasaportun
  yanına). Sırasız ya da başlıklı listede eskisi gibi sona. Nota yeni alan YOK.

## 3. Beyin fırtınası — Hızlı ekle

Değer (D) / emek (E) / risk (R): ●●● yüksek, ● düşük.

| Fikir | Ne | D | E | R | Not |
|---|---|---|---|---|---|
| HE-2 kalanı | Üç anahtar (AI/klavye/dinle) ⚙ arkasına; yapay zekâ beklerken 300 ms sonra "Ben seçeyim"; çiplerde arama (12 sınırı kalkar) | ●● | ● | ● | Levha sadeleşir |
| Önizlemede düzelt | Önizlemedeki maddeye dokun → "tek madde yap / ayır" (yanlış bölme/birleştirme tek dokunuş) | ●● | ●● | ● | Öğrenme hafızasına yazar |
| Art arda ekle | Levhada iğne: Ekle'den sonra kapanmaz, alan temizlenir (farklı notlara peş peşe) | ●● | ● | ● | Ofis/ders kullanımı |
| Tarihli madde (HE-4 adım 2) | "yarın 9'da dişçi" → hatırlatıcılı madde; ayrıştırıcı sesli komutta hazır | ●●● | ●● | ●● | Önizleme "⏰ yarın 09:00" gösterir |
| Tek cümlede çok hedef (HE-5) | "süt markete, fatura yapılacaklara" — ayırıcı hazır | ●● | ●● | ●● | Önizleme iki satır |
| Gelen kutusu notu | Uygun hedef yoksa sabit "Gelen kutusu"; haftada bir "boşalt" ipucu | ●● | ● | ● | H11'in kalıcı hâli |
| Panodakini ekle | Panoda kısa metin varsa (yalnız dokununca okunur) "Panodakini ekle" çipi | ● | ● | ●● | Android 13 pano bildirimi — yalnız dokunuşla |
| Sesle "geri al / dur" | Geri sayımda "dur", "hayır" → Bekle; "başka not" → sor | ●● | ● | ● | Elleri dolu kullanım |
| Uygulamayı açmadan (HE-3) | Başlatıcı kısayolu → 1×1/4×1 araç → hızlı ayar karosu → paylaşımda "Nota ekle" → metin seçim menüsü → `notlar://ekle` | ●●● | ●● | ● | Asıl değer; hepsi aynı levhaya |
| Saate göre hedef (HE-5) | Sabah "Yapılacaklar", akşam "Market" öne (cihazda sayaç) | ● | ●● | ● | Ölçmeden yapma |
| Eklendi vurgusu | Levha kapanınca hedef kart ana ekranda kısa parlar | ● | ● | ● | Yalnız boyama (kasma kuralı) |

## 4. Beyin fırtınası — Akıllı liste

| Fikir | Ne | D | E | R | Not |
|---|---|---|---|---|---|
| AL-2 "Alışverişi bitir" | İşaretlileri kaldır + sıklık hafızasını güncelle, kalanlar dursun | ●●● | ● | ● | Haftalık market döngüsünü kapatır |
| AL-2 reyon görünümü | "Reyona göre grupla": başlıklar çizimde türetilir, nota yazılmaz | ●● | ●● | ●● | Editöre görünür kip → kasma listesi + A/B |
| Miktar toplama | "2 süt" + "1 süt" → "3 süt" (bugün yeni miktar ESKİSİNİN YERİNE geçer) | ● | ● | ●● | **Karar:** topla mı değiştir mi? |
| Tahmin çipi (AL-4c) | "her hafta süt alıyorsun, 9 gündür yok" — cihazda, sıklık hafızası + tarih | ●●● | ●● | ● | Yapay zekâsız, ücretsiz katmanda |
| Fişten işaretle (AL-6) | Fiş fotoğrafı → cihaz içi OCR → listedeki eşleşenler işaretlenir | ●● | ●● | ●● | OCR hazır |
| Mağaza kipi (AL-5) | Büyük yazı, ekran açık, tek el, işaretlenen alta iner | ●● | ●● | ● | Telefonda A/B |
| Düzeltmeden öğren (AL-4a) | Maddeyi başka reyona taşıyınca kişisel eşleme (cihazlar arası) | ●● | ●● | ●● | Senkron alanı gerekir |
| Yeni türler (AL-3) | Eczane, kırtasiye/okul, bebek çantası, kamp, taşınma, hırdavat — sözlük + öneri seti | ●● | ● | ● | Kod büyümez, sözlük işi |
| Sözlük dışı madde → bir kez AI (AL-4b) | Sonuç sonsuza dek cihazda; çevrimdışıysa "diğer" | ● | ●● | ● | Pro |
| Ortak liste bildirimi (AL-5) | "Ayşe sütü aldı" (FCM/Functions hazır) | ●● | ●● | ●● | Pro adayı |
| Liste aracı | Ana ekranda market listesi, dokununca işaretle | ●● | ●● | ● | HE-3 araç altyapısıyla ortak |
| "Bu listeyi şablon yap" (AL-6) | Haftalık market, spor çantası | ● | ● | ● | |

## 5. Önerilen sıra (bir faz = bir oturum, `[apk]` başına ≤ 5 görünür değişiklik)

1. **Bu oturumun cihaz turu** (KONTROL): özellikle H1 eşikleri (~0,7 sn / ~1,4 sn) tanıyıcının
   gerçek ara sonuç sıklığıyla doğrulanmalı; gerekirse sayılar oynatılır.
2. HE-2 kalanı + "Art arda ekle" + "Alışverişi bitir" (küçük, telefonsuz yazılır).
3. HE-3 (uygulamayı açmadan ekle) — en büyük değer.
4. HE-4 tarihli madde → tek giriş.
5. Tahmin çipi + yeni türler (AL-3/AL-4c).

**Durum (2026-11-20 akşam):** kararlar `PLAN.md` 1.0b'ye yazıldı; 2. adımdaki 5'li paket aynı gün
yazıldı (cihazda doğrulanmadı, `docs/hafiza/editor.md` "2026-11-20 (2)").

## 6. Sabah bakılacak (karar gerektirenler — 2026-11-20 akşam KARAR, bkz. PLAN 1.0b)

1. Miktar toplama: "2 süt" varken "1 süt" eklenince 3 mü olsun, 1 mi (bugün 1)?
2. `listKind` alanı: reyon yerleşimi alansız çalışıyor; reyon görünümü ve sonradan editörde
   eklenen maddenin reyona düşmesi için gerekir mi? (HAFIZA kural 5: üç karşılaştırmaya eklenir.)
3. "Gelen kutusu" sabit notu istenir mi?
