import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Faz 12 — not ekranı: biçim paneli adları, liste "+ Yeni öğe" tekrarı,
/// menünün ince alt satırı.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('tr'),
    home: Scaffold(body: child),
  );

  testWidgets('biçim paneli: renk daireleri adlı, boyut "Boyut %100", '
      '"Tümüne uygula" ve "Sayfa rengi" yok', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      wrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: FormatBar(
            onFormat: (_, {colorIndex}) {},
            onClearFormat: () {},
            onRemoveFormat: (_) {},
            fontFamily: null,
            fontScale: 1,
            textOpacity: 1,
            hasSelection: () => false,
            onFontChanged: (_) {},
            onScaleChanged: (_) {},
            onScaleEnd: (_) {},
            onOpacityChanged: (_) {},
            onOpacityEnd: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    final tips = [
      for (var i = 1; i <= 5; i++)
        tester
            .widget<Tooltip>(
              find.ancestor(
                of: find.byKey(ValueKey('format-color-$i')),
                matching: find.byType(Tooltip),
              ),
            )
            .message,
    ];
    expect(tips.first, 'Yazı rengi: Kırmızı');
    expect(tips.toSet(), hasLength(5));
    expect(find.text('Boyut'), findsOneWidget);
    expect(find.bySemanticsLabel('Boyut %100'), findsOneWidget);
    expect(find.byKey(const ValueKey('format-apply-all')), findsNothing);
    expect(find.byKey(const ValueKey('format-page')), findsNothing);
    semantics.dispose();
  });

  testWidgets('liste: boş madde ipucu düğmeden ayrı adda — tek "Yeni öğe"', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ItemsEditor(
          items: [
            NoteItem(id: 'a', text: 'Süt'),
            NoteItem(id: 'b', text: ''),
          ],
          onChanged: (_) {},
          showCheckboxes: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('items-add-button')), findsOneWidget);
    expect(find.text('Yeni öğe'), findsOneWidget);
    expect(find.text('Madde yaz'), findsWidgets);
  });

  testWidgets('menünün ince alt satırı Sil\'in altında ve seçilebilir', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      wrap(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showActionMenuSheet(
                context,
                const ActionMenu(
                  quick: [MenuAction('a', 'A', Icons.star)],
                  sections: [],
                  danger: MenuAction('delete', 'Sil', Icons.delete),
                  footer: [MenuAction('settings', 'Ayarlar', Icons.settings)],
                ),
              );
            },
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    final del = tester.getRect(find.byKey(const ValueKey('menu-tile-delete')));
    final foot = find.byKey(const ValueKey('menu-footer-settings'));
    expect(tester.getRect(foot).top, greaterThan(del.bottom));
    expect(tester.getSize(foot).height, greaterThanOrEqualTo(48));
    await tester.tap(foot);
    await tester.pumpAndSettle();
    expect(picked, 'settings');
  });
}
