/// Desteklenen AI sağlayıcıları (BYOK — kullanıcının kendi anahtarı).
///
/// Uygulamanın İÇ istek biçimi Gemini'nin `contents` şekli olarak kalır:
/// `AiCost.forContents` ve `FirebaseAiClient` zaten onu tüketiyor, çağrı
/// yerlerinin tamamı (özet, OCR, PDF sohbeti...) o şekli üretiyor. Diğer
/// sağlayıcılara giderken biçim tek yerde çevrilir (bkz. provider_chat.dart);
/// böylece yeni bir sağlayıcı eklemek 1000 satırlık servisi değil yalnız o
/// çeviriyi ilgilendirir.
library;

/// Sağlayıcının telde konuştuğu protokol. Birden çok sağlayıcı aynı
/// protokolü kullanır (OpenRouter, OpenAI uyumlu) — çeviri kodu protokole
/// göre seçilir, sağlayıcıya göre değil.
enum AiWire {
  /// `contents`/`parts` + `inline_data` (Google Gemini).
  gemini,

  /// `messages`/`content` + `image_url` (OpenAI ve uyumluları).
  openai,

  /// `messages`/`content` + `source.base64` (Anthropic).
  anthropic,
}

enum AiProvider {
  gemini(
    id: 'gemini',
    label: 'Google Gemini',
    wire: AiWire.gemini,
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    keyUrl: 'https://aistudio.google.com/apikey',
    keyHint: 'AIza...',
    freeTier: true,
  ),
  openai(
    id: 'openai',
    label: 'OpenAI',
    wire: AiWire.openai,
    baseUrl: 'https://api.openai.com/v1',
    keyUrl: 'https://platform.openai.com/api-keys',
    keyHint: 'sk-...',
    freeTier: false,
  ),
  anthropic(
    id: 'anthropic',
    label: 'Anthropic Claude',
    wire: AiWire.anthropic,
    baseUrl: 'https://api.anthropic.com/v1',
    keyUrl: 'https://console.anthropic.com/settings/keys',
    keyHint: 'sk-ant-...',
    freeTier: false,
  ),
  /// Tek anahtarla yüzlerce modele (Google/OpenAI/Meta/Mistral...) erişim.
  /// "Diğer sağlayıcılar" isteğinin tek tek entegrasyon yazmadan karşılığı.
  openrouter(
    id: 'openrouter',
    label: 'OpenRouter',
    wire: AiWire.openai,
    baseUrl: 'https://openrouter.ai/api/v1',
    keyUrl: 'https://openrouter.ai/keys',
    keyHint: 'sk-or-...',
    freeTier: true,
  );

  const AiProvider({
    required this.id,
    required this.label,
    required this.wire,
    required this.baseUrl,
    required this.keyUrl,
    required this.keyHint,
    required this.freeTier,
  });

  /// Kalıcı anahtar (SharedPreferences/secure storage) — DEĞİŞTİRME.
  final String id;

  /// Ayarlarda görünen ad.
  final String label;

  final AiWire wire;
  final String baseUrl;

  /// "Anahtarı nereden alırım?" bağlantısı.
  final String keyUrl;

  /// Anahtar alanının ipucu metni — yanlış sağlayıcıya yapıştırmayı önler.
  final String keyHint;

  /// Sağlayıcının ücretsiz kademesi var mı? (Ayarlarda rozet olarak gösterilir;
  /// "AI'ı bedava dene" yolunu görünür kılar.)
  final bool freeTier;

  /// Model listesi uç noktası (tam yol).
  String get modelsUrl => '$baseUrl/models';

  static AiProvider fromId(String? id) => values.firstWhere(
    (p) => p.id == id,
    orElse: () => AiProvider.gemini,
  );

  /// İsteğe eklenecek kimlik doğrulama başlıkları.
  ///
  /// TUZAK (web): Anthropic tarayıcıdan doğrudan çağrıyı varsayılan olarak
  /// reddeder; `anthropic-dangerous-direct-browser-access` olmadan web
  /// sürümünde CORS hatası alınır. Anahtar kullanıcının kendisine ait olduğu
  /// ve tarayıcıda zaten onun elinde bulunduğu için burada sızdırılan bir sır
  /// yok.
  Map<String, String> authHeaders(String key) => switch (this) {
    AiProvider.gemini => {'x-goog-api-key': key},
    AiProvider.openai => {'Authorization': 'Bearer $key'},
    AiProvider.openrouter => {'Authorization': 'Bearer $key'},
    AiProvider.anthropic => {
      'x-api-key': key,
      'anthropic-version': '2023-06-01',
      'anthropic-dangerous-direct-browser-access': 'true',
    },
  };
}
