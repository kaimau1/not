import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/core/widgets/color_palette.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Renk paleti (kullanıcı isteği 2026-10-20: "renk seçenekleri için palet
/// olsun; aynı palet zemin, çerçeve rengine de gelsin").
void main() {
  group('satır içi özel renk', () {
    const custom = 0xFF1E88E5;

    test('özel renk #RRGGBB önekiyle yazılır ve geri okunur', () {
      final r = toggleFormat(
        'merhaba dünya',
        8,
        13,
        RichFormat.color,
        colorIndex: custom,
      );
      expect(r.text, 'merhaba %%#1E88E5:dünya%%');
      final segs = richSegments(r.text);
      expect(segs.last.text, 'dünya');
      expect(segs.last.mark.color, custom);
      expect(isCustomRichColor(segs.last.mark.color), isTrue);
      expect(stripRichMarkers(r.text), 'merhaba dünya');
    });

    test('vurgu da özel renk alır; palet indeksi bozulmaz', () {
      final r = toggleFormat(
        'abc',
        0,
        3,
        RichFormat.highlight,
        colorIndex: custom,
      );
      expect(r.text, '==#1E88E5:abc==');
      expect(richSegments('==2:abc==').single.mark.highlight, 2);
      expect(isCustomRichColor(2), isFalse);
    });

    test('özel renk palet rengiyle değiştirilebilir', () {
      final r = toggleFormat(
        '%%#1E88E5:abc%%',
        0,
        15,
        RichFormat.color,
        colorIndex: 3,
      );
      expect(stripRichMarkers(r.text), 'abc');
      expect(richSegments(r.text).single.mark.color, 3);
    });
  });

  group('not zemini/çerçevesi özel renk', () {
    test('toMap/fromMap gidiş-dönüş; null da yazılır (merge temizlesin)', () {
      const note = Note(
        id: 'n',
        type: NoteType.text,
        customColor: 0xFFFFD54F,
        customFrameColor: 0xFF5E35B1,
      );
      final map = note.toMap();
      expect(map['customColor'], 0xFFFFD54F);
      // Sunucu zaman damgaları (FieldValue) okuma yoluna girmez.
      final back = Note.fromMap(
        'n',
        Map.of(map)..removeWhere((_, v) => v is FieldValue),
      );
      expect(back.customColor, 0xFFFFD54F);
      expect(back.customFrameColor, 0xFF5E35B1);
      expect(back.hasFrame, isTrue);
      final cleared = back.copyWith(clearCustomColor: true);
      expect(cleared.toMap().containsKey('customColor'), isTrue);
      expect(cleared.toMap()['customColor'], isNull);
    });
  });

  testWidgets('palet: hazır ton ve özel renk seçilir', (tester) async {
    Color? picked;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ColorPalette(title: 'Renk', onPick: (c) => picked = c),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(ValueKey('palette-${kPaletteColors[9].toARGB32()}')),
    );
    expect(picked, kPaletteColors[9]);
    await tester.tap(find.byKey(const ValueKey('palette-custom-use')));
    expect(picked, isNotNull);
    expect(picked!.a, 1.0);
  });
}
