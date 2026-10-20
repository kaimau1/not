# Geliştirme raporu — 2026-10-20

Kapsam: bu turda yapılanlar + kod tabanı ve ekran görüntüleri üzerinden
çıkan **düzeltme / sadeleştirme / ekleme** önerileri. Öneriler öncelik
sırasında; her biri "neden" ve "nasıl" ile. Karar senin — "şunu yap" demen
yeterli.

## A. Bu turda yapılanlar

| # | İstek | Ne yapıldı |
|---|---|---|
| 1 | Defter modunda yazılar çizgilerle üst üste | Çizgiler artık sabit ızgara değil, **her metin satırının altından** çiziliyor (`RuledLines`). Madde satırları defterde çizgi aralığının tam katı, kutucuk tek satırın bandına sığıyor; maddeler ardışık çizgilere yazılıyor. Sistem yazı ölçeği de hesaba giriyor (eskiden girmiyordu). Kenar çizgisi kutucukların/başlığın üstünden geçmiyor. |
| 2 | Satır aralarına çizgi / kesikli çizgi | (a) Yeni kâğıt: **Kesikli çizgili**. (b) Liste maddesine uzun bas → **Alta çizgi çek / Alta kesikli çizgi / Alta noktalı çizgi / Çizgiyi kaldır** (kartta da görünür, senkronlanır). |
| 3 | Defter modu dashboard'da da görünsün | Defter notunun kartı kendi kâğıdıyla çiziliyor (çizgili/kesikli/bloknotta çizgiler kart yazılarının altında; kareli/noktalı desen arkada). |
| 4 | Ek menüsü: "Dosya ekle" yeterli | Ekle levhası üç bölüm: **Not içeriği · Dosya ve bağlantı · Kamera ve kayıt**. PDF, Slayt, Ses dosyası, Galeriden video, Görseli ek olarak yükle ve Dosyayı metne dök **tek "Dosya ekle"de**: tür kendiliğinden tanınır; görselde "sayfaya / ek olarak", ses-videoda "ek olarak / metne dök" sorulur. 18 → 12 düğme. Boşa düşen "Belgeler" eklentisi Kişiselleştir'den kalktı. |
| 5 | Aramada notun klasörü yazsın | Arama sonucundaki kartta klasör rozeti (klasörün kendi ekranında gösterilmez). "Tümü" görünümünde de çıkar. |
| 6 | Klasörlerin başına "Tümü" | Şeridin (ve karo görünümünün) başında **Tümü** çipi: klasörde olan olmayan bütün notlar, arşiv hariç (gizli klasörler yine gizli). Tercih hatırlanır; tekrar dokununca eski görünüme döner. |
| 7 | Arşiv aramasına AI | Arşivde arama açıkken ✨ düğmesi: anlamca arama (ana ekranla aynı indeks/eşik). |
| 8 | Çöp kutusuna AI analiz | Çöp → 📊 **Akıllı analiz**: cihazda anında kurallar (boş not, aktif notta kopyası var, çöpte daha yeni kopyası var → *güvenle silinebilir*; ileri tarihli hatırlatıcı, şifre/IBAN/telefon, yapılmamış madde, ek, uzun metin → *geri yüklemeyi düşün*) + isteğe bağlı **AI ile derin analiz** (kısa döküm gider, kilitli notlar gitmez). Satır satır ya da toplu geri yükle / kalıcı sil (onaylı). |
| + | Benim eklediklerim | Uzun yapılacaklar kartında **ilerleme çubuğu** (`12/46`); klasör sırası levhasında "sürüklemek sırayı Elle'ye çevirir" açıklaması. |

## B. Önerilen düzeltmeler (öncelikli)

1. **Şifreler kartta açıkça görünüyor (gizlilik).** Ana ekran görüntüsünde
   "Şifreler" notunun içeriği (kullanıcı adı:parola) herkesin görebileceği
   kartta. Öneri: içerikte şifre/IBAN/kart kalıbı görülünce notun altında
   "Bu not hassas görünüyor — kilitle?" önerisi; ya da kilitsiz de olsa
   "kartta içeriği gizle" bayrağı. Çöp analizindeki kalıp hazır
   (`trash_analysis.dart`), yeniden kullanılır. *Küçük iş, yüksek değer.*
2. **Yüzen düğmeler kartları örtüyor.** Ana ekranda mikrofon + ✨ + "+"
   üç ayrı FAB, sağ alttaki kartın (ör. "Klinik asistan") yarısını
   kapatıyor. Öneri: ızgaranın altına FAB yüksekliği kadar pay; ✨ ve
   mikrofonu tek düğmede birleştirmek (dokun = yazdır, basılı tut = AI —
   zaten böyle) ve "+"ın yanında küçük ikincil düğme olarak durmak.
3. **Boş klasörler şeritte yer kaplıyor** ("Genel 0", "Borç 0"). Öneri:
   0 notlu klasörleri şeridin sonuna at ya da soluk çiz; "Not sayısına
   göre" sıralamada zaten sona düşüyorlar, diğer sıralamalarda düşmüyor.
4. **Arama yüzeyleri dört ayrı kopya** (ana ekran, klasör, arşiv, çöp —
   her biri kendi `TextField`'ı, sayaç metni, boş durum). AI anahtarı artık
   iki yerde. Öneri: ortak `NoteSearchField` + `SearchResultHeader`
   bileşeni; çöpe ve klasöre de AI araması tek satırla gelir.
5. **Defter: belge (PDF/slayt) notlarında** sayfa tuvali olmadığından
   çizgiler eski sabit ızgarada kaldı. Orada defter görünümü sunuluyorsa
   ya menüden kaldırılmalı ya sayfa notu bölmesine aynı yaklaşım
   uygulanmalı (cihazda kontrol edilmeli).

## C. Sadeleştirme

1. **Dev dosyalar**: `note_editor_screen.dart` 3,9 bin, `items_editor.dart`
   2,7 bin, `dashboard_screen.dart` 2,4 bin satır. Editör F9.3'te bölündü;
   aynısı `ItemsEditor` (satır kurulumu `_itemRow` ~450 satır tek yöntem) ve
   dashboard (klasör rafı, not dilimleri, üst çubuk ayrı dosyalar) için.
2. **Kullanılmayan metinler**: `addPdf`, `addSlide`, `moduleDocuments*`,
   `attachSectionVisual` vb. artık hiçbir yerde çizilmiyor — arb'den
   temizlenebilir (çeviri yükü azalır).
3. **Not kartı çizim yolu üç kopya** (metin+madde, liste, sıralı liste aynı
   satırı ayrı ayrı kuruyor). Tek `_CardItemRow` hem ayırıcıyı hem üstü
   çiziliyi tek yerde çözer.
4. **Kâğıt desenleri**: 8 desen var; kullanım ölçülürse (ör. milimetrik,
   izometrik) az kullanılanlar "Diğer" altına inebilir.

## D. Eklenebilecek özellikler

1. **Defter için satır aralığı seçeneği** (dar / normal / geniş): satır
   çizgisi artık yazıya bağlı olduğu için yalnız `height` çarpanı yeter.
2. **Gövde metninde ayırıcı çizgi**: madde listesinde var; düz metinde de
   tek başına `---` satırı çizgi olarak çizilebilir (düzenlenebilir alanda
   bindirme katmanıyla).
3. **Çöp için otomatik öneri bildirimi**: 30 gün dolmadan bir gün önce
   "geri yüklemeyi düşün" listesinde not varsa tek bildirim.
4. **"Tümü" görünümünde klasöre göre grupla**: kartlar klasör başlıkları
   altında (SABİT / BU HAFTA başlıkları gibi).
5. **Arşivde toplu AI özeti**: "Arşivimde neler var?" — çöpteki
   analizin arşiv karşılığı (kategori + eskimiş notlar).
6. **Liste kartında dokunarak işaretleme**: karttaki kutucuğa dokununca
   editörü açmadan madde işaretlensin (Keep'teki gibi).

## E. Cihazda bakılması gerekenler (bu tur)

- [ ] Defter (çizgili/kesikli/bloknot): uzun maddeler, büyük yazı ölçeği,
  başlık + etiket çipi + sayfa çubuğu olan not — yazı çizginin üstünde mi?
- [ ] Madde uzun bas → Alta çizgi çek (düz/kesikli/noktalı), kartta görünüyor mu?
- [ ] Ekle → Dosya ekle: görsel / ses / video için soru levhası; PDF ve
  sunum doğrudan.
- [ ] "Tümü" çipi; aramada klasör rozeti.
- [ ] Arşiv → ara → ✨; Çöp → 📊 Akıllı analiz → AI ile derin analiz.
