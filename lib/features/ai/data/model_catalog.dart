import 'ai_provider.dart';

/// Modelin NE İŞE yaradığı.
///
/// KÖK NEDEN (kullanıcı bulgusu 2026-08-09: "gemini TTS'den okuma çalışmıyor,
/// ayrıca başka modeller olmasına rağmen listede eksik gösteriliyor"):
/// katalog kurulurken sohbete uygun OLMAYAN her model listeden büsbütün
/// ATILIYORDU. Seslendirme modelleri de o elemeye takılıyordu (`tts`), yani
/// "Seslendirme modeli" seçicisi katalogdan HİÇBİR ŞEY bulamıyor ve iki
/// sabit önizleme kimliğine düşüyordu; o kimlikler kullanıcının anahtarında
/// yoksa istek 404 dönüyor ve seslendirme hiç çalışmıyordu. Model artık
/// atılmıyor, SINIFLANDIRILIYOR: her seçici kendi türünü süzüyor.
enum AiModelKind {
  /// Metin/görsel işleri (sohbet, özet, başlık…).
  chat,

  /// Seslendirme (TTS).
  tts,

  /// Uygulamanın hiçbir yolunda kullanılmayan modeller (embedding, görsel
  /// üretimi, canlı ses…). Listede gizli durur; "Tümünü göster" açılırsa
  /// görünür — kullanıcı sağlayıcısında ne varsa görebilmeli.
  other,
}

/// Sağlayıcıdan çekilen tek bir model.
class AiModel {
  const AiModel({
    required this.id,
    required this.label,
    this.recommended = false,
    this.note,
    this.kind = AiModelKind.chat,
  });

  /// API'ye gönderilen kimlik (ör. `gemini-3.1-flash`, `openai/gpt-5-mini`).
  final String id;

  /// Ekranda görünen ad — sağlayıcı bir görünen ad verdiyse o, yoksa [id].
  final String label;

  /// "Not uygulaması için yeterli" mi? Ayarlarda ÖNERİLEN rozetiyle çıkar.
  final bool recommended;

  /// Rozetin altındaki tek satırlık gerekçe ("hızlı ve ucuz", "ücretsiz"...).
  final String? note;

  /// Modelin türü — hangi seçicide görüneceğini belirler.
  final AiModelKind kind;

  @override
  bool operator ==(Object other) =>
      other is AiModel &&
      other.id == id &&
      other.label == label &&
      other.recommended == recommended &&
      other.note == note &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(id, label, recommended, note, kind);

  @override
  String toString() => 'AiModel($id, recommended: $recommended)';
}

/// SESLENDİRME modelleri. Ayrı desen: bunlar "sohbete uygun değil" ama
/// uygulamanın SES yolunda birinci sınıf vatandaş.
final RegExp _ttsPattern = RegExp(
  r'tts|text-to-speech',
  caseSensitive: false,
);

/// Sohbete uygun OLMAYAN modeller — her sağlayıcıda ortak.
///
/// Sağlayıcıların `/models` uç noktaları sohbet dışı her şeyi de döndürüyor
/// (embedding, konuşma tanıma, görsel üretimi, moderasyon, canlı ses).
/// Metin seçicisinde "gemini-embedding-001" seçip her AI özelliğini bozmak
/// mümkün olmasın diye bunlar [AiModelKind.other] işaretlenir ve seçicide
/// varsayılan olarak GİZLENİR (silinmez — "Tümünü göster" ile görünür).
/// Desenler dar tutuldu ki sohbet modellerini yanlışlıkla yutmasın
/// (ör. `audio` var ama `auto` yok).
final RegExp _notForChat = RegExp(
  r'embed|embedding|whisper|transcribe|moderation|'
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
/// (yoksa null). Dönen liste: önce ÖNERİLEN sohbet modelleri (desen sırasına
/// göre, aynı desen içinde yeniden eskiye), sonra kalan sohbet modelleri,
/// sonra SESLENDİRME modelleri, en sonda uygulamanın kullanmadığı modeller.
///
/// **Hiçbir model ATILMAZ** — sınıflandırılır (bkz. [AiModelKind]). Çağıran
/// kendi türünü süzer; kullanıcı "Tümünü göster" derse gerisi de görünür.
List<AiModel> rankModels(AiProvider provider, Map<String, String?> raw) {
  final patterns = _recommendations[provider] ?? const [];
  final recommended = <int, List<AiModel>>{};
  final chat = <AiModel>[];
  final tts = <AiModel>[];
  final other = <AiModel>[];

  for (final entry in raw.entries) {
    final id = entry.key.trim();
    if (id.isEmpty) continue;
    final label = (entry.value ?? '').trim();
    final kind = _ttsPattern.hasMatch(id)
        ? AiModelKind.tts
        : _notForChat.hasMatch(id)
        ? AiModelKind.other
        : AiModelKind.chat;
    // Öneri rozeti yalnız SOHBET modellerinde anlamlı: desenler
    // ("flash", "mini") ses ve embedding kimliklerine de çarpabiliyor.
    var rank = -1;
    String? note;
    if (kind == AiModelKind.chat) {
      for (var i = 0; i < patterns.length; i++) {
        if (RegExp(patterns[i].$1, caseSensitive: false).hasMatch(id)) {
          rank = i;
          note = patterns[i].$2;
          break;
        }
      }
    }
    final model = AiModel(
      id: id,
      label: label.isEmpty ? id : label,
      recommended: rank >= 0,
      note: note,
      kind: kind,
    );
    switch (kind) {
      case AiModelKind.tts:
        tts.add(model);
      case AiModelKind.other:
        other.add(model);
      case AiModelKind.chat:
        if (rank >= 0) {
          (recommended[rank] ??= []).add(model);
        } else {
          chat.add(model);
        }
    }
  }

  // Sürüm numarası kimliğin içinde olduğundan ters alfabetik sıralama
  // pratikte "yeniden eskiye" demektir (gemini-3.1-flash > gemini-2.5-flash).
  int newestFirst(AiModel a, AiModel b) => b.id.compareTo(a.id);
  final ranks = recommended.keys.toList()..sort();
  return [
    for (final rank in ranks) ...(recommended[rank]!..sort(newestFirst)),
    ...chat..sort(newestFirst),
    ...tts..sort(newestFirst),
    ...other..sort(newestFirst),
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
      final name = (raw['name'] as String? ?? '').replaceFirst('models/', '');
      if (name.isEmpty) continue;
      // `generateContent` desteklemeyenler (yalnız embedding/sayaç uçları)
      // listeye girmemeli. SESLENDİRME modelleri istisna: bazı sürümlerde bu
      // alanı bildirmiyorlar ama `generateContent` ile ses üretiyorlar —
      // eleseydik seslendirme seçicisi yine boş kalırdı.
      final methods = raw['supportedGenerationMethods'];
      final generates = methods is List && methods.contains('generateContent');
      if (!generates && !_ttsPattern.hasMatch(name)) continue;
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
