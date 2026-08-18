/// Uygulama genelinde kullanılan sabitler.
abstract final class AppConstants {
  static const String appName = 'Notlar';

  // Firestore koleksiyon adları
  static const String usersCollection = 'users';
  static const String notesCollection = 'notes';

  /// Dahili AI kota sayacı — `users/{uid}` ALTINDA DEĞİL, ayrı kök
  /// koleksiyonda. Gerekçe firestore.rules'da: kullanıcı dokümanı istemciden
  /// silinebildiği için sayaç orada sıfırlanabiliyordu.
  static const String aiQuotaCollection = 'aiQuota';
  static const String foldersCollection = 'folders';

  /// Kişiler (arkadaşlar) — `users/{uid}/friends/{friendUid}`.
  static const String friendsCollection = 'friends';

  /// Bekleyen arkadaşlık istekleri — `users/{uid}/friendRequests/{fromUid}`.
  /// Alıcının kendi alt koleksiyonuna GÖNDEREN yazar (bkz. firestore.rules).
  static const String friendRequestsCollection = 'friendRequests';

  /// E-postadan kullanıcı bulmak için KÖK koleksiyon (kullanıcı adı altında
  /// DEĞİL — aksi hâlde "ben bu e-postanın sahibiyim" iddiasını doğrulayacak
  /// hiçbir yer olmazdı). Doküman kimliği küçük harfe çevrilmiş e-posta;
  /// içeriği yalnız `{uid}`. Her kullanıcı GİRİŞTE kendi kaydını yazar.
  static const String userDirectoryCollection = 'userDirectory';

  /// Klasör paylaşımının KÖK ayna koleksiyonu — `folderShares/{folderId}`,
  /// kimliği paylaşılan klasörün kendi id'siyle AYNI. Paylaşılan kullanıcının
  /// "hangi klasörler bana açıldı" sorusunu tek sorguda yanıtlamasını sağlar
  /// (`sharedWith` dizisinde `array-contains`); asıl klasör ve notlar yine
  /// SAHİBİNİN `users/{ownerId}/...` altında kalır (bkz. firestore.rules).
  static const String folderSharesCollection = 'folderShares';

  // Gemini
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Sıralı model tercihi: biri 404 (model yok) veya 429 (kota) verirse
  /// sıradaki denenir. API'den çekilen gerçek listeyle kesiştirilir ve
  /// listede olmayan yeni flash modelleri sona eklenir (GeminiService).
  /// Varsayılan model 3.1 flash lite'tır (hızlı + ucuz).
  static const List<String> geminiModelPreference = [
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
  ];

  /// Gecikmeye duyarlı akışlarda (otomatik başlık, dikte) ilk denenecek
  /// hızlı model.
  static const String fastGeminiModel = 'gemini-3.1-flash-lite';

  /// Sesli not asistanı (araç çağrılı not oluşturma) için ilk denenecek
  /// model. Bu görev yapısal (tool-call) olduğundan hızlı "lite" model
  /// tipi/içeriği tutarsız verip BOŞ not üretebiliyordu; daha yetenekli
  /// standart flash modeli önce denenir, lite yalnızca yedek olarak zincirde
  /// kalır (model geçişleri böyle optimize edilir).
  static const String voiceAssistantModel = 'gemini-3.5-flash';

  /// Gemini SESLENDİRME (TTS) modelleri — model listesi çekilemezse kullanılan
  /// yedek. Ayarlardaki seçici katalogdan "tts" içeren kimlikleri süzer;
  /// katalog gelmezse bu liste gösterilir.
  ///
  /// TTS ayrı bir model ailesidir: metin modelleri ses ÜRETEMEZ, bu yüzden
  /// podcast modeliyle aynı seçiciye konamaz (bkz. AiTask, ttsModelProvider).
  static const List<String> geminiTtsModelPreference = [
    'gemini-2.5-flash-preview-tts',
    'gemini-2.5-pro-preview-tts',
  ];

  /// Gemini TTS'in hazır ses adları. Tümü çok dilli (Türkçe dahil); liste
  /// bilerek kısa tutuldu — otuz sesin hepsini göstermek seçimi kolaylaştırmaz.
  static const List<String> geminiTtsVoices = [
    'Kore',
    'Puck',
    'Zephyr',
    'Charon',
    'Aoede',
    'Leda',
    'Orus',
    'Fenrir',
  ];

  /// Dahili AI günlük bütçesi PUAN olarak sayılır, çağrı olarak değil:
  /// 100 sayfalık bir PDF özeti ile bir başlık üretiminin maliyeti arasında
  /// iki mertebe fark var; ikisini "1 hak" saymak faturayı öngörülemez
  /// kılıyordu. Puanlar isteğin içeriğinden türetilir (bkz. AiCost).
  ///
  /// 30 puan ≈ günde 30 küçük metin işlemi VEYA 3 PDF özeti.
  /// Kendi API anahtarını girenlere sınır uygulanmaz (kendi kotaları).
  static const int freeDailyAiPoints = 30;

  /// Premium günlük puanı. Premium "sınırsız" değil: dahili AI çağrıları
  /// projenin Gemini faturasından karşılandığı için (kredi tükenince herkes
  /// hata alır) premium'a da bir tavan konur.
  static const int premiumDailyAiPoints = 300;

  /// İstek maliyetinin puana çevrilmesi. Taban her istekte 1 puandır;
  /// ekli dosyalar ve uzun metin üstüne eklenir.
  static const int aiPointsPerImage = 3;
  static const int aiPointsPerDocument = 10;

  /// Her bu kadar karakter girdi için +1 puan (token maliyetinin kaba
  /// karşılığı — uzun sohbet geçmişi de faturaya yazılıyor).
  static const int aiCharsPerPoint = 4000;

  // Ek sınırları — dosya boyutu premium'a göre değişir. Sunucu (storage.rules)
  // 50 MB tavanı zorlar; ücretsiz 10 MB sınırı uygulama tarafında (yükleme
  // öncesi) uygulanır — kişisel not uygulaması, katı sunucu zorlaması için
  // her yüklemede Firestore okuması gerekirdi, gereksiz.
  // ponytail: free 10 MB app-side, server 50 MB tavan; katı server zorlaması
  // istenirse storage.rules'da firestore.get(premiumUntil) eklenir.
  static const int maxFreeAttachmentBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxPremiumAttachmentBytes = 50 * 1024 * 1024; // 50 MB

  // Toplam bulut depolama tavanı. TEK dosya sınırı (üstteki) maliyeti
  // öngörülebilir kılmıyordu: 10 MB'lık eklerden 500 tane yüklenince fatura
  // yine patlıyor. Lifetime (tek ödeme) paketinin maliyeti ancak TOPLAM bir
  // tavanla hesaplanabilir olduğu için bu ikinci kapı eklendi.
  //
  // Sayım istemci tarafında yapılır (notlardaki `sizeBytes` toplamı) — katı
  // sunucu zorlaması için her yüklemede Firestore okuyan bir Storage kuralı
  // ya da Cloud Function gerekir; kişisel not uygulamasında gereksiz.
  // ponytail: Play Billing eklenirken sunucu tarafı sayaç da düşünülmeli.
  static const int maxFreeStorageBytes = 50 * 1024 * 1024; // 50 MB
  static const int maxPremiumStorageBytes = 2 * 1024 * 1024 * 1024; // 2 GB
  /// Görsel eklerin saklandığı/senkronlandığı en büyük kenar (px).
  ///
  /// 2048'den 1600'e indirildi: senkron boyutu ~%40 küçülüyor ve OCR/"PDF'i
  /// özetle" akışları bozulmuyor — Gemini görseli 768 px'lik karolara bölerek
  /// okuduğundan 1600 px zaten fazlasıyla yeterli. Yerel kopya da bu ölçüde
  /// tutulur (tek dosya yüklenir), yani cihaz depolaması da azalır.
  static const int maxImageDimension = 1600;

  /// Görsel eklerin JPEG kalitesi. q80 → q75: gözle ayırt edilmesi güç,
  /// dosya ~%15 daha küçük.
  static const int imageJpegQuality = 75;

  /// Ses eklerinin kayıt bit hızı (bit/sn) ve örnekleme oranı (Hz).
  /// Konuşma için AAC-LC tek kanal 32 kbps / 22.05 kHz yeterli; 48 kbps'e göre
  /// dosya üçte bir küçülür (dakikada ~240 KB), Storage kotası ve mobil veri
  /// buna gidiyordu.
  static const int audioBitRate = 32000;
  static const int audioSampleRate = 22050;

  /// Ek bu boyutu aşarsa kullanıcıya sorulur (engellenmez). Firebase Storage
  /// ücretsiz katmanı 5 GB; sıkıştırılamayan PDF'ler kotayı sessizce yiyordu.
  static const int largeAttachmentWarnBytes = 5 * 1024 * 1024; // 5 MB

  // Google OAuth (masaüstü) — derleme sırasında --dart-define ile verilir:
  //   flutter run --dart-define=GOOGLE_DESKTOP_CLIENT_ID=... \
  //               --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=...
  static const String desktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
  );
  static const String desktopClientSecret = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_SECRET',
  );

  // Android'de google_sign_in için sunucu (web) client ID — ZORUNLU.
  //
  // DİKKAT: "boş bırakılırsa eklenti google-services.json içinden okur" DOĞRU
  // DEĞİL — bu repoda google-services.json yok (Firebase yapılandırması
  // firebase_options.dart üzerinden geliyor). Define geçilmezse uygulama
  // sorunsuz DERLENİR ama giriş çalışma anında
  // "serverClientId must be provided on Android" ile çöker; hata ancak
  // telefonda görülür. 2026-08-04'te yerel bir release derlemesi tam bu
  // yüzden kırık çıktı.
  //
  // Yerel derleme:  flutter build apk --release --dart-define-from-file=env.json
  // CI: aynı değeri GitHub Secrets'tan geçer (.github/workflows/build.yml).
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
