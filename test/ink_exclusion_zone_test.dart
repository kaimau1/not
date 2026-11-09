import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// 2026-11-09: gömülü PDF'in üstüne kalemle yazınca çizgi SAYFAYA gidiyordu.
/// [InkExclusionZone] içindeki dokunuş sayfa katmanına ulaşmaz.
void main() {
  setUp(InkToolMemory.reset);

  testWidgets('bölge içindeki kalem sayfaya çizmez, dışındaki çizer', (
    tester,
  ) async {
    final page = InkController(initial: const [], onChanged: (_) {})
      ..setEditing(true);
    var boxDowns = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: PageInkStack(
              ink: page,
              page: 1,
              penActive: true,
              scroll: ScrollController(),
              child: Column(
                children: [
                  const SizedBox(height: 200),
                  InkExclusionZone(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => boxDowns++,
                      child: const SizedBox(
                        key: ValueKey('box'),
                        width: 300,
                        height: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 300),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> stroke(Offset at) async {
      final g = await tester.startGesture(at, kind: PointerDeviceKind.stylus);
      await g.moveBy(const Offset(40, 10));
      await g.moveBy(const Offset(40, 10));
      await g.up();
      await tester.pump();
    }

    final box = tester.getCenter(find.byKey(const ValueKey('box')));
    await stroke(box);
    expect(page.ink, isEmpty, reason: 'gömülü kutunun üstü sayfaya çizdi');
    expect(boxDowns, 1, reason: 'kutu dokunuşu almadı');
    await tester.pump(const Duration(seconds: 1));
    await stroke(const Offset(20, 20));
    expect(page.ink, isNotEmpty, reason: 'bölge dışı sayfaya çizmeli');
    page.dispose();
  });
}
