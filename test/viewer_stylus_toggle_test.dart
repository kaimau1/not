import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/image_viewer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// **TAM EKRANDA YÜZEN KALEM DÜĞMESİ** (OTURTMA F63.4, KALEM K3): kalem
/// görülmüş cihazda düğme tam ekran görüntüleyicide de var; "kalem yazar"
/// iken kalem çizim düğmesine basmadan yazar, parmak gezinir; "dokunur"da
/// kalem yazmaz. Kalem ilk kez burada görülürse de işaretlenir.
void main() {
  const image = Attachment(
    id: 'img1',
    kind: AttachmentKind.image,
    fileName: 'foto.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 10,
    width: 100,
    height: 100,
  );
  const toggle = ValueKey('stylus-toggle');

  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  Future<List<Attachment>> pump(
    WidgetTester tester, {
    bool editable = true,
  }) async {
    final saved = <Attachment>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: ImageViewerScreen(
          attachment: image,
          onChanged: editable ? saved.add : null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return saved;
  }

  Future<void> draw(WidgetTester tester, PointerDeviceKind kind) async {
    final g = await tester.startGesture(
      tester.getCenter(find.byType(InkPageLayer)),
      kind: kind,
    );
    for (var i = 0; i < 4; i++) {
      await g.moveBy(const Offset(6, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await g.up();
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('kalem görülmüş cihaz: düğme var, kalem düğmesiz yazar, parmak '
      'yazmaz', (tester) async {
    InkToolMemory.stylusEver = true;
    final saved = await pump(tester);
    expect(find.byKey(toggle), findsOneWidget);
    await draw(tester, PointerDeviceKind.touch);
    expect(saved.where((a) => a.ink.isNotEmpty), isEmpty);
    await draw(tester, PointerDeviceKind.stylus);
    expect(saved.last.ink, hasLength(1));
  });

  testWidgets('"kalem dokunur": kalem yazmaz; açık çizim kipi de kapanır', (
    tester,
  ) async {
    InkToolMemory.stylusEver = true;
    final saved = await pump(tester);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.byKey(toggle));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(InkToolMemory.autoStylus, isFalse);
    expect(find.byIcon(Icons.check), findsNothing);
    await draw(tester, PointerDeviceKind.stylus);
    expect(saved.where((a) => a.ink.isNotEmpty), isEmpty);
  });

  testWidgets('kalemsiz cihazda düğme yok; kalem ilk kez burada görülünce '
      'işaretlenir ve düğme çıkar', (tester) async {
    await pump(tester);
    expect(find.byKey(toggle), findsNothing);
    await draw(tester, PointerDeviceKind.stylus);
    expect(InkToolMemory.stylusEver, isTrue);
    await tester.pump();
    expect(find.byKey(toggle), findsOneWidget);
  });

  testWidgets('salt görüntülemede düğme yok', (tester) async {
    InkToolMemory.stylusEver = true;
    await pump(tester, editable: false);
    expect(find.byKey(toggle), findsNothing);
  });
}
