import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets('İşaretlenen öğe işaretsizlerin altına iner', (tester) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta'),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => latest = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), ['Ekmek', 'Yumurta', 'Süt']);
    expect(latest!.last.checked, isTrue);
  });

  testWidgets('En son işaretlenen, işaretlilerin EN ÜSTÜnde olur',
      (tester) async {
    List<NoteItem>? latest;
    // 'c' zaten işaretli ve altta; 'a' işaretlenince onun ÜSTÜne girmeli.
    final items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta', checked: true),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => latest = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    // İlk işaretsiz satırın kutusu = 'Süt'.
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), ['Ekmek', 'Süt', 'Yumurta']);
  });

  testWidgets('İşaretlileri sil tüm işaretli öğeleri kaldırır', (tester) async {
    List<NoteItem>? latest;
    final items = [
      NoteItem(id: 'a', text: 'Süt', checked: true),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta', checked: true),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => latest = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('İşaretlileri sil'), findsOneWidget);
    await tester.tap(find.textContaining('İşaretlileri sil'));
    await tester.pumpAndSettle();

    expect(latest!.map((i) => i.text).toList(), ['Ekmek']);
  });

  testWidgets('Dışarıdan eklenen öğe ANINDA ekranda görünür', (tester) async {
    // Regresyon: dikte/hesap makinesi/AI bir öğe eklediğinde didUpdateWidget
    // yerel listeyi yenilemiyordu; öğe ancak editör kapanıp açılınca
    // görünüyordu ("söylediğim yazılmıyor, geri gelince beliriyor").
    var items = [NoteItem(id: 'a', text: 'Süt')];
    late StateSetter rebuild;

    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) {
        rebuild = setState;
        return ItemsEditor(
          items: items,
          onChanged: (updated) => items = updated,
          showCheckboxes: true,
        );
      },
    )));
    await tester.pumpAndSettle();
    expect(find.text('Ekmek'), findsNothing);

    // Dışarıdan (dikte gibi) yeni öğe eklendi.
    rebuild(() => items = [...items, NoteItem(id: 'b', text: 'Ekmek')]);
    await tester.pumpAndSettle();

    expect(find.text('Ekmek'), findsOneWidget);
  });

  testWidgets('"Seç" düğmesi seçim modunu açar, seçilen madde kopyalanır',
      (tester) async {
    // Seçim modu yalnız satırın sol kenarına uzun basışla açılıyordu ve
    // görünür bir girişi olmadığı için bulunamıyordu.
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );

    await tester.pumpWidget(_wrap(ItemsEditor(
      items: [
        NoteItem(id: 'a', text: 'Süt'),
        NoteItem(id: 'b', text: 'Ekmek'),
      ],
      onChanged: (_) {},
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Seç'));
    await tester.pumpAndSettle();

    // Seçim modunda satıra dokunmak düzenlemeye değil seçime gider: dokunuş
    // AbsorbPointer yüzünden TextField'a DEĞİL üstündeki GestureDetector'a
    // düşer, bu yüzden "ıskaladı" uyarısı beklenen davranış.
    await tester.tap(find.text('Süt'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('1 madde seçildi'), findsOneWidget);

    await tester.tap(find.byTooltip('Kopyala'));
    await tester.pumpAndSettle();

    expect(copied.single, '[ ] Süt');
    // Kopyaladıktan sonra mod kapanır.
    expect(find.text('Seç'), findsOneWidget);
  });

  testWidgets('hemen geri alınan işaret öğeyi ESKİ sırasına döndürür',
      (tester) async {
    // Yanlışlıkla işaretlenip hemen geri alınan öğe listenin sonunda
    // kalıyordu; kullanıcı onu elle eski yerine sürüklemek zorundaydı.
    var items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek'),
      NoteItem(id: 'c', text: 'Yumurta'),
    ];
    late StateSetter rebuild;
    await tester.pumpWidget(_wrap(StatefulBuilder(
      builder: (context, setState) {
        rebuild = setState;
        return ItemsEditor(
          items: items,
          onChanged: (updated) => rebuild(() => items = updated),
          showCheckboxes: true,
        );
      },
    )));
    await tester.pumpAndSettle();

    // 'Ekmek' (1. sıra) yanlışlıkla işaretlendi → işaretlilerin arasına iner.
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(items.map((i) => i.text).toList(), ['Süt', 'Yumurta', 'Ekmek']);

    // Hemen geri alındı: eski sırasına (1) dönmeli.
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(items.map((i) => i.text).toList(), ['Süt', 'Ekmek', 'Yumurta']);
    expect(items.every((i) => !i.checked), isTrue);
  });

  testWidgets('metni boş öğe işaretlenemez', (tester) async {
    // Yeni açılan "Yeni öğe" satırının kutusuna yanlışlıkla dokunmak, içi boş
    // bir maddeyi işaretlilerin arasına indiriyordu.
    var items = [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: ''),
    ];
    await tester.pumpWidget(_wrap(ItemsEditor(
      items: items,
      onChanged: (updated) => items = updated,
      showCheckboxes: true,
    )));
    await tester.pumpAndSettle();

    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes[1].onChanged, isNull, reason: 'boş satırın kutusu pasif değil');

    await tester.tap(find.byType(Checkbox).at(1), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(items.every((i) => !i.checked), isTrue);
    expect(items.map((i) => i.id).toList(), ['a', 'b']);
  });

  test('geri alma penceresi geçince öğe işaretsizlerin SONUNA girer', () {
    // Pencere içinde: hatırlanan sıra.
    expect(
      uncheckRestoreIndex(
        uncheckedCount: 3,
        rememberedIndex: 1,
        sinceChecked: const Duration(seconds: 5),
      ),
      1,
    );
    // Pencere dışında: eski davranış (sona ekle).
    expect(
      uncheckRestoreIndex(
        uncheckedCount: 3,
        rememberedIndex: 1,
        sinceChecked: kUncheckRestoreWindow + const Duration(seconds: 1),
      ),
      3,
    );
    // Hatıra yoksa (uygulama yeniden açıldı, öğe zaten işaretliydi) sona.
    expect(uncheckRestoreIndex(uncheckedCount: 2), 2);
    // Arada öğeler silinmişse hatırlanan sıra listenin dışına taşmaz.
    expect(
      uncheckRestoreIndex(
        uncheckedCount: 1,
        rememberedIndex: 7,
        sinceChecked: Duration.zero,
      ),
      1,
    );
  });
}
