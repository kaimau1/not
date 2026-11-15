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

// ---------------------------------------------------------------------------
// GÖREV BAŞINA GEMINI SIRASI (kullanıcı isteği 2026-11-15: "model sıralamasını
// baştan yap, otomatik modu ayarla").
//
// KÖK NEDEN: otomatik zincir ve "Önerilen" bölümü `_recommendations`
// desenlerinden geliyordu (`flash-lite` → `flash`, yeniden eskiye). Desen
// kotayı bilmiyor: "Nano Banana 2 Lite" (görüntü modeli, kota 0) ve hesapta
// olmayan "3.1 Flash Lite Preview" de öneriliyordu; zincir de katalogdaki
// HER kimliği (TTS, embedding dahil) sırayla deniyordu. Artık sıra AÇIK bir
// izin listesi.
//
// TEK YER: kotalar zamanla değişir — güncelleme yalnız bu tabloda.
// Kaynak: kullanıcının Google AI Studio ücretsiz katman limit tablosu,
// 2026-11-15 (RPM / TPM / RPD). Kotası 0 olanlar (2 Flash, 2.5/3.1 Pro,
// Gemini 4 Argon/Carbon, Omni, tüm Nano Banana'lar, Lyria, 2.5 Pro TTS,
// Computer Use, Deep Research) ile uygulamaya uymayanlar (Robotics ER,
// Decision, Antigravity) BİLEREK yok: "Tümünü göster" kapalıyken
// görünmezler, otomatik zincir onları hiç denemez.
// ---------------------------------------------------------------------------

/// Otomatik zincirin türü — her görev bunlardan birine eşlenir.
enum ModelChain {
  /// Özet, başlık, etiket, sohbet, brifing (kısa işte Gemma yedeği var).
  general,

  /// Uzun / çok kipli işler: PDF, OCR, podcast anlatısı, çeviri. Gemma YOK
  /// (16K TPM, görsel okumaz).
  long,

  /// Araç çağrılı sesli not asistanı: standart Flash önce (lite boş not
  /// üretebiliyordu — 2026-08 madde 15), lite'lar yedek.
  voice,

  /// Seslendirme (TTS).
  tts,

  /// Yazıya döküm: Transcribe modeli, sonra çok kipli metin modelleri.
  transcribe,
}

/// Tablodaki tek satır.
class ChainEntry {
  const ChainEntry(this.pattern, this.note, {this.shortOnly = false});

  /// Normalize edilmiş kimliğe ya da görünen ada (küçük harf, `-`/`_` →
  /// boşluk) uyan desen. Sonuna ` preview`, ` latest`, sayı gelebilir.
  final String pattern;

  /// Rozetin altındaki gerekçe (kota özeti).
  final String note;

  /// Yalnız kısa, düz metin işlerde denenir (Gemma: 16K TPM; JSON ve görsel
  /// desteklemez).
  final bool shortOnly;
}

const _fl35 = ChainEntry(r'gemini 3\.5 flash lite', 'Günde 500 istek — ana model');
// "3.1 Flash Lite Preview" hesabın tablosunda yok: önizleme eki dışlanır.
const _fl31 = ChainEntry(
  r'gemini 3\.1 flash lite(?! preview)',
  'Günde 500 istek — yedek',
);
const _gemma31 = ChainEntry(
  r'gemma 4 31b( it)?',
  'Günde 14.400 istek — yalnız kısa işler',
  shortOnly: true,
);
const _gemma26 = ChainEntry(
  r'gemma 4 26b( a4b)?( it)?',
  'Günde 14.400 istek — yalnız kısa işler',
  shortOnly: true,
);
const _f38 = ChainEntry(r'gemini 3\.8 flash', 'Günde 20 istek — güçlü');
const _f3 = ChainEntry(r'gemini 3 flash', 'Günde 20 istek');
const _f25 = ChainEntry(r'gemini 2\.5 flash', 'Günde 20 istek');
const _fl25 = ChainEntry(r'gemini 2\.5 flash lite', 'Günde 20 istek');
const _f36 = ChainEntry(r'gemini 3\.6 flash', 'Günde 20 istek — sık doluyor');
const _hydrogen = ChainEntry(
  r'gemini 4 hydrogen',
  'Günde 20 istek — sık doluyor',
);

/// Görev → deneme sırası (2026-11-15).
const geminiChains = <ModelChain, List<ChainEntry>>{
  ModelChain.general: [
    _fl35, _fl31, _gemma31, _gemma26, //
    _f38, _f3, _f25, _fl25, _f36, _hydrogen,
  ],
  ModelChain.long: [_fl35, _fl31, _f38, _f3, _f25, _fl25, _f36, _hydrogen],
  ModelChain.voice: [_f38, _f3, _f25, _fl35, _fl31, _fl25, _f36, _hydrogen],
  ModelChain.tts: [
    ChainEntry(r'gemini 3\.8 flash tts', 'Günde 10 istek'),
    ChainEntry(r'gemini 3\.8 flash lite tts', 'Günde 10 istek'),
    ChainEntry(r'gemini 3\.1 flash tts', 'Günde 10 istek'),
    ChainEntry(r'gemini 2\.5 flash( preview)? tts', 'Günde 10 istek'),
  ],
  ModelChain.transcribe: [
    ChainEntry(r'gemini 3\.5 transcribe', 'Günde 25 istek — yazıya döküm'),
    _fl35, _fl31, _f38, _f3, _f25, _fl25, _f36, _hydrogen,
  ],
};

String _normalize(String s) => s
    .toLowerCase()
    .replaceFirst('models/', '')
    .replaceAll(RegExp(r'[-_\s]+'), ' ')
    .trim();

bool _entryMatches(ChainEntry e, String text) => RegExp(
  '^(?:${e.pattern})(?: preview| latest| \\d+)*\$',
).hasMatch(_normalize(text));

bool _modelMatches(ChainEntry e, AiModel m) =>
    _entryMatches(e, m.id) || _entryMatches(e, m.label);

/// Kimlik [chain]'in bir satırına uyuyor mu? (Katalogsuz — eski seçimlerin
/// göçü için.)
bool chainAccepts(ModelChain chain, String id) =>
    geminiChains[chain]!.any((e) => _entryMatches(e, id));

/// Yalnız kısa işlerde denenecek model mi (Gemma)?
bool isShortOnly(String id) => geminiChains[ModelChain.general]!.any(
  (e) => e.shortOnly && _entryMatches(e, id),
);

/// [catalog]'u [chain]'in sırasına sokar: her satır için katalogdaki EN KISA
/// kimlikli eşleşme (önizlemesiz sürüm önce) — aynı modelin iki kaydı tek
/// satır olur. Dönenler `recommended: true` ve kota notlu. Katalogda olmayan
/// satır atlanır (kimlik UYDURULMAZ).
List<AiModel> orderForChain(ModelChain chain, List<AiModel> catalog) {
  final out = <AiModel>[];
  for (final entry in geminiChains[chain]!) {
    final hits = [
      for (final m in catalog)
        if (_modelMatches(entry, m) && !out.any((o) => o.id == m.id)) m,
    ]..sort((a, b) => a.id.length.compareTo(b.id.length));
    if (hits.isEmpty) continue;
    final m = hits.first;
    out.add(
      AiModel(
        id: m.id,
        label: m.label,
        recommended: true,
        note: entry.note,
        kind: m.kind,
      ),
    );
  }
  return out;
}

/// Aynı görünen adlı kayıtları tekilleştirir (ilk gelen kalır) — sağlayıcı
/// bazı modelleri iki kimlikle döndürüyor ("Nano Banana Pro" ×2).
List<AiModel> dedupeByLabel(Iterable<AiModel> models) {
  final seen = <String>{};
  return [
    for (final m in models)
      if (seen.add(_normalize(m.label))) m,
  ];
}

/// Kota/erişim hatası alan modeli bir süre zincirden çıkarır (bellekte).
///
/// 429 gövdesinde `PerDay` geçiyorsa günlük kota (RPD) dolmuştur: kota
/// Pasifik gece yarısı sıfırlanır, o ana dek atlanır. Diğer 429'lar (RPM)
/// bir dakika atlanır. 404 (model bu hesapta yok) da gün sonuna dek.
class ModelCooldown {
  ModelCooldown({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  final DateTime Function() _now;
  final _until = <String, DateTime>{};

  bool isCooling(String id) {
    final until = _until[id];
    return until != null && _now().isBefore(until);
  }

  void hit(String id, int status, {Object? body}) {
    final now = _now().toUtc();
    final daily = status == 404 || '$body'.contains('PerDay');
    _until[id] = daily
        ? nextPacificMidnight(now)
        : now.add(const Duration(minutes: 1));
  }

  // ponytail: sabit UTC-8; yaz saatinde (PDT) kilit bir saat geç açılır —
  // zararsız, zincirde başka model var.
  static DateTime nextPacificMidnight(DateTime utc) {
    final pacific = utc.toUtc().subtract(const Duration(hours: 8));
    return DateTime.utc(
      pacific.year,
      pacific.month,
      pacific.day + 1,
    ).add(const Duration(hours: 8));
  }
}
