# Notlar — Gizlilik Politikası

Son güncelleme: 26 Kasım 2026

Bu politika, "Notlar" uygulamasının (Android ve web) hangi
verileri işlediğini, neden işlediğini ve haklarınızı açıklar. Uygulamayı
kullanarak bu politikayı kabul etmiş olursunuz.

## Toplanan veriler

1. Hesap bilgileri — Google ile giriş yaptığınızda adınız, e-posta
   adresiniz ve profil fotoğrafınız kimlik doğrulama için kullanılır
   (Firebase Authentication). Google'sız "misafir" hesap seçerseniz
   anonim bir hesap açılır; bu hesap yalnız o cihaza bağlıdır, uygulama
   silinirse ya da oturum kapatılırsa notlarınıza bir daha erişilemez.

2. Not içerikleri — Notlarınız, listeleriniz, etiketleriniz,
   hatırlatıcılarınız ve ekleriniz (fotoğraf, PDF, ses kaydı, çizim, belge)
   cihazlar arası eşitleme için Google Firebase (Firestore ve Cloud
   Storage) veya etkinse Cloudflare (Workers, D1 ve ortak medya için R2)
   üzerinde hesabınıza bağlı olarak saklanır. Kilitlediğiniz notların gövdesi,
   kontrol listesi maddeleri, ek metin sayfaları ve PDF sayfa notları
   buluta gönderilmeden önce cihazınızda AES-256-GCM ile uçtan uca
   şifrelenir. Google hesabıyla giriş yapıp "Ekleri Google Drive'ında
   sakla" seçeneğini bağladığınızda kişisel ekleriniz KENDİ Google
   Drive'ınızda, uygulamaya özel gizli klasörde (`drive.appdata` izni —
   uygulama Drive'ınızdaki başka hiçbir dosyayı göremez) saklanır.
   "Yalnız bu cihazda" seçtiğiniz notlar ve videolar buluta yüklenmez.
   Misafir hesapta notlar ve ekler yalnız cihazda tutulur. Not içerikleri
   reklam amacıyla kullanılmaz.

3. Kişiler ve paylaşım — Uygulama bir kişiler (arkadaşlar) özelliği
   içerir:
   - Google hesabıyla giriş yaptığınızda adınız ve e-posta adresiniz bir
     kullanıcı dizinine yazılır; böylece başka kullanıcılar sizi adınızın
     ilk harfleriyle (en az 3 harf) ya da TAM e-posta adresinizle bulup
     arkadaşlık isteği gönderebilir. Dizin doğrudan okunamaz; arama
     sunucuda yapılır, misafir hesaplara kapalıdır, kişi başı dakikada 10
     arama ve arama başına en fazla 15 sonuçla sınırlıdır.
     Ayarlar → Kişiler → "Adımla bulunabilirim" anahtarını kapatırsanız
     arama kaydınız silinir; yalnız e-posta adresinizi bilen biri size
     istek gönderebilir.
   - Arkadaşlık isteğini kabul ettiğiniz kişilerle, siz seçtiğinizde not
     gönderebilir, ortak not ya da paylaşılan klasör açabilir ve klasör
     sohbetinde yazı/görsel paylaşabilirsiniz. Paylaştığınız içeriği o
     kişiler görür (ve rolüne göre düzenleyebilir); gönderdiğiniz bir notun
     kopyası alıcıda kalır.
   Bunların dışında verileriniz başka kullanıcılarla paylaşılmaz.

4. Akıllı kararlar ve cihaz içi işleme — Yazım denetimi v3, sözlü dikte
   düzenleme, belge/fiş tarama OCR ve market reyonu eşleştirme öncelikle
   cihaz içinde çevrimdışı çalışır. Tam Sürüm (veya +1.000 paket ya da
   kendi Gemini API anahtarınız) ile Akıllı Kararlar açıkken ve rıza
   verdiğinizde, yalnızca seçili görev için gereken kısa metin (ör. ürün
   adı, hızlı ekle hedef not başlıkları veya etiket önerisi bağlamı;
   kilitli notlar hariç) Google Gemini Decisions API'ye gönderilir:
   - Tam Sürüm ve ek paket kullanımlarında istek güvenli sunucu vekili
     üzerinden Google Gemini Decisions API'ye iletilir ve yalnız hak/kota
     doğrulaması için kullanım sayacı (çağrı ve girdi jetonu sayısı)
     tutulur.
   - Kendi Gemini API anahtarınızı girerseniz istek doğrudan Google
     Gemini Decisions API'ye gider; API anahtarınız yalnızca cihazınızdaki
     güvenli depoda tutulur ve sunucuya yazılmaz.
   Uygulama bu isteklerin içeriğini reklam veya model eğitimi için
   saklamaz. İstediğiniz an Ayarlar → Akıllı Kararlar'dan özelliği
   kapatabilir veya rızanızı geri çekebilirsiniz.

5. Barkod ürün bilgisi — Alışveriş listesinde ürün barkodu taradığınızda
   yalnızca okunan barkod numarası (EAN/UPC) ürün adını ve miktarını
   bulmak amacıyla herkese açık Open Food Facts API'ye gönderilir;
   hesap veya not bilginiz iletilmez.

6. Ses tanıma — Diktede konuşmanız cihazınızın ses tanıma hizmetiyle
   (Android'de genellikle Google) yazıya dökülür. "İnternetsiz tanıma"
   açıksa ve dil paketi yüklüyse ses cihazdan çıkmaz.

7. Konum (yalnız Play dışı sürümlerde konum hatırlatıcısı kullanılırsa) —
   Google Play sürümünde konum hatırlatıcısı ve arka plan konum erişimi
   bulunmaz; Play dışı kişisel kurulumda "yere varınca hatırlat"
   seçilirse seçilen koordinat cihazın geofence servisi tarafından yerel
   izlenir, konum geçmişi sunucuya gönderilmez.

8. Bildirimler — Not, takvim ve görev hatırlatıcıları cihazınızda yerel
   olarak planlanır; içerikleri sunucuya gönderilmez.

9. Satın alma bilgileri — Google Play üzerinden Tam Sürüm veya +1.000
   Akıllı Karar paketi aldığınızda hak doğrulaması ve iade iptali için
   satın alma belirteci (purchaseToken) sunucuda doğrulanır ve tek yönlü
   özeti (SHA-256) saklanır; kredi kartı veya ödeme bilginiz toplanmaz.

10. Çökme raporları ve hata günlüğü — Android'de uygulama çöktüğünde ya
    da beklenmeyen bir hata oluştuğunda teknik bir rapor (hata mesajı,
    kod satırları, cihaz modeli, Android ve uygulama sürümü) Firebase
    Crashlytics'e gönderilir. Rapor not içeriğinizi, adınızı ya da
    e-postanızı İÇERMEZ; hesabınızla eşleştirilmez. Ayarlar → Hesap ve
    tanılama altından kapatabilirsiniz. Küçük yerel hata günlüğü yalnız
    siz "Hata günlüğünü paylaş" dediğinizde ve seçtiğiniz yere gönderilir.

11. Gömülü içerik — Bir nota YouTube bağlantısı eklediğinizde video
    YouTube'un gömülü oynatıcısıyla açılır; bu sırada YouTube'un kendi
    politikası geçerlidir.

## Google hesabından istenen izinler

Her izin yalnız ilgili özelliği ilk kullandığınızda istenir; istemediğiniz
izni vermeden uygulamanın geri kalanını kullanabilirsiniz.

- Giriş (openid, e-posta, profil): hesabınızı tanımak ve notlarınızı
  eşitlemek için.
- Google Drive (drive.appdata, drive.file): yalnız uygulamanın kendi
  oluşturduğu dosyalar ve gizli uygulama klasörü; Drive'ınızdaki diğer
  dosyalara erişilmez.
- Google Takvim (calendar.readonly, calendar.events) ve Google Görevler
  (tasks): etkinliklerinizi ve görevlerinizi uygulamada göstermek, notlarla
  eşleştirmek ve yalnız sizin istediğiniz etkinlik/görevleri oluşturmak ya
  da güncellemek için.

Google API'lerinden alınan veriler Google API Hizmetleri Kullanıcı Verisi
Politikası'na (Sınırlı Kullanım şartları dahil) uygun kullanılır: yalnız
uygulamanın size sunduğu özellikler için, reklam için değil; üçüncü
kişilere satılmaz ya da aktarılmaz. İzinleri istediğiniz an
https://myaccount.google.com/permissions adresinden geri alabilirsiniz.

## Toplanmayan veriler

- Reklam kimliği, kişi listesi (rehber), konum geçmişi veya tarama
  geçmişi toplanmaz.
- Reklam ya da pazarlama analitiği SDK'sı kullanılmaz (yalnız yukarıdaki
  çökme raporu).
- Verileriniz üçüncü taraflara satılmaz veya pazarlama için paylaşılmaz.

## Veri saklama ve silme

- Verileriniz siz silene kadar bulut hesabınızda (ekleriniz Drive'ı
  bağladıysanız Google Drive'ınızda) saklanır. Drive'daki uygulama
  klasörünü Google Drive → Ayarlar → Uygulamaları yönet'ten de
  silebilirsiniz.
- Tek bir notu çöp kutusuna taşıyıp kalıcı silebilirsiniz.
- Ayarlar → Hesap → "Hesabımı ve verilerimi sil" ile hesabınızı ve TÜM
  verilerinizi uygulama içinden kalıcı olarak silebilirsiniz. Uygulama
  cihazınızda kurulu değilse aynı işlemi web sitemizdeki "Hesap ve veri
  silme" sayfasından (hesap-silme.html) giriş yaparak yapabilirsiniz;
  hesabınıza giremiyorsanız İletişim bölümündeki adrese yazın, talebiniz
  30 gün içinde sonuçlandırılır. Silinenler: notlar,
  klasörler, ekler (Storage/R2 ve bağlıysa Drive), kişiler ve istekler,
  gelen notlar, paylaştığınız klasörler (sohbet mesajları ve görselleri
  dahil), ortak not kayıtları, kullanıcı dizini ve arama kaydınız, hesap
  kaydı. Bu işlem geri alınamaz. Yalnız satın alma belirteci özeti ve
  karar kotası / hız sınırı sayaçları (kişisel içerik taşımayan, sayı +
  zaman) kötüye kullanımı önlemek ve satın alma haklarını korumak için
  saklanır.
- Başkasına gönderdiğiniz notların kopyaları ve başkalarının ortak
  klasörüne yazdığınız notlar o kişilerin verisi olduğundan sizin
  hesabınızla silinmez.
- Çökme raporları Firebase Crashlytics'te 90 gün tutulur.

## Veri güvenliği

Veriler aktarımda HTTPS / TLS ile şifrelenir. Kilitli notların gövdesi,
kontrol listesi maddeleri, ek metin sayfaları ve sayfa notları buluta
yazılmadan önce istemcide AES-256-GCM ile uçtan uca şifrelenir (E2EE):
parmak izi kilidinde anahtar cihazın güvenli deposunda (Keystore), şifre
veya desen kilidinde ise sırrınızdan türetilerek korunur (şifre
unutulursa eski şifreli içerik çözülemez). Erişim kuralları her
kullanıcının yalnızca kendi verisine ve kendisiyle paylaşılan içeriğe
erişmesine izin verir. API anahtarınız (girdiyseniz) Android Keystore ile
korunan güvenli depoda (web'de tarayıcının yerel deposunda) saklanır.

## Üçüncü taraf hizmetler

Uygulama şu hizmetleri kullanır: Firebase Authentication, Cloud
Firestore, Cloud Storage, Cloud Functions, Firebase App Check, Firebase
Crashlytics, Cloudflare Workers / D1 / R2 (senkron arka ucu etkinse),
Google Drive API (bağlarsanız), Google Takvim ve Görevler API (bağlarsanız),
Google Play Billing (Play satın alımları), Google Gemini Decisions API ve
Open Food Facts API (barkod ürün sorgusu). Google hizmetleri için Google'ın
gizlilik politikası geçerlidir: https://policies.google.com/privacy

## Çocukların gizliliği

Uygulama 13 yaş altı çocuklara yönelik değildir.

## İletişim

Sorularınız için: hekimasistanitr@gmail.com

Bu politika değiştiğinde güncel sürüm uygulama içinde ve bu dosyada
yayınlanır.
