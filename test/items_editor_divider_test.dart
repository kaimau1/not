import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// Kullanıcı bulgusu 2026-10-20: "alta çizgi çek defterde yalnız düz çizgi,
/// o da kararsız; diğerleri ve defter dışı notlarda hiç çalışmıyor". KÖK
/// NEDEN: satır önbelleğinin anahtarında `divider` yoktu.
void main() {
  Finder dividerPaint() => find.byWidgetPredicate(
    (w) =>
        w is CustomPaint &&
        w.foregroundPainter.runtimeType.toString() == '_ItemDividerPainter',
  );

  for (final paper in [false, true]) {
    testWidgets('menüden seçilen çizgi hemen çizilir (defter: $paper)', (
      tester,
    ) async {
      var items = const [
        NoteItem(id: 'a', text: 'süt'),
        NoteItem(id: 'b', text: 'ekmek'),
      ];
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return ItemsEditor(
                  items: items,
                  // Editör gibi: değişen listeyi geri verir.
                  onChanged: (next) => rebuild(() => items = next),
                  showCheckboxes: true,
                  paperLines: paper,
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(dividerPaint(), findsNothing);

      Future<void> pick(String label) async {
        await tester.longPress(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip(label));
        await tester.pumpAndSettle();
      }

      for (final (label, kind) in [
        ('Alta kesikli çizgi', NoteItem.dividerDashed),
        ('Alta noktalı çizgi', NoteItem.dividerDotted),
        ('Alta çizgi çek', NoteItem.dividerSolid),
      ]) {
        await pick(label);
        expect(items.first.divider, kind, reason: label);
        expect(dividerPaint(), findsOneWidget, reason: label);
        final painter = tester
            .widget<CustomPaint>(dividerPaint())
            .foregroundPainter!;
        expect(painter.toString(), isNotEmpty);
      }
      // Ayrı "Çizgiyi kaldır" yok (2026-10-28 sade menü): etkin türe
      // yeniden basmak çizgiyi kaldırır.
      await pick('Alta çizgi çek');
      expect(items.first.divider, '');
      expect(dividerPaint(), findsNothing);
    });
  }
}
