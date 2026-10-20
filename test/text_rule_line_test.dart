import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';

/// Düz metinde tek başına `---` satırı çizgi olarak çizilir (D2).
void main() {
  List<TextSpan> flat(List<InlineSpan> spans) => [
    for (final s in spans)
      if (s is TextSpan) ...[
        if (s.text != null) s,
        ...flat(s.children ?? const []),
      ],
  ];

  test('--- satırı üstü çizili saydam tire; metin uzunluğu korunur', () {
    const text = 'üst\n---\n**alt**';
    final spans = flat(
      richSpans(
        text,
        const TextStyle(fontSize: 16, color: Colors.black),
        palette: const [Colors.red],
        markerColor: Colors.transparent,
      ),
    );
    final rule = spans.firstWhere((s) => s.text == '---');
    expect(rule.style?.decoration, TextDecoration.lineThrough);
    expect(rule.style?.color?.a, 0);
    expect(spans.map((s) => s.text).join(), text);
  });

  test('satır içindeki --- çizgi sayılmaz', () {
    final spans = flat(
      richSpans(
        'a --- b',
        null,
        palette: const [Colors.red],
        markerColor: Colors.transparent,
      ),
    );
    expect(
      spans.any((s) => s.style?.decoration == TextDecoration.lineThrough),
      isFalse,
    );
  });
}
