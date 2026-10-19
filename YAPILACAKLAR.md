# YAPILACAKLAR

## Durum: kurulum tamamlandı ✅

Firebase, Google girişi, imza anahtarı ve GitHub secret'ları hazır.
Geriye sadece **uygulamayı kurmak** ve **Gemini anahtarını girmek** kaldı.

---

## 1. Uygulamayı indir ve kur

1. **Android:** https://github.com/kaimau1/not/releases → en son sürümün `notlar-v1.0.N.apk`
   dosyasını telefona indirip kur (telefon "bilinmeyen kaynaklara izin ver" derse onayla).
   APK yalnız `main`'e başlığında `[apk]` geçen commit'le derlenir.
2. **Windows:** CI'da derlenmiyor — depo kökündeki `build-windows.bat` ile yerelde derle
   (bkz. README → "Windows sürümünü derlemek"). Çıktı `build\windows\x64\runner\Release\notlar.exe`.
3. Uygulamada **Google ile giriş yap**.

## 2. Gemini API anahtarı

1. https://aistudio.google.com → **Get API key** → **Create API key** → kopyala.
2. Bu anahtarı hiçbir yere yazma; uygulamada **Ayarlar → Gemini API Anahtarı** alanına
   yapıştırıp **Doğrula ve Kaydet**'e bas.

---

## Kurulmuş yapılandırma (referans)

| Ne | Değer |
|---|---|
| Firebase projesi | `notlar-kaimau` |
| Konsol | https://console.firebase.google.com/project/notlar-kaimau |
| Android paket adı | `dev.kaimau.notlar` |
| Firestore | `europe-west1`, kurallar yayınlandı |
| Storage | kurallar yayınlandı (dosya başına 25 MB sınırı) |
| GitHub secret'ları | 5/5 tanımlı |

**İmza anahtarı:** `android/app/notlar-release.jks` (gitignore'lu) + parolalar
`android/key.properties`. `Masaüstü\notlar-keystore\` klasörü ARTIK YOK — tek kopya
repo klasöründe. ⚠️ **Makine dışında bir yedeği olmalı** (Drive, harici disk vb.).
Kaybolursa aynı imza bir daha üretilemez; güncellemeler için uygulamayı silip yeniden
kurman gerekir. CI imzası GitHub Secrets'tan.

## Güncellemeler nasıl çalışacak?

Yeni bir özellik istediğinde kodu yazıp push'layacağım; GitHub Actions otomatik olarak
**aynı imzayla** ve **artan sürüm numarasıyla** yeni APK üretecek. Yeni APK'yı indirip
mevcut uygulamanın üzerine kurman yeterli — verilerin Firebase'de olduğu için hiçbir şey
kaybolmaz.

## Önemli notlar

- ⚠️ **Bu depo özel (private) kalmalı.** Herkese açık yapmak istersen önce bana söyle.
- Google girişi OAuth "Testing" modunda yalnızca test kullanıcısı olarak eklediğin
  hesaplarla çalışır. (Gmail özelliği kaldırıldı.)
