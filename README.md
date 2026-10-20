# Notlar

Firebase senkronlu, yapay zeka destekli not uygulaması — **Android** ve **web** için tek Flutter kod tabanı. (Windows sürümü 2026-10-19'da kaldırıldı; bilgisayarda web sürümü kullanılır.)

## Özellikler

- **Kesintisiz otomatik senkron** — Firestore offline-first çalışır: notlar internet yokken de yazılır, bağlantı gelince kendiliğinden tüm cihazlara yayılır. Senkron düğmesi yoktur, her şey anlıktır.
- **Dashboard** — Google Keep tarzı masonry ızgara; pencere genişliğine göre 2–6 sütun, tek sayfada olabildiğince çok not.
- **Not tipleri** — metin, alışveriş/kontrol listesi (işaretlenebilir), sıralı liste (sürükle-bırak).
- **Ekler** — fotoğraf/ekran görüntüsü ve PDF; Firebase Storage'da (istersen Google Drive'ında) saklanır.
- **Yapay zeka** — not özeti/analizi, PDF sohbeti, sesli komut, canlı çeviri, semantik arama, günlük brifing. Varsayılan dahili Gemini (Firebase AI Logic, günlük kota); istersen kendi anahtarınla Gemini, OpenAI, Anthropic ya da OpenRouter. Anahtar yalnızca cihazda saklanır.
- **Kişiler ve paylaşım** — arkadaş ekleme (ad/e-posta araması, Cloud Function), paylaşılan klasörler (okuma/yazma rolleri, sohbet), ortak not, gelen kutusu (not gönderme).
- **Ekler için Google Drive** (isteğe bağlı) — ekler kendi Drive'ının uygulama klasöründe saklanabilir.
- **Premium sade tasarım** — Material 3, açık/koyu tema (isteğe bağlı saat aralıklı otomatik koyu tema), ayarlanabilir yazı boyutu, yüksek yenileme hızı (120/144/165 Hz) desteği.
- Hızlı ekleme çubuğu, `Ctrl+N` kısayolu, otomatik kayıt, kaydırarak/sağ tıkla silme + geri alma.
- **Hatırlatıcılar** — nota tarih/saat ekle, zamanı gelince bildirim al (cihazlar arası senkronlanır).
- **Etiketler, arşiv ve çöp kutusu** — `#etiket` filtreleri, arşiv ekranı, 30 gün geri alınabilir silme, arama sonuçlarında vurgulama.
- **Ses kaydı notları** — kaydet, dinle, yapay zekaya yazıya döktür.
- **Çizim notları** — parmakla/mouse ile çiz, görsel olarak nota ekle.
- **Fotoğraftan metin (OCR)** — görseldeki metni yapay zeka ile çıkarıp nota ekle.
- **Notlarla sohbet** — "geçen hafta yazdığım tarif neydi?" gibi soruları AI'a sor.
- **Haftalık özet** — son 7 günün notlarından otomatik özet ve yapılacaklar.
- **Android ana ekran widget'ı** — son notların bir bakışta.

## Kurulum

Önkoşullar: [Flutter](https://docs.flutter.dev/get-started/install) (stable 3.47.7 — CI ile aynı), Android için Android Studio/SDK.

### 1. Firebase projesi

1. [Firebase Console](https://console.firebase.google.com)'da proje oluştur.
2. **Authentication → Sign-in method → Google**'ı etkinleştir.
3. **Firestore Database** oluştur (production mode; bölge ör. `europe-west1`).
4. **Storage** oluştur.
5. Depodaki kuralları yükle (Console'dan yapıştır ya da `firebase deploy`):
   - `firestore.rules`
   - `storage.rules`

### 2. FlutterFire yapılandırması

```sh
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android,web
```

Bu komut `lib/firebase_options.dart` dosyasındaki yer tutucuyu gerçek değerlerle değiştirir. (Bu yapılmadan uygulama açılışta kurulum ekranı gösterir.)

### 3. Android imza parmak izleri

Google girişi için SHA parmak izlerini Firebase'e ekle (Proje ayarları → Android uygulaması):

```sh
cd android && ./gradlew signingReport
```

Çıktıdaki **SHA-1** ve **SHA-256** değerlerini ekle. (Yayın anahtarı için tekrarla.)

### 4. Google Cloud Console (aynı proje)

1. **OAuth consent screen**: External + **Testing** modu; kendi Google adresini *test user* olarak ekle (Drive eki için `drive.appdata` kapsamı).
2. Firebase'in otomatik oluşturduğu **Web client ID**'yi not al (Android `serverClientId` olarak kullanılır).
3. Drive ekleri kullanılacaksa **Google Drive API**'yi etkinleştir (APIs & Services → Library).
4. Kişi araması için Cloud Functions (`functions/`, Blaze planı) — `main`'e push'ta CI'ın `deploy` işi yayınlar.

### 5. (İsteğe bağlı) Kendi AI anahtarın

Dahili AI kotalıdır. Kendi anahtarınla sınırsız kullanmak için [Google AI Studio](https://aistudio.google.com)'dan (ya da OpenAI/Anthropic/OpenRouter'dan) anahtar al → uygulamada **Ayarlar → Yapay zeka** bölümüne yapıştır.

## Çalıştırma

```sh
flutter pub get

# Android
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_CLIENT_ID>

# Web
flutter run -d chrome
```

> Değerleri her seferinde yazmamak için `--dart-define-from-file=env.json` kullanabilirsin (`env.json` gitignore'dadır; şablon `env.example.json`).

## Mimari

```
lib/
├── app/            # MaterialApp, router (go_router), tema, oturum boyu servisler (app_services)
├── core/           # sabitler, ağ (net/), ortak widget'lar, yardımcılar, hata günlüğü, sürüm kapısı
├── features/
│   ├── auth/       # Google/misafir girişi (Android: google_sign_in, web: Firebase popup), hesap silme
│   ├── notes/      # domain modelleri, Firestore/yerel/Drive depoları, dashboard, editörler, ekler
│   ├── folders/    # klasörler, paylaşılan klasör + sohbet
│   ├── friends/    # kişiler: arama, istek/kabul
│   ├── inbox/      # gelen notlar (arkadaştan gönderilen)
│   ├── ai/         # çok sağlayıcılı AI istemcisi, AI sayfaları
│   └── settings/   # ayarlar, kılavuz, gizlilik
├── l10n/           # arayüz metinleri (ARB: tr + en; şablon Türkçe)
web/                # web derlemesi kabuğu
functions/          # Cloud Functions (searchUsers + FCM itmeleri, push.js)
rules-test/         # Firestore/Storage kural testleri (emülatör)
```

- **State management**: Riverpod. Firestore `snapshots()` akışları doğrudan provider'lara bağlanır.
- **Veri modeli**: her not `users/{uid}/notes/{noteId}` altında bir doküman; ağır kısmı (çizim/balon/PDF işareti) 16 KB'ı aşınca `heavy/data` alt belgesinde, sürüm geçmişi `versions/`'ta. Ekler Storage'da `users/{uid}/notes/{noteId}/...` yolunda.
- **Çakışma çözümü**: alan bazlı merge yazımlar; açık editör eşzamanlı düzenlemede metni üç yönlü birleştirir.
- **Ek yükleme kuyruğu**: dosya önce cihaza kopyalanır, bağlantı gelince arka planda Storage'a yüklenir.

## Testler

```sh
flutter analyze
flutter test
```

## CI: Otomatik derleme (GitHub Actions)

Her push'ta `.github/workflows/build.yml` çalışır: analiz + testler. **Android APK** yalnız `main`'de, başlığında `[apk]` geçen commit'le derlenir ve kalıcı bir **Release** olarak yayınlanır (GitHub → Releases). `main`'e push'ta ayrıca Firestore/Storage kuralları ve Cloud Functions yayınlanır (`deploy` işi) ve web sürümü derlenir.

Google girişinin derlemeye gömülü gelmesi için depoda şu *secret*'ları tanımlayabilirsin (Settings → Secrets and variables → Actions):

| Secret | Açıklama |
|---|---|
| `GOOGLE_SERVER_CLIENT_ID` | Web client ID (Android girişi) |
| `ANDROID_KEYSTORE_BASE64` | Kalıcı imza anahtarı (base64) |
| `ANDROID_KEYSTORE_PASSWORD` | İmza anahtarı parolası |

Secret'lar tanımlı olmasa da derleme başarıyla tamamlanır (APK debug anahtarıyla imzalanır).

> Not: `lib/firebase_options.dart` yer tutucu değerlerle derlenirse uygulama açılışta kurulum ekranı gösterir. Gerçek yapılandırmayı (`flutterfire configure` çıktısını) commit'lersen CI'daki APK doğrudan kullanılabilir olur.
