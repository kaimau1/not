import 'dart:async';

// 2026-11-08 ikinci tur istek listesi: not paketi, tablette hızlı satır,
// Esc = geri, kalem simgesi yazısız, satır hatırlatıcısı menüsü.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/app.dart' show EscBackAction, EscBackIntent;
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/text_merge.dart';
import 'package:notlar/features/notes/presentation/editor/editor_quick_row.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_package.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('not paketi kendi kendine iptal olmaz', () {
    // KÖK NEDEN: madde karşılaştırması `package` alanına bakmıyordu;
    // birleştirme yerelin paketlemesini "değişmedi" sayıp uzaktaki paketsiz
    // kopyayı yazıyordu.
    test('birleştirmede yerel paketleme korunur', () {
      const base = [
        NoteItem(id: 'a', text: 'bir'),
        NoteItem(id: 'b', text: 'iki'),
      ];
      const local = [
        NoteItem(id: 'a', text: 'bir', package: 'p1'),
        NoteItem(id: 'b', text: 'iki', package: 'p1'),
      ];
      const remote = [
        NoteItem(id: 'a', text: 'bir'),
        NoteItem(id: 'b', text: 'iki'),
        NoteItem(id: 'c', text: 'üç'),
      ];
      final out = mergeItems3(base, local, remote);
      expect(out.map((i) => i.package).toList(), ['p1', 'p1', '']);
      expect(sameItems(base, local), isFalse);
    });

    testWidgets('açık pakette Enter: yeni madde pakette kalır; boşta çıkar', (
      tester,
    ) async {
      List<NoteItem>? latest;
      await tester.pumpWidget(
        _wrap(
          ItemsEditor(
            items: const [
              NoteItem(id: 'a', text: 'bir', package: 'p'),
              NoteItem(id: 'b', text: 'iki', package: 'p'),
            ],
            onChanged: (u) => latest = u,
            showCheckboxes: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(NotePackagePill));
      await tester.pumpAndSettle();
      final field = find.byType(TextField).at(1);
      await tester.tap(field);
      await tester.pump();
      final c = tester.widget<TextField>(field).controller!;
      c.selection = TextSelection.collapsed(offset: c.text.length);
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(latest, hasLength(3));
      expect(latest!.last.package, 'p', reason: 'yeni madde pakette');
      expect(find.byType(NotePackagePill), findsNothing, reason: 'paket açık');
      // Boş son maddede Enter: paketten çıkar, yeni madde açılmaz.
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();
      expect(latest, hasLength(3));
      expect(latest!.last.package, '');
    });
  });

  group('tablette üst hızlı satır', () {
    Future<void> pumpSwitch(
      WidgetTester tester,
      Size size,
      bool editing,
    ) async {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: KeyboardSwitch(
            editing: ValueNotifier(editing),
            open: const Text('hızlı'),
            closed: const Text('tarih'),
          ),
        ),
      );
    }

    testWidgets('klavye boşluğu yokken de alan odaktaysa görünür', (
      tester,
    ) async {
      await pumpSwitch(tester, const Size(1024, 700), true);
      expect(find.text('hızlı'), findsOneWidget);
    });

    testWidgets('telefonda klavye yokken görünmez', (tester) async {
      await pumpSwitch(tester, const Size(400, 800), true);
      expect(find.text('tarih'), findsOneWidget);
    });
  });

  testWidgets('hızlı satırda kalem yalnız simge (uzun yazı yok)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        EditorQuickRow(
          onBold: () {},
          onBullet: () {},
          onCheckbox: null,
          onHeading: () {},
          onPhoto: () {},
          onFile: () {},
          onPen: () {},
          onPenSettings: () {},
          onReminder: () {},
          onDate: () {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    final pen = find.byKey(const ValueKey('quick-row-pen'));
    expect(pen, findsOneWidget);
    expect(find.descendant(of: pen, matching: find.byType(Text)), findsNothing);
    expect(find.byKey(const ValueKey('quick-row-date')), findsOneWidget);
  });

  testWidgets('Esc = geri: üstteki sayfa kapanır', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        shortcuts: {
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.escape):
              const EscBackIntent(),
        },
        actions: {
          ...WidgetsApp.defaultActions,
          EscBackIntent: EscBackAction(),
        },
        home: const Text('ana'),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: TextField(autofocus: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ana'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('ana'), findsOneWidget);
  });

  testWidgets('Esc: diyalog açıksa yalnız diyalog kapanır', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        shortcuts: {
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.escape):
              const EscBackIntent(),
        },
        actions: {...WidgetsApp.defaultActions, EscBackIntent: EscBackAction()},
        home: const Text('ana'),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('sayfa')),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      showDialog<void>(
        context: nav.currentContext!,
        builder: (_) => const AlertDialog(content: TextField(autofocus: true)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('sayfa'), findsOneWidget);
  });
}
