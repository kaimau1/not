import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/note_template_sheet.dart';
import 'package:notlar/features/notes/presentation/quick_list_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AKILLI LİSTE (kullanıcı isteği 2026-11-16): tek tip liste; türü
/// söylenenlerden bulur, maddeleri reyon/grup sırasına dizer.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
  });
  setUp(() => AutoSpell.memory = SpellMemory());

  group('tür', () {
    test('öbekten: "bavul listesi", "alışveriş listesi", "market"', () {
      expect(smartKindFromPhrase('bavul listesi'), SmartListKind.packing);
      expect(smartKindFromPhrase('Tatil için'), SmartListKind.packing);
      expect(smartKindFromPhrase('alışveriş listesi'), SmartListKind.shopping);
      expect(smartKindFromPhrase('market'), SmartListKind.shopping);
      expect(smartKindFromPhrase('liste'), isNull);
      expect(smartKindFromPhrase('markete uğra ekmek al'), isNull);
      expect(smartKindFromPhrase('domates'), isNull);
    });

    test('maddelerden: yalnız tek türe ait olanlar sayılır', () {
      ({bool grocery, bool packing}) g() => (grocery: true, packing: false);
      ({bool grocery, bool packing}) p() => (grocery: false, packing: true);
      ({bool grocery, bool packing}) both() => (grocery: true, packing: true);
      expect(smartKindOf([g(), g(), p()]), SmartListKind.shopping);
      expect(smartKindOf([p(), p(), g()]), SmartListKind.packing);
      expect(smartKindOf([both(), both()]), SmartListKind.generic);
      expect(smartKindOf(const []), SmartListKind.generic);
    });

    test('sıra: türün grupları önce, tanınmayan en sonda', () {
      const docs = kPackingGroupBase; // PackingGroup.docs
      const clothes = kPackingGroupBase + 1;
      expect(
        smartRank(SmartListKind.packing, grocery: -1, packing: docs),
        lessThan(
          smartRank(SmartListKind.packing, grocery: -1, packing: clothes),
        ),
      );
      // Bavulda market maddesi bavul gruplarından sonra.
      expect(
        smartRank(SmartListKind.packing, grocery: 0, packing: -1),
        greaterThan(
          smartRank(SmartListKind.packing, grocery: -1, packing: clothes),
        ),
      );
      expect(smartRank(SmartListKind.shopping, grocery: -1, packing: -1), -1);
    });
  });

  group('ekran', () {
    Future<SharedPreferences> open(
      WidgetTester tester, {
      Map<String, Object> values = const {},
      List<Note> notes = const [],
    }) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
            notesRepositoryProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Consumer(
              builder: (context, ref, _) {
                ref.watch(notesStreamProvider);
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () =>
                        showQuickList(context, smartListArgs(context)),
                    child: const Text('aç'),
                  ),
                );
              },
            ),
          ),
        ),
      );
      // Ana ekran akışı uygulamada hep dinlenir: değer hazır olsun.
      await tester.pump();
      await tester.tap(find.text('aç'));
      await tester.pumpAndSettle();
      return prefs;
    }

    Finder field() => find.byKey(const ValueKey('quick-entry-field'));
    String title(WidgetTester tester) => tester
        .widget<TextField>(find.byKey(const ValueKey('quick-list-title')))
        .controller!
        .text;
    List<String> rows(WidgetTester tester) {
      final scroll = find.byKey(const ValueKey('quick-list-scroll'));
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: scroll, matching: find.byType(Text)),
          )
          .map((t) => t.data ?? '')
          .where((t) => t.isNotEmpty)
          .toList();
      // İki sütun: önce sol sütun yukarıdan aşağı, sonra sağ — sırayı
      // ekrandaki konumdan değil bu düzenden oku.
      return texts;
    }

    testWidgets('bavul maddeleri: başlık "Bavul listesi", belgeler önce', (
      tester,
    ) async {
      await open(tester);
      expect(title(tester), 'Liste');
      await tester.enterText(field(), 'tişört, şort, pasaport, şarj aleti,');
      await tester.pumpAndSettle();
      expect(title(tester), 'Bavul listesi');
      expect(find.byIcon(Icons.luggage_outlined), findsOneWidget);
      expect(rows(tester), ['Pasaport', 'Tişört', 'Şort', 'Şarj aleti']);
    });

    testWidgets('market maddeleri reyon sırasıyla; tür öbeği madde olmaz', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(field(), 'alışveriş listesi, et, domates, ekmek,');
      await tester.pumpAndSettle();
      expect(title(tester), 'Alışveriş listesi');
      // Manav → fırın → kasap (QuickAisle sırası).
      expect(rows(tester), ['Domates', 'Ekmek', 'Et']);
    });

    testWidgets('boşlukla yazılan market maddeleri ayrılır (sözlük hatası)', (
      tester,
    ) async {
      // 2026-11-17: akıllı listenin ayrıştırıcısında 1100 maddelik market
      // sözlüğü yoktu; çiplerde olmayan "süt yumurta ekmek" TEK madde
      // oluyordu.
      await open(tester);
      await tester.enterText(field(), 'süt yumurta ekmek ');
      await tester.pumpAndSettle();
      final r = rows(tester);
      expect(r, containsAll(<String>['Süt', 'Yumurta', 'Ekmek']));
      expect(r.where((t) => t.contains(' ')), isEmpty, reason: '$r');
    });

    // AL-1 (17 Kasım raporu §5.2): sık kullanılanlar TÜRE bölünür, geçen
    // seferden kalanlar başlığa değil türe göre, boş ekranda ipucu.
    testWidgets('boş akıllı listede tür ipucu', (tester) async {
      await open(tester);
      expect(find.textContaining('bavul listesi'), findsOneWidget);
    });

    testWidgets('sık eklenenler türe göre kaydedilir ve gösterilir', (
      tester,
    ) async {
      final memory = QuickEntryMemory(
        kinds: {
          'smart:market': {'zeytin': ('Zeytin', 3)},
          'smart:bavul': {'mayo': ('Mayo', 2)},
        },
      );
      final prefs = await open(
        tester,
        values: {'quick_entry_memory_v1': memory.encode()},
      );
      // Tür belli değilken ikisi birden.
      expect(find.byKey(const ValueKey('quick-chip-Zeytin')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-chip-Mayo')), findsOneWidget);
      await tester.enterText(field(), 'tişört, şort,');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('quick-tab-0')));
      await tester.pumpAndSettle();
      // Bavul: market sık eklenenleri karışmaz.
      expect(find.byKey(const ValueKey('quick-chip-Mayo')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-chip-Zeytin')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('quick-list-done')));
      await tester.pumpAndSettle();
      final saved = QuickEntryMemory.decode(
        prefs.getString('quick_entry_memory_v1'),
      );
      expect(saved.top('smart:bavul'), containsAll(<String>['Tişört', 'Şort']));
      expect(saved.top('smart:market'), ['Zeytin']);
      expect(saved.top('smart'), isEmpty);
      await tester.pump(const Duration(seconds: 8));
    });

    testWidgets('geçen seferden kalanlar başlığa değil türe göre', (
      tester,
    ) async {
      final notes = [
        Note(
          id: 'antalya',
          type: NoteType.checklist,
          title: 'Antalya',
          updatedAt: DateTime(2026, 11, 10),
          items: const [
            NoteItem(id: '1', text: 'Pasaport', checked: true),
            NoteItem(id: '2', text: 'Mayo'),
            NoteItem(id: '3', text: 'Güneş kremi'),
          ],
        ),
        Note(
          id: 'market',
          type: NoteType.checklist,
          title: 'Liste',
          updatedAt: DateTime(2026, 11, 12),
          items: const [NoteItem(id: '1', text: 'Domates')],
        ),
      ];
      await open(tester, notes: notes);
      // Düz "Liste" başlığıyla eşleşen market listesi bavulda görünmez.
      await tester.enterText(field(), 'tişört, şort,');
      await tester.pumpAndSettle();
      expect(find.text('Geçen seferden'), findsOneWidget);
      await tester.tap(find.text('Geçen seferden'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('quick-chip-Mayo')), findsOneWidget);
      expect(find.byKey(const ValueKey('quick-chip-Pasaport')), findsNothing);
      expect(find.byKey(const ValueKey('quick-chip-Domates')), findsNothing);
    });

    testWidgets('elle değişen başlığa dokunulmaz', (tester) async {
      await open(tester);
      await tester.enterText(
        find.byKey(const ValueKey('quick-list-title')),
        'Antalya',
      );
      await tester.enterText(field(), 'mayo, bikini, güneş kremi,');
      await tester.pumpAndSettle();
      expect(title(tester), 'Antalya');
    });
  });
}
