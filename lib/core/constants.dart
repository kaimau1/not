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

  /// Dahili AI (Firebase AI Logic) için premium olmayanların günlük
  /// ücretsiz istek hakkı. Kendi API anahtarını girenlere sınır uygulanmaz.
  static const int freeDailyAiCalls = 5;
  static const String geminiLiveTranslateModel =
      'gemini-3.5-live-translate-preview';
  static const String geminiLiveWsUrl =
      'wss://generativelanguage.googleapis.com/ws/'
      'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';

  // Ek sınırları
  static const int maxAttachmentBytes = 25 * 1024 * 1024; // 25 MB
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
