# Notlar — Gizlilik Politikası

Son güncelleme: 17 Temmuz 2026

Bu politika, "Notlar" uygulamasının (Android ve Windows) hangi verileri
işlediğini, neden işlediğini ve haklarınızı açıklar. Uygulamayı kullanarak
bu politikayı kabul etmiş olursunuz.

## Toplanan veriler

1. Hesap bilgileri — Google ile giriş yaptığınızda adınız, e-posta
   adresiniz ve profil fotoğrafınız kimlik doğrulama için kullanılır
   (Firebase Authentication).

2. Not içerikleri — Notlarınız, listeleriniz, etiketleriniz,
   hatırlatıcılarınız ve ekleriniz (fotoğraf, PDF, ses kaydı, çizim)
   cihazlar arası eşitleme için Google Firebase (Firestore ve Cloud
   Storage) üzerinde, yalnızca sizin hesabınıza bağlı olarak saklanır.
   Google hesabıyla giriş yapıp "Ekleri Google Drive'ında sakla"
   seçeneğini bağladığınızda ekleriniz bunun yerine KENDİ Google
   Drive'ınızda, uygulamaya özel gizli klasörde (drive.appdata izni —
   uygulama Drive'ınızdaki başka hiçbir dosyayı göremez) saklanır.
   Misafir (Google'sız) hesapta ekler buluta yüklenmez, cihazda kalır.
   Verileriniz başka kullanıcılarla paylaşılmaz ve reklam amacıyla
   kullanılmaz.

3. Yapay zeka işlemleri — Özetleme, sesli not, OCR, çeviri, sohbet gibi
   AI özelliklerini kullandığınızda ilgili not metni, ses kaydı veya
   görsel, işlenmek üzere Google Gemini API'sine gönderilir. İçerik
   yalnızca isteğinizi yerine getirmek için işlenir; uygulama bu
   içerikleri ayrıca kaydetmez. Kendi API anahtarınızı girerseniz
   istekler doğrudan sizin anahtarınızla Google'a gider; anahtar yalnızca
   cihazınızdaki güvenli depoda tutulur ve hiçbir sunucuya yazılmaz.

4. Gmail (isteğe bağlı) — Gmail bağlantısını açarsanız uygulama yalnızca
   okuma izniyle son e-postalarınızın başlık ve kısa önizlemelerini alır
   ve önemli olanları özetlemek için Gemini API'sine iletir. E-posta
   içerikleri hiçbir yere kaydedilmez. Bağlantıyı Ayarlar'dan istediğiniz
   an kesebilirsiniz.

5. Bildirimler — Hatırlatıcı ve günlük brifing bildirimleri cihazınızda
   yerel olarak planlanır; bildirim içerikleri sunucuya gönderilmez.

## Toplanmayan veriler

- Reklam kimliği, konum, kişi listesi veya arama geçmişi toplanmaz.
- Analitik/izleme SDK'sı kullanılmaz.
- Verileriniz üçüncü taraflara satılmaz veya pazarlama için paylaşılmaz.

## Veri saklama ve silme

- Verileriniz siz silene kadar Firebase'de (ekleriniz Drive'ı
  bağladıysanız Google Drive'ınızda) saklanır. Drive'daki uygulama
  klasörünü Google Drive → Ayarlar → Uygulamaları yönet'ten de
  silebilirsiniz.
- Tek bir notu çöp kutusuna taşıyıp kalıcı silebilirsiniz.
- Ayarlar → "Hesabımı ve verilerimi sil" ile hesabınızı ve TÜM
  verilerinizi (notlar, ekler, hesap kaydı) uygulama içinden kalıcı
  olarak silebilirsiniz. Bu işlem geri alınamaz.

## Veri güvenliği

Veriler aktarımda TLS ile şifrelenir. Firebase erişim kuralları her
kullanıcının yalnızca kendi verisine erişmesine izin verir. Gemini API
anahtarınız (girdiyseniz) Android Keystore / Windows DPAPI ile korunan
güvenli depoda saklanır.

## Üçüncü taraf hizmetler

Uygulama şu Google hizmetlerini kullanır: Firebase Authentication,
Cloud Firestore, Cloud Storage, Google Drive API (bağlarsanız),
Firebase AI Logic ve Gemini API.
Bu hizmetler için Google'ın gizlilik politikası geçerlidir:
https://policies.google.com/privacy

## Çocukların gizliliği

Uygulama 13 yaş altı çocuklara yönelik değildir.

## İletişim

Sorularınız için: hekimasistanitr@gmail.com

Bu politika değiştiğinde güncel sürüm uygulama içinde ve bu dosyada
yayınlanır.
