import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/menu_layout.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: child),
);

void main() {
  setUp(() {
    MenuLayouts.reset();
    Personalize.debugReset();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    MenuLayouts.reset();
    Personalize.debugReset();
  });

  testWidgets(
    'menü düzenleme: 360 dp telefonda taşma yok, yıldız/gizle kart içinde ve sütunlar dengeli',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      const menu = ActionMenu(
        menuId: 'redesign.test',
        title: 'Notlar',
        quick: [
          MenuAction('bg', 'Zemin rengi', Icons.format_color_fill),
          MenuAction('frame', 'Çerçeve', Icons.border_color),
          MenuAction('share', 'Paylaş', Icons.share),
          MenuAction('folder', 'Klasöre taşı', Icons.drive_file_move),
          MenuAction('star', 'Yıldızla', Icons.star_outline),
        ],
        sections: [
          MenuSection('Düzenle', [
            MenuAction('cal', 'Takvime bağla', Icons.calendar_today),
            MenuAction('cols', '2 sütun', Icons.view_column),
            MenuAction('clear', 'İçeriği temizle', Icons.backspace_outlined),
          ]),
        ],
      );

      await tester.pumpWidget(_wrap(const SingleChildScrollView(child: menu)));
      await tester.tap(find.byKey(const ValueKey('menu-edit')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // 2 sütunlu satırdaki iki kart eşit genişlikte olmalı (eski dar/boşluklu yapı yok).
      final calRect = tester.getRect(find.byKey(const ValueKey('menu-drag-cal')));
      final colsRect = tester.getRect(find.byKey(const ValueKey('menu-drag-cols')));
      expect((calRect.width - colsRect.width).abs(), lessThan(1.0));

      // Tek kalan 3. öğe (clear) tüm satır enini kaplar (sağda ölü boşluk yok).
      final clearRect = tester.getRect(
        find.byKey(const ValueKey('menu-drag-clear')),
      );
      expect(clearRect.width, greaterThan(calRect.width * 1.8));

      // Yıldız ve gizle düğmeleri kart sınırlarının İÇİNDE (havada süzülmez).
      for (final id in ['bg', 'cal', 'cols', 'clear']) {
        final cardRect = tester.getRect(find.byKey(ValueKey('menu-drag-$id')));
        final visRect = tester.getRect(find.byKey(ValueKey('menu-visible-$id')));
        final starRect = tester.getRect(
          find.byKey(ValueKey('menu-edit-quick-$id')),
        );
        expect(cardRect.contains(visRect.center), isTrue, reason: '$id vis');
        expect(cardRect.contains(starRect.center), isTrue, reason: '$id star');
        expect(visRect.overlaps(starRect), isFalse, reason: '$id çakışmasın');
      }
    },
  );

  testWidgets(
    'kişiselleştirme düzenleme çerçevesi: yan yana sıkı düğmelerde rozetler taşmaz ve çakışmaz',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrap(
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final id in [
                  UiItem.barFormat,
                  UiItem.barPen,
                  UiItem.barUndo,
                ])
                  Customizable(
                    id: id,
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.edit),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      Personalize.startEditing();
      await tester.pumpAndSettle();

      final frames = find.byType(CustomizeFrame);
      expect(frames, findsNWidgets(3));

      final rects = [
        for (var i = 0; i < 3; i++) tester.getRect(frames.at(i)),
      ];
      // Her rozet ikonu (✓ veya −) yalnızca kendi çerçevesinin İÇİNDE.
      final badges = find.descendant(
        of: frames,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              (w.icon == Icons.check_rounded || w.icon == Icons.remove_rounded),
        ),
      );
      expect(badges, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        final bRect = tester.getRect(badges.at(i));
        expect(
          rects[i].left <= bRect.left &&
              rects[i].top <= bRect.top &&
              rects[i].right >= bRect.right &&
              rects[i].bottom >= bRect.bottom,
          isTrue,
          reason: 'rozet $i kendi yuvasından taşmamalı',
        );
      }
    },
  );
}
