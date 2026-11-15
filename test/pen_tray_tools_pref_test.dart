import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/features/notes/presentation/editor/pen_tray.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_pen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// P63 PB3 (plan §3.2.1, §3.4): tepside hangi kalemler dursun
/// (`UiItem.penTool`) ve panelde görünür sabitleme düğmesi.
void main() {
  setUp(InkToolMemory.reset);
  tearDown(() => Personalize.prefs.value = const UiPrefs());

  Future<InkController> pump(
    WidgetTester tester, {
    bool dock = false,
    bool rail = false,
  }) async {
    final ink = InkController(initial: const [], onChanged: (_) {});
    addTearDown(ink.dispose);
    ink.setEditing(true);
    final tray = PenTray(controller: ink, dock: dock, rail: rail);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: dock
              ? Stack(children: [tray])
              : rail
              ? Row(children: [tray])
              : null,
          bottomNavigationBar: dock || rail ? null : tray,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ink;
  }

  Finder tool(String name) => find.byKey(ValueKey('pen-tray-$name'));

  for (final kind in const ['serit', 'kapsul', 'sutun']) {
    testWidgets('gizlenen araç $kind kipinde çizilmez', (tester) async {
      Personalize.prefs.value = UiPrefs(
        hidden: {UiItem.penTool('marker'), UiItem.penTool('lasso')},
      );
      await pump(tester, dock: kind == 'kapsul', rail: kind == 'sutun');
      expect(tool('marker'), findsNothing);
      expect(tool('lasso'), findsNothing);
      expect(tool('pen'), findsOneWidget);
      expect(tool('highlighter'), findsOneWidget);
    });
  }

  testWidgets('seçili araç gizli olsa da çizilir; tercih anında yansır', (
    tester,
  ) async {
    final ink = await pump(tester);
    ink.setPen(InkPen.marker);
    await tester.pump();
    Personalize.prefs.value = UiPrefs(hidden: {UiItem.penTool('marker')});
    await tester.pump();
    expect(tool('marker'), findsOneWidget);
    Personalize.prefs.value = UiPrefs(hidden: {UiItem.penTool('fountain')});
    await tester.pump();
    expect(tool('fountain'), findsNothing);
  });

  testWidgets('tükenmez ve silgi gizlenemez', (tester) async {
    Personalize.prefs.value = UiPrefs(
      hidden: {UiItem.penTool('pen'), UiItem.penTool('eraser')},
    );
    await pump(tester);
    expect(tool('pen'), findsOneWidget);
    expect(tool('eraser'), findsOneWidget);
  });

  testWidgets('paneldeki iğne sabitler / kaldırır; 6. en eskiyi düşürür', (
    tester,
  ) async {
    final ink = await pump(tester);
    await tester.tap(find.byKey(const ValueKey('pen-tray-color')));
    await tester.pumpAndSettle();
    final pin = find.byKey(const ValueKey('pen-panel-pin'));
    expect(pin, findsOneWidget);
    expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
    await tester.tap(pin);
    await tester.pumpAndSettle();
    expect(InkToolMemory.presets, hasLength(1));
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    await tester.tap(pin);
    await tester.pumpAndSettle();
    expect(InkToolMemory.presets, isEmpty);

    const colors = [
      0xFF000001,
      0xFF000002,
      0xFF000003,
      0xFF000004,
      0xFF000005,
      0xFF000006,
    ];
    for (final c in colors) {
      ink.setColor(Color(c));
      await tester.pump();
      await tester.tap(pin);
      await tester.pumpAndSettle();
    }
    expect(InkToolMemory.presets, hasLength(InkToolMemory.maxPresets));
    expect(InkToolMemory.presets.first.color, colors[1]);
    expect(InkToolMemory.presets.last.color, colors.last);
  });
}
