import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/ink_plan.dart';

InkStroke _s(double y, {int page = 1, int seed = 0, int n = 20}) => InkStroke(
  page: page,
  color: 0xFF000000 + seed,
  width: 0.004,
  points: [
    for (var i = 0; i < n; i++) ...[0.1 + i * 0.002, y + (i % 3) * 0.001],
  ],
);

/// Kaydedilmiş hâli taklit et: planla → çöz (yüklenen çizgiler kayıttaki
/// z'lerini taşır).
List<InkStroke> _load(Map<String, Uint8List> docs, InkOrder order) =>
    mergeInkDocs(docs.values, order);

Set<String> _changed(Map<String, Uint8List> a, Map<String, Uint8List> b) => {
  for (final k in {...a.keys, ...b.keys})
    if (a[k] == null || b[k] == null || !listEquals(a[k], b[k])) k,
};

void main() {
  // Üç bantlı uzun sayfa: y 0.2, 1.4, 2.6 …
  List<InkStroke> sample() => [
    for (var i = 0; i < 30; i++) _s((i % 3) * 1.2 + 0.2, seed: i),
  ];

  test('merge(plan(x)) == x, sıra dahil', () {
    final x = sample();
    final order = InkOrder();
    final docs = planInkDocs(surface: 'a1', strokes: x, order: order);
    expect(docs.keys.toSet(), {'a1~1~0', 'a1~1~1', 'a1~1~2'});
    final back = _load(docs, InkOrder());
    expect(back.length, x.length);
    for (var i = 0; i < x.length; i++) {
      expect(back[i].color, x[i].color);
    }
  });

  group('yalnız değişen bant', () {
    late InkOrder order;
    late List<InkStroke> loaded;
    late Map<String, Uint8List> before;
    setUp(() {
      order = InkOrder();
      final first = planInkDocs(surface: 'a', strokes: sample(), order: order);
      order = InkOrder();
      loaded = _load(first, order);
      before = planInkDocs(surface: 'a', strokes: loaded, order: order);
      expect(_changed(first, before), isEmpty);
    });

    test('sona çizgi eklemek 1 belge değiştirir', () {
      final after = planInkDocs(
        surface: 'a',
        strokes: [...loaded, _s(1.5, seed: 99)],
        order: order,
      );
      expect(_changed(before, after), {'a~1~1'});
    });

    test('ortadan silmek yalnız o bandı değiştirir', () {
      final after = planInkDocs(
        surface: 'a',
        strokes: [...loaded]..removeAt(10), // y 1.4 → bant 1
        order: order,
      );
      expect(_changed(before, after), {'a~1~1'});
    });

    test('taşıma eski ve yeni bandı değiştirir', () {
      final moved = loaded[0]; // bant 0
      final list = [...loaded];
      list[0] = moved.copyWith(
        points: [
          for (var i = 0; i < moved.points.length; i++)
            moved.points[i] + (i.isOdd ? 2.4 : 0),
        ],
      );
      final after = planInkDocs(surface: 'a', strokes: list, order: order);
      expect(_changed(before, after), {'a~1~0', 'a~1~2'});
      // Sıra korunur: taşınan çizgi hâlâ ilk.
      expect(_load(after, InkOrder()).first.color, moved.color);
    });

    test('yerinde değiştirme çizim sırasını korur', () {
      final list = [...loaded];
      list[13] = _s(1.45, seed: 500); // bant 1, 13. sıra
      final after = planInkDocs(surface: 'a', strokes: list, order: order);
      expect(_changed(before, after), {'a~1~1'});
      final back = _load(after, InkOrder());
      expect(back[13].color, 0xFF000000 + 500);
      expect(back.map((s) => s.color).toList(), list.map((s) => s.color));
    });
  });

  test('20 000 çizgi → hiçbir belge 256 KB üstü değil, sıra korunur', () {
    final x = [for (var i = 0; i < 20000; i++) _s(0.5, seed: i, n: 40)];
    final docs = planInkDocs(surface: 'p', strokes: x, order: InkOrder());
    expect(docs.length, greaterThan(1));
    for (final d in docs.values) {
      expect(d.length, lessThanOrEqualTo(kInkDocMaxBytes));
    }
    final back = _load(docs, InkOrder());
    expect(back.length, 20000);
    expect(back.last.color, x.last.color);
  });

  test('aynı yere çok ekleme: z yine kesin artan', () {
    final order = InkOrder();
    var list = [_s(0.1, seed: 1), _s(0.1, seed: 2)];
    planInkDocs(surface: 'a', strokes: list, order: order);
    for (var i = 0; i < 80; i++) {
      list = [list.first, _s(0.1, seed: 100 + i), ...list.skip(1)];
      planInkDocs(surface: 'a', strokes: list, order: order);
    }
    final z = order.assign(list);
    for (var i = 1; i < z.length; i++) {
      expect(z[i], greaterThan(z[i - 1]));
    }
  });
}
