import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kartta görünenler (kullanıcı isteği 2026-10-20: "97/97 sayacı ayarlardan
/// açılıp kapatılsın, varsayılan kapalı; bu tip şeylerin hepsi tek tek
/// açılıp kapatılabilsin").
void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  final note = Note(
    id: 'c',
    type: NoteType.checklist,
    title: 'Liste',
    tags: const ['yazilim'],
    pinned: true,
    updatedAt: DateTime(2026, 10, 20, 22, 21),
    items: [
      for (var i = 0; i < 10; i++)
        NoteItem(id: 'i$i', text: 'madde $i', checked: i < 3),
    ],
  );

  Future<void> pump(WidgetTester tester, Map<String, bool> values) async {
    for (final e in values.entries) {
      await prefs.setBool(e.key, e.value);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(width: 300, child: NoteCard(note: note)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('varsayılan: ilerleme sayacı YOK, öbürleri görünür', (
    tester,
  ) async {
    await pump(tester, const {});
    expect(find.text('3/10'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('#yazilim'), findsOneWidget);
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.textContaining('madde daha'), findsOneWidget);
  });

  testWidgets('her öğe tek tek açılıp kapatılır', (tester) async {
    await pump(tester, const {
      'card_show_progress': true,
      'card_show_tag': false,
      'card_show_status_icons': false,
      'card_show_more_count': false,
      'card_show_date': false,
    });
    expect(find.text('3/10'), findsOneWidget);
    expect(find.text('#yazilim'), findsNothing);
    expect(find.byIcon(Icons.push_pin), findsNothing);
    expect(find.textContaining('madde daha'), findsNothing);
    expect(find.text('22:21'), findsNothing);
  });

  // F14.2: 11 kart anahtarı Görünüm'de alt alta değil, canlı örnekli
  // levhada; örnek kart anahtarla aynı anda değişir.
  testWidgets('Kartta görünenler levhası: canlı örnek anahtarla değişir', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: const Scaffold(body: CardElementsRow()),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('açık'), findsOneWidget);
    await tester.tap(find.byType(CardElementsRow));
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('card-elements-preview'));
    expect(preview, findsOneWidget);
    expect(
      find.descendant(of: preview, matching: find.text('#ev')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Etiket'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: preview, matching: find.text('#ev')),
      findsNothing,
    );
  });
}
