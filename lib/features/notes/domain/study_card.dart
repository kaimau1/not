import 'package:cloud_firestore/cloud_firestore.dart';

/// **Aralıklı tekrar kartı** (F18.19, 2026-11-02; kullanıcı kararı: basit
/// sürüm — kartlar NOTUN alanında, SM-2, "Bugünün kartları" Yapay zekâ
/// ekranından). Nottan yapay zekâyla soru–cevap olarak üretilir.
class StudyCard {
  const StudyCard({
    required this.id,
    required this.question,
    required this.answer,
    this.ease = 2.5,
    this.interval = 0,
    this.reps = 0,
    this.due,
  });

  final String id;
  final String question;
  final String answer;

  /// SM-2 kolaylık katsayısı (en az 1.3).
  final double ease;

  /// Gün cinsinden sonraki aralık.
  final int interval;

  /// Art arda doğru tekrar sayısı.
  final int reps;

  /// Sonraki tekrar günü; null = yeni kart (bugün görünür).
  final DateTime? due;

  bool isDue(DateTime now) => due == null || !due!.isAfter(now);

  factory StudyCard.fromMap(Map<String, dynamic> m) => StudyCard(
    id: m['id'] as String? ?? '',
    question: m['q'] as String? ?? '',
    answer: m['a'] as String? ?? '',
    ease: (m['ef'] as num?)?.toDouble() ?? 2.5,
    interval: (m['iv'] as num?)?.toInt() ?? 0,
    reps: (m['n'] as num?)?.toInt() ?? 0,
    due: (m['due'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'q': question,
    'a': answer,
    'ef': ease,
    'iv': interval,
    'n': reps,
    if (due != null) 'due': Timestamp.fromDate(due!),
  };

  StudyCard copyWith({double? ease, int? interval, int? reps, DateTime? due}) =>
      StudyCard(
        id: id,
        question: question,
        answer: answer,
        ease: ease ?? this.ease,
        interval: interval ?? this.interval,
        reps: reps ?? this.reps,
        due: due ?? this.due,
      );
}

/// Değerlendirme düğmeleri ve SM-2 notu (0–5).
enum CardGrade {
  again(1),
  hard(3),
  good(4),
  easy(5);

  const CardGrade(this.quality);
  final int quality;
}

/// SM-2 (SuperMemo 2) — saf, birim testli. Yanlışta (q < 3) tekrar sayısı
/// sıfırlanır ve kart YARIN gelir; doğruda aralık 1 → 6 → aralık × EF.
/// Tarih günün başına yuvarlanır: "bugünün kartları" saatten bağımsız.
StudyCard reviewCard(StudyCard card, CardGrade grade, DateTime now) {
  final q = grade.quality;
  var ease = card.ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
  if (ease < 1.3) ease = 1.3;
  int reps;
  int interval;
  if (q < 3) {
    reps = 0;
    interval = 1;
  } else {
    reps = card.reps + 1;
    interval = switch (reps) {
      1 => 1,
      2 => 6,
      _ => (card.interval * ease).round(),
    };
    if (grade == CardGrade.easy && reps <= 2) interval += 2;
  }
  final today = DateTime(now.year, now.month, now.day);
  return card.copyWith(
    ease: ease,
    reps: reps,
    interval: interval,
    due: DateTime(today.year, today.month, today.day + interval),
  );
}
