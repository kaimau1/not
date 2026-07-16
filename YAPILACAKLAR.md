# YAPILACAKLAR — Sana Kalan İşler

Bunların hepsi **tarayıcıdan** yapılır; bilgisayarına hiçbir program kurman gerekmez.
Kod işi çıkarsa değerleri bana (Claude'a) yapıştırman yeterli — dosyalara ben işlerim.

Toplam süre: yaklaşık 20–30 dakika. Sıra önemli, yukarıdan aşağı git.

---

## 1. Firebase projesi oluştur (≈3 dk)

1. https://console.firebase.google.com adresine gir (Google hesabınla).
2. **"Proje oluştur"** → isim: `notlar` → Google Analytics **kapalı** olabilir → Oluştur.

## 2. Google girişini aç (≈1 dk)

1. Sol menü: **Build → Authentication** → **Get started**.
2. **Sign-in method** sekmesi → **Google** → **Etkinleştir** → destek e-postanı seç → Kaydet.

## 3. Firestore veritabanı (≈2 dk)

1. Sol menü: **Build → Firestore Database** → **Create database**.
2. Konum: `europe-west1` (Belçika) → **Production mode** → Oluştur.
3. Üstteki **Rules** sekmesine geç, içeriği sil ve şunu yapıştır → **Publish**:

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

## 4. Storage (dosya deposu) (≈2 dk)

1. Sol menü: **Build → Storage** → **Get started** → Production mode → aynı konum → Bitti.
2. **Rules** sekmesi → içeriği sil, şunu yapıştır → **Publish**:

```
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    match /users/{uid}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == uid;
      allow write: if request.auth != null
        && request.auth.uid == uid
        && request.resource.size < 25 * 1024 * 1024;
    }
  }
}
```

> Not: Storage bazı projelerde Blaze (kredi kartlı, kullandıkça öde) plan ister.
> Ücretsiz kotalar kişisel kullanım için fazlasıyla yeterlidir; kota aşılmadıkça ücret çıkmaz.

## 5. Android uygulamasını kaydet (≈3 dk)

1. Firebase'de sol üstteki ⚙️ → **Project settings** → aşağıda **Your apps** → **Android** simgesi.
2. İstenen bilgiler (kopyala-yapıştır):
   - **Android package name:** `dev.kaimau.notlar`
   - Takma ad: `Notlar Android`
   - **Debug signing certificate SHA-1:** `C0:CE:E3:0C:6A:0A:0E:DB:09:C1:3A:3F:F6:61:C0:02:C2:62:9F:92`
3. **Register app** → sonraki adımları (google-services.json indirme vs.) **Atla / Next / Continue** diyerek geç — o dosyaya ihtiyacımız yok.
4. Kayıt bitince aynı sayfada Android uygulamasının kartında **Add fingerprint** → şu **SHA-256**'yı da ekle:
   `5A:12:FF:D0:24:CA:0A:5A:09:61:2E:E7:4C:59:5D:9F:02:64:AB:2C:E5:6C:36:E4:1F:87:58:CA:32:81:83:D5`

## 6. Web uygulamasını kaydet — Windows sürümü için (≈2 dk)

1. Aynı yerde (**Your apps**) → **Web** simgesi (`</>`).
2. Takma ad: `Notlar Windows` → **Register app**.
3. Karşına `firebaseConfig` diye bir kod bloğu çıkacak (apiKey, authDomain, projectId...).
   **Bu bloğun tamamını kopyala** — 7. adımda bana göndereceksin.

## 7. Değerleri bana gönder (≈2 dk)

Claude oturumuna dön ve şunları yapıştır:

1. 6. adımdaki **firebaseConfig** bloğunun tamamı.
2. Project settings → Your apps → **Android** uygulamasının kartındaki **App ID**
   (şuna benzer: `1:123456789:android:abc123...`).

Ben bunları `lib/firebase_options.dart` dosyasına işleyip push'layacağım; CI otomatik olarak
gerçek yapılandırmayla yeni APK ve Windows sürümü üretecek.

## 8. Google girişi kimlikleri (≈5 dk)

1. https://console.cloud.google.com adresine gir; üstteki proje seçiciden **notlar** projesini seç
   (Firebase projesi otomatik olarak burada da görünür).
2. **APIs & Services → OAuth consent screen**:
   - Zaten yapılandırılmışsa dokunma. Değilse: **External** → uygulama adı `Notlar`, kendi e-postanı gir → kaydet.
   - **Audience / Test users** bölümüne **kendi Gmail adresini** test kullanıcısı olarak ekle.
3. **APIs & Services → Credentials** → **+ Create credentials → OAuth client ID**:
   - Application type: **Desktop app**, isim: `Notlar Windows` → Create.
   - Çıkan **Client ID** ve **Client secret** değerlerini kopyala (9. adımda kullanılacak).
4. Aynı sayfada (Credentials) **Web client (auto created by Google Service)** diye bir satır göreceksin —
   onun **Client ID**'sini kopyala (9. adımda `GOOGLE_SERVER_CLIENT_ID` olacak).
5. **APIs & Services → Library** → "Gmail API" ara → **Enable**.

## 9. GitHub'a gizli değerleri ekle (≈5 dk)

1. https://github.com/kaimau1/not → **Settings** → sol menüde **Secrets and variables → Actions**.
2. **New repository secret** ile şu beşini tek tek ekle:

| Name (aynen böyle yaz) | Value |
|---|---|
| `GOOGLE_SERVER_CLIENT_ID` | 8.4'teki Web client ID |
| `GOOGLE_DESKTOP_CLIENT_ID` | 8.3'teki Desktop Client ID |
| `GOOGLE_DESKTOP_CLIENT_SECRET` | 8.3'teki Desktop Client secret |
| `ANDROID_KEYSTORE_BASE64` | Claude'un sana gönderdiği `keystore-base64.txt` dosyasının **tüm içeriği** |
| `ANDROID_KEYSTORE_PASSWORD` | Claude'un sana gönderdiği bilgi dosyasındaki şifre |

> ⚠️ Son iki secret, APK'nın her güncellemede **aynı imzayla** çıkmasını sağlar.
> Telefonuna kuracağın İLK kalıcı APK'dan ÖNCE bunları eklemiş olmalısın; yoksa
> sonraki güncellemede "uygulama yüklenemedi" hatası alır, uygulamayı silip
> yeniden kurmak zorunda kalırsın (notlar Firebase'de olduğu için veri kaybolmaz).
> Claude'un gönderdiği `notlar-release.jks` dosyasını da güvenli bir yerde sakla
> (yedek — kaybolursa imza bir daha üretilemez).

## 10. Gemini API anahtarı (≈2 dk)

1. https://aistudio.google.com → **Get API key** → **Create API key** → kopyala.
2. Bu anahtarı bir yere GİRME; uygulama telefonuna/bilgisayarına kurulduktan sonra
   uygulamanın içinde **Ayarlar → Gemini API Anahtarı** alanına yapıştırıp **Doğrula ve Kaydet**'e bas.

## 11. Uygulamayı indir ve kur

7. ve 9. adımlar bitince bana "tamam" de; son derlemeyi tetikleyip kontrol edeyim. Sonra:

1. https://github.com/kaimau1/not/actions → en üstteki yeşil ✓ işaretli çalıştırmaya tıkla.
2. Sayfanın altındaki **Artifacts** bölümünden:
   - **notlar-android-apk** → indir, zip'ten çıkan `app-release.apk`'yı telefonuna at ve kur
     (telefonda "bilinmeyen kaynaklara izin ver" diyebilir, onayla).
   - **notlar-windows** → indir, zip'i bir klasöre çıkar, içindeki **notlar.exe**'yi çalıştır.
     (Windows'ta ilk açılışta SmartScreen uyarısı çıkarsa: "Ek bilgi → Yine de çalıştır".)
3. Uygulamada Google ile giriş yap → Ayarlar'dan Gemini anahtarını gir → istersen Gmail'i bağla.

## Güncellemeler nasıl çalışacak?

- Benden yeni bir özellik istediğinde kodu yazıp push'layacağım; GitHub Actions otomatik olarak
  **aynı imzayla** ve **artan sürüm numarasıyla** yeni APK üretecek.
- Yeni APK'yı indirip mevcut uygulamanın üzerine kurman yeterli — verilerin Firebase'de olduğu
  için hiçbir şey kaybolmaz, ayrıca imza aynı olduğu için "uygulama yüklenemedi" hatası almazsın.

## Önemli notlar

- ⚠️ **Bu depo özel (private) kalmalı.** İmza anahtarı ve şifresi depoda tutuluyor
  (sen hiçbir şeyle uğraşma diye). Depoyu herkese açık yapmak istersen önce bana söyle.
- Gmail özelliği "Testing" modunda yalnızca test kullanıcısı olarak eklediğin hesapla çalışır —
  kişisel kullanım için tam olarak istediğimiz şey bu.
