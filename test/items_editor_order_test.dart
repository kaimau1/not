import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

/// Ekranda "işaretsiz blok" olarak çizilen satırlar — sürüklenebilir listenin
/// gösterdiği sıra.
List<String> _texts(List<NoteItem> items) => [for (final i in items) i.text];

void main() {
  group('normalizeItems', () {
    test('zaten düzenli liste değişmez', () {
      final items = [
        NoteItem(id: 'a', text: 'Süt'),
        NoteItem(id: 'b', text: 'Ekmek'),
        NoteItem(id: 'c', text: 'Yumurta', checked: true),
      ];
      expect(_texts(normalizeItems(items)), ['Süt', 'Ekmek', 'Yumurta']);
    });

    test('ortada kalan işaretli öğe sona iner, blok içi sıra korunur', () {
      final items = [
        NoteItem(id: 'a', text: 'Süt'),
        NoteItem(id: 'b', text: 'Ekmek', checked: true),
        NoteItem(id: 'c', text: 'Yumurta'),
        NoteItem(id: 'd', text: 'Peynir', checked: true),
        NoteItem(id: 'e', text: 'Zeytin'),
      ];
      expect(_texts(normalizeItems(items)), [
        'Süt',
        'Yumurta',
        'Zeytin',
        'Ekmek',
        'Peynir',
      ]);
    });

    test('kaynak listeye dokunulmaz (kopya döner)', () {
      final items = [
        NoteItem(id: 'a', text: 'Süt', checked: true),
        NoteItem(id: 'b', text: 'Ekmek'),
      ];
      normalizeItems(items);
      expect(_texts(items), ['Süt', 'Ekmek']);
    });
  });

  // KÖK NEDEN: "işaretsizler listenin başında" değişmezi hiçbir yerde
  // zorlanmıyordu; bozulduğunda hem yeni öğe hem sürükle-sırala yanlış
  // konumla çalışıyordu (kullanıcı: "yeni öğe alta eklenmiyor", "madde
  // sıralamasını değiştiremiyorum iptal oluyor").
  group('bozuk sırayla kaydedilmiş liste', () {
    List<NoteItem> broken() => [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek', checked: true),
      NoteItem(id: 'c', text: 'Yumurta'),
      NoteItem(id: 'd', text: 'Zeytin'),
    ];

    testWidgets('"Yeni öğe" işaretsizlerin SONUNA girer', (tester) async {
      List<NoteItem>? latest;
      await tester.pumpWidget(
        _wrap(
          ItemsEditor(
            items: broken(),
            onChanged: (updated) => latest = updated,
            showCheckboxes: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final addButton = find.widgetWithText(TextButton, 'Yeni öğe');
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(_texts(latest!), ['Süt', 'Yumurta', 'Zeytin', '', 'Ekmek']);
      expect(latest!.last.checked, isTrue);
    });

    testWidgets('sürükleyerek sıralama DOĞRU maddeyi taşır', (tester) async {
      List<NoteItem>? latest;
      await tester.pumpWidget(
        _wrap(
          ItemsEditor(
            items: broken(),
            onChanged: (updated) => latest = updated,
            showCheckboxes: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ekrandaki işaretsiz blok: [Süt, Yumurta, Zeytin]. İlk satır sona
      // taşınıyor. (Sürüklemenin kendisi değil, listenin bildirdiği indeks
      // eşlemesi sınanıyor — kusur oradaydı.)
      final list = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      list.onReorderItem!(0, 2);
      await tester.pumpAndSettle();

      expect(_texts(latest!), ['Yumurta', 'Zeytin', 'Süt', 'Ekmek']);
      // İşaretli öğe blokta kalır, sıralama onu kaydırmaz.
      expect(latest!.last.checked, isTrue);
      expect(latest!.where((i) => i.checked), hasLength(1));
    });
  });

  testWidgets('odak değişimi listenin TAMAMINI yeniden çizmez', (tester) async {
    // KÖK NEDEN (kasma): odak dinleyicisi `setState(() {})` çağırıyordu; her
    // satır dokunuşu iki kez (bırakan + alan satır) tüm listeyi — her
    // TextField'ı, her taşma ölçümünü — yeniden kuruyordu.
    var headerBuilds = 0;
    await tester.pumpWidget(
      _wrap(
        ItemsEditor(
          items: [
            NoteItem(id: 'a', text: 'Süt'),
            NoteItem(id: 'b', text: 'Ekmek'),
          ],
          onChanged: (_) {},
          showCheckboxes: true,
          header: Builder(
            builder: (context) {
              headerBuilds++;
              return const SizedBox(height: 4);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = headerBuilds;

    await tester.tap(find.byType(EditableText).first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EditableText>(find.byType(EditableText).first)
          .focusNode
          .hasFocus,
      isTrue,
    );
    expect(
      headerBuilds,
      before,
      reason: 'odak değişimi ItemsEditor build\'ini tetiklememeli',
    );

    // Odağın satırdan satıra geçmesi de listeyi kurmamalı.
    await tester.tap(find.byType(EditableText).at(1));
    await tester.pumpAndSettle();
    expect(headerBuilds, before);
  });

  testWidgets('görselin yanındaki liste ÖLÇÜMÜ yakınsar (kare döngüsü yok)', (
    tester,
  ) async {
    // Satırların görselden kaçma ölçümü kare sonunda koşuyor ve sonucu
    // yerleşimi değiştiriyor. Yakınsamazsa uygulama her kareyi yeniden kurar
    // ve KALICI olarak kasar ("yeni öğe eklendiğinde uygulama kasmaya
    // başlıyor"). `pumpAndSettle` durulmayan bir ağaçta zaman aşımına uğrar,
    // yani bu test doğrudan o döngüyü yakalar.
    final pageKey = GlobalKey();
    RenderBox? pageBox() {
      final box = pageKey.currentContext?.findRenderObject();
      return box is RenderBox && box.hasSize ? box : null;
    }

    await tester.pumpWidget(
      _wrap(
        SingleChildScrollView(
          child: KeyedSubtree(
            key: pageKey,
            child: ItemsEditor(
              items: [
                for (var i = 0; i < 6; i++)
                  NoteItem(id: '$i', text: 'Uzunca bir madde metni $i'),
              ],
              onChanged: (_) {},
              showCheckboxes: true,
              shrinkWrap: true,
              pageBox: pageBox,
              floats: const [
                FloatBox(top: 0, left: 0, right: 260, height: 240),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addButton = find.widgetWithText(TextButton, 'Yeni öğe');
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    // Yeni satır eklendikten SONRA da durulmalı.
    await tester.pumpAndSettle();

    expect(find.byType(EditableText), findsNWidgets(7));
  });

  testWidgets('görsel bantları sonradan gelince alanın state\'i KORUNUR', (
    tester,
  ) async {
    // KÖK NEDEN (kullanıcı: "yeni öğe görselin yanına ilk defa eklendiğinde
    // yanıp sönen imleç çıkmıyor"): sarma sarmalayıcısı yalnız bant VARKEN
    // kuruluyordu. Bantlar çalışma anında doluyor; o an TextField ağaçta
    // başka bir konuma düşüyor, state'i (ve EditableText'i) sıfırdan
    // kuruluyor ve imlecin yanıp sönme zamanlayıcısı hiç başlamıyordu.
    Widget build(List<FloatBox> floats) => _wrap(
      ItemsEditor(
        items: [NoteItem(id: 'a', text: 'Süt')],
        onChanged: (_) {},
        showCheckboxes: true,
        pageBox: () => null,
        floats: floats,
      ),
    );

    await tester.pumpWidget(build(const []));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EditableText).first);
    await tester.pumpAndSettle();
    final before = tester.state(find.byType(EditableText).first);

    await tester.pumpWidget(
      build(const [FloatBox(top: 0, left: 0, right: 80, height: 120)]),
    );
    await tester.pumpAndSettle();

    expect(
      identical(before, tester.state(find.byType(EditableText).first)),
      isTrue,
      reason: 'bant gelince alanın state\'i yeniden kurulmamalı',
    );
    expect((before as EditableTextState).widget.focusNode.hasFocus, isTrue);
  });
}
