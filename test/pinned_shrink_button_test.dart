import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı isteği 2026-11-22: "Daraltınca küçülsün" sabit bölmenin alt
/// çubuğunda, solda; açık/kapalı simgesi değişir, dokunuş ayarı çevirir.
void main() {
  const image = Attachment(
    id: 'g',
    kind: AttachmentKind.image,
    fileName: 'g.jpg',
    mimeType: 'image/jpeg',
    width: 200,
    height: 400,
    pinHeight: 200,
  );

  setUp(InkToolMemory.reset);
  tearDown(InkToolMemory.reset);

  testWidgets('çubuktaki küçült düğmesi ayarı açar/kapatır', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var shrink = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PinnedMediaPane(
              media: image,
              shrinkToFit: shrink,
              onShrinkToFitChanged: (v) => setState(() => shrink = v),
              onHeightChanged: (_) {},
              onUnpin: () {},
              onOpen: () {},
              onChanged: (_) {},
              child: const Text('not gövdesi'),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    final button = find.byKey(const ValueKey('pinned-shrink'));
    expect(button, findsOneWidget);
    expect(
      find.descendant(
        of: button,
        matching: find.byIcon(Icons.fit_screen_outlined),
      ),
      findsOneWidget,
    );
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    expect(shrink, isTrue);
    expect(
      find.descendant(of: button, matching: find.byIcon(Icons.fit_screen)),
      findsOneWidget,
    );
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 300));
    expect(shrink, isFalse);
  });
}
