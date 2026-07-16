# Notlar

Firebase senkronlu, yapay zeka destekli not uygulaması — **Android** ve **Windows** için tek Flutter kod tabanı.

## Özellikler

- **Kesintisiz otomatik senkron** — Firestore offline-first çalışır: notlar internet yokken de yazılır, bağlantı gelince kendiliğinden tüm cihazlara yayılır. Senkron düğmesi yoktur, her şey anlıktır.
- **Dashboard** — Google Keep tarzı masonry ızgara; pencere genişliğine göre 2–6 sütun, tek sayfada olabildiğince çok not.
- **Not tipleri** — metin, alışveriş/kontrol listesi (işaretlenebilir), sıralı liste (sürükle-bırak).
- **Ekler** — fotoğraf/ekran görüntüsü ve PDF; Firebase Storage'da saklanır. Windows'ta panodan görsel yapıştırma (`Ctrl+Shift+V`).
- **Yapay zeka (Gemini)** — not özeti/analizi, PDF özeti, notlardan öneriler. Kendi API anahtarınla çalışır; anahtar yalnızca cihazda saklanır.
- **Gmail** — gelen kutundaki son e-postaları yapay zeka tarar, önemli olanları kısa Türkçe özetle listeler (salt-okunur erişim; e-posta içeriği hiçbir yere kaydedilmez).
- **Premium sade tasarım** — Material 3, açık/koyu tema, yüksek yenileme hızı (120/144/165 Hz) desteği.
- Hızlı ekleme çubuğu, `Ctrl+N` kısayolu, otomatik kayıt, kaydırarak/sağ tıkla silme + geri alma.

## Kurulum

Önkoşullar: [Flutter](https://docs.flutter.dev/get-started/install) (stable ≥ 3.44), Android için Android Studio/SDK, Windows derlemesi için Visual Studio 2022 **"Desktop development with C++"** iş yükü (FlutterFire'ın Windows desteği beta'dır ve C++ SDK kullanır).

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
flutterfire configure --platforms=android,windows
```

Bu komut `lib/firebase_options.dart` dosyasındaki yer tutucuyu gerçek değerlerle değiştirir. (Bu yapılmadan uygulama açılışta kurulum ekranı gösterir.)

### 3. Android imza parmak izleri

Google girişi için SHA parmak izlerini Firebase'e ekle (Proje ayarları → Android uygulaması):

```sh
cd android && ./gradlew signingReport
```

Çıktıdaki **SHA-1** ve **SHA-256** değerlerini ekle. (Yayın anahtarı için tekrarla.)

### 4. Google Cloud Console (aynı proje)

1. **OAuth consent screen**: External + **Testing** modu; kendi Gmail adresini *test user* olarak ekle; kapsamlara `gmail.readonly` ekle.
2. **Credentials → Create credentials → OAuth client ID → Desktop app** oluştur (Windows girişi için). Client ID ve secret'ı not al.
3. Firebase'in otomatik oluşturduğu **Web client ID**'yi not al (Android `serverClientId` olarak kullanılır).
4. **Gmail API**'yi etkinleştir (APIs & Services → Library).

### 5. Gemini API anahtarı

[Google AI Studio](https://aistudio.google.com)'dan ücretsiz anahtar al → uygulamada **Ayarlar → Gemini API Anahtarı** alanına yapıştır.

## Çalıştırma

```sh
flutter pub get

# Android
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=<WEB_CLIENT_ID>

# Windows
flutter run -d windows \
  --dart-define=GOOGLE_DESKTOP_CLIENT_ID=<DESKTOP_CLIENT_ID> \
  --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=<DESKTOP_CLIENT_SECRET>
```

> Google'ın masaüstü ("installed app") istemcilerinde client secret gizli sayılmaz; yine de depoya yazmayıp `--dart-define` ile vermek en temiz yoldur. Değerleri her seferinde yazmamak için `--dart-define-from-file=env.json` kullanabilirsin (`env.json` gitignore'dadır).

## Mimari

```
lib/
├── app/            # MaterialApp, router (go_router), tema
├── core/           # sabitler, ortak widget'lar, yardımcılar
├── features/
│   ├── auth/       # Google girişi (Android: google_sign_in, Windows: PKCE loopback)
│   ├── notes/      # domain modelleri, Firestore repository, dashboard, editörler, ekler
│   ├── ai/         # Gemini REST servisi, AI sayfaları
│   ├── gmail/      # Gmail API + e-posta triyajı
│   └── settings/   # tema, API anahtarı, Gmail bağlantısı, hesap
└── l10n/           # Türkçe arayüz metinleri (ARB)
```

- **State management**: Riverpod. Firestore `snapshots()` akışları doğrudan provider'lara bağlanır.
- **Veri modeli**: her not `users/{uid}/notes/{noteId}` altında tek doküman; ekler Storage'da `users/{uid}/notes/{noteId}/...` yolunda.
- **Çakışma çözümü**: last-write-wins (`serverTimestamp`), alan bazlı merge yazımlar.
- **Ek yükleme kuyruğu**: dosya önce cihaza kopyalanır, bağlantı gelince arka planda Storage'a yüklenir.

## Testler

```sh
flutter analyze
flutter test
```
