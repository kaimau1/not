import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// SATIR ÖNBELLEĞİ (2026-08-07 / 16. tur).
///
/// KÖK NEDEN: liste `shrinkWrap: true` ile bir `SingleChildScrollView`'ın
/// içinde. `ShrinkWrappingViewport` kendi boyunu bulmak için BÜTÜN çocukları
/// kurmak zorunda — 60 maddelik bir notta ekranda 8 satır görünse bile 60
/// `TextField` her build'de yeniden kuruluyor ve yeniden yerleşiyordu. Yani
/// editörün her yeniden kurulumunun bedeli madde sayısıyla doğru orantılıydı.
///
/// Ölçüt: girdileri değişmemiş satır için AYNI widget örneği dönmeli. Flutter
/// `updateChild`te birebir aynı widget'ı görünce alt ağacı hiç kurmaz ve
/// kurulmayan `RenderObject` "kirli" işaretlenmediği için `layout()` da erken
/// döner — kazanç hem yeniden kurulumda hem yerleşimde.
///
/// Testler widget ÖRNEK KİMLİĞİNE bakıyor: `identical` ise satır atlanmış,
/// değilse yeniden kurulmuş demektir.
void main() {
  final pageKey = GlobalKey();

  /// Üstteki durumu değiştirip yeniden kurulum tetikleyebilen kabuk.
  late void Function(void Function()) forceRebuild;

  Future<void> pumpList(
    WidgetTester tester,
    List<NoteItem> items, {
    List<FloatBox> floats = const [],
    bool showCheckboxes = false,
  }) async {
    var current = items;
    var checks = showCheckboxes;
    var currentFloats = floats;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              forceRebuild = (fn) => setState(fn);
              return SingleChildScrollView(
                child: KeyedSubtree(
                  key: pageKey,
                  child: ItemsEditor(
                    items: current,
                    onChanged: (next) => setState(() => current = next),
                    showCheckboxes: checks,
                    shrinkWrap: true,
                    floats: currentFloats,
                    pageBox: () {
                      final box = pageKey.currentContext?.findRenderObject();
                      return box is RenderBox && box.hasSize ? box : null;
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Kabuğun kapanışları testten görünsün diye alanlar dışarı sızdırılıyor.
    _setChecks = (v) => forceRebuild(() => checks = v);
    _setFloats = (v) => forceRebuild(() => currentFloats = v);
    _setItems = (v) => forceRebuild(() => current = v);
  }

  List<TextField> fields(WidgetTester tester) =>
      tester.widgetList<TextField>(find.byType(TextField)).toList();

  final sample = [
    const NoteItem(id: 'a', text: 'bir'),
    const NoteItem(id: 'b', text: 'iki'),
    const NoteItem(id: 'c', text: 'uc'),
  ];

  testWidgets('üstten gelen boş yeniden kurulum satırları YENİDEN KURMAZ', (
    tester,
  ) async {
    await pumpList(tester, sample);
    final before = fields(tester);
    expect(before.length, 3);

    // Hiçbir girdi değişmedi, yalnız üst ağaç yeniden kuruldu.
    forceRebuild(() {});
    await tester.pump();

    final after = fields(tester);
    expect(after.length, 3);
    for (var i = 0; i < before.length; i++) {
      expect(
        identical(before[i], after[i]),
        isTrue,
        reason: '${i + 1}. satır boşuna yeniden kuruldu',
      );
    }
  });

  testWidgets('metni DEĞİŞEN satır yeniden kurulur, komşuları kurulmaz', (
    tester,
  ) async {
    await pumpList(tester, sample);
    final before = fields(tester);

    _setItems([
      const NoteItem(id: 'a', text: 'bir'),
      const NoteItem(id: 'b', text: 'iki DEGISTI'),
      const NoteItem(id: 'c', text: 'uc'),
    ]);
    await tester.pump();

    final after = fields(tester);
    expect(identical(before[0], after[0]), isTrue, reason: 'komşu kuruldu');
    expect(
      identical(before[1], after[1]),
      isFalse,
      reason: 'değişen satır tazelenmedi',
    );
    expect(identical(before[2], after[2]), isTrue, reason: 'komşu kuruldu');
  });

  testWidgets('LİSTE DÜZEYİ girdi değişince tüm satırlar tazelenir', (
    tester,
  ) async {
    await pumpList(tester, sample);
    final before = fields(tester);

    // Onay kutuları açıldı: her satırın başı değişiyor.
    _setChecks(true);
    await tester.pumpAndSettle();

    final after = fields(tester);
    for (var i = 0; i < before.length; i++) {
      expect(
        identical(before[i], after[i]),
        isFalse,
        reason: '${i + 1}. satır bayat önbellekten geldi',
      );
    }
    expect(find.byType(Checkbox), findsNWidgets(3));
  });

  testWidgets('BANTLAR değişince tüm satırlar tazelenir (sarma yeniden)', (
    tester,
  ) async {
    await pumpList(tester, sample);
    final before = fields(tester);

    // Bantlar YERİNDE de değişebiliyor; önbellek anahtarı listenin kopyası
    // olmasaydı karşılaştırma hep eşit çıkar ve satırlar bayat kalırdı.
    _setFloats(const [FloatBox(top: 0, left: 0, right: 120, height: 90)]);
    await tester.pumpAndSettle();

    final after = fields(tester);
    for (var i = 0; i < before.length; i++) {
      expect(
        identical(before[i], after[i]),
        isFalse,
        reason: '${i + 1}. satır yeni bantları görmedi',
      );
    }
  });

  testWidgets('yazmak komşu satırları yeniden kurmaz', (tester) async {
    await pumpList(tester, sample);
    final before = fields(tester);

    await tester.enterText(find.byType(TextField).at(0), 'bir yazildi');
    await tester.pump();

    final after = fields(tester);
    expect(identical(before[1], after[1]), isTrue);
    expect(identical(before[2], after[2]), isTrue);
  });
}

late void Function(bool) _setChecks;
late void Function(List<FloatBox>) _setFloats;
late void Function(List<NoteItem>) _setItems;
