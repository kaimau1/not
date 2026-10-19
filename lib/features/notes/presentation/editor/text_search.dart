import '../../../../core/utils/rich_text.dart';
import '../../../../core/utils/search_fold.dart';

// Katlama artık ortak (F1.8): ana ekran araması, not içi bul ve diğer
// aramalar AYNI kuralı kullanır.
export '../../../../core/utils/search_fold.dart' show foldForSearch;
import 'text_wrap.dart';

/// Bir eşleşme: [start, end) DÜZENLEME TAMPONUNDA (denetleyicinin `text`i —
/// görünmez biçim işaretleri ve sarma çapaları dahil), [visibleStart] ise
/// ekranda okunan metinde.
typedef TextSearchMatch = ({int start, int end, int visibleStart});

/// Bir alanın metninde canlı arama (kullanıcı isteği 2026-09-26: "not içi
/// aramada sayfada canlı aranmalı").
///
/// Aranan şey EKRANDA OKUNAN metindir: biçim işaretleri (`**`, `==2:`) ve
/// sarma çapaları atlanır, yani "**sü**t" içinde "süt" bulunur. Bulunan
/// aralık yine tamponun konumlarıyla döner — vurgu ve kaydırma doğrudan o
/// konumlarla çalışır.
class TextSearchIndex {
  factory TextSearchIndex(String buffer) {
    final offsets = <int>[];
    final visible = StringBuffer();
    for (final (from, to) in visibleRuns(buffer)) {
      for (var i = from; i < to; i++) {
        final unit = buffer.codeUnitAt(i);
        if (isWrapAnchorCode(unit)) continue;
        offsets.add(i);
        visible.writeCharCode(unit);
      }
    }
    final text = visible.toString();
    return TextSearchIndex._(text, foldForSearch(text), offsets);
  }

  TextSearchIndex._(this.visible, this._folded, this._offsets);

  /// Ekranda okunan metin (işaretsiz, çapasız).
  final String visible;
  final String _folded;
  final List<int> _offsets;

  /// [query]nin bütün (çakışmayan) eşleşmeleri, baştan sona.
  List<TextSearchMatch> find(String query) {
    final needle = foldForSearch(query);
    if (needle.isEmpty) return const [];
    final out = <TextSearchMatch>[];
    var from = 0;
    while (true) {
      final at = _folded.indexOf(needle, from);
      if (at < 0) break;
      final last = at + needle.length - 1;
      out.add((
        start: _offsets[at],
        end: _offsets[last] + 1,
        visibleStart: at,
      ));
      from = at + needle.length;
    }
    return out;
  }

  /// Eşleşmenin çevresinden tek satırlık okunur parça (sonuç listesi için).
  /// [before]/[after] eşleşmeden önce/sonra kaç karakter gösterileceği.
  ({String lead, String hit, String tail}) snippet(
    TextSearchMatch match,
    int length, {
    int before = 32,
    int after = 60,
  }) {
    String flat(String s) => s.replaceAll(RegExp(r'\s+'), ' ');
    final start = match.visibleStart;
    final end = (start + length).clamp(start, visible.length);
    final from = (start - before).clamp(0, start);
    final to = (end + after).clamp(end, visible.length);
    return (
      lead: '${from > 0 ? '…' : ''}${flat(visible.substring(from, start)).trimLeft()}',
      hit: flat(visible.substring(start, end)),
      tail: '${flat(visible.substring(end, to)).trimRight()}${to < visible.length ? '…' : ''}',
    );
  }
}
