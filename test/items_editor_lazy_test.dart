import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// F24.3: yalnız dokunulan madde gerçek metin alanı; düz çizim alanla BİREBİR
/// aynı yerleşir (satır zıplamaz) ve bütün odak yolları alanı kurdurur.
void main() {
  setUp(() => debugEagerItemFields = false);
  tearDown(() => debugEagerItemFields = true);

  const long =
      'Bu madde dar ekranda birkaç satıra kırılacak kadar uzun bir metin, '
      'kelimeler satır sonunda aynı yerden bölünmeli ve yükseklik değişmemeli.';

  Future<void> pump(
    WidgetTester tester,
    List<NoteItem> items, {
    ValueChanged<List<NoteItem>>? onChanged,
    double width = 320,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              child: ItemsEditor(
                items: items,
                onChanged: onChanged ?? (_) {},
                showCheckboxes: true,
                shrinkWrap: true,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  int fields() => find.byType(TextField, skipOffstage: false).evaluate().length;

  testWidgets(
    '120 maddede hiç metin alanı kurulmaz; ilk kare kısmi, geçişten sonra tamam',
    (tester) async {
      await pump(tester, [
        for (var i = 0; i < 120; i++) NoteItem(id: 'i$i', text: 'Madde $i'),
      ]);
      expect(fields(), 0);
      expect(
        find.text('Madde 119', skipOffstage: false, findRichText: true),
        findsNothing,
      );
      await tester.pump(const Duration(milliseconds: 600));
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(fields(), 0);
      expect(
        find.text('Madde 119', skipOffstage: false, findRichText: true),
        findsOneWidget,
      );
    },
  );

  testWidgets('düz çizim gerçek alanla aynı yükseklikte', (tester) async {
    final items = [
      const NoteItem(id: 'a', text: 'Kısa'),
      const NoteItem(id: 'b', text: long),
    ];
    for (final width in [260.0, 320.0, 411.0]) {
      debugEagerItemFields = false;
      await tester.pumpWidget(const SizedBox());
      await pump(tester, items, width: width);
      final lazy = tester.getSize(find.byType(ItemsEditor));
      expect(fields(), 0);
      debugEagerItemFields = true;
      await tester.pumpWidget(const SizedBox());
      await pump(tester, items, width: width);
      final real = tester.getSize(find.byType(ItemsEditor));
      expect(fields(), 2);
      expect(lazy.height, real.height, reason: 'genişlik $width');
    }
  });

  testWidgets('dokununca o madde alana döner, odak ve imleç dokunulan yerde', (
    tester,
  ) async {
    await pump(tester, [
      const NoteItem(id: 'a', text: 'Birinci madde'),
      const NoteItem(id: 'b', text: 'İkinci madde'),
    ]);
    final target = find.text('İkinci madde', findRichText: true);
    final box = tester.getRect(target);
    await tester.tapAt(box.centerLeft + const Offset(2, 0));
    await tester.pump();
    await tester.pump();
    expect(fields(), 1);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasPrimaryFocus, isTrue);
    expect(field.controller!.text, 'İkinci madde');
    expect(field.controller!.selection.baseOffset, 0);
    await tester.tapAt(
      tester.getRect(find.byType(TextField)).centerRight - const Offset(8, 0),
    );
    await tester.pump();
    expect(fields(), 1, reason: 'alan yerinde kalır');
  });

  testWidgets(
    'başta Geri Sil: üst madde (kurulu değilken) alana döner ve birleşir',
    (tester) async {
      List<NoteItem>? last;
      await pump(tester, [
        const NoteItem(id: 'a', text: 'Üst'),
        const NoteItem(id: 'b', text: 'Alt'),
      ], onChanged: (v) => last = v);
      await tester.tapAt(
        tester.getRect(find.text('Alt', findRichText: true)).centerLeft +
            const Offset(1, 0),
      );
      await tester.pump();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(last, isNotNull);
      expect(last!.single.text, 'ÜstAlt');
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.focusNode!.hasPrimaryFocus, isTrue);
      expect(field.controller!.selection.baseOffset, 3);
    },
  );

  testWidgets('boş madde ve bağlantılı madde baştan gerçek alan', (
    tester,
  ) async {
    await pump(tester, [
      const NoteItem(id: 'a', text: ''),
      const NoteItem(id: 'b', text: 'bak https://ornek.com'),
      const NoteItem(id: 'c', text: 'düz'),
    ]);
    expect(fields(), 2);
  });

  testWidgets('dışarıdan gelen metin düz çizimde görünür', (tester) async {
    await pump(tester, [const NoteItem(id: 'a', text: 'eski')]);
    await pump(tester, [const NoteItem(id: 'a', text: 'yeni')]);
    await tester.pump();
    expect(find.text('yeni', findRichText: true), findsOneWidget);
  });
}
