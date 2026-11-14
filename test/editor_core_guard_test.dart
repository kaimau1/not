import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// EDİTÖR ÇEKİRDEĞİ BEKÇİSİ (P20 adım 6, OTURTMA F64.5). Kural
/// (`docs/hafiza/editor.md`): editöre yeni görünür parça = `NoteSlice` ya da
/// kendi notifier'ını dinleyen ayrı widget; `_NoteEditorScreenState`'e
/// alan/`_update` eklenmez. Sayılar yalnız DÜŞER.
void main() {
  const dir = 'lib/features/notes/presentation/editor';
  final screen = File('$dir/note_editor_screen.dart').readAsStringSync();

  test('note_editor_*.dart içindeki _update( satırı artmaz', () {
    var lines = 0;
    for (final f in Directory(dir).listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (!name.startsWith('note_editor_') || !name.endsWith('.dart')) {
        continue;
      }
      lines += f.readAsLinesSync().where((l) => l.contains('_update(')).length;
    }
    expect(lines, lessThanOrEqualTo(32), reason: 'kök setState yolu arttı');
  });

  test('_sameVisual karşılaştırma sayısı artmaz (M6: daraldı)', () {
    final start = screen.indexOf('static bool _sameVisual(');
    expect(start, isNot(-1));
    final end = screen.indexOf(
      ';\n',
      screen.indexOf('isBlankText(a.body) == isBlankText(b.body)', start),
    );
    final terms = '&&'.allMatches(screen.substring(start, end)).length + 1;
    // 34 → 32 (P20 adım 4: pinned/starred NoteSlice'a geçti).
    expect(terms, lessThanOrEqualTo(32));
  });

  test('note.starred / note.pinned yalnız NoteSlice içinde', () {
    // Dilimin seçicisi `(n) => n.starred` yazar; kökün yerel `note`'u
    // kurulmadığı için bayattır — build'de okunmamalı.
    expect(RegExp(r'\bnote\.(starred|pinned)\b').hasMatch(screen), isFalse);
    expect(
      RegExp(r'select: \(n\) => n\.(starred|pinned)').allMatches(screen).length,
      2,
    );
  });
}
