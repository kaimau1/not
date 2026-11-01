import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/title_fit.dart';
import 'package:notlar/features/notes/presentation/editor/view_mode_switch.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// 2026-11-01 kullanıcı listesi: "Gelen" ana ekranı süzer, düzenleme modu
/// ekranı aşağı itmez, görünüm anahtarında "Yazıya göm", madde satırının
/// tamamı yeni madde açar, uzun başlık küçülerek sığar.
void main() {
  Widget app(Widget home, {TransitionBuilder? builder}) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    builder: builder,
    home: home,
  );

  group('başlık sığdırma', () {
    InlineSpan Function(double) span(String text) =>
        (size) => TextSpan(
          text: text,
          style: TextStyle(fontSize: size),
        );

    test('sığan başlık taban boyda kalır', () {
      expect(
        fitTitleFontSize(spanFor: span('Kısa'), maxWidth: 400, baseSize: 24),
        24,
      );
    });

    test('uzun başlık sığana kadar küçülür', () {
      // Test yazı tipinde (Ahem) her harf yazı boyu genişliğinde: 20 harf × 24
      // = 480 px, 300 px'e ~14,7 boyda sığar.
      const text = 'Uzun başlık burada!!';
      final size = fitTitleFontSize(
        spanFor: span(text),
        maxWidth: 300,
        baseSize: 24,
      );
      expect(size, lessThan(24));
      expect(size, greaterThanOrEqualTo(14));
      final painter = TextPainter(
        text: span(text)(size),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      expect(painter.width, lessThanOrEqualTo(300));
      painter.dispose();
    });

    test('en küçük boyun altına inmez (sonra alan kayar)', () {
      final size = fitTitleFontSize(
        spanFor: span('x' * 400),
        maxWidth: 200,
        baseSize: 24,
      );
      expect(size, 14);
    });
  });

  testWidgets('düzenleme şeridi açıkken ekran boyu şeridin altındaki alan', (
    tester,
  ) async {
    Personalize.debugReset();
    addTearDown(Personalize.debugReset);
    late Size seen;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const SizedBox.expand();
          },
        ),
        builder: (context, child) => CustomizeModeHost(child: child!),
      ),
    );
    final full = seen;
    Personalize.startEditing();
    await tester.pumpAndSettle();
    // Not açılış geçişi sayfayı `MediaQuery.size` ile çiziyor: tam ekran
    // kalsaydı alt çubuk şerit kadar ekranın dışına taşardı.
    final body = tester.getSize(find.byType(SizedBox).last);
    expect(seen.height, lessThan(full.height));
    expect(seen.height, body.height);
  });

  testWidgets('görünüm anahtarında "Yazıya göm" düğmesi', (tester) async {
    var embedded = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Center(
            child: AttachmentViewSwitch(
              current: AttachmentView.floating,
              available: const {AttachmentView.pinned, AttachmentView.floating},
              onChanged: (_) {},
              onEmbed: () => embedded++,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('view-embed')));
    expect(embedded, 1);
  });

  testWidgets('madde ekleme satırının sağına dokunmak da madde açar', (
    tester,
  ) async {
    var latest = <NoteItem>[NoteItem(id: 'a', text: 'Süt')];
    await tester.pumpWidget(
      app(
        Scaffold(
          body: ItemsEditor(
            items: latest,
            onChanged: (updated) => latest = updated,
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = tester.getRect(find.byKey(const ValueKey('items-add-row')));
    final button = tester.getRect(
      find.byKey(const ValueKey('items-add-button')),
    );
    expect(row.width, greaterThan(button.width * 2));
    await tester.tapAt(Offset(row.right - 10, row.center.dy));
    await tester.pumpAndSettle();
    expect(latest, hasLength(2));
  });

  test('"Gelen" süzgeci varsayılan kapalı, açılıp kapanır', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(sharedHubOnHomeProvider), isFalse);
    container.read(sharedHubOnHomeProvider.notifier).set(true);
    expect(container.read(sharedHubOnHomeProvider), isTrue);
  });
}
