// Madde alanına çok satırlı yapıştırma ayrı maddelere bölünür; işaretli
// maddeden Enter işaretsizlerin sonuna öğe açar; dıştan değişen madde metni
// ekrana yansır (2026-08-06 denetim düzeltmeleri).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('çok satırlı yapıştırma ayrı maddelere bölünür', (tester) async {
    List<NoteItem>? latest;
    final items = [NoteItem(id: 'a', text: '')];
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: items,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Yapıştırma onChanged üzerinden gelir: alana çok satırlı metin girilir.
    await tester.enterText(
      find.byType(TextField).first,
      'ekmek\nsüt\nyumurta',
    );
    await tester.pumpAndSettle();

    expect(latest, isNotNull);
    expect(latest!.map((i) => i.text).toList(), ['ekmek', 'süt', 'yumurta']);
  });

  testWidgets('liste önekleri soyulur, [x] işaret olarak okunur', (
    tester,
  ) async {
    List<NoteItem>? latest;
    final items = [NoteItem(id: 'a', text: '')];
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: items,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'başlık\n- [x] bitti\n- [ ] duruyor\n2. sıra',
    );
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), [
      'başlık',
      'bitti',
      'duruyor',
      'sıra',
    ]);
    expect(latest![1].checked, isTrue);
    expect(latest![2].checked, isFalse);
  });

  testWidgets('donanım Enter satır sonunda YENİ boş madde açar', (
    tester,
  ) async {
    List<NoteItem>? latest;
    final items = [NoteItem(id: 'a', text: 'merhaba')];
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: items,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Donanım klavyesinin Enter'ı çok satırlı alana '\n' olarak düşer.
    await tester.enterText(find.byType(TextField).first, 'merhaba\n');
    await tester.pumpAndSettle();

    expect(latest!.length, 2);
    expect(latest![0].text, 'merhaba');
    expect(latest![1].text, '');
  });

  testWidgets('dıştan değişen madde metni EKRANA yansır (undo/AI yolu)', (
    tester,
  ) async {
    final before = [NoteItem(id: 'a', text: 'eski metin')];
    final after = [NoteItem(id: 'a', text: 'yeni metin')];
    Widget build(List<NoteItem> items) => _wrap(
      ItemsEditor(items: items, onChanged: (_) {}, showCheckboxes: true),
    );

    await tester.pumpWidget(build(before));
    await tester.pumpAndSettle();
    expect(find.text('eski metin'), findsOneWidget);

    // Aynı kimlikle metni dışarıdan değişti (Geri al / AI "Değiştir").
    await tester.pumpWidget(build(after));
    await tester.pumpAndSettle();
    expect(find.text('yeni metin'), findsOneWidget);
    expect(find.text('eski metin'), findsNothing);
  });

  testWidgets('işaretli maddeden Enter işaretsizlerin SONUNA öğe açar', (
    tester,
  ) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'işaretsiz'),
      NoteItem(id: 'b', text: 'bitti-1', checked: true),
      NoteItem(id: 'c', text: 'bitti-2', checked: true),
    ];
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: items,
          onChanged: (updated) => latest = updated,
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // İşaretli 'bitti-1' satırının metnine donanım Enter'ı düşür.
    await tester.enterText(find.widgetWithText(TextField, 'bitti-1'), 'bitti-1\n');
    await tester.pumpAndSettle();

    expect(latest, isNotNull);
    // Yeni boş öğe işaretli bloğun ORTASINA girmemeli; işaretsizlerin
    // sonunda (indeks 1) olmalı.
    expect(latest!.length, 4);
    expect(latest![1].text, '');
    expect(latest![1].checked, isFalse);
    expect(latest![2].text, 'bitti-1');
    expect(latest![3].text, 'bitti-2');
  });
}
