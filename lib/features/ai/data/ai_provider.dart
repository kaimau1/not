/// Desteklenen AI sağlayıcısı (BYOK — kullanıcının kendi Gemini anahtarı).
///
/// Faz 1 sadeleştirmesi: çoklu üretken sağlayıcılar (OpenAI/Anthropic/
/// OpenRouter) kaldırıldı; yalnızca düşük maliyetli `gemini-decision-1`
/// Decisions API için Google Gemini anahtarı desteklenir.
library;

enum AiProvider {
  gemini(
    id: 'gemini',
    label: 'Google Gemini',
    baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
    keyUrl: 'https://aistudio.google.com/apikey',
    keyHint: 'AIza...',
  );

  const AiProvider({
    required this.id,
    required this.label,
    required this.baseUrl,
    required this.keyUrl,
    required this.keyHint,
  });

  /// Kalıcı anahtar (SharedPreferences/secure storage) — DEĞİŞTİRME.
  final String id;

  /// Ayarlarda görünen ad.
  final String label;

  final String baseUrl;

  /// "Anahtarı nereden alırım?" bağlantısı.
  final String keyUrl;

  /// Anahtar alanının ipucu metni.
  final String keyHint;

  String get modelsUrl => '$baseUrl/models';

  static AiProvider fromId(String? id) => AiProvider.gemini;

  Map<String, String> authHeaders(String key) => {'x-goog-api-key': key};
}
