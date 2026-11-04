import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/search_highlight.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F21.6 (AKICILIK_PLANI): arama vurgusu kartın üstünde ayrı katman — sorgu
/// değişince kart yeniden kurulmaz, yalnız vurgu yeniden boyanır.
void main() {
  test('eşleşme başlangıçları katlanmış metinde (İ/ı, aksan)', () {
    expect(searchMatchStarts('Önemli ve ÖNEMLİ', 'onemli'), [0, 10]);
    expect(searchMatchStarts('abc', ''), isEmpty);
  });

  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final deep = Note(
    id: 'd',
    type: NoteType.text,
    title: 'Başlık',
    body:
        '${List.generate(60, (i) => 'satır $i').join('\n')}\n'
        'derinde benzersiz sözcük\n${List.generate(20, (i) => 'son $i').join('\n')}',
    updatedAt: DateTime(2026, 11, 4),
  );

  List<TextRange> ranges(WidgetTester tester) => [
    for (final r in tester.renderObjectList<RenderSearchHighlight>(
      find.byType(SearchHighlight),
    ))
      ...r.currentRanges(),
  ];

  String longest(WidgetTester tester) {
    var out = '';
    for (final w in tester.widgetList<RichText>(find.byType(RichText))) {
      final t = w.text.toPlainText();
      if (t.length > out.length) out = t;
    }
    return out;
  }

  testWidgets('canlı sorgu: kart aynı örnek, vurgu ve kesit güncellenir; '
      'LayoutBuilder içinde yazım güvenli', (tester) async {
    final live = ValueNotifier<String>('satır');
    addTearDown(live.dispose);
    // Kart önbelleği (pano gibi): aynı örnek döner.
    final card = NoteCard(note: deep, liveQuery: live);
    var query = 'satır';
    late StateSetter outer;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                outer = setState;
                // Pano canlı sorguyu yerleşim aşamasında (LayoutBuilder)
                // yazıyor — aynı yol.
                return LayoutBuilder(
                  builder: (context, c) {
                    if (live.value != query) live.value = query;
                    return SizedBox(width: 300, child: card);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(ranges(tester), isNotEmpty);
    final cardElement = tester.element(find.byType(NoteCard));

    outer(() => query = 'satır 1');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(
      identical(tester.element(find.byType(NoteCard)), cardElement),
      isTrue,
    );
    expect(ranges(tester).first.end - ranges(tester).first.start, 7);

    // Derindeki eşleşme: kesit görünür ve vurgulanır.
    outer(() => query = 'benzersiz');
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(longest(tester), contains('benzersiz sözcük'));
    expect(ranges(tester), isNotEmpty);

    // Eşleşmeyen sorgu: vurgu yok, hata yok.
    outer(() => query = 'zzzz');
    await tester.pump();
    expect(ranges(tester), isEmpty);
  });

  testWidgets('sabit sorgu boşken katman hiç kurulmaz', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(width: 300, child: NoteCard(note: deep)),
          ),
        ),
      ),
    );
    expect(find.byType(SearchHighlight), findsNothing);
  });
}
