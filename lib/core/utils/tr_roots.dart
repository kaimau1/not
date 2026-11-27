/// **YERLEŞİK TÜRKÇE KÖK SÖZLÜĞÜ** (yazım v3 Y-1, 2026-11-20). Elle derlendi
/// (telif yok): notlarda sık geçen ad/sıfat/zarf kökleri ve fiil kökleri.
/// Ek çözücü ([TrMorph]) kelimeyi kök + ek zinciri olarak dener; kök buradan,
/// yerleşik sık kelimelerden (`kCommonTurkish`) ya da kişisel sözlükten gelir.
///
/// ponytail: açık lisanslı büyük kök listesi (ör. Zemberek) EKLENMEDİ — APK
/// boyu ve lisans sayfası kararı sabah bakılacak (17K §3.3 "büyük hazır
/// sözlük ekleme"). Eksik kök = kelime "bilinmez" = yalnız eski davranış.
library;

Set<String> _words(String s) => {
  for (final w in s.split(RegExp(r'\s+')))
    if (w.isNotEmpty) w,
};

/// Ad, sıfat, zarf, adıl, sayı, bağlaç kökleri (küçük harf).
final Set<String> kTrNounRoots = _words('''
ev oda kapı pencere duvar masa sandalye koltuk kanepe yatak dolap raf halı
perde lamba ayna mutfak banyo tuvalet salon balkon bahçe çatı merdiven asansör
kat daire apartman bina site sokak cadde mahalle semt şehir köy ülke dünya
deniz göl nehir dağ orman ağaç çiçek çimen toprak taş kum su hava güneş ay
yıldız bulut yağmur kar rüzgar fırtına sıcak soğuk ılık serin ışık gölge
zaman saat dakika saniye gün hafta yıl sabah öğle öğlen akşam gece dün bugün
yarın şimdi önce sonra erken geç tatil bayram doğum yaş takvim tarih randevu
toplantı etkinlik davet düğün nişan parti kutlama hediye sürpriz
pazartesi salı çarşamba perşembe cuma cumartesi pazar ocak şubat mart nisan
mayıs haziran temmuz ağustos eylül ekim kasım aralık mevsim ilkbahar yaz
sonbahar kış
insan kişi adam kadın erkek kız oğul çocuk bebek anne baba kardeş abla abi
ağabey dede nine anneanne babaanne teyze hala amca dayı yenge kuzen eş koca
aile akraba arkadaş komşu misafir sevgili nişanlı halk millet
iş ofis şirket firma patron müdür şef çalışan personel ekip takım müşteri
tedarikçi proje görev rapor sunum belge dosya evrak form dilekçe sözleşme
fatura makbuz fiş hesap banka kart kredi borç faiz maaş ücret prim vergi
ödeme para lira dolar euro kuruş fiyat indirim kampanya sipariş kargo paket
teslimat iade bütçe gelir gider masraf harcama birikim yatırım
okul sınıf ders öğretmen öğrenci hoca sınav ödev not karne üniversite
fakülte bölüm kurs eğitim kitap defter kalem silgi çanta tahta kâğıt kağıt
hastane doktor hemşire hasta ilaç reçete eczane muayene tahlil kontrol
ameliyat ağrı ateş grip öksürük nezle tansiyon şeker kalp mide baş diş göz
kulak burun ağız el kol bacak ayak parmak sırt bel boyun omuz yüz saç cilt
vücut sağlık akıl beyin gönül ruh nefes
yemek kahvaltı öğün çorba salata pilav makarna ekmek peynir zeytin yumurta
bal reçel tereyağı yağ tuz un süt yoğurt ayran çay kahve meyve sebze et
tavuk balık köfte kebap döner börek pasta kek kurabiye tatlı dondurma
çikolata bisküvi cips kola elma armut muz portakal mandalina limon üzüm
çilek kiraz karpuz kavun şeftali erik incir nar domates salatalık biber
patlıcan patates soğan sarımsak havuç ıspanak marul lahana fasulye nohut
mercimek pirinç bulgur sos ketçap mayonez hardal baharat nane maydanoz
tarif sofra tabak bardak fincan kaşık çatal bıçak tencere tava fırın ocak
market bakkal manav kasap pastane lokanta restoran kafe büfe mağaza dükkan
çarşı alışveriş liste sepet poşet torba kutu şişe kavanoz
araba otobüs minibüs taksi tren metro tramvay vapur uçak bisiklet motor yol
trafik durak istasyon havalimanı liman bilet yolcu seyahat otel pansiyon
valiz bavul pasaport vize harita adres konum yön
telefon bilgisayar tablet ekran klavye fare yazıcı internet şarj pil kablo
uygulama program yazılım sayfa şifre kullanıcı mesaj mail posta bildirim
ayar klasör resim fotoğraf video ses müzik şarkı film dizi oyun kanal haber
hesap profil
madde başlık metin yazı kelime cümle paragraf satır harf rakam sayı numara
soru cevap konu durum sonuç neden sebep amaç hedef karar seçim fikir öneri
istek dilek ihtiyaç plan alarm süre an kez defa sefer kere sorun çözüm
sorumluluk işlem adım aşama süreç yöntem tarz şekil biçim tür çeşit model
marka güvenlik sigorta kira aidat elektrik doğalgaz abonelik hizmet destek
kıyafet elbise gömlek pantolon etek ceket mont kazak tişört ayakkabı çorap
şapka eldiven atkı gözlük yüzük kolye cüzdan anahtar şemsiye eşya
temizlik çamaşır bulaşık makine deterjan sabun şampuan havlu süpürge çöp
rezervasyon vitamin spor yürüyüş koşu egzersiz uyku hayat yaşam dinlenme
devam dikkat önem gerek lazım hız güç enerji ilgi sevgi saygı umut korku
merak sabır huzur mutluluk keyif şans başarı hata yanlış doğru eksik fazla
iyi kötü güzel çirkin büyük küçük uzun kısa yeni eski genç yaşlı hızlı yavaş
kolay zor ağır hafif temiz kir dolu boş açık kapalı önemli gerekli hazır az
çok tam yarım bütün tüm her hiç bazı başka diğer aynı farklı benzer özel
genel ana ilk son orta yakın uzak sağ sol üst alt ön arka iç dış yan
kırmızı mavi yeşil sarı siyah beyaz mor turuncu pembe gri kahverengi lacivert
renk mutlu üzgün yorgun aç tok kızgın sakin rahat meşgul müsait
var yok değil tamam
ben sen o biz siz onlar kendi bu şu bun şun on bura şura ora nere ne kim
kimse hangi kaç nasıl neden niye niçin hep herkes biri birbiri hiçbir hiçbiri
bir iki üç dört beş altı yedi sekiz dokuz yirmi otuz kırk elli altmış yetmiş
seksen doksan yüz bin milyon milyar
karşı yalnız birkaç birçok ahmet alan alış bakım bazen biraz birlikte dolayı
geri güncel iptal şey tablo yazım yer yorum yukarı aşağı ileri ara
bugünkü yarınki dünkü önceki sonraki şimdiki akşamki sabahki geceki geçenki
öbürkü özür teşekkür değer fark sıra kural ölçü örnek parça taraf
tabi dem merkez bilgi haber yardım kayıt dert güç isim ad hak hepsi soyad
ihtimal hal hayal kabul rol alkol seyahat
ek uç kip veri sabit odak palet desen hiza koyu acil gerçek şablon sütun kısım
aynen elektronik kullanım
web mod avatar gmail öğe bkz internet wifi pdf email eposta blog online
bluetooth widget selfie story youtube instagram whatsapp telegram google
android iphone ios windows excel word powerpoint zoom router url qr link
ibuprofen yoğunbakım hemogram trigliserit tiroid kolonoskopi ekg eeg emar
folik omega antidepresan antikoagülan metformin gluten vegan smoothie avm
metrobüs marmaray hostel bitcoin kdv iban eft
''');

/// Ek almayan kapalı sınıf (bağlaç, edat, ünlem, soru eki): YALNIZ yazıldığı
/// gibi bilinir — kök sayılsa "yinede", "hemde", "iyiki" de bilinirdi.
final Set<String> kTrClosed = _words('''
ve veya ya ile ama fakat ancak çünkü ki gibi için kadar göre rağmen beri dek
ait dair artık daha en pek gayet oldukça epey bile sadece hemen yine gene
henüz hâlâ zaten sanki keşke acaba hani işte yani mesela örneğin aslında
galiba herhalde maalesef lütfen hem de da mi mı mu mü diye evet hayır peki
belki ise hatta yoksa tabii merhaba selam günaydın teşekkürler hoşça
neyin
''');

/// Tek heceli olduğu hâlde ünlüyle başlayan ek alınca yumuşayan ad kökleri
/// ("renk-i" → "rengi", "kap-ı" → "kabı"); öteki tek heceliler yumuşamaz
/// ("iç-i", "et-i").
final Set<String> kTrSoftMono = _words('''
kap dip taç uç yurt kurt dert renk kalp tat
''');

/// Ünlüyle başlayan ek alınca son ünsüzü ikizleşen kökler ("hak-kı").
final Set<String> kTrDoubling = _words('''
hak his af zan sır tıp hat şık zam hac had üs ret
''');

/// Fiil kökleri (mastar eki olmadan, küçük harf).
final Set<String> kTrVerbRoots = _words('''
gel git yap al ver bak oku yaz çalış kal ol et de ye iç gör bil iste başla
bit bekle ara sor söyle düşün anla sev koş otur kalk yat uyu uyan çık gir dön
getir götür unut hatırla öğren öğret kullan aç kapa kapat sil ekle kaydet
gönder yolla öde sat koy tut bul kaybet izle dinle konuş yürü bin in çiz boya
pişir yıka temizle topla hazırla düzenle planla değiş seç tanı tanış anlat
göster dene giy çıkar taşı bırak at çek it bas dokun kes kır kop yık hallet
bitir geç sür kur say dur kazan harca biriktir kirala uç ağla gül sevin kız
üzül kork yorul dinlen acık acı özle ısın soğu doldur boşalt yükle indir aktar
paylaş incele araştır onayla ertele bildir yanıtla cevapla açıkla sun karşıla
evlen doğ öl yaşa büyü art azal düş bağla çöz duy hisset sus bağır çağır
gerek yet uy uygula ayarla sırala sakla gizle kilitle sabitle imzala tamamla
ilet ulaş eriş katıl buluş görüş oyna seyret ör tak soy ütüle katla as süpür
düzelt onar yenile güncelle kaldır kopyala yapıştır işaretle başlat durdur
kapan anımsa san inan güven beğen bulun yetiş koru yönet ilerle yerleş taşın
sonlan geliş gülümse anlaş hazırlan iyileş
sön yayıl dolan çakış tara aş kısal taş hizala
tasarla geliştir iyileştir denetle sınıflandır
''');

/// Arapça/Fransızca kökenli, son ünlüsü kalın olduğu hâlde İNCE ek alan kökler
/// ("saat-i", "kontrol-ü", "dikkat-li", "kalb-i").
final Set<String> kTrFrontLoans = _words('''
saat kontrol dikkat hal hayal ihtimal kabul rol gol alkol petrol sembol
protokol meşgul usul seyahat hakikat cemaat itaat kanaat sadakat ziraat idrak
istikbal istiklal festival normal final sinyal moral global emsal misal helal
kalp kalb harf hakikat sual etap
''');
