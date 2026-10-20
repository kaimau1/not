import 'package:flutter/material.dart';

import 'text_search.dart';
import 'text_wrap.dart';

/// Not içi canlı aramada taranan bir alan (başlık, gövde, madde).
typedef NoteFindField = ({
  WrapTextController controller,
  FocusNode focus,
  String where,
  IconData icon,
});

/// Bulunan tek eşleşme ve bulunduğu alan.
class NoteFindHit {
  const NoteFindHit({
    required this.controller,
    required this.focus,
    required this.where,
    required this.icon,
    required this.match,
    required this.index,
  });

  final WrapTextController controller;
  final FocusNode focus;
  final String where;
  final IconData icon;
  final TextSearchMatch match;

  /// Parça (snippet) üretmek için alanın arama dizini.
  final TextSearchIndex index;
}

/// Not içi canlı aramanın durumu (F9.3: editörden ayrıldı). Eşleşme ve
/// odak değişince yalnız dinleyenler (arama çubuğu) yeniden çizilir —
/// eskiden aramadaki her harf 9.000 satırlık editörün tamamını kuruyordu.
class NoteFindController extends ChangeNotifier {
  final query = TextEditingController();
  final focus = FocusNode();

  List<NoteFindHit> _hits = const [];
  int _index = -1;

  /// Vurgusu olan alanlar — kapanışta/yeni aramada temizlenir.
  final Set<WrapTextController> _painted = {};

  List<NoteFindHit> get hits => _hits;

  /// Odaktaki eşleşme (-1 = yok).
  int get index => _index;

  NoteFindHit? get current =>
      _index >= 0 && _index < _hits.length ? _hits[_index] : null;

  String get text => query.text.trim();

  /// [fields]da arar. [keepIndex]: düzenleme sonrası tazeleme — odak AYNI
  /// alanda, aynı ya da ilk sonraki eşleşmede kalsın (imleç başa fırlamasın).
  void search(List<NoteFindField> fields, {bool keepIndex = false}) {
    final needle = text;
    final previous = keepIndex ? current : null;
    final hits = <NoteFindHit>[];
    if (needle.isNotEmpty) {
      for (final field in fields) {
        final index = TextSearchIndex(field.controller.text);
        for (final match in index.find(needle)) {
          hits.add(
            NoteFindHit(
              controller: field.controller,
              focus: field.focus,
              where: field.where,
              icon: field.icon,
              match: match,
              index: index,
            ),
          );
        }
      }
    }
    var next = hits.isEmpty ? -1 : 0;
    if (previous != null) {
      final same = hits.indexWhere(
        (h) =>
            h.controller == previous.controller &&
            h.match.start >= previous.match.start,
      );
      if (same >= 0) next = same;
    }
    _hits = hits;
    _index = next;
    notifyListeners();
  }

  /// Odağı [delta] kadar döngüsel kaydırır.
  void step(int delta) {
    final count = _hits.length;
    if (count == 0) return;
    var next = (_index + delta) % count;
    if (next < 0) next += count;
    select(next);
  }

  void select(int index) {
    if (index < 0 || index >= _hits.length || index == _index) return;
    _index = index;
    notifyListeners();
  }

  /// Vurguları alanlara dağıtır (odaktaki eşleşme koyu).
  void paint({required bool dark}) {
    final byController = <WrapTextController, List<(int, int)>>{};
    final currentIn = <WrapTextController, int>{};
    for (var i = 0; i < _hits.length; i++) {
      final hit = _hits[i];
      final list = byController.putIfAbsent(hit.controller, () => []);
      if (i == _index) currentIn[hit.controller] = list.length;
      list.add((hit.match.start, hit.match.end));
    }
    for (final c in _painted.difference(byController.keys.toSet())) {
      c.clearSearchHighlights();
    }
    _painted
      ..clear()
      ..addAll(byController.keys);
    final hitColor = dark ? const Color(0x80C28B00) : const Color(0x66FFD54F);
    final currentColor = dark
        ? const Color(0xFFE65100)
        : const Color(0xFFFFA726);
    for (final entry in byController.entries) {
      entry.key.setSearchHighlights(
        entry.value,
        current: currentIn[entry.key] ?? -1,
        hitColor: hitColor,
        currentColor: currentColor,
      );
    }
  }

  /// Vurguları ve sorguyu siler.
  void reset() {
    for (final c in _painted) {
      c.clearSearchHighlights();
    }
    _painted.clear();
    query.clear();
    if (focus.hasFocus) focus.unfocus();
    _hits = const [];
    _index = -1;
    notifyListeners();
  }

  @override
  void dispose() {
    query.dispose();
    focus.dispose();
    super.dispose();
  }
}
