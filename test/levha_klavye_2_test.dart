import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPrintLayouts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/ai_result_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/note_search_sheet.dart';
import 'package:notlar/features/notes/presentation/note_link_ui.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

/// **S53 — levha klavye karesi, ikinci tur** (kasma envanteri K-01…K-11,
/// 2026-11-17). S52'nin kalıbı: levha State'i kendi build'inde
/// `viewInsetsOf` okursa klavyenin her karesinde BÜTÜN levha (arama
/// levhasında bütün not + ek metni taranarak) yeniden kurulur. Düzeltme:
/// pay yalnız `SheetInsetPadding`'de okunur. Ölçü: 6 klavye karesinde TÜM
/// widget kurulumu + dizilme; levhanın kendi widget'ı 0 kez kurulmalı.
void main() {
  final budget =
      (jsonDecode(File('test/perf_budget/budgets.json').readAsStringSync())
              as Map<String, dynamic>)['S53']
          as Map<String, dynamic>;

  testWidgets('S53: üç levha × klavye açılışı (6 inset karesi)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notes = [
      for (var i = 0; i < 40; i++)
        Note(id: 'n$i', type: NoteType.text, title: 'Not $i', body: 'yazı $i'),
    ];
    late BuildContext ctx;
    late WidgetRef wref;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              ctx = context;
              wref = ref;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      ),
    );

    Future<void> settle() async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));
    }

    final oldPrint = debugPrint;
    Future<(int, int, int)> keyboard(
      void Function() open,
      String sheetType,
    ) async {
      open();
      await settle();
      await tester.tap(find.byType(TextField).first);
      await tester.pump(const Duration(milliseconds: 100));
      var layouts = 0;
      debugPrint = (String? m, {int? wrapWidth}) {
        if (m != null && m.startsWith('Laying out')) layouts++;
      };
      debugPrintLayouts = true;
      final counter = BuildCounter()..start();
      try {
        for (final b in <double>[50, 100, 150, 200, 250, 300]) {
          tester.view.viewInsets = FakeViewPadding(bottom: b);
          await tester.pump(const Duration(milliseconds: 16));
        }
      } finally {
        counter.stop();
        debugPrintLayouts = false;
        debugPrint = oldPrint;
      }
      tester.view.viewInsets = FakeViewPadding.zero;
      await tester.binding.handlePopRoute();
      await settle();
      return (
        counter.counts.values.fold(0, (a, b) => a + b),
        layouts,
        counter.of(sheetType),
      );
    }

    final search = await keyboard(
      () => showNoteSearchSheet(ctx, wref, notes.first, initialQuery: 'yazı'),
      '_NoteSearchSheet',
    );
    final picker = await keyboard(
      () => showNotePicker(ctx, notes: notes),
      '_NotePicker',
    );
    final result = await keyboard(
      () => showAiResultSheet(
        ctx,
        title: 'Özet',
        text: 'satır bir\nsatır iki',
        onInsert: (_) {},
        onCreateNote: (_, {asType}) {},
      ),
      '_AiResultSheet',
    );
    final measured = {
      'arama_kurulum': search.$1,
      'arama_dizilme': search.$2,
      'secici_kurulum': picker.$1,
      'secici_dizilme': picker.$2,
      'ai_sonuc_kurulum': result.$1,
      'ai_sonuc_dizilme': result.$2,
    };
    // ignore: avoid_print
    print(
      'S53: $measured · levha kökü: ${search.$3}/${picker.$3}/${result.$3}',
    );
    expect(search.$3, 0, reason: 'arama levhası klavye karesinde kuruldu');
    expect(picker.$3, 0, reason: 'not seçici klavye karesinde kuruldu');
    expect(result.$3, 0, reason: 'AI sonuç levhası klavye karesinde kuruldu');
    for (final e in measured.entries) {
      expect(
        e.value,
        lessThanOrEqualTo(budget[e.key] as int),
        reason: 'S53 ${e.key}',
      );
    }
  });
}
