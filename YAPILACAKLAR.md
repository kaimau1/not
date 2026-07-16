# YAPILACAKLAR

## Durum: kurulum tamamlandı ✅

Firebase, Google girişi, imza anahtarı ve GitHub secret'ları hazır.
Geriye sadece **uygulamayı kurmak** ve **Gemini anahtarını girmek** kaldı.

---

## 1. Uygulamayı indir ve kur

1. https://github.com/kaimau1/not/actions → en üstteki yeşil ✓ işaretli çalıştırmaya tıkla.
2. Sayfanın altındaki **Artifacts** bölümünden:
   - **notlar-android-apk** → indir, zip'ten çıkan `app-release.apk`'yı telefonuna at ve kur
     (telefon "bilinmeyen kaynaklara izin ver" derse onayla).
   - **notlar-windows** → indir, zip'i bir klasöre çıkar, içindeki **notlar.exe**'yi çalıştır.
     (SmartScreen uyarısı çıkarsa: "Ek bilgi → Yine de çalıştır".)
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

**İmza anahtarı:** `Masaüstü\notlar-keystore\` klasöründe.
⚠️ **Bu klasörü yedekle** (Drive, harici disk vb.). Kaybolursa aynı imza bir daha
üretilemez; güncellemeler için uygulamayı silip yeniden kurman gerekir.

## Güncellemeler nasıl çalışacak?

Yeni bir özellik istediğinde kodu yazıp push'layacağım; GitHub Actions otomatik olarak
**aynı imzayla** ve **artan sürüm numarasıyla** yeni APK üretecek. Yeni APK'yı indirip
mevcut uygulamanın üzerine kurman yeterli — verilerin Firebase'de olduğu için hiçbir şey
kaybolmaz.

## Önemli notlar

- ⚠️ **Bu depo özel (private) kalmalı.** Herkese açık yapmak istersen önce bana söyle.
- Gmail özelliği "Testing" modunda yalnızca test kullanıcısı olarak eklediğin hesapla
  çalışır — kişisel kullanım için istediğimiz şey tam olarak bu.
