# Kontrol listem

Senin bakman ya da yapman gereken her şey, en önemlisi üstte. Bir maddeye baktığında kutuyu
işaretle (`[x]`) ya da bana "3. madde tamam / bozuk" de. Bozuksa: ekran görüntüsü ya da kısa
ekran kaydı alıp gönder, hangi notta olduğunu söyle. Yapamadığını silme, "denemedim" yaz.

(Her maddenin adım adım uzun hâli geliştirici belgelerindeki "cihaz turu" listesinde; gerekmedikçe
oraya bakman gerekmez. Son güncelleme: 14 Kasım 2026.)

## Telefonda bak

- [ ] **Alt panel klavye açılırken zıplıyor mu — üç kip karşılaştırması (oto/alt-panel-klavye, cihazda bakılmadı)**
  Nerede: üç ayrı ölçüm APK'sı (a = bugünkü gibi klavyeyi birebir izler, b = yumuşak izler, c = klavye hareket ederken gizlenip oturunca belirir); bir metin notunda gövdeye dokunup klavyeyi aç-kapa.
  Nasıl: her kipte 10 kez aç-kapa; hangisinde panel "zıplamadan" geliyor? `tool/perf/panel_kayit.py` sayıları da yanında.
  Doğruysa: seçtiğin kipi söyle — varsayılan o olur (şu an a).
  Yanlışsa: ekran kaydı gönder, hangi kipte olduğunu söyle.
- [ ] **Konfor kararları (oto/konfor, cihazda bakılmadı — 2026-11-15)**
  Nerede: tablette bir not açıkken sol kenar; küçük telefonda ⋮ → Ekranı düzenle; ana ekranda "+" → ayar simgesi (Düzenle).
  Nasıl: sol kenardan çekmeceyi yavaşça az çek (açılmamalı), biraz daha çek (açılmalı), kısa fiske (açılmalı); düzen şeridinin başlığı kesilmeden ("Düzenleme modu" ya da "Düzen") görünsün; "+" → Düzenle "+" panosunu açsın, bir öğeyi gizle/sırala, son görünen öğeyi gizlemeye çalış (uyarı çıkmalı), paneli yeniden aç.
  Doğruysa: çekmece kazara açılmıyor; panelde sıra/gizleme panodakiyle aynı. Yanlışsa: ekran görüntüsü gönder.
- [ ] **Anlamca arama açılışta yeniden gömmüyor (kalıcı önbellek, cihazda bakılmadı)**
  Nerede: ana ekran arama, anlamca arama açık (kendi Gemini anahtarı).
  Nasıl: bir arama yap, sonuç gelsin; uygulamayı tamamen kapatıp aç, aynı ya da başka bir arama yap. Büyük defterde ilk aramada sonuçlar birkaç dakika içinde tamamlanarak çoğalabilir.
  Doğruysa: ikinci açılışta sonuç hemen geliyor, düz metin aramasına düşmüyor; çıkış yapıp girince ilk arama yine biraz sürüyor (önbellek silindi).
  Yanlışsa: hangi adımda ne gördüğünü yaz.

- [ ] **Düzen modu ve "Sırala" (yeni görünüş, cihazda bakılmadı — P63 G5)**
  Nerede: bir notta ⋮ → Ekranı düzenle; üst şeritteki ⇅ (Sırala); Ayarlar → Kişiselleştir; not ⋮ → Menüyü düzenle.
  Nasıl: düzen modunu aç (şerit yukarıdan kayarak gelsin), alt çubukta 2–3 düğmeye dokun (gizli olan kesikli çerçeveli, şeritte sayı çıksın), Geri al / Bitti; ⇅ ile levhayı aç — notta "Alt çubuk", klavye açıkken "Hızlı satır" seçili gelsin; üstteki şeritte bir simgeyi basılı tutup sürükleyerek sırala, hızlı satırı yeniden sırala ve klavyeyi açıp satırın o sırada olduğuna bak; Ekle levhasının sırasını değiştir; sabit PDF'li notta düzen modunda çubuktaki düğmeleri gizle/göster; küçük telefonda şerit başlığının sığdığına bak.
  Doğruysa: titreme/zıplama yok, mod açılıp kapanırken not kaymıyor; sıra uygulama kapanıp açılınca korunuyor; varsayılan düzende hiçbir şey değişmemiş.
  Yanlışsa: ekran görüntüsü / kısa kayıt gönder.
- [ ] **Bildirimler, kalıcı şeritler, yana çekiş ve takvim mini ayı (yeni his, cihazda bakılmadı — P62 G3)**
  Nerede: ana ekran (ipucu, "Geri al", Yenilikler, bekleyen ek / zamanı gelen / yeni sürüm şeritleri), liste görünümünde satır çekişi, takvim → ajanda → başlıktaki ay düğmesi; tablette not açıkken soldan çekmece.
  Nasıl: bir notu sil → "Geri al" mikrofon / "+" ile çakışmasın; levha açıkken sil → bildirim levhanın üstünde; ana ekranda yana yavaş çek / fiskele / son klasörde çek; liste satırını sağa-sola çek (eşikte hafif titreşim); mini ayı parmakla kaydır, aç-kapa.
  Doğruysa: ipucu arama çubuğunun altında, bildirimler üst üste binmiyor; şerit belirirken liste titremiyor; çekiş bırakınca yumuşak yerine oturuyor; mini ay parmağı izliyor, açılırken liste aşağı kayıyor (zıplama yok); çekmece %22 çekişte açılıyor.
  Yanlışsa: ekran görüntüsü / kısa kayıt gönder.
- [ ] **Ses kartı açılışı + klavye kasması (oto/ses-karti-kasma, cihazda bakılmadı)**
  Nerede: liste notunda bir maddeye dokun (klavye açık) → alt çubuktan Dikte.
  Nasıl: kart tek karede tam açılsın (yarım/soluk ara hâl yok); klavye açıkken konuş-sus-konuş: alt çubuk ve kart yerinde kalsın; kart açıkken ve Bitir'den sonra klavyeyi aç-kapa — alt panel akıcı mı? Hâlâ zıplıyorsa ekran kaydı al (P55 `bar_track` kalıbı).

- [ ] **Kalem kapsülü sadeleşti (yazıldı, cihazda doğrulanmadı — 2026-11-15, dal oto/kalem-tepsisi)**
  Nerede: notta Kalem → kapsülü aç.
  Nasıl: kapsülde geri al, × ve ✓ YOK; kalemler kapsüle yayılmış mı (sola sıkışık değil); kalem seç, yaz, sağdaki klavye düğmesiyle yazıya dön — çizim duruyor mu; silgi düğmesi mürekkep yokken soluk, yazınca belirgin; silgiye basılı tut → "Çizimler temizlendi" → "Geri al" hepsini geri getiriyor mu; ⋯ → "Çizimleri temizle". Telefon küçük ekran, MatePad ve bölünmüş görünümde taşma yok.
  Doğruysa: seçim anında geçerli, veri kaybı yok. Yanlışsa: ekran görüntüsü gönder.
- [ ] **Kalem seti ve sesle yazma kartı (yeni görünüş, cihazda bakılmadı — P63 G4)**
  Nerede: bir notta alt çubuktan Kalem → hap / kapsül / renk paneli; çizim ekranı; PDF üstüne çizim; notta Dikte ve ✨ → sesli not.
  Nasıl: kapsülü aç-kapa, kalem değiştir (kalem yukarı kalkar), paneli aç (üstte gerçek çizgi önizlemesi, soldaki iğneyle sabitle), kalınlığı sürükle; tablette bölünmüş görünümde kapsül taşmasın. Dikte açıkken konuş / sus: dalga sesinle oynasın, susunca alttaki ince çizgi dolsun ve "Sessizlik — birazdan biter" yazsın; dikte açıkken tablette kaydır + yaz.
  Doğruysa: zıplama yok, panel açılırken sayfa oynamıyor, kalemle yazarken gecikme yok; dalga konuşunca yükselir, susunca alçalır; kart boyu sabit.
  Yanlışsa: ekran görüntüsü / kısa kayıt gönder.
- [ ] **Şablonlar ve madde çizgileri (yeni görünüş, cihazda bakılmadı)**
  Nerede: "+" → Şablondan; bir liste notunda madde → Biçim → Alt çizgi.
  Nasıl: şablon kartlarına, bir şablonun önizlemesine (alttaki Oluştur düğmesi) ve kendi şablonunu düzenlemeye bak; çizgi tepsisinde beş türü dene, ⚙ ile ayar levhasını aç; çizgisiz maddeye çizgi ekle.
  Doğruysa: kartlarda küçük sayfa çizimi, Oluştur hep görünür; tepsideki örnekler maddenin rengini taşır; çizgi soldan sağa bir kez çizilir; klavye açılırken takılma yok.
  Yanlışsa: ekran görüntüsü / kısa kayıt gönder.

- [ ] **1. Yedek gerçekten geri geliyor mu**
  Nerede: Ayarlar → Tam yedek.
  Nasıl: yedek al → başka bir hesapta ya da web'de geri yükle → bir kez daha geri yükle.
  Doğruysa: notlar, görseller, el yazıları, balonlar, klasörler, takvim etkinlikleri geliyor; ikinci yükleme hiçbir şeyi çoğaltmıyor.
  Yanlışsa: neyin gelmediğini yaz, ekran görüntüsü gönder.

- [ ] **2. Liste maddeleri kaybolmuyor mu**
  Nerede: herhangi bir liste notu.
  Nasıl: 3 maddeye yaz → notu kapat → aç. Birkaç gün boyunca arada tekrarla.
  Doğruysa: hiçbir madde "Boş madde"ye dönmüyor.
  Yanlışsa: hemen ne yaptığını adım adım yaz (bu hatanın kökü hâlâ bulunamadı).

- [ ] **3. Not açma-kapama, klavye ve alt panel akıcı mı**
  Nerede: ana ekran ve herhangi bir not.
  Nasıl: 20 kez nota gir-çık → bir notta klavyeyi aç-kapa → alt çizgili (noktalı/dalgalı) maddeye dokun.
  Doğruysa: takılma, titreme, alt panelde sıçrama yok; 20. açılış ilki kadar akıcı.
  Yanlışsa: hangi notta, hangi anda takıldığını söyle (ekran kaydı en iyisi).

- [ ] **4. Hatırlatıcı dakikasında çalıyor mu**
  Nerede: telefon ayarları → Uygulamalar → Notlar → "Alarmlar ve hatırlatıcılar"; sonra Notlar → Ayarlar → İzinler.
  Nasıl: bu izni kapat → Notlar'daki İzinler bölümünde "Alarmlar ve hatırlatıcılar" uyarısı çıkmalı → "Ayarları aç" ile izni geri aç → uyarı kaybolmalı. Sonra uygulamayı kapat, 10 dk sonraya hatırlatıcı kur, ekranı kapat.
  Doğruysa: hatırlatıcı dakikasında çalıyor, dokununca not açılıyor; kilitli notta yalnız "Kilitli not" yazıyor.
  Yanlışsa: kaç dakika geç çaldığını ya da hiç çalmadığını yaz.

- [ ] **5. Uzun notta yazma doğru yerde mi**
  Nerede: uzun (birkaç sayfalık) bir not.
  Nasıl: klavyenin önerileri ve sesle yazma ile yaz, uzak bir paragrafa dokun, Tümünü seç → Kopyala.
  Doğruysa: yazı imlecin olduğu yere gidiyor; kopyada her şey var.
  Yanlışsa: ekran kaydı gönder.

- [ ] **6. Kilitler**
  Nerede: Ayarlar → Uygulama kilidi; bir notta not kilidi.
  Nasıl: kilidi aç → uygulamayı arka plana al, 1 dk bekle, dön.
  Doğruysa: kilit soruluyor; son uygulamalar ekranında içerik görünmüyor.

- [ ] **7. Ana ekran düzeni ve hareketler**
  Nerede: ana ekran.
  Nasıl: karta basılı tut ve sürükle; çöpe sürükle; "Tümü" çipine dokun / basılı tut; aramada bir karta dokun; sağa kaydır.
  Doğruysa: kart parmağı izliyor, çöpe bırakınca "Geri al" çıkıyor; Tümü = bütün notlar, basılı tutunca klasörler; aramadan açılan not kelimeye kayıyor; sağa kaydırma takvimi açıyor.

- [ ] **8. Not ekranındaki çubuklar**
  Nerede: Ayarlar → Kişiselleştir → "Not ekranı · alt çubuk" ve "Hızlı menü"; notta ⋮ → Ekranı düzenle.
  Nasıl: bir düğmeyi gizle, birini taşı, sırayı değiştir → nota gir → "Varsayılana döndür".
  Doğruysa: değişiklik hemen ve kalıcı uygulanıyor; dar ekranda taşma yok; varsayılan eski düzeni geri getiriyor.
  Ayrıca bak (14 Kasım sürümü): not ekranının ÜST çubuğundaki 5 düğme artık Ayarlar'da ayrı "Üst çubuk" grubunda ve sırası notun içinden de değişiyor. Bilinen: "Alt çubuğu varsayılana döndür" üst sırayı sıfırlamıyor; yıldıza basınca küçük bir tepki yok. Bunlar sana dert mi, söyle.

- [ ] **9. Ek sayısı doğru mu**
  Nerede: zemin resmi olan, başka eki olmayan bir not.
  Nasıl: başka uygulamadan bir dosyayı Notlar'a paylaş → "Var olan nota" listesine bak; bir arşiv defterine zemin koy.
  Doğruysa: zemin resmi ek sayılmıyor (ataç işareti yok, defterde "0 dosya").

- [ ] **10. Ekler ve PDF**
  Nerede: bir nota 300 sayfalık PDF ekle ve sabitle.
  Nasıl: hızlıca kaydır, parmakla birkaç çizgi çiz, sayfa değiştir, notu kapat-aç; görsel ekle → sabit / yüzen / balonlu arasında geç, Paylaş'ı dene.
  Doğruysa: kasma ve kapanma yok, çizgiler doğru sayfada, kaldığın sayfadan açılıyor; paylaşılan dosyada çizim ve yazı var.

- [ ] **11. Çevrimdışı hâller**
  Nerede: uçak kipi açıkken ana ekran ve not.
  Nasıl: "Gelen" süzgecini seç; notta ✨ yapay zekâ levhasını aç; nota fotoğraf ekle; sonra uçak kipini kapat.
  Doğruysa: "Bağlantı yok" + Tekrar dene görünüyor (boş liste değil); fotoğraf "bağlantı gelince yüklenecek" diye bekliyor, bağlantı gelince yükleniyor.

- [ ] **12. Yazım düzeltme**
  Nerede: herhangi bir not.
  Nasıl: "bu kalen " ve "herşey " yaz; düzeltmeden hemen sonra geri sil tuşuna bas.
  Doğruysa: "Bu kalem", "Her şey" oluyor; geri sil eski kelimeyi getiriyor ve o notta bir daha düzeltmiyor.

- [ ] **13. Görünüm ve temalar**
  Nerede: Ayarlar → Görünüm; yazı boyutunu en büyüğe al.
  Nasıl: renkleri sırayla dene, koyu temaya geç; menüleri ve not ekranını aç.
  Doğruysa: yazılar okunuyor, kartlar zeminden ayrılıyor, hiçbir şey taşmıyor; açılışta beyaz parlama yok.

- [ ] **14. Takvim**
  Nerede: ana ekranda sağa kaydır → takvim.
  Nasıl: 10 dk sonraya etkinlik kur; tekrarlı bir etkinliğin yalnız birini sil; bir etkinliği basılı tutup başka güne sürükle.
  Doğruysa: bildirim zamanında geliyor, dokununca takvim açılıyor, "Geri al" çalışıyor.

- [ ] **42. Menüler ve sabit PDF'te hızlı satır (2026-11-14, yazıldı, cihazda doğrulanmadı)**
  Nerede: ana ekran ⋮; bir notun ⋮'i; sabit PDF'li not (ör. Rezilyans) ve onun ⋮ menüsü; görseli gizlenmiş YouTube notu.
  Nasıl: menüleri aç, üstteki tutamaktan aşağı çek; sabit PDF'li notta "Not al"a yaz; PDF ⋮ → PDF → "Tüm balonlar".
  Doğruysa: her menüde tutamak var ve aşağı çekince kapanıyor; ⚙ ve ✕ telefonun üst çubuğunun altında; ana ekran ⋮'te tek maddelik "Diğer" grubu yok (Arşiv "Uygulama"nın sonunda); "Not al"a yazarken üst çubukta hızlı satır çıkıyor, çubuktaki başlığı düzenlerken başlık yerinde kalıyor; balon listesi açılıyor, balona dokununca o sayfaya gidiyor; kartta "YouTube videosu" üstte, video adı altta.
- [ ] **43. Başka uygulamadan içe aktarma tam geliyor mu**
  Nerede: ölçüm uygulaması (`pm clear` sonrası, misafir) → Ayarlar → Senkronizasyon → "Başka uygulamadan içe aktar".
  Nasıl: `keep_olcum.zip` (240 not, 6 sabit) içe aktar, 3 dk bekle, aynı dosyayı bir daha içe aktar.
  Doğruysa: ana ekranda 240 not ve 6 sabit; ikinci deneme "0 not içe aktarıldı, 240 atlandı" der.

## Tablette bak

- [ ] **15. Kalemle yazma**
  Nerede: herhangi bir not, kalem kipi.
  Nasıl: avucunu ekrana dayayarak yaz; yan düğmeyle sil; kalemle kutucuğa/metne tek dokun.
  Doğruysa: avuç iz bırakmıyor, yazı basınçla kalınlaşıyor, kalem dokunuşu metne gidiyor.

- [ ] **16. Şekiller ve silgi**
  Nerede: kalem kipi.
  Nasıl: daire, kare, ok çiz → sağ alttaki düğme; silgide kıpırdamadan basılı tut → "Kaleme dön".
  Doğruysa: şekil düzgünleşiyor, geri al eskisini getiriyor; "Kaleme dön" son kalemi seçiyor ve silinen yazıyı geri getiriyor.

- [ ] **17. Sabit PDF'e yazma**
  Nerede: sabit PDF'li not.
  Nasıl: bölmedeki ✏'yi aç, yaz, silgiye bas, renk değiştir; yüzen kalem düğmesini aç-kapa.
  Doğruysa: yazılar yerinde kalıyor, ✏ ile yüzen düğme birbirini izliyor.

- [ ] **18. Tablet düzeni**
  Nerede: ana ekran ve not, yatay ve dikey.
  Nasıl: ayracı sürükle, sola zorla (tam ekran); tableti döndür; fiziksel klavyeyle Esc'e bas; nottan geri dön.
  Doğruysa: liste yerinde kalıyor, sütun sayısı değişiyor, yatayda sabit ek solda; geri dönüş kayarak/solarak, takılmadan.

- [ ] **19. Tablette sesle yazma**
  Nerede: notta mikrofon.
  Nasıl: mikrofona bas, konuş.
  Doğruysa: canlı tanıma yoksa birkaç saniye içinde açıklama + sesli not levhası açılıyor, ses yazıya dökülüyor.

- [ ] **41. Parmak siler (yeni araç)**
  Nerede: el yazısı notu ya da PDF, kalem tepsisi → ayarlar (⚙) → "Parmak: Siler".
  Nasıl: parmakla bir çizginin üstünden geç; sonra avucunu dayayarak kalemle yaz; iki parmakla yakınlaştır.
  Doğruysa: parmak siler, kalem yazar; avuç hiçbir şey silmez (silerse kalem değince geri gelir); yakınlaştırırken silinen geri gelir; "geri al" tek adımda geri getirir; yüzen kalem düğmesinin yanındaki hap "Parmak siliyor" der.
  Yanlışsa: avuç sildiyse ya da parmak ucu silmiyorsa söyle (eşik ayarlanacak).

- [ ] **20. Çok büyük PDF**
  Nerede: tablette ek menüsü.
  Nasıl: 500 MB–1 GB'lık bir PDF ekle, üstüne yaz, kapat-aç.
  Doğruysa: açılıyor (boyut engeli yok), "yalnız bu cihazda" yazıyor, yazdıkların yerinde.
  Yanlışsa: hangi mesajı gördüğünü yaz.

- [ ] **32. İki not yan yana** (yazıldı, tablette doğrulanmadı)
  Nerede: tablet YATAY, bir not açıkken soldaki listede başka bir kartın ⋮ menüsü → "Yanda aç".
  Nasıl: iki notta da yaz (klavye ve kalem); ortadaki ayracı sürükle, çift dokun; ☰ ile listeyi aç-kapa; tabletı dikeye çevir, geri yatay; tam ekrana gir-çık; yandakini ✕ ile kapat; iki not açıkken geri tuşuna bas; birinde dikte sürerken öbüründe mikrofona bas.
  Doğruysa: iki not yan yana, liste kendiliğinden çekilir; yazdığın bölme yazar, öbürü kıpırdamaz; ☰ açınca yandaki gizlenir, kapatınca döner; dikeyde yandaki kaybolur, yatayda geri gelir; geri tuşu ikisini de kapatıp listeye döner; ikinci mikrofon "Mikrofon yandaki notta kullanılıyor" der. Telefonda ve dikey tablette menüde "Yanda aç" YOK.
  Yanlışsa: hangi adımda ne olduğunu yaz.

## Bilgisayarda (web) bak

- [ ] **21. Web temel tur**
  Nerede: tarayıcıda uygulama.
  Nasıl: aç, giriş yap, not yaz → telefonda görünüyor mu; pencereyi daralt-genişlet; yedek kaydet/geri yükle.
  Doğruysa: not 20 sn içinde telefonda; liste ve açık not yerinde kalıyor.

- [ ] **22. Klavye ve fare**
  Nerede: web.
  Nasıl: Ctrl+/ ile kısayol penceresini aç, listedeki tuşları dene; Tab ile gez; Ctrl+tekerlek; madde metnini fareyle seç.
  Doğruysa: kısayollar çalışıyor, odak halkası görünüyor, Ctrl+tekerlek sayfayı değil sütunları büyütüyor; seçim yalnız açık yeşil.

- [ ] **23. Web'de ekler**
  Nerede: telefondan görsel eklenmiş bir not; web'de PDF ekleme.
  Nasıl: notu web'de aç; web'den büyük PDF ekle.
  Doğruysa: görsel görünüyor; PDF ekleniyor. Olmazsa ekranda çıkan hata metnini bana yaz.

## Konsol / hesap işleri

- [ ] **24. Yapay zekâ faturasına tavan koy**
  Nerede: Google Cloud konsolu → proje → Faturalandırma → Bütçe ve uyarılar; API'ler → Kotalar.
  Nasıl: aylık bütçe + %50/%90/%100 e-posta uyarısı kur; yapay zekâ API'lerinde dakika ve kullanıcı başı sınırı düşür.
  Doğruysa: bütçe listede görünüyor.

- [ ] **25. Sunucuda düzenli yedek**
  Nerede: Firebase konsolu → Firestore → Yedekler; Storage → nesne koruma.
  Nasıl: günlük ya da haftalık zamanlanmış yedek aç.
  Doğruysa: yedek planı listede.

- [ ] **26. Takvim ve Görevler bağlantısı**
  Nerede: Google Cloud konsolu → API'ler ve Hizmetler.
  Nasıl: Google Calendar API ve Google Tasks API'yi etkinleştir; OAuth onay ekranına takvim (salt okunur) ve görevler izinlerini ekle.
  Doğruysa: uygulamada Takvim → Google'a bağlan çalışıyor.

- [ ] **27. Masaüstü giriş kimliği**
  Nerede: Google Cloud konsolu → Kimlik bilgileri; GitHub → depo ayarları → Secrets.
  Nasıl: "Masaüstü uygulaması" türünde OAuth istemcisi oluştur, kimliği ve sırrı GitHub'a ekle (adı bende yazılı, sorarsan söylerim).
  Doğruysa: Google hizmetleri olmayan tablette girişte "Bağla" tekrar istenmiyor.

- [ ] **28. Çökme raporları**
  Nerede: Firebase konsolu → Crashlytics.
  Nasıl: etkinleştir → uygulamada Ayarlar → Hakkında → sürüm satırına uzun bas → "Çökert" → uygulamayı yeniden aç.
  Doğruysa: konsolda ilk rapor görünüyor.

- [ ] **29. Drive ve sunucu fonksiyonları**
  Nerede: Google Cloud → API'ler (Google Drive API); GitHub → Actions → deploy.
  Nasıl: Drive API'nin etkin olduğuna bak; son yayın işinde "Cloud Functions'ı yayınla" adımının yeşil olduğuna bak.
  Doğruysa: ikisi de açık/yeşil.

- [ ] **30. Eski sürüm kilidi**
  Nerede: Firebase konsolu → Firestore → config → app.
  Nasıl: telefon, tablet ve web en yeni sürümdeyken en düşük sürüm değerini güncelle (değeri sorarsan söylerim).
  Doğruysa: eski sürümler güncelleme ister. Bunu yeni el yazısı biçimi açılmadan yapma — 33. maddeye bak.

- [ ] **31. Uygulama doğrulaması (App Check)**
  Nerede: Firebase konsolu → App Check.
  Nasıl: web uygulamasını kaydet, birkaç gün izle. ZORLAMA: uygulamayı Play'den kurmadığın sürece telefonun da kilitlenir.
  Doğruysa: "doğrulanmış istek" oranı yüksek.

## Karar vermen gerekenler

- [ ] **33. Yeni el yazısı kayıt biçimi** — hızlı ve küçük kayıt için hazır ama YAZMA kapalı; açmak için önce telefonda ölçüm, sonra bütün cihazlar güncel olunca konsolda bayrak (30. madde). Şu an: kapalı (en güvenli). Açmak istersen "el yazısı v2'yi aç" de.
- [ ] **34. Kalem ucu tahmini ve parmağa ayrı araç** — Kalem ucu tahmini: 14 Kasım'da "yalnız parmak aracı olsun" dedin, tahmin YAZILMADI. Parmak aracı: YAZILDI (kalem ayarlarında ve Ayarlar → Kalem'de "Parmak: Kaydırır · Çizer · Siler"), tablette denenmedi → 41. madde. Siler'deyken tek parmak kaydırmaz (iki parmakla kaydır/yakınlaştır); istemezsen söyle.
- [ ] **35. Birden çok sabit ek** — seçenekler: sekme / yan yana / tek. Şu an: tek sabit ek. Değiştirmek istersen hangisini istediğini söyle.
- [ ] **36. Hatırlatıcı ipucu** — alarm izni kapalıyken Ayarlar'da uyarı var; ilk hatırlatıcıyı kurarken ayrıca ipucu çıksın mı? Şu an: çıkmıyor.
- [ ] **37. Ana ekranda tek elle arama** — yeni not düğmesi zaten sağ altta; arama kutusu üstte. Alta bir arama kısayolu ister misin? Şu an: yok.
- [ ] **38. Bulutta hız ölçümü** — her sürüm öncesi otomatik emülatör ölçümü kurulsun mu (yaklaşık 1 saat ve CI kotası)? Şu an: yok, ölçüm telefonda yapılıyor.
- [ ] **39. Sabit ek çubuğu yazı en büyükken** — en büyük yazı boyunda sabit PDF çubuğu taşarsa küçültelim mi, kaydıralım mı? Şu an: taşma görülürse sen söyleyince.
- [x] **40. Hız ölçümünün karşılaştırma tabanı yenilendi** (14 Kasım, P60) — sebep doğrulandı: ölçüm telefonundaki deneme notları yeniden kurulunca ilk kart PDF'li not olmuştu, ölçüm yanlış notu açıyordu (not açma/klavye/yazma/kapatma ~3 kat yavaş görünüyordu). Telefondaki ölçüm verisi sıfırdan kuruldu, ölçüm aracı artık deneme notlarını atlıyor; aynı sürüm iki kez ölçülüp taban buna göre yeniden alındı. Senin yapacağın bir şey yok. Not: içe aktarma ilk denemede 240 notun 67'sini sessizce atladı, ikinci içe aktarma tamamladı — ayrı iş olarak açıldı.
