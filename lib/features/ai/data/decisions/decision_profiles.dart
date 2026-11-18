// Karar profilleri (plan §4.2, §3B): her profil = girdi metni + soru şeması
// (build) + iki eşikli yorum (interpret). Saf Dart, ağsız test edilir.
// EŞİKLER BAŞLANGIÇ DEĞERİ (plan §3B); Türkçe altın set ölçülmeden
// (DA-E0, `tool/ai_altin/decisions_kos_test.dart`) bayrak açılmamalı.
import 'decision_flag.dart';
import 'decision_models.dart';
import 'decision_service.dart';

String _cut(String s, int max) =>
    s.length > max ? s.substring(0, max).trim() : s.trim();

String _key(int i) => i.toString().padLeft(2, '0');

// ── DA-1 Hızlı ekle hedef notu ─────────────────────────────────────────────

abstract final class DropTargetProfile {
  /// Uygula (geri sayımla eklenir).
  static const hi = 0.80;

  /// Bunun altı = eski yol; arası = seçili gelir ama SORULUR.
  static const lo = 0.50;
  static const maxTitles = 40;

  static String input(String text) => 'Kullanıcının cümlesi: "$text"';

  static Map<String, DecisionQuestion> questions(List<String> titles) => {
    'hedef': ChoiceQuestion(
      'Kullanıcı bu cümleyi hangi nota eklenmesi için söyledi? Not adı '
      'cümlenin sonunda ya da başında olabilir; ek, iyelik ve yazım farkı '
      'olabilir ("dosyalara" → "Dosyalarımdaki hatalar"). Hiçbir not '
      'adlandırılmadıysa ya da hiçbiri uymuyorsa a_yok seç.',
      {
        ChoiceQuestion.none: 'Hiçbir not adlandırılmadı ya da hiçbiri uymuyor',
        for (var i = 0; i < titles.length && i < maxTitles; i++)
          'n${_key(i)}': _cut(titles[i], 60),
      },
    ),
  };

  /// [count]: başlık sayısı. Seçim yok/a_yok/düşük güven → `no`.
  static ({int? index, DecisionOutcome outcome}) interpret(
    Map<String, DecisionAnswer> answers,
    int count,
  ) {
    final a = answers['hedef'];
    final c = a?.choice;
    final i = c != null && RegExp(r'^n\d\d$').hasMatch(c)
        ? int.parse(c.substring(1))
        : null;
    if (a == null || i == null || i >= count || a.confidence < lo) {
      return (index: null, outcome: DecisionOutcome.no);
    }
    return (
      index: i,
      outcome: a.confidence >= hi
          ? DecisionOutcome.yes
          : DecisionOutcome.unsure,
    );
  }
}

/// null = karar yok (bayrak kapalı, anahtar yok, hata, zaman aşımı).
Future<({int? index, DecisionOutcome outcome})?> decideDropTarget(
  DecisionService service,
  String text,
  List<String> titles,
) async {
  final count = titles.length.clamp(0, DropTargetProfile.maxTitles);
  if (count == 0) return null;
  final r = await service.decide(
    DecisionFeature.dropTarget,
    input: DropTargetProfile.input(text),
    questions: DropTargetProfile.questions(titles),
  );
  return r == null ? null : DropTargetProfile.interpret(r, count);
}
