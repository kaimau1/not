import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/note_grid.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **KARE ÖLÇÜMÜ (F2.6)** — "kasma" bulgusu 10+ turda geldi ama hiç sayı
/// yoktu. Gerçek cihazda/emülatörde (profil kipi) iki senaryo ölçülür:
///  (a) 300 notlu ana ekran ızgarasında fırlatma kaydırma,
///  (b) editörün metin alanına (aynı `WrapTextController`) 200 karakter.
/// Zaman çizelgeleri sürücüye gider (`test_driver/perf_driver.dart`), o
/// kare build/raster p90'ını özetler; bütçe p90 build
/// < 8 ms (120 Hz karesi). Firebase gerekmez: sağlayıcılar sahte.
///
/// Koşturma (Android cihaz/emülatör bağlıyken):
///   flutter drive --profile --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart
/// CI: build.yml → `perf` işi (yalnız elle tetiklenince).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('tr'),
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );

  testWidgets('ana ekran: 300 not fırlatma kaydırma', (tester) async {
    final notes = [
      for (var i = 0; i < 300; i++)
        Note(
          id: 'n$i',
          type: i % 3 == 0 ? NoteType.checklist : NoteType.text,
          title: i % 4 == 0 ? '' : 'Not $i',
          body: List.filled(
            1 + i % 7,
            'Bugün **önemli** bir satır $i.',
          ).join('\n'),
          pinned: i < 4,
          updatedAt: DateTime(2026, 10, 19).subtract(Duration(hours: i)),
        ),
    ];
    final scroll = ScrollController();
    await tester.pumpWidget(
      host(
        LayoutBuilder(
          builder: (context, c) {
            const columns = 2;
            final cellWidth = (c.maxWidth - 24 - 8) / columns;
            return CustomScrollView(
              controller: scroll,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: sliverBalancedNoteColumns(
                    items: notes,
                    columns: columns,
                    cellWidth: cellWidth,
                    cell: (context, i) => NoteCard(note: notes[i]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await binding.traceAction(() async {
      for (var i = 0; i < 6; i++) {
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, -900),
          4000,
        );
        await tester.pumpAndSettle();
      }
      for (var i = 0; i < 3; i++) {
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 900),
          4000,
        );
        await tester.pumpAndSettle();
      }
    }, reportKey: 'dashboard_scroll');
  });

  testWidgets('editör: 200 karakter yazma', (tester) async {
    final controller = WrapTextController(
      text: List.filled(40, 'Uzun bir notun **biçimli** satırı.').join('\n'),
    );
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(border: InputBorder.none),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    await binding.traceAction(() async {
      var text = controller.text;
      for (var i = 0; i < 200; i++) {
        text += i % 30 == 29 ? '\n' : 'a';
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();
    }, reportKey: 'editor_typing');
  });
}
