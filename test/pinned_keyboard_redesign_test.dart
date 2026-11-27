import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  testWidgets(
    'telefonda sabit medyada klavye açılınca >= 168 dp yazım alanı kalır',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final focus = FocusNode();
      addTearDown(focus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: PinnedMediaPane(
              media: const Attachment(
                id: 'm1',
                kind: AttachmentKind.image,
                fileName: 'foto.jpg',
                mimeType: 'image/jpeg',
                width: 100,
                height: 200,
                pinHeight: 500,
              ),
              onHeightChanged: (_) {},
              onUnpin: () {},
              onOpen: () {},
              child: TextField(focusNode: focus),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('pinned-collapse')), findsOneWidget);
      expect(find.byKey(const ValueKey('pinned-hide-keyboard')), findsNothing);

      // Odak + klavye açılır.
      focus.requestFocus();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 400));

      final winRect = tester.getRect(
        find.byKey(const ValueKey('pinned-media-window')),
      );
      final barRect = tester.getRect(
        find.byKey(const ValueKey('pinned-media-bar')),
      );
      final remainingNoteSpace = (800 - 300) - barRect.bottom;
      expect(winRect.height, lessThan(260));
      expect(remainingNoteSpace, greaterThanOrEqualTo(168));
      expect(
        find.byKey(const ValueKey('pinned-hide-keyboard')),
        findsOneWidget,
      );

      // Tek dokunuş küçült -> medya penceresi 0 dp, tekrar dokun -> geri açılır.
      await tester.tap(find.byKey(const ValueKey('pinned-collapse')));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('pinned-media-window')))
            .height,
        0,
      );
      await tester.tap(find.byKey(const ValueKey('pinned-collapse')));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSize(find.byKey(const ValueKey('pinned-media-window')))
            .height,
        greaterThan(0),
      );

      // Klavyeyi gizle düğmesi odağı bırakır.
      await tester.tap(find.byKey(const ValueKey('pinned-hide-keyboard')));
      await tester.pump();
      expect(focus.hasFocus, isFalse);
    },
  );
}
