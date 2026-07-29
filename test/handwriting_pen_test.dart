import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/drawing_screen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// El yazısı ekranı kendi çizim motorunu bırakıp PDF/görsel üstü çizimle AYNI
/// parçaları kullanıyor. Bu testler o birleşmeyi korur: kalem seçenekleri iki
/// yerde birden görünmeli ve çizim hâlâ PNG olarak dönmeli.
void main() {
  Future<Uint8List?> pumpAndDraw(
    WidgetTester tester, {
    bool draw = true,
    IconData? pen,
  }) async {
    Uint8List? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Uint8List>(
                    MaterialPageRoute(builder: (_) => const DrawingScreen()),
                  );
                },
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();

    if (pen != null) {
      await tester.tap(find.byIcon(pen));
      await tester.pumpAndSettle();
    }
    if (draw) {
      final layer = find.byType(InkPageLayer);
      expect(layer, findsOneWidget, reason: 'çizim katmanı kurulmadı');
      await tester.dragFrom(tester.getCenter(layer), const Offset(40, 40));
      await tester.pumpAndSettle();
    }
    // "Nota ekle": çizim PNG'ye çevrilip geri döner. PNG kodlaması motora
    // gider (`Picture.toImage`), sahte zamanlı test zone'unda ilerlemez —
    // `runAsync` olmadan ekran hiç kapanmaz ve sonuç sonsuza kadar null kalır.
    await tester.tap(find.byIcon(Icons.check));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('el yazısı ekranı kalem türlerini ve silgiyi gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DrawingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Aynı çubuk PDF/slayt/görsel üstünde de kullanılıyor.
    expect(find.byType(InkToolbar), findsOneWidget);
    // Tükenmez / keçeli / fosforlu + silgi.
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.byIcon(Icons.brush), findsOneWidget);
    expect(find.byIcon(Icons.format_color_fill), findsOneWidget);
    expect(find.byIcon(Icons.cleaning_services_outlined), findsOneWidget);
    // Renk seçenekleri ve kalınlık.
    expect(find.byType(Slider), findsOneWidget);
  });

  testWidgets('çizim PNG olarak döner', (tester) async {
    final bytes = await pumpAndDraw(tester);
    expect(bytes, isNotNull, reason: 'çizim geri dönmedi');
    // PNG imzası: çıktı gerçekten görsel.
    expect(bytes!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('hiç çizilmezse ekran boş döner (boş görsel eklenmez)', (
    tester,
  ) async {
    expect(await pumpAndDraw(tester, draw: false), isNull);
  });

  testWidgets('fosforlu ile çizilen iz de PNG\'ye girer', (tester) async {
    final bytes = await pumpAndDraw(tester, pen: Icons.format_color_fill);
    expect(bytes, isNotNull);
    expect(bytes!.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
  });

  testWidgets('fosforlu seçilince kalınlık kendiliğinden artar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DrawingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      InkPen.pen.defaultWidth,
    );
    await tester.tap(find.byIcon(Icons.format_color_fill));
    await tester.pumpAndSettle();
    // Fosforlu 3 px'te kalsaydı vurgulama işe yaramazdı.
    expect(
      tester.widget<Slider>(find.byType(Slider)).value,
      InkPen.highlighter.defaultWidth,
    );
  });
}
