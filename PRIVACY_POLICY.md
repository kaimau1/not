# Notlar — Gizlilik Politikası

Son güncelleme: 19 Ekim 2026

Bu politika, "Notlar" uygulamasının (Android, Windows ve web) hangi
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
   Storage) üzerinde, hesabınıza bağlı olarak saklanır. Google hesabıyla
   giriş yapıp "Ekleri Google Drive'ında sakla" seçeneğini bağladığınızda
   ekleriniz bunun yerine KENDİ Google Drive'ınızda, uygulamaya özel gizli
   klasörde (drive.appdata izni — uygulama Drive'ınızdaki başka hiçbir
   dosyayı göremez) saklanır. "Yalnız bu cihazda" seçtiğiniz notlar ve
   videolar buluta yüklenmez. Misafir hesapta ekler buluta yüklenmez.
   Not içerikleri reklam amacıyla kullanılmaz.

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

4. Yapay zeka işlemleri — Özetleme, sesli not düzenleme, OCR, çeviri,
   sohbet, PDF sohbeti, semantik arama, günlük brifing gibi AI
   özelliklerini kullandığınızda ilgili not metni, ses kaydı, görsel veya
   belge işlenmek üzere bir yapay zeka sağlayıcısına gönderilir:
   - Varsayılan olarak Google Gemini (Firebase AI Logic üzerinden).
   - Kendi API anahtarınızı girerseniz, seçtiğiniz sağlayıcıya: Google
     Gemini, OpenAI, Anthropic ya da OpenRouter (OpenRouter isteği
     seçtiğiniz modelin sağlayıcısına iletir). Bu durumda o sağlayıcının
     gizlilik politikası geçerlidir.
   İçerik yalnızca isteğinizi yerine getirmek için gönderilir; uygulama
   bu içerikleri ayrıca bir sunucuya kaydetmez (sonucu notunuza siz
   eklerseniz notla birlikte saklanır). API anahtarınız yalnızca
   cihazınızdaki güvenli depoda tutulur ve hiçbir sunucuya yazılmaz.
   Dahili AI kullanımında günlük kota için hesabınıza bağlı bir sayaç
   (yalnız sayı ve zaman) tutulur.

5. Ses tanıma — Sesli notta konuşmanız cihazınızın ses tanıma hizmetiyle
   (Android'de genellikle Google) yazıya dökülür. "İnternetsiz tanıma"
   açıksa ve dil paketi yüklüyse ses cihazdan çıkmaz.

6. Konum (yalnız konum hatırlatıcısı kullanırsanız) — Bir nota "şu yere
   varınca/ayrılınca hatırlat" eklediğinizde seçtiğiniz yerin koordinatı
   notla birlikte saklanır. Konumunuzu uygulama değil, Android'in
   geofence hizmeti cihazda izler; uygulama kapalıyken de tetiklenmesi için
   "her zaman" konum izni istenir. Konum geçmişiniz toplanmaz, sunucuya
   gönderilmez. Konum hatırlatıcısı kullanmıyorsanız konum izni
   gerekmez.

7. Bildirimler — Hatırlatıcı ve günlük brifing bildirimleri cihazınızda
   yerel olarak planlanır; bildirim içerikleri sunucuya gönderilmez.

8. Çökme raporları ve hata günlüğü — Android'de uygulama çöktüğünde ya
   da beklenmeyen bir hata oluştuğunda teknik bir rapor (hata mesajı,
   kod satırları, cihaz modeli, Android ve uygulama sürümü) Firebase
   Crashlytics'e gönderilir. Rapor not içeriğinizi, adınızı ya da
   e-postanızı İÇERMEZ; hesabınızla eşleştirilmez. Ayarlar → Hakkında →
   "Çökme raporlarını gönder" ile kapatabilirsiniz. Ayrıca son hatalar
   cihazınızda küçük bir günlükte tutulur; bu günlük yalnız siz
   "Hata günlüğünü paylaş" dediğinizde ve seçtiğiniz yere gönderilir.

9. Gömülü içerik — Bir nota YouTube bağlantısı eklediğinizde video
   YouTube'un gömülü oynatıcısıyla açılır; bu sırada YouTube'un kendi
   politikası geçerlidir.

## Toplanmayan veriler

- Reklam kimliği, kişi listesi (rehber), konum geçmişi veya tarama
  geçmişi toplanmaz.
- Reklam ya da pazarlama analitiği SDK'sı kullanılmaz (yalnız yukarıdaki
  çökme raporu).
- Verileriniz üçüncü taraflara satılmaz veya pazarlama için paylaşılmaz.

## Veri saklama ve silme

- Verileriniz siz silene kadar Firebase'de (ekleriniz Drive'ı
  bağladıysanız Google Drive'ınızda) saklanır. Drive'daki uygulama
  klasörünü Google Drive → Ayarlar → Uygulamaları yönet'ten de
  silebilirsiniz.
- Tek bir notu çöp kutusuna taşıyıp kalıcı silebilirsiniz.
- Ayarlar → "Hesabımı ve verilerimi sil" ile hesabınızı ve TÜM
  verilerinizi uygulama içinden kalıcı olarak silebilirsiniz: notlar,
  klasörler, ekler (Storage ve bağlıysa Drive), kişiler ve istekler,
  gelen notlar, paylaştığınız klasörler (sohbet mesajları ve görselleri
  dahil), ortak not kayıtları, kullanıcı dizini ve arama kaydınız, hesap
  kaydı. Bu işlem geri alınamaz. Yalnız AI kota ve arama hız sınırı
  sayaçları (kişisel içerik taşımayan, sayı + zaman) kötüye kullanımı
  önlemek için silinmez.
- Başkasına gönderdiğiniz notların kopyaları ve başkalarının ortak
  klasörüne yazdığınız notlar o kişilerin verisi olduğundan sizin
  hesabınızla silinmez.
- Çökme raporları Firebase Crashlytics'te 90 gün tutulur.

## Veri güvenliği

Veriler aktarımda TLS ile şifrelenir. Firebase erişim kuralları her
kullanıcının yalnızca kendi verisine ve kendisiyle paylaşılan içeriğe
erişmesine izin verir. Notlar sunucuda Google'ın standart disk
şifrelemesiyle saklanır; uygulamaya özel uçtan uca şifreleme YOKTUR —
"not kilidi" yalnız cihazda açılışı parmak izi/yüz/ekran kilidiyle
korur, içeriği şifrelemez. API anahtarınız (girdiyseniz) Android
Keystore / Windows DPAPI ile korunan güvenli depoda saklanır.

## Üçüncü taraf hizmetler

Uygulama şu hizmetleri kullanır: Firebase Authentication, Cloud
Firestore, Cloud Storage, Cloud Functions (kişi araması), Firebase App
Check, Firebase AI Logic, Firebase Crashlytics, Google Drive API
(bağlarsanız), Gemini API ve — kendi anahtarınızla seçerseniz — OpenAI,
Anthropic, OpenRouter. Google hizmetleri için Google'ın gizlilik
politikası geçerlidir: https://policies.google.com/privacy

## Çocukların gizliliği

Uygulama 13 yaş altı çocuklara yönelik değildir.

## İletişim

Sorularınız için: hekimasistanitr@gmail.com

Bu politika değiştiğinde güncel sürüm uygulama içinde ve bu dosyada
yayınlanır.
