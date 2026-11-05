import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Madde kipinde ARA BAŞLIK (kullanıcı isteği 2026-11-05).
Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  test('başlık alanı yalnız doluyken yazılır, geri okunur', () {
    const item = NoteItem(id: 'a', text: 'Sebze', header: true);
    expect(item.toMap()['header'], isTrue);
    expect(NoteItem.fromMap(item.toMap()).header, isTrue);
    expect(
      const NoteItem(id: 'b', text: 'x').toMap().containsKey('header'),
      isFalse,
    );
    expect(NoteItem.fromMap(item.toMap()).extras, isEmpty);
  });

  test('sıralı listede numara başlıkta 1den başlar, başlık numarasız', () {
    const items = [
      NoteItem(id: '1', text: 'a'),
      NoteItem(id: '2', text: 'b'),
      NoteItem(id: 'h', text: 'Bölüm', header: true),
      NoteItem(id: '3', text: 'c'),
    ];
    expect(
      [for (var i = 0; i < items.length; i++) itemOrderNumber(items, i)],
      [1, 2, null, 1],
    );
  });

  testWidgets('"Ara başlık" kutucuksuz satır açar; başlık işaretlenmez', (
    tester,
  ) async {
    List<NoteItem>? latest;
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: const [NoteItem(id: 'a', text: 'Süt')],
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('items-add-header')));
    await tester.pumpAndSettle();
    expect(latest!.length, 2);
    expect(latest!.last.header, isTrue);
    // Yeni satır kutucuksuz: hâlâ tek kutucuk.
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.text('Ara başlık yaz'), findsOneWidget);
    // Boş başlık varken ikinci kez basmak yenisini açmaz.
    await tester.tap(find.byKey(const ValueKey('items-add-header')));
    await tester.pumpAndSettle();
    expect(latest!.length, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uzun basış menüsü maddeyi başlığa çevirir ve geri alır', (
    tester,
  ) async {
    List<NoteItem>? latest;
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: const [
            NoteItem(id: 'a', text: 'Meyve'),
            NoteItem(id: 'b', text: 'Elma'),
          ],
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başlık yap'));
    await tester.pumpAndSettle();
    expect(latest!.first.header, isTrue);
    expect(find.byType(Checkbox), findsOneWidget);
    expect(find.byKey(const ValueKey('item-header-a')), findsOneWidget);
    await tester.longPress(find.byKey(const ValueKey('item-header-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maddeye çevir'));
    await tester.pumpAndSettle();
    expect(latest!.first.header, isFalse);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  test('hiza yalnız doluyken yazılır, geri okunur', () {
    const item = NoteItem(
      id: 'a',
      text: 'Sebze',
      header: true,
      align: NoteItem.alignCenter,
    );
    expect(NoteItem.fromMap(item.toMap()).align, NoteItem.alignCenter);
    expect(NoteItem.fromMap(item.toMap()).extras, isEmpty);
    expect(
      const NoteItem(id: 'b', text: 'x').toMap().containsKey('align'),
      isFalse,
    );
  });

  testWidgets('ara başlık odaktaki maddenin ALTINA girer', (tester) async {
    List<NoteItem>? latest;
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: const [
            NoteItem(id: 'a', text: 'Bir'),
            NoteItem(id: 'b', text: 'İki'),
            NoteItem(id: 'c', text: 'Üç'),
          ],
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bir'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('items-add-header')));
    await tester.pumpAndSettle();
    expect([for (final i in latest!) i.header], [false, true, false, false]);
    expect(latest![0].id, 'a');
  });

  testWidgets('başlığa basılı tutunca hiza seçilir', (tester) async {
    List<NoteItem>? latest;
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: const [
            NoteItem(id: 'h', text: 'Bölüm', header: true),
            NoteItem(id: 'b', text: 'Elma'),
          ],
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byKey(const ValueKey('item-header-h')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-menu-align')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.format_align_center));
    await tester.pumpAndSettle();
    expect(latest!.first.align, NoteItem.alignCenter);
    expect(tester.takeException(), isNull);
  });
}
