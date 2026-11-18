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

// ── DA-2 Sessiz düzen: tek çağrı, yalnız ÖNERİ ─────────────────────────────

class TriageSuggestion {
  const TriageSuggestion({
    this.tags = const [],
    this.folderId,
    this.needsTitle = false,
    this.needsReminder = false,
  });

  final List<String> tags;
  final String? folderId;
  final bool needsTitle;
  final bool needsReminder;

  bool get isEmpty =>
      tags.isEmpty && folderId == null && !needsTitle && !needsReminder;
}

abstract final class NoteTriageProfile {
  /// Etiket çipi önerisi (plan DA-2: `noul >= 0,70`).
  static const tagHi = 0.70;
  static const otherHi = 0.75;
  static const maxTags = 30;
  static const maxFolders = 30;
  static const inputChars = 4000;

  static String input(String title, String text) =>
      'Not başlığı: ${title.trim().isEmpty ? '(yok)' : _cut(title, 80)}\n'
      'Not içeriği:\n${_cut(text, inputChars)}';

  /// [tags]: kullanıcının KENDİ etiketleri (yeni etiket üretilmez);
  /// [folders]: kimlik → ad (ORTAK/gizli klasör çağıran tarafından çıkarılır).
  static Map<String, DecisionQuestion> questions({
    required List<String> tags,
    required Map<String, String> folders,
    required bool hasTitle,
  }) {
    final fl = folders.entries.take(maxFolders).toList();
    return {
      for (var i = 0; i < tags.length && i < maxTags; i++)
        't${_key(i)}': NoulQuestion(
          'Bu not "#${tags[i]}" etiketiyle etiketlenmeye uygun mu? Etiket '
          'notun asıl konusunu anlatıyorsa evet.',
        ),
      if (fl.isNotEmpty)
        'klasor': ChoiceQuestion(
          'Bu not hangi klasöre en uygun? Uygun klasör yoksa a_yok seç.',
          {
            ChoiceQuestion.none: 'Uygun klasör yok',
            for (var i = 0; i < fl.length; i++)
              'f${_key(i)}': _cut(fl[i].value, 60),
          },
        ),
      if (!hasTitle)
        'baslik_gerekli': const NoulQuestion(
          'Notun ilk satırı kısa bir başlık işi görmüyor mu; nota ayrıca '
          'başlık yazmak gerekir mi?',
        ),
      'hatirlatici': const NoulQuestion(
        'Notta belirli bir tarih ya da saate bağlı, hatırlatılması gereken '
        'bir iş var mı?',
      ),
    };
  }

  static TriageSuggestion interpret(
    Map<String, DecisionAnswer> answers, {
    required List<String> tags,
    required Map<String, String> folders,
  }) {
    final scored = <(String, double)>[
      for (var i = 0; i < tags.length && i < maxTags; i++)
        if ((answers['t${_key(i)}']?.noul ?? 0) >= tagHi)
          (tags[i], answers['t${_key(i)}']!.noul!),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final f = answers['klasor'];
    final ids = folders.keys.take(maxFolders).toList();
    final fc = f?.choice;
    final fi = fc != null && RegExp(r'^f\d\d$').hasMatch(fc)
        ? int.parse(fc.substring(1))
        : null;
    return TriageSuggestion(
      tags: [for (final s in scored.take(3)) s.$1],
      folderId: fi != null && fi < ids.length && f!.confidence >= otherHi
          ? ids[fi]
          : null,
      needsTitle: (answers['baslik_gerekli']?.noul ?? 0) >= otherHi,
      needsReminder: (answers['hatirlatici']?.noul ?? 0) >= otherHi,
    );
  }
}

Future<TriageSuggestion?> decideNoteTriage(
  DecisionService service, {
  required String title,
  required String text,
  required List<String> tags,
  required Map<String, String> folders,
}) async {
  if (text.trim().length < 20) return null;
  final r = await service.decide(
    DecisionFeature.noteTriage,
    input: NoteTriageProfile.input(title, text),
    questions: NoteTriageProfile.questions(
      tags: tags,
      folders: folders,
      hasTitle: title.trim().isNotEmpty,
    ),
  );
  return r == null
      ? null
      : NoteTriageProfile.interpret(r, tags: tags, folders: folders);
}

// ── DA-13 Başlık doğrulama ─────────────────────────────────────────────────

abstract final class TitleOkProfile {
  static const okHi = 0.75;
  static const okLo = 0.40;
  static const genericHi = 0.70;
  static const inputChars = 600;

  static String input(String title, String text) =>
      'Başlık: $title\nNot içeriği:\n${_cut(text, inputChars)}';

  static const questions = <String, DecisionQuestion>{
    'baslik_uygun': NoulQuestion(
      'Yukarıdaki başlık, notun içeriğini kısa ve doğru anlatıyor mu?',
      ifTrue:
          'Başlık notun asıl konusunu söylüyor; yanıltıcı ya da alakasız '
          'değil',
      ifFalse:
          'Başlık ilgisiz, yanıltıcı, dosya adı gibi anlamsız ya da '
          'içeriğin yalnız küçük bir parçası',
    ),
    'baslik_cok_genel': NoulQuestion(
      'Başlık çok genel mi (Not, Liste, Yeni not, Taslak, Belge gibi)?',
    ),
  };

  /// `no` = yeniden üret; `yes` = kabul; `unsure` = dokunma.
  static DecisionOutcome? interpret(Map<String, DecisionAnswer> answers) {
    final ok = answers['baslik_uygun']?.noul;
    final generic = answers['baslik_cok_genel']?.noul;
    if (ok == null) return null;
    if (ok <= okLo || (generic ?? 0) >= genericHi) return DecisionOutcome.no;
    if (ok >= okHi && (generic ?? 0) < 0.5) return DecisionOutcome.yes;
    return DecisionOutcome.unsure;
  }
}

Future<DecisionOutcome?> decideTitleOk(
  DecisionService service,
  String title,
  String text,
) async {
  if (title.trim().isEmpty || text.trim().isEmpty) return null;
  final r = await service.decide(
    DecisionFeature.titleOk,
    input: TitleOkProfile.input(title, text),
    questions: TitleOkProfile.questions,
  );
  return r == null ? null : TitleOkProfile.interpret(r);
}

/// AI başlığını üretir, DA-13 ile doğrular; Decisions "yanlış/genel" derse
/// [generate] BİR kez daha (reddedilen başlık [avoid] ile) çağrılır.
/// Gölge kipte karar yalnız günlüğe gider, ilk başlık döner. Elle yazılan
/// başlık buraya GELMEZ (K5): çağıranlar yalnız AI başlığı üretirken çağırır.
Future<String> checkedTitle(
  DecisionService service,
  String text,
  Future<String> Function({String? avoid}) generate,
) async {
  final first = await generate();
  final mode = service.modeOf(DecisionFeature.titleOk);
  if (first.isEmpty || mode == DecisionMode.off) return first;
  final verdict = await decideTitleOk(service, first, text);
  if (mode == DecisionMode.shadow) {
    DecisionService.logShadow(
      DecisionFeature.titleOk,
      'verdict=${verdict?.name ?? 'none'}',
    );
    return first;
  }
  if (verdict != DecisionOutcome.no) return first;
  final again = await generate(avoid: first);
  return again.isEmpty ? first : again;
}
