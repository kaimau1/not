import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// 2026-10-30 kullanıcı bulguları: balonlu modda kaybolan/eskiyen balonlar,
/// işaretli maddesi çok notta kasma, kırık beyaz temada mavi vurgu.
void main() {
  group('balon denetleyicisi', () {
    PageBubble bubble({String title = '', String text = ''}) => PageBubble(
      id: 'b1',
      page: 1,
      x: 0.5,
      y: 0.5,
      title: title,
      text: text,
      color: BubbleController.defaultColor,
    );

    test('yalnız BAŞLIĞI yazılan balon kapanışta silinmez', () {
      final c = BubbleController(
        initial: [bubble(title: 'Soru')],
        onChanged: (_) {},
      );
      addTearDown(c.dispose);
      c.dropEmpty();
      expect(c.bubbles, hasLength(1));
    });

    test('başlığı/aciliyeti değişen liste dışarıdan benimsenir', () {
      final c = BubbleController(initial: [bubble()], onChanged: (_) {});
      addTearDown(c.dispose);
      c.replace([bubble(title: 'Yeni başlık')]);
      expect(c.bubbles.single.title, 'Yeni başlık');
      c.replace([c.bubbles.single.copyWith(urgent: true)]);
      expect(c.bubbles.single.urgent, isTrue);
    });
  });

  testWidgets('işaretli maddeler opaklık KATMANIYLA çizilmez', (tester) async {
    final items = [
      for (var i = 0; i < 12; i++)
        NoteItem(id: 'i$i', text: 'Madde $i', checked: i.isOdd),
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: ItemsEditor(
            items: items,
            onChanged: (_) {},
            showCheckboxes: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dimmed = find.descendant(
      of: find.byType(ItemsEditor),
      matching: find.byWidgetPredicate(
        (w) =>
            // 0 katman kurmaz (çizilmez); 0–1 arası kalıcı OpacityLayer.
            (w is AnimatedOpacity && w.opacity > 0 && w.opacity < 1) ||
            (w is Opacity && w.opacity > 0 && w.opacity < 1),
      ),
    );
    expect(dimmed, findsNothing);
  });

  test('kırık beyaz temanın vurgusu mavi değil, ılık', () {
    final scheme = AppTheme.offWhite().colorScheme;
    for (final color in [
      scheme.primary,
      scheme.secondary,
      scheme.secondaryContainer,
      scheme.primaryContainer,
    ]) {
      final hsl = HSLColor.fromColor(color);
      // Mavi/mor bant (≈190–290°) dışında ya da neredeyse doygunluksuz.
      final bluish = hsl.hue > 190 && hsl.hue < 290 && hsl.saturation > 0.12;
      expect(bluish, isFalse, reason: '$color');
    }
  });
}
