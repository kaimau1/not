import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
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
///  (b) editörün metin alanına (aynı `WrapTextController`) 200 karakter,
///  (c) 30 KB'lık notta 100 tuş (K2 — tek `TextField` tuş başına O(n)),
///  (d) kart ızgarasında arama sorgusu değişimi (K1 — vurgu kartı kurar).
/// **GERÇEKÇİ VERİ (F20.3, 2026-11-04):** ızgarada 10 uzun gövde (300–600
/// satır) ve 120 maddelik liste var — telefondaki ölçüm setinin (244 not)
/// ağır uçları. (c)/(d) bugün bütçeyi AŞMALI (K2 Faz 24, arama F21.6
/// bitmeden); kırmızı beklenen sonuçtur, iş yalnız `[perf]` ile koşar.
/// Zaman çizelgeleri sürücüye gider (`test_driver/perf_driver.dart`), o
/// kare build/raster p90'ını özetler; bütçe p90 build
/// < 8 ms (120 Hz karesi). Firebase gerekmez: sağlayıcılar sahte.
///
/// Koşturma (Android cihaz/emülatör bağlıyken):
///   flutter drive --profile --driver=test_driver/perf_driver.dart \
///     --target=integration_test/perf_test.dart
/// CI: build.yml → `perf` işi (elle ya da commit başlığında `[perf]`).
///
/// **pumpAndSettle YOK** (F18.7, 2026-11-02): koşu 41340200235 34 dk çıktısız
/// kaldı. Kök neden: odaktaki metin alanının imleci sürekli yanıp söner
/// (her 500 ms yeni kare ister) → `pumpAndSettle` hiç "durulmaz", 10 dk'lık
/// zaman aşımına kadar bekler; senaryo başına birkaç kez. Yerine sabit süreli
/// [_settle] — ölçüm için yeterli, asla takılmaz.
Future<void> _settle(WidgetTester tester, [int frames = 30]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

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

  Widget grid(
    List<Note> notes, {
    ScrollController? scroll,
    String query = '',
  }) => host(
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
                cell: (context, i) => NoteCard(
                  key: ValueKey(notes[i].id),
                  note: notes[i],
                  highlightQuery: query,
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  testWidgets('ana ekran: 300 not fırlatma kaydırma', (tester) async {
    final notes = _realisticNotes();
    final scroll = ScrollController();
    await tester.pumpWidget(grid(notes, scroll: scroll));
    await _settle(tester);

    await binding.traceAction(() async {
      for (var i = 0; i < 6; i++) {
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, -900),
          4000,
        );
        await _settle(tester, 120);
      }
      for (var i = 0; i < 3; i++) {
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, 900),
          4000,
        );
        await _settle(tester, 120);
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
    await _settle(tester);

    await binding.traceAction(() async {
      var text = controller.text;
      for (var i = 0; i < 200; i++) {
        text += i % 30 == 29 ? '\n' : 'a';
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _settle(tester);
    }, reportKey: 'editor_typing');
  });

  testWidgets('editör: 30 KB notta 100 tuş', (tester) async {
    final controller = WrapTextController(text: _longBody(30 * 1024));
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
    // Uzun alanın ortası ekran dışında: dokunuş yerine doğrudan odak.
    await tester.showKeyboard(find.byType(TextField));
    await _settle(tester);

    await binding.traceAction(() async {
      var text = controller.text;
      for (var i = 0; i < 100; i++) {
        text += i % 30 == 29 ? '\n' : 'a';
        await tester.enterText(find.byType(TextField), text);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await _settle(tester);
    }, reportKey: 'editor_typing_30kb');
  });

  testWidgets('editör: klavye aç/kapa ×10 (F38.7)', (tester) async {
    await tester.pumpWidget(
      host(
        KeyboardSnap(
          builder: (context, inset) => Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: TextField(
              controller: WrapTextController(text: _longBody(4 * 1024)),
              maxLines: null,
              expands: true,
            ),
          ),
        ),
      ),
    );
    await _settle(tester);
    addTearDown(tester.view.resetViewInsets);
    await binding.traceAction(() async {
      for (var round = 0; round < 10; round++) {
        for (var i = 1; i <= 15; i++) {
          tester.view.viewInsets = FakeViewPadding(bottom: i * 20);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pump(const Duration(milliseconds: 200));
        for (var i = 14; i >= 0; i--) {
          tester.view.viewInsets = FakeViewPadding(bottom: i * 20);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pump(const Duration(milliseconds: 200));
      }
    }, reportKey: 'keyboard_cycle');
  });

  testWidgets('ana ekran: arama sorgusu değişimi', (tester) async {
    final notes = _realisticNotes();
    var query = '';
    late StateSetter setQuery;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          setQuery = setState;
          return grid(notes, query: query);
        },
      ),
    );
    await _settle(tester);

    await binding.traceAction(() async {
      // Kullanıcı "önemli" yazıp siliyor: her harf bir sorgu değişimi.
      const word = 'önemli';
      for (var round = 0; round < 3; round++) {
        for (var i = 1; i <= word.length; i++) {
          setQuery(() => query = word.substring(0, i));
          await _settle(tester, 8);
        }
        for (var i = word.length - 1; i >= 0; i--) {
          setQuery(() => query = word.substring(0, i));
          await _settle(tester, 8);
        }
      }
    }, reportKey: 'dashboard_search');
  });
}

/// Telefondaki ölçüm setinin (Ek A, 244 not) ağır uçlarını taşıyan 300 not:
/// 10 uzun gövde (300–600 satır) ve 120 maddelik liste dahil.
List<Note> _realisticNotes() => [
  for (var i = 0; i < 300; i++)
    if (i % 30 == 7)
      Note(
        id: 'n$i',
        type: NoteType.text,
        title: 'Uzun not $i',
        body: List.generate(
          300 + (i * 37) % 301,
          (l) => 'Satır $l: bugün **önemli** bir ayrıntı ve biraz da metin.',
        ).join('\n'),
        updatedAt: DateTime(2026, 10, 19).subtract(Duration(hours: i)),
      )
    else if (i == 12)
      Note(
        id: 'n$i',
        type: NoteType.checklist,
        title: 'Alışveriş (120)',
        items: [
          for (var k = 0; k < 120; k++)
            NoteItem(id: 'i$k', text: 'Madde $k önemli', checked: k % 5 == 0),
        ],
        updatedAt: DateTime(2026, 10, 19).subtract(Duration(hours: i)),
      )
    else
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

/// Yaklaşık [bytes] büyüklüğünde biçimli, çok satırlı gövde.
String _longBody(int bytes) {
  final b = StringBuffer();
  var l = 0;
  while (b.length < bytes) {
    b.writeln('Satır ${l++}: uzun bir notun **biçimli** ve _eğik_ satırı.');
  }
  return b.toString();
}
