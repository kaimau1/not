import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/image_viewer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Tam ekran görselin üzerine elle yazma: çizim ekin `ink` alanına döner
/// (görsel dosyasına gömülmez), yani notla birlikte senkronlanır.
void main() {
  final image = Attachment(
    id: 'img1',
    kind: AttachmentKind.image,
    fileName: 'foto.jpg',
    mimeType: 'image/jpeg',
    sizeBytes: 10,
    width: 100,
    height: 100,
  );

  Future<Attachment?> pumpAndDraw(
    WidgetTester tester, {
    required bool editable,
  }) async {
    Attachment? saved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ImageViewerScreen(
          attachment: image,
          onChanged: editable ? (a) => saved = a : null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pencil = find.byIcon(Icons.edit_outlined);
    if (editable) {
      expect(pencil, findsOneWidget, reason: 'çizim düğmesi yok');
      await tester.tap(pencil);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget, reason: 'çizim modu açılmadı');
      final layer = find.byType(InkPageLayer);
      expect(layer, findsOneWidget);
      await tester.dragFrom(tester.getCenter(layer), const Offset(30, 30));
      await tester.pumpAndSettle();
    } else {
      expect(pencil, findsNothing);
    }
    return saved;
  }

  testWidgets('cizim ekin ink alanina kaydedilir', (tester) async {
    final saved = await pumpAndDraw(tester, editable: true);
    expect(saved, isNotNull, reason: 'cizim kaydedilmedi');
    expect(saved!.ink, isNotEmpty);
    expect(saved.ink.first.page, 1);
    // Noktalar 0-1 orani olarak saklanir (gorsel boyutundan bagimsiz).
    expect(saved.ink.first.points.every((p) => p >= 0 && p <= 1), isTrue);
  });

  testWidgets('salt goruntulemede cizim kapali', (tester) async {
    await pumpAndDraw(tester, editable: false);
  });
}
