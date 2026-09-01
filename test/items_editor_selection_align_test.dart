import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **SEÇ KİPİNDE HİZA** (kullanıcı bulgusu 2026-09-01, ekran görüntüsüyle:
/// "işaretli yer hizasız oluyor seç aktifken").
///
/// KÖK NEDEN: sürükleme tutamacı yalnız SÜRÜKLENEBİLİR satırlarda çiziliyordu.
/// Checklist'te İŞARETLİ maddeler sürüklenebilir listenin DIŞINDA, footer'da
/// duruyor (Keep'in "tamamlananlar" bölümü gibi) — o satırlarda tutamaç yok,
/// dolayısıyla seçim yuvarlağı 22 dp solda kalıyor ve aynı ekranda iki farklı
/// sol kenar oluşuyordu.
void main() {
  Future<void> pumpEditor(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ItemsEditor(
            items: const [
              NoteItem(id: 'a', text: 'işaretsiz bir'),
              NoteItem(id: 'b', text: 'işaretsiz iki'),
              NoteItem(id: 'c', text: 'işaretli bir', checked: true),
              NoteItem(id: 'd', text: 'işaretli iki', checked: true),
            ],
            onChanged: (_) {},
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.state<ItemsEditorState>(find.byType(ItemsEditor)).startSelection();
    await tester.pumpAndSettle();
  }

  testWidgets('işaretli ve işaretsiz satırların seçim yuvarlağı AYNI hizada', (
    tester,
  ) async {
    await pumpEditor(tester);

    final circles = find.byIcon(Icons.circle_outlined);
    expect(circles, findsNWidgets(4));

    final lefts = <double>{
      for (var i = 0; i < 4; i++)
        // Yuvarlağın sol kenarı: yarım pikselden ince farklar (ölçek/yuvarlama)
        // hizasızlık sayılmasın diye tam sayıya yuvarlanır.
        tester.getTopLeft(circles.at(i)).dx.roundToDouble(),
    };
    expect(
      lefts.length,
      1,
      reason: 'Seçim kipinde bütün satırlar aynı sol kenardan başlamalı',
    );
  });

  testWidgets('6 nokta ile seçim yuvarlağı AYNI yükseklikte', (tester) async {
    // Kullanıcı bulgusu 2026-09-01 (ekran görüntüsüyle): "6 nokta ile seçim
    // işareti hâlâ hizasız".
    //
    // KÖK NEDEN: bir önceki tur tutamacın YUVASINI her satırda ayırdı (sol
    // kenarlar hizalandı) ama tutamacın kendisi satırın Row'una doğrudan
    // konuyordu. Satır `CrossAxisAlignment.start` ile dizildiği için simge
    // satırın en üstüne yapışıyor, yanındaki yuvarlak ise ilk yazı satırının
    // ortasına hizalanıyordu — yani ikisi dikeyde ayrı yerlerde duruyordu.
    await pumpEditor(tester);

    final handle = tester.getCenter(find.byIcon(Icons.drag_indicator).first).dy;
    final circle = tester
        .getCenter(find.byIcon(Icons.circle_outlined).first)
        .dy;
    expect(
      (handle - circle).abs(),
      lessThan(1.0),
      reason:
          'Tutamaç ve seçim yuvarlağı aynı satırda aynı yükseklikte '
          'durmalı (fark: ${handle - circle})',
    );
  });

  testWidgets('tutamaç yalnız sürüklenebilir satırlarda çizilir', (
    tester,
  ) async {
    await pumpEditor(tester);
    // İşaretliler footer'da ve sürüklenemez: tutamaç yalnız iki işaretsiz
    // satırda görünür — yuvası ise (hiza için) her satırda ayrılır.
    expect(find.byIcon(Icons.drag_indicator), findsNWidgets(2));
  });

  testWidgets('seçim kipi kapalıyken tutamaç hiç yok', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ItemsEditor(
            items: const [
              NoteItem(id: 'a', text: 'bir'),
              NoteItem(id: 'b', text: 'iki', checked: true),
            ],
            onChanged: (_) {},
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.drag_indicator), findsNothing);
  });
}
