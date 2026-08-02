import 'ai_provider.dart';

/// Sağlayıcıdan çekilen tek bir model.
class AiModel {
  const AiModel({
    required this.id,
    required this.label,
    this.recommended = false,
    this.note,
  });

  /// API'ye gönderilen kimlik (ör. `gemini-3.1-flash`, `openai/gpt-5-mini`).
  final String id;

  /// Ekranda görünen ad — sağlayıcı bir görünen ad verdiyse o, yoksa [id].
  final String label;

  /// "Not uygulaması için yeterli" mi? Ayarlarda ÖNERİLEN rozetiyle çıkar.
  final bool recommended;

  /// Rozetin altındaki tek satırlık gerekçe ("hızlı ve ucuz", "ücretsiz"...).
  final String? note;

  @override
  bool operator ==(Object other) =>
      other is AiModel &&
      other.id == id &&
      other.label == label &&
      other.recommended == recommended &&
      other.note == note;

  @override
  int get hashCode => Object.hash(id, label, recommended, note);

  @override
  String toString() => 'AiModel($id, recommended: $recommended)';
}

/// Modellerin ELENME kuralı — her sağlayıcıda ortak.
///
/// Sağlayıcıların `/models` uç noktaları sohbet dışı her şeyi de döndürüyor
/// (embedding, konuşma tanıma, görsel üretimi, moderasyon, canlı ses).
/// Kullanıcıya ham liste gösterilirse "gemini-embedding-001" seçip her AI
/// özelliğinin bozulmasına yol açabilir; bu yüzden liste sunulmadan önce
/// süzülür. Elemenin sohbet modellerini yanlışlıkla yutmaması için desenler
/// dar tutuldu (ör. `audio` var ama `auto` yok).
final RegExp _notForChat = RegExp(
  r'embed|embedding|tts|text-to-speech|whisper|transcribe|moderation|'
  r'dall-e|stable-diffusion|image-generation|imagen|sora|veo|'
  r'realtime|:?live|guard|rerank|davinci|babbage|curie|ada-00',
  caseSensitive: false,
);

/// Sağlayıcıya göre ÖNERİ desenleri — sıralı: baştakiler listede önce çıkar.
///
/// Ölçüt "en güçlü model" DEĞİL, "bu uygulama için doğru model": notların
/// işlerinin çoğu başlık/etiket/özet gibi kısa işler, ama OCR ve PDF sohbeti
/// yüzünden model GÖRSEL de okuyabilmeli. Yani hızlı + çok kipli olanlar
/// önerilir; büyük "pro/opus" modelleri listede kalır ama önerilmez (yavaş ve
/// pahalıdır, kullanıcının faturasını gereksiz büyütür).
const _recommendations = <AiProvider, List<(String, String)>>{
  AiProvider.gemini: [
    (r'gemini-[\d.]+-flash-lite', 'En hızlı ve en ucuz — kısa işler için ideal'),
    (r'gemini-[\d.]+-flash', 'Hızlı, görsel ve PDF okur — günlük kullanım'),
  ],
  AiProvider.openai: [
    (r'gpt-[\d.]+-mini', 'Hızlı ve ucuz — görsel okur'),
    (r'gpt-[\d.]+o-mini', 'Hızlı ve ucuz — görsel okur'),
    (r'gpt-[\d.]+o$', 'Dengeli — görsel ve belge okur'),
  ],
  AiProvider.anthropic: [
    (r'claude-.*haiku', 'En hızlı Claude — kısa işler için ideal'),
    (r'claude-.*sonnet', 'Dengeli — uzun belge ve görsel okur'),
  ],
  AiProvider.openrouter: [
    (r':free$', 'Ücretsiz — OpenRouter üzerinden'),
    (r'google/gemini-[\d.]+-flash', 'Hızlı ve ucuz — görsel okur'),
    (r'openai/gpt-[\d.]+-mini', 'Hızlı ve ucuz — görsel okur'),
    (r'anthropic/claude-.*haiku', 'Hızlı ve ucuz — görsel okur'),
  ],
};

/// Sağlayıcının ham model listesini uygulamaya uygun sıraya sokar.
///
/// [raw] anahtarı model kimliği, değeri sağlayıcının verdiği görünen addır
/// (yoksa null). Dönen liste: önce ÖNERİLENLER (desen sırasına göre, aynı
/// desen içinde yeniden eskiye), sonra kalan sohbet modelleri (yeniden
/// eskiye). Sohbet dışı modeller hiç dönmez.
List<AiModel> rankModels(AiProvider provider, Map<String, String?> raw) {
  final patterns = _recommendations[provider] ?? const [];
  final recommended = <int, List<AiModel>>{};
  final others = <AiModel>[];

  for (final entry in raw.entries) {
    final id = entry.key.trim();
    if (id.isEmpty || _notForChat.hasMatch(id)) continue;
    final label = (entry.value ?? '').trim();
    var rank = -1;
    String? note;
    for (var i = 0; i < patterns.length; i++) {
      if (RegExp(patterns[i].$1, caseSensitive: false).hasMatch(id)) {
        rank = i;
        note = patterns[i].$2;
        break;
      }
    }
    final model = AiModel(
      id: id,
      label: label.isEmpty ? id : label,
      recommended: rank >= 0,
      note: note,
    );
    if (rank >= 0) {
      (recommended[rank] ??= []).add(model);
    } else {
      others.add(model);
    }
  }

  // Sürüm numarası kimliğin içinde olduğundan ters alfabetik sıralama
  // pratikte "yeniden eskiye" demektir (gemini-3.1-flash > gemini-2.5-flash).
  int newestFirst(AiModel a, AiModel b) => b.id.compareTo(a.id);
  final ranks = recommended.keys.toList()..sort();
  return [
    for (final rank in ranks) ...(recommended[rank]!..sort(newestFirst)),
    ...others..sort(newestFirst),
  ];
}

/// Sağlayıcının `/models` yanıtını `{id: görünen ad}` haritasına indirger.
///
/// Üç ayrı gövde şekli var ve hepsi tek yerde çözülür ki servis kodu
/// sağlayıcıya göre dallanmasın:
/// - Gemini: `{models: [{name: "models/x", displayName, supportedGenerationMethods}]}`
/// - OpenAI/OpenRouter: `{data: [{id, name}]}`
/// - Anthropic: `{data: [{id, display_name}]}`
Map<String, String?> parseModelList(AiProvider provider, Object? body) {
  if (body is! Map) return const {};
  final result = <String, String?>{};
  // Beklenen alan liste DEĞİLSE (sağlayıcı hata gövdesi döndürdüyse) `as
  // List?` dönüşümü istisna atardı; liste olup olmadığı açıkça sınanır.
  List<dynamic> listOf(String field) {
    final value = body[field];
    return value is List ? value : const [];
  }

  if (provider == AiProvider.gemini) {
    for (final raw in listOf('models')) {
      if (raw is! Map) continue;
      // `generateContent` desteklemeyenler (yalnız embedding/sayaç uçları)
      // listeye hiç girmemeli.
      final methods = raw['supportedGenerationMethods'];
      if (methods is! List || !methods.contains('generateContent')) continue;
      final name = (raw['name'] as String? ?? '').replaceFirst('models/', '');
      if (name.isEmpty) continue;
      result[name] = raw['displayName'] as String?;
    }
    return result;
  }
  for (final raw in listOf('data')) {
    if (raw is! Map) continue;
    final id = raw['id'] as String? ?? '';
    if (id.isEmpty) continue;
    result[id] = (raw['display_name'] ?? raw['name']) as String?;
  }
  return result;
}
