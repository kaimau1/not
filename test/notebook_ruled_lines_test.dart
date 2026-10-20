import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/archive_paper.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/features/notes/presentation/editor/notebook_paper.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

/// Kullanıcı bulgusu 2026-10-20: "defter modunda çizgilerle yazılar düzgün
/// olmalı, şu an üst üste geliyorlar". Çizgiler artık sabit ızgara değil,
/// her metin satırının ALTINDAN çizilir (RuledLines).
void main() {
  group('layoutRuledLines', () {
    test('metin satırlarının altı kesin çizgi; boşluk eşit adımla dolar', () {
      final lines = layoutRuledLines(
        anchors: [20, 40, 100],
        blocked: const [],
        gap: 20,
        bottom: 160,
      );
      // 40 → 100 arası 3 adım: 60 ve 80 eklenir; son metinden sonra 20'de bir.
      expect(lines, [20, 40, 60, 80, 100, 120, 140]);
    });

    test('dolgu çizgisi düğme yazısının içinden geçmez', () {
      final lines = layoutRuledLines(
        anchors: [20, 80],
        blocked: const [(45.0, 75.0)],
        gap: 20,
        bottom: 81,
      );
      // 40 serbest, 60 yazının içinde → atlanır.
      expect(lines, [20, 40, 80]);
    });

    test(
      'ilk metnin üstüne çizgi çekilmez; aynı hizadaki iki alan tek çizgi',
      () {
        final lines = layoutRuledLines(
          anchors: [50, 50.5, 70],
          blocked: const [],
          gap: 20,
          bottom: 71,
        );
        expect(lines, [50, 70]);
      },
    );

    test('metin yoksa sayfa baştan çizgili', () {
      expect(
        layoutRuledLines(
          anchors: const [],
          blocked: const [],
          gap: 25,
          bottom: 80,
        ),
        [25, 50, 75],
      );
    });
  });

  testWidgets('RuledLines: çizgiler alanın her satırının altına oturur', (
    tester,
  ) async {
    const style = TextStyle(fontSize: 16, height: 1.5);
    const line = 24.0;
    final key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: RuledLines(
                key: key,
                gap: line,
                color: Colors.black,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık: büyük punto + üst pay (ızgaraya uymayan yükseklik).
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Text('Başlık', style: TextStyle(fontSize: 26)),
                    ),
                    TextField(
                      controller: TextEditingController(text: 'bir\niki\nüç'),
                      maxLines: null,
                      style: style,
                      strutStyle: wrapStrutStyle(style),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final ruled = tester.renderObject<RenderRuledLines>(find.byKey(key));
    final lines = ruled.computeLines();
    final editable = tester.renderObject<RenderBox>(find.byType(EditableText));
    final top =
        editable.localToGlobal(Offset.zero).dy -
        ruled.localToGlobal(Offset.zero).dy;
    for (var k = 1; k <= 3; k++) {
      expect(
        lines.any((y) => (y - (top + line * k)).abs() < 0.5),
        isTrue,
        reason: '$k. satırın altında çizgi yok: $lines (alan tepesi $top)',
      );
    }
    // Hiçbir çizgi bir metin satırının ORTASINDAN geçmez.
    for (final y in lines) {
      final inside = (y - top) % line;
      if (y > top && y < top + 3 * line) {
        expect(inside < 0.5 || inside > line - 0.5, isTrue, reason: '$y');
      }
    }
  });

  testWidgets(
    'defterde madde listesi: çizgiler eşit aralıklı, yazının içinden geçmez',
    (tester) async {
      const style = TextStyle(fontSize: 16, height: 1.45);
      const gap = 16 * 1.45;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: RuledLines(
                key: key,
                gap: gap,
                color: Colors.black,
                child: ItemsEditor(
                  items: const [
                    NoteItem(id: 'a', text: 'süt'),
                    NoteItem(id: 'b', text: 'ekmek'),
                    NoteItem(id: 'c', text: 'peynir'),
                  ],
                  onChanged: (_) {},
                  showCheckboxes: true,
                  shrinkWrap: true,
                  textStyle: style,
                  paperLines: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ruled = tester.renderObject<RenderRuledLines>(find.byKey(key));
      final origin = ruled.localToGlobal(Offset.zero).dy;
      final lines = ruled.computeLines();
      // Her madde satırının altında çizgi.
      final editables = tester
          .renderObjectList<RenderBox>(find.byType(EditableText))
          .toList();
      expect(editables, hasLength(3));
      for (final e in editables) {
        final bottom = e.localToGlobal(Offset(0, e.size.height)).dy - origin;
        final top = e.localToGlobal(Offset.zero).dy - origin;
        expect(
          lines.any((y) => (y - bottom).abs() < 0.5),
          isTrue,
          reason: 'alt kenar $bottom, çizgiler $lines',
        );
        for (final y in lines) {
          expect(y <= top + 0.5 || y >= bottom - 0.5, isTrue, reason: '$y');
        }
      }
      // Maddeler ARDIŞIK çizgilerde: aralık satır aralığı (kutu 24 dp,
      // satır 23,2 dp — ±%20). "Yeni öğe" düğmesi listenin altında, ölçüm
      // dışında.
      final first = editables.first.localToGlobal(Offset.zero).dy - origin;
      final last =
          editables.last
              .localToGlobal(Offset(0, editables.last.size.height))
              .dy -
          origin;
      final inList = [
        for (final y in lines)
          if (y >= first && y <= last + 0.5) y,
      ];
      for (var i = 1; i < inList.length; i++) {
        expect(
          (inList[i] - inList[i - 1] - gap).abs() < gap * 0.2,
          isTrue,
          reason:
              'aralık ${inList[i] - inList[i - 1]} (beklenen ~$gap): $inList',
        );
      }
    },
  );

  test('çizgili desenler içerikten çizilir, kareli/noktalı ızgara kalır', () {
    expect(ArchivePaper.lined.ruled, isTrue);
    expect(ArchivePaper.dashed.ruled, isTrue);
    expect(ArchivePaper.legal.ruled, isTrue);
    expect(ArchivePaper.grid.ruled, isFalse);
    expect(ArchivePaper.dots.ruled, isFalse);
    expect(ArchivePaper.fromId('dashed'), ArchivePaper.dashed);
  });
}
