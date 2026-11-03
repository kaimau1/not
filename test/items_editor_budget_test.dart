import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/note_route_closing.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// UZUN LİSTEDE AÇILIŞ/KAPANIŞ KASMASI (2026-11-02, telefonda ölçüldü): 90
/// maddelik notta açılış geçişinin sonunda 5 kare 33–82 ms, kapanışın sonunda
/// 2 kare ~50 ms sürüyordu. Maddeler geçiş BİTTİKTEN sonra küçük adımlarla
/// kurulur, kapanırken kare başına birkaçı sökülür.
void main() {
  final items = [
    for (var i = 0; i < 90; i++) NoteItem(id: 'i$i', text: 'Madde $i'),
  ];

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ItemsEditor(
            items: items,
            onChanged: (_) {},
            showCheckboxes: true,
            shrinkWrap: true,
          ),
        ),
      ),
    ),
  );

  int built() => find.byType(TextField, skipOffstage: false).evaluate().length;

  tearDown(() => noteRouteClosing.value = false);

  testWidgets('ilk karede 12, geçiş bitince kalanı küçük adımlarla', (
    tester,
  ) async {
    await pump(tester);
    expect(built(), 12);

    await tester.pump(const Duration(milliseconds: 1000));
    expect(built(), 12, reason: 'geçiş sürerken büyümez');

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    final first = built();
    expect(first, inInclusiveRange(13, 24), reason: 'kare başına birkaç madde');

    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(built(), 90);
  });

  testWidgets('kapanırken maddeler kare başına birkaç sökülür', (tester) async {
    await pump(tester);
    for (var i = 0; i < 140; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(built(), 90);

    noteRouteClosing.value = true;
    // Gerçekte geçiş animasyonu kare istiyor; testte kareyi biz isteriz.
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump();
    final step = built();
    expect(step, greaterThan(12));
    expect(step, lessThan(90));

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(built(), 12);
  });

  // Kullanıcı bulgusu 2026-11-03: "son kasma güncellemesinden sonra klavye
  // açılırken kasma, titreme". Notu açıp hemen maddeye dokunan kullanıcıda
  // kalan maddelerin kurulumu klavye animasyonuna biniyordu.
  testWidgets('klavye hareket ederken kurulum bekler, durunca sürer', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(built(), 12);

    // Kurulum başlamak üzereyken klavye açılmaya başlar.
    for (var i = 1; i <= 16; i++) {
      tester.view.viewInsets = FakeViewPadding(bottom: 600.0 * i / 16);
      await tester.pump(const Duration(milliseconds: 16));
      expect(built(), 12, reason: 'klavye karesi $i: madde eklenmez');
    }
    // Klavye durdu: sessizlik süresi dolunca kalanlar kurulur.
    await tester.pump(const Duration(milliseconds: 400));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(built(), 90);
  });
}
