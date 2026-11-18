// Gemini Decisions API (`POST /v1beta/decisions`, `gemini-decision-1`) için
// saf modeller: soru şeması ve SAVUNMACI yanıt ayrıştırma. Plan:
// `docs/plan_decisions_api.md` §1.3–§1.4, §4.2. API bir haftalık ve v1beta;
// alanlar canlı doğrulanmadı (DA-E0) → bilinmeyen alan yok sayılır, eksik ya
// da bozuk yanıt "karar yok" (null) olur, asla istisna atmaz.

/// Bir soru. Model YALNIZ [instructions]'ı görür, soru anahtarını görmez.
sealed class DecisionQuestion {
  const DecisionQuestion(this.instructions);

  final String instructions;

  Map<String, Object?> toJson();
}

/// Evet/hayır; yanıt evet olasılığı (`noul`, [0.01, 0.99]'a kırpılı).
class NoulQuestion extends DecisionQuestion {
  const NoulQuestion(super.instructions, {this.ifTrue, this.ifFalse});

  final String? ifTrue;
  final String? ifFalse;

  @override
  Map<String, Object?> toJson() => {
    'type': 'noul',
    'instructions': instructions,
    if (ifTrue != null && ifFalse != null)
      'criteria': {'true_description': ifTrue, 'false_description': ifFalse},
  };
}

/// Seçeneklerden biri. Model HER ZAMAN bir seçenek seçer → çağıran "hiçbiri"
/// seçeneğini ([none], alfabetik İLK: tam eşitlikte o kazanır) eklemeli.
class ChoiceQuestion extends DecisionQuestion {
  const ChoiceQuestion(super.instructions, this.options);

  /// kimlik → açıklama (2–255 seçenek).
  final Map<String, String> options;

  static const none = 'a_yok';

  @override
  Map<String, Object?> toJson() => {
    'type': 'choice',
    'instructions': instructions,
    'criteria': options,
  };
}

/// Alçaktan yükseğe sıralı düzeyler; yanıt 0..K-1 arası kesirli ortalama.
class ScoreQuestion extends DecisionQuestion {
  const ScoreQuestion(super.instructions, this.levels);

  final List<String> levels;

  @override
  Map<String, Object?> toJson() => {
    'type': 'score',
    'instructions': instructions,
    'criteria': levels,
  };
}

/// Tek sorunun yanıtı. [confidence] her zaman [0, 1].
class DecisionAnswer {
  const DecisionAnswer({
    required this.type,
    required this.confidence,
    this.noul,
    this.choice,
    this.score,
    this.probabilities = const {},
  });

  final String type;
  final double confidence;

  /// `noul`: evet olasılığı.
  final double? noul;

  /// `choice`: seçilen kimlik.
  final String? choice;

  /// `score`: olasılık ağırlıklı ortalama düzey.
  final double? score;

  /// `choice`: kimlik → olasılık; `score`: düzey sırası ('0', '1'…) →
  /// olasılık (biçim doğrulanmadı: nesne de dizi de kabul).
  final Map<String, double> probabilities;
}

double? _num(Object? v) {
  final d = v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);
  if (d == null || d.isNaN || d.isInfinite) return null;
  return d;
}

double _unit(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// `probabilities`: `{"n00": 0.9}`, `[0.1, 0.9]` ya da
/// `[{"option"|"label"|"choice"|"level": .., "probability": ..}]`.
Map<String, double> _probabilities(Object? raw) {
  final out = <String, double>{};
  if (raw is Map) {
    raw.forEach((k, v) {
      final p = _num(v);
      if (p != null) out['$k'] = _unit(p);
    });
  } else if (raw is List) {
    for (var i = 0; i < raw.length; i++) {
      final e = raw[i];
      if (e is Map) {
        final key = e['option'] ?? e['label'] ?? e['choice'] ?? e['level'];
        final p = _num(e['probability'] ?? e['p']);
        if (p != null) out['${key ?? i}'] = _unit(p);
      } else {
        final p = _num(e);
        if (p != null) out['$i'] = _unit(p);
      }
    }
  }
  return out;
}

/// Tek yanıt nesnesi; tanınmayan ya da değersiz yanıt null.
DecisionAnswer? parseDecisionAnswer(Object? raw, {String? expectType}) {
  if (raw is! Map) return null;
  final type = (raw['type'] as Object?)?.toString() ?? expectType ?? '';
  final probs = _probabilities(raw['probabilities']);
  final conf = _num(raw['confidence']);
  switch (type) {
    case 'noul':
      final p = _num(raw['noul']);
      if (p == null) return null;
      final v = _unit(p);
      return DecisionAnswer(
        type: type,
        noul: v,
        confidence: _unit(conf ?? (v > 0.5 ? v : 1 - v)),
      );
    case 'choice':
      final c = raw['choice'];
      if (c is! String || c.isEmpty) return null;
      final pc = conf ?? probs[c];
      if (pc == null) return null;
      return DecisionAnswer(
        type: type,
        choice: c,
        probabilities: probs,
        confidence: _unit(pc),
      );
    case 'score':
      final s = _num(raw['score']);
      if (s == null) return null;
      return DecisionAnswer(
        type: type,
        score: s,
        probabilities: probs,
        confidence: _unit(
          conf ??
              (probs.isEmpty
                  ? 0
                  : probs.values.reduce((a, b) => a > b ? a : b)),
        ),
      );
  }
  return null;
}

/// Tüm yanıt gövdesi → soru anahtarı → yanıt. Yalnız [questions]'ta olan
/// anahtarlar alınır (beklenen tür yanıtta yoksa sorudan). Bozuk gövde boş.
Map<String, DecisionAnswer> parseDecisionResponse(
  Object? body,
  Map<String, DecisionQuestion> questions,
) {
  final answers = body is Map ? body['answers'] : null;
  if (answers is! Map) return const {};
  final out = <String, DecisionAnswer>{};
  for (final e in questions.entries) {
    final a = parseDecisionAnswer(
      answers[e.key],
      expectType: switch (e.value) {
        NoulQuestion() => 'noul',
        ChoiceQuestion() => 'choice',
        ScoreQuestion() => 'score',
      },
    );
    if (a != null) out[e.key] = a;
  }
  return out;
}

/// İki eşikli karar (K4): eşik uygulamaya aittir, API olasılık verir.
enum DecisionOutcome { yes, no, unsure }

/// `noul >= hi` → evet; `<= lo` → hayır; arası emin değil. Yanıt yoksa null.
DecisionOutcome? noulOutcome(
  DecisionAnswer? a, {
  required double hi,
  required double lo,
}) {
  final p = a?.noul;
  if (p == null) return null;
  if (p >= hi) return DecisionOutcome.yes;
  if (p <= lo) return DecisionOutcome.no;
  return DecisionOutcome.unsure;
}

/// Soru anahtarı kuralı: `[A-Za-z0-9_-]+`, ≤ 64 karakter.
final decisionKeyPattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');
