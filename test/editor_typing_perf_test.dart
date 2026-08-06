import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('sameItemsVisually — liste notunda saf yazım', () {
    test('yalnız METİN değişti: ekranda aynı (tam build atlanır)', () {
      final before = [
        NoteItem(id: 'a', text: 'Sü'),
        NoteItem(id: 'b', text: 'Ekmek'),
      ];
      final after = [
        NoteItem(id: 'a', text: 'Süt'),
        NoteItem(id: 'b', text: 'Ekmek'),
      ];
      // Liste her tuşta YENİ nesnedir; identical bu yüzden yetmiyordu.
      expect(identical(before, after), isFalse);
      expect(sameItemsVisually(before, after), isTrue);
    });

    test('işaret değişti: görünür', () {
      final before = [NoteItem(id: 'a', text: 'Süt')];
      final after = [NoteItem(id: 'a', text: 'Süt', checked: true)];
      expect(sameItemsVisually(before, after), isFalse);
    });

    test('madde eklendi/silindi ya da sıra değişti: görünür', () {
      final base = [
        NoteItem(id: 'a', text: 'Süt'),
        NoteItem(id: 'b', text: 'Ekmek'),
      ];
      expect(
        sameItemsVisually(base, [...base, NoteItem(id: 'c', text: '')]),
        isFalse,
      );
      expect(sameItemsVisually(base, [base[1], base[0]]), isFalse);
    });

    test('DOLULUK değişimi görünür (Note.isEmpty menüyü etkiliyor)', () {
      final before = [NoteItem(id: 'a', text: '')];
      final after = [NoteItem(id: 'a', text: 'S')];
      expect(sameItemsVisually(before, after), isFalse);
      // Boştan boşa (yalnız boşluk) fark değil.
      expect(
        sameItemsVisually(before, [NoteItem(id: 'a', text: '   ')]),
        isTrue,
      );
    });
  });

  testWidgets(
    'tek satır kipinde odaklanmak alanın state\'ini KORUR (imleç anında çıkar)',
    (tester) async {
      // KÖK NEDEN: odakla birlikte ağacın şekli değişince TextField'ın state'i
      // sıfırdan kuruluyor; yeni EditableText odağı zaten almış bir düğümle
      // açıldığı için "odak değişti" olayı gelmiyor ve imlecin yanıp sönmesi
      // ancak ilk harfte başlıyordu.
      await tester.pumpWidget(
        _wrap(
          ItemsEditor(
            items: [NoteItem(id: 'a', text: 'Süt')],
            onChanged: (_) {},
            showCheckboxes: true,
            expandItems: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final before = tester.state(find.byType(EditableText).first);
      await tester.tap(find.byType(EditableText).first);
      await tester.pumpAndSettle();
      final after = tester.state(find.byType(EditableText).first);

      expect(
        identical(before, after),
        isTrue,
        reason: 'odaklanınca alanın state\'i yeniden kurulmamalı',
      );
      expect((after as EditableTextState).widget.focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('tek satır kipinde taşan metinde "…" göstergesi durur', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        SizedBox(
          // "Yeni öğe / Seç" düğme satırı en az 280 px ister; daha darı
          // ürünle ilgisi olmayan bir taşma hatası verir.
          width: 400,
          child: ItemsEditor(
            items: [
              NoteItem(
                id: 'a',
                text:
                    'Bu satır tek satıra sığmayacak kadar uzun bir madde '
                    'metnidir ve devamı olduğu belirtilmelidir',
              ),
            ],
            onChanged: (_) {},
            showCheckboxes: true,
            expandItems: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('…'), findsOneWidget);

    // Odaklanınca satır açılır, gösterge kalkar.
    await tester.tap(find.byType(EditableText).first);
    await tester.pumpAndSettle();
    expect(find.text('…'), findsNothing);
  });
}
