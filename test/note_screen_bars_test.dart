import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Faz 12 — not ekranı: biçim paneli adları, liste "+ Yeni madde" tekrarı,
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
    await tester.tap(find.byKey(const ValueKey('format-color-menu')));
    await tester.pumpAndSettle();
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

  testWidgets('liste: boş madde ipucu düğmeden ayrı adda — tek "Yeni madde"', (
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
    expect(find.text('Yeni madde'), findsOneWidget);
    expect(find.text('Madde yaz'), findsWidgets);
  });

  testWidgets('ekran/ayar maddeleri başlıktaki ⚙ açılır menüsünde (K-D10)', (
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
                  title: 'Not',
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
    // Sil'in altında satır YOK. ✕ olan levhada da TUTAMAK var (K-D7
    // kalktı, kullanıcı isteği 2026-11-14: aşağı çekerek kapatma).
    expect(find.byKey(const ValueKey('menu-footer-settings')), findsNothing);
    expect(find.byKey(const ValueKey('sheet-close')), findsOneWidget);
    // Tutamak (48 dp) çizili: ✕ levhanın tepesinden ≥ 40 aşağıda.
    final sheetTop = tester.getRect(find.byType(BottomSheet)).top;
    final closeTop = tester.getRect(find.byKey(const ValueKey('sheet-close'))).top;
    expect(closeTop - sheetTop, greaterThanOrEqualTo(40));
    await tester.tap(find.byKey(const ValueKey('menu-edit')));
    await tester.pumpAndSettle();
    final foot = find.byKey(const ValueKey('menu-footer-settings'));
    expect(tester.getSize(foot).height, greaterThanOrEqualTo(48));
    await tester.tap(foot);
    await tester.pumpAndSettle();
    expect(picked, 'settings');
  });
}
