import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/core/widgets/action_menu_sheet.dart';
import 'package:notlar/features/notes/presentation/reminder_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

Widget _app(Widget Function(BuildContext) body) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  home: Scaffold(body: Builder(builder: body)),
);

/// Kullanıcı isteği 2026-11-06: hatırlatıcı tek levhada kurulur, değişir,
/// kaldırılır; levha gezinme çubuğunun altına girmez.
void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  Future<ReminderChoice?> open(
    WidgetTester tester, {
    DateTime? current,
    String repeat = '',
  }) async {
    ReminderChoice? result;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    tester.view.padding = const FakeViewPadding(bottom: 130);
    tester.view.viewPadding = const FakeViewPadding(bottom: 130);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () async {
            result = await showReminderSheet(
              context,
              current: current,
              repeat: repeat,
            );
          },
          child: const Text('aç'),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('yeni: tekrar seç, kaydet → zaman + tekrar tek seferde', (
    tester,
  ) async {
    ReminderChoice? result;
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () async => result = await showReminderSheet(context),
          child: const Text('aç'),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    // Yeni hatırlatıcıda Kaldır yok.
    expect(find.byKey(const ValueKey('reminder-sheet-remove')), findsNothing);
    await tester.tap(find.text('Yarın 09:00'));
    await tester.tap(find.byKey(const ValueKey('reminder-repeat-daily')));
    await tester.pump();
    // Önem düzeyi (2026-11-08): acil.
    await tester.ensureVisible(
      find.byKey(const ValueKey('reminder-level-urgent')),
    );
    await tester.tap(find.byKey(const ValueKey('reminder-level-urgent')));
    await tester.pump();
    // F77.2: kaydetmek tek "tamamlandı" titreşimi (lightImpact) verir.
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add(call.arguments);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    await tester.tap(find.byKey(const ValueKey('reminder-sheet-save')));
    await tester.pumpAndSettle();
    expect(haptics, ['HapticFeedbackType.lightImpact']);
    expect(result, isNotNull);
    expect(result!.at!.hour, 9);
    expect(result!.repeat, 'daily');
    expect(result!.level, 'urgent');
  });

  testWidgets('var olan: Kaldır → zaman null', (tester) async {
    ReminderChoice? result;
    final at = DateTime.now().add(const Duration(days: 2));
    await tester.pumpWidget(
      _app(
        (context) => TextButton(
          onPressed: () async =>
              result = await showReminderSheet(context, current: at),
          child: const Text('aç'),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reminder-sheet-remove')));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.at, isNull);
  });

  testWidgets('düğmeler gezinme çubuğunun üstünde', (tester) async {
    await open(tester, current: DateTime.now().add(const Duration(days: 1)));
    final save = tester.getRect(
      find.byKey(const ValueKey('reminder-sheet-save')),
    );
    final screenH = tester.view.physicalSize.height / 2.75;
    expect(save.bottom, lessThanOrEqualTo(screenH - 130 / 2.75));
  });

  testWidgets('başlıksız menüde ⚙ ayrı satır kaplamaz', (tester) async {
    await tester.pumpWidget(
      _app(
        (_) => const SingleChildScrollView(
          child: ActionMenu(
            menuId: 'test.inline',
            quick: [MenuAction('a', 'Bir', Icons.star)],
            sections: [
              MenuSection('Grup', [MenuAction('c', 'Üç', Icons.copy)]),
            ],
          ),
        ),
      ),
    );
    final edit = tester.getRect(find.byKey(const ValueKey('menu-edit')));
    final group = tester.getRect(find.text('Grup'));
    // Aynı satırda: dikey merkezler yakın.
    expect((edit.center.dy - group.center.dy).abs(), lessThan(12));
  });
}
