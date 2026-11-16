import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPrintLayouts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/capture_mode_sheet.dart';
import 'package:notlar/features/notes/presentation/file_use_sheet.dart';
import 'package:notlar/features/notes/presentation/place_reminder_sheet.dart';
import 'package:notlar/features/notes/presentation/share_target_sheet.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

import 'support/editor_harness.dart';

/// **S52 — levha klavye karesi** (şablon kasmasının kalıbı, S48 /
/// 8820bba2): levha builder'ı `viewInsetsOf(sheetContext)` okuyup her
/// çağrıda YENİ içerik örneği kurarsa klavyenin her karesinde bütün levha
/// baştan kurulur. İçerik builder dışında bir kez kurulunca yalnız dolgu
/// yeniden kurulur. Ölçü: 6 klavye karesinde TÜM widget kurulumu + dizilme.
void main() {
  final budget =
      (jsonDecode(File('test/perf_budget/budgets.json').readAsStringSync())
              as Map<String, dynamic>)['S52']
          as Map<String, dynamic>;

  testWidgets('S52: dört levha × klavye açılışı (6 inset karesi)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final notes = [
      for (var i = 0; i < 12; i++)
        Note(id: 'n$i', type: NoteType.text, title: 'Not $i', body: 'yazı $i'),
    ];
    late BuildContext ctx;
    late WidgetRef wref;
    await tester.pumpWidget(
      ProviderScope(
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
    Future<(int, int)> keyboard(void Function() open) async {
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
      return (counter.counts.values.fold(0, (a, b) => a + b), layouts);
    }

    final capture = await keyboard(
      () => showCaptureModeSheet(ctx, title: 'Başlık', askAnyway: true),
    );
    final file = await keyboard(
      () => showFileUseSheet(
        ctx,
        kind: PickedFileKind.image,
        names: const ['a.jpg', 'b.jpg'],
      ),
    );
    final place = await keyboard(
      () => showPlaceReminderSheet(ctx, wref, notes.first),
    );
    final share = await keyboard(
      () => showShareTargetSheet(
        ctx,
        incoming: const ShareIncoming(
          files: [(name: 'kasko.pdf', kind: AttachmentKind.pdf)],
        ),
        notes: notes,
      ),
    );
    final measured = {
      'kip_kurulum': capture.$1,
      'kip_dizilme': capture.$2,
      'dosya_kurulum': file.$1,
      'dosya_dizilme': file.$2,
      'konum_kurulum': place.$1,
      'konum_dizilme': place.$2,
      'paylas_kurulum': share.$1,
      'paylas_dizilme': share.$2,
    };
    // ignore: avoid_print
    print('S52: $measured');
    for (final e in measured.entries) {
      expect(
        e.value,
        lessThanOrEqualTo(budget[e.key] as int),
        reason: 'S52 ${e.key}',
      );
    }
  });
}
