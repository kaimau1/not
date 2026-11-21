import '../../../core/utils/attachment_tag.dart';
import '../../../core/utils/spell_engine.dart';
import '../../../core/utils/spell_learn.dart';
import 'note_item.dart';

/// Toplu yazım denetiminde bir bulgunun not içindeki konumu (Y-5, 17K §3.3).
enum SpellReviewTarget { title, body, item }

/// Notun tamamında bulunan tek bir olası yazım yanlışı.
class SpellFinding {
  const SpellFinding({
    required this.id,
    required this.target,
    required this.itemIndex,
    required this.start,
    required this.end,
    required this.word,
    required this.lower,
    required this.suggestions,
    required this.hint,
    required this.before,
    required this.after,
  });

  final int id;
  final SpellReviewTarget target;

  /// [target] == [SpellReviewTarget.item] iken madde dizini; aksi halde -1.
  final int itemIndex;

  /// İlgili alanın mantıksal metnindeki aralık (`[start, end)`).
  final int start;
  final int end;

  /// Kullanıcının yazdığı özgün büyük/küçük harfli biçim.
  final String word;

  /// Küçük harfli anahtar (sözlüğe ekleme / notta yoksayma için).
  final String lower;

  /// Kullanıcının harf düzenine uyarlanmış en çok 3 öneri.
  final List<String> suggestions;

  /// Bağlama bağlı ipucu ("bende" → "ben de"): "Tümünü düzelt" dokunmaz,
  /// kullanıcı tek dokunuşla seçebilir.
  final bool hint;

  /// Bulgunun çevresindeki kısa bağlam parçaları.
  final String before;
  final String after;

  /// "Tümünü düzelt" kapsamına girer mi (kesin önerili, bağlam ipucu değil).
  bool get autoFixable => !hint && suggestions.isNotEmpty;
}

/// Bir notun başlık, gövde ve liste maddelerini tarayıp olası yazım
/// yanlışlarını sırayla döndürür (saf, test edilir).
List<SpellFinding> scanNoteSpellFindings({
  required String title,
  required String body,
  required List<NoteItem> items,
  required SpellMemory memory,
  Set<String> noteKeep = const {},
  List<String> attachmentNames = const [],
}) {
  final out = <SpellFinding>[];
  var nextId = 0;

  void scanText(
    String text,
    SpellReviewTarget target,
    int itemIndex, {
    bool checkTags = false,
  }) {
    if (text.trim().isEmpty) return;
    var base = 0;
    for (final para in text.split('\n')) {
      if (para.isNotEmpty) {
        final tags = checkTags && para.contains(kAttachmentTagPrefix)
            ? findAttachmentTags(para, attachmentNames)
            : const <({int start, int end, String fileName})>[];
        for (final t in SpellEngine.tokens(para)) {
          if (noteKeep.contains(t.word)) continue;
          if (tags.any((g) => g.start < t.end && t.start < g.end)) continue;
          final res = SpellEngine.suggestions(t.word, memory);
          if (res == null) continue;
          final typed = para.substring(t.start, t.end);
          final opts = [
            for (final s in res.list.take(3)) SpellEngine.matchCase(typed, s),
          ];
          final snippet = _contextSnippet(para, t.start, t.end);
          out.add(
            SpellFinding(
              id: nextId++,
              target: target,
              itemIndex: itemIndex,
              start: base + t.start,
              end: base + t.end,
              word: typed,
              lower: t.word,
              suggestions: opts,
              hint: res.hint,
              before: snippet.before,
              after: snippet.after,
            ),
          );
        }
      }
      base += para.length + 1;
    }
  }

  scanText(title, SpellReviewTarget.title, -1);
  scanText(body, SpellReviewTarget.body, -1, checkTags: true);
  for (var i = 0; i < items.length; i++) {
    scanText(items[i].text, SpellReviewTarget.item, i);
  }
  return out;
}

({String before, String after}) _contextSnippet(
  String para,
  int start,
  int end,
) {
  const radius = 24;
  final bStart = (start - radius).clamp(0, start);
  final aEnd = (end + radius).clamp(end, para.length);
  var before = para.substring(bStart, start);
  var after = para.substring(end, aEnd);
  if (bStart > 0) before = '…${before.trimLeft()}';
  if (aEnd < para.length) after = '${after.trimRight()}…';
  return (before: before, after: after);
}

/// Tek bir metinde verilen aralıkları sağdan sola (büyükten küçüğe)
/// değiştirir; önceki konumlar kaymaz.
String applySpellTextFixes(
  String text,
  List<({int start, int end, String replacement})> edits,
) {
  if (edits.isEmpty) return text;
  final sorted = [...edits]..sort((a, b) => b.start.compareTo(a.start));
  var result = text;
  var prevStart = result.length + 1;
  for (final e in sorted) {
    if (e.start < 0 || e.end > result.length || e.start >= e.end) continue;
    if (e.end > prevStart) continue; // Çakışan aralığı koru.
    result = result.replaceRange(e.start, e.end, e.replacement);
    prevStart = e.start;
  }
  return result;
}

/// Seçilen [replacements] (`finding.id → öneri`) haritasını başlık, gövde ve
/// liste maddelerine tek seferde uygular (tek Geri Al adımı için).
({String title, String body, List<NoteItem> items, int count}) applySpellReview({
  required String title,
  required String body,
  required List<NoteItem> items,
  required List<SpellFinding> findings,
  required Map<int, String> replacements,
}) {
  if (replacements.isEmpty) {
    return (title: title, body: body, items: items, count: 0);
  }
  final titleEdits = <({int start, int end, String replacement})>[];
  final bodyEdits = <({int start, int end, String replacement})>[];
  final itemEdits = <int, List<({int start, int end, String replacement})>>{};
  var count = 0;

  for (final f in findings) {
    final to = replacements[f.id];
    if (to == null || to == f.word) continue;
    final edit = (start: f.start, end: f.end, replacement: to);
    switch (f.target) {
      case SpellReviewTarget.title:
        titleEdits.add(edit);
      case SpellReviewTarget.body:
        bodyEdits.add(edit);
      case SpellReviewTarget.item:
        if (f.itemIndex >= 0 && f.itemIndex < items.length) {
          (itemEdits[f.itemIndex] ??= []).add(edit);
        }
    }
    count++;
  }

  final nextTitle = applySpellTextFixes(title, titleEdits);
  final nextBody = applySpellTextFixes(body, bodyEdits);
  final nextItems = itemEdits.isEmpty
      ? items
      : [
          for (var i = 0; i < items.length; i++)
            if (itemEdits[i] case final edits?)
              items[i].copyWith(text: applySpellTextFixes(items[i].text, edits))
            else
              items[i],
        ];
  return (title: nextTitle, body: nextBody, items: nextItems, count: count);
}
