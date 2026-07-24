/// Uygulama genelinde kullanılan sabitler.
abstract final class AppConstants {
  static const String appName = 'Notlar';

  // Firestore koleksiyon adları
  static const String usersCollection = 'users';
  static const String notesCollection = 'notes';
  static const String foldersCollection = 'folders';

  // Gemini
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  /// Sıralı model tercihi: biri 404 (model yok) veya 429 (kota) verirse
  /// sıradaki denenir. API'den çekilen gerçek listeyle kesiştirilir ve
  /// listede olmayan yeni flash modelleri sona eklenir (GeminiService).
  /// Varsayılan model 3.1 flash lite'tır (hızlı + ucuz); canlı çeviri
  /// [geminiLiveTranslateModel] ile ayrı modelde kalır.
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
  static const String geminiLiveTranslateModel =
      'gemini-3.5-live-translate-preview';
  static const String geminiLiveWsUrl =
      'wss://generativelanguage.googleapis.com/ws/'
      'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  // Ek sınırları — dosya boyutu premium'a göre değişir. Sunucu (storage.rules)
  // 50 MB tavanı zorlar; ücretsiz 10 MB sınırı uygulama tarafında (yükleme
  // öncesi) uygulanır — kişisel not uygulaması, katı sunucu zorlaması için
  // her yüklemede Firestore okuması gerekirdi, gereksiz.
  // ponytail: free 10 MB app-side, server 50 MB tavan; katı server zorlaması
  // istenirse storage.rules'da firestore.get(premiumUntil) eklenir.
  static const int maxFreeAttachmentBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxPremiumAttachmentBytes = 50 * 1024 * 1024; // 50 MB
  static const int maxImageDimension = 2048;

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

  // Android'de google_sign_in için sunucu (web) client ID.
  // Boş bırakılırsa eklenti google-services.json içinden okur.
  static const String serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static const String gmailReadonlyScope =
      'https://www.googleapis.com/auth/gmail.readonly';
}
