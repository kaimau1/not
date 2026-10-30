import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/ink_gestures.dart';

/// 2026-10-30 turu: madde jestleri, biçim kapsamı, özel renk işareti,
/// belgesiz belge notu.
void main() {
  List<Offset> line(Offset from, Offset to, {int steps = 20}) => [
    for (var i = 0; i <= steps; i++) Offset.lerp(from, to, i / steps)!,
  ];

  group('classifyInkGesture', () {
    test('yatay çizgi → üstünü çiz', () {
      expect(
        classifyInkGesture(line(const Offset(10, 100), const Offset(200, 104))),
        InkGesture.strike,
      );
    });

    test('✓ → işaret', () {
      final points = [
        ...line(const Offset(10, 100), const Offset(30, 120), steps: 8),
        ...line(const Offset(30, 120), const Offset(80, 60), steps: 16),
      ];
      expect(classifyInkGesture(points), InkGesture.check);
    });

    test('zikzak → karalama', () {
      final points = <Offset>[];
      for (var i = 0; i < 6; i++) {
        points.addAll(
          line(
            Offset(i.isEven ? 10 : 120, 100 + i * 2.0),
            Offset(i.isEven ? 120 : 10, 102 + i * 2.0),
            steps: 8,
          ),
        );
      }
      expect(classifyInkGesture(points), InkGesture.scribble);
    });

    test('halka → daire', () {
      final points = [
        for (var i = 0; i <= 40; i++)
          Offset(
            100 + 80 * math.cos(i / 40 * 2 * math.pi),
            100 + 20 * math.sin(i / 40 * 2 * math.pi),
          ),
      ];
      expect(classifyInkGesture(points), InkGesture.circle);
    });

    test('dokunuş kadar kısa çizgi jest değil', () {
      expect(
        classifyInkGesture(line(const Offset(10, 10), const Offset(14, 12))),
        InkGesture.none,
      );
    });
  });

  group('scopeSelection', () {
    const text = 'ilk satır\nikinci kelime burada\nson';

    test('imleç kipi seçimi değiştirmez', () {
      expect(
        scopeSelection(
          text,
          const TextSelection.collapsed(offset: 12),
          FormatScope.caret,
        ),
        isNull,
      );
    });

    test('kelime', () {
      final s = scopeSelection(
        text,
        const TextSelection.collapsed(offset: 20),
        FormatScope.word,
      )!;
      expect(text.substring(s.start, s.end), 'kelime');
    });

    test('satır', () {
      final s = scopeSelection(
        text,
        const TextSelection.collapsed(offset: 12),
        FormatScope.line,
      )!;
      expect(text.substring(s.start, s.end), 'ikinci kelime burada');
    });

    test('tümü', () {
      final s = scopeSelection(
        text,
        const TextSelection.collapsed(offset: 3),
        FormatScope.all,
      )!;
      expect(s.start, 0);
      expect(s.end, text.length);
    });

    test('dolu seçim olduğu gibi kalır', () {
      expect(
        scopeSelection(
          text,
          const TextSelection(baseOffset: 0, extentOffset: 3),
          FormatScope.line,
        ),
        isNull,
      );
    });
  });

  test('ARGB ondalıklı eski renk işareti okunur, # olarak yazılır', () {
    // Kullanıcı bulgusu: "4290190364:merhaba" ekranda ham görünüyordu.
    const legacy = '%%4290190364:merhaba%%';
    expect(stripRichMarkers(legacy), 'merhaba');
    expect(richIndexToken(0xFFB71C1C), '#B71C1C');
    expect(richIndexToken(3), '3');
  });

  test('belge notunun belgesi kalmadı mı', () {
    const pdf = Attachment(
      id: 'a',
      kind: AttachmentKind.pdf,
      fileName: 'x.pdf',
      mimeType: 'application/pdf',
    );
    const note = Note(id: 'n', type: NoteType.pdf);
    expect(note.hasModeDocument, isFalse);
    expect(note.copyWith(attachments: [pdf]).hasModeDocument, isTrue);
  });
}
