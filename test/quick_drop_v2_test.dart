import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/core/utils/spell_learn.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/domain/quick_drop.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/quick_drop_sheet.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/features/shopping/domain/shop_item_meta.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DropV2Repo implements NotesRepository {
  final updates = <({String id, Map<String, dynamic> fields})>[];
  final richCreated =
      <
        ({
          NoteType type,
          String title,
          String body,
          List<NoteItem>? items,
          List<String> tags,
          bool urgent,
          String? listKind,
        })
      >[];

  @override
  Future<void> updateFields(String noteId, Map<String, dynamic> fields) async {
    updates.add((id: noteId, fields: fields));
  }

  @override
  Future<String> createRichNote(
    NoteType type, {
    double? orderIndex,
    String title = '',
    String body = '',
    List<NoteItem>? items,
    List<String> tags = const [],
    bool urgent = false,
    String? folderId,
    DateTime? reminderAt,
    int listColumns = 1,
    String? listKind,
  }) async {
    richCreated.add((
      type: type,
      title: title,
      body: body,
      items: items,
      tags: tags,
      urgent: urgent,
      listKind: listKind,
    ));
    return 'rich-${richCreated.length}';
  }

  @override
  Future<String> createNote(
    NoteType type, {
    double? orderIndex,
    String title = '',
    String body = '',
    List<String>? items,
    String? folderId,
    DateTime? reminderAt,
    int listColumns = 1,
    String? listKind,
  }) async {
    return 'plain-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });
  setUp(() => AutoSpell.memory = SpellMemory());

  group('QuickDrop v2 — parsers, modifiers & smart list commands', () {
    test('EN prepositions & trailing arrow routing resolve targets', () {
      const titles = ['Shopping List', 'Work Tasks', 'Packing List'];
      final put = parseDropTarget('put batteries into shopping list', titles);
      expect(put.index, 0);
      expect(put.content, 'batteries');

      final save = parseDropTarget('save passport on packing list', titles);
      expect(save.index, 2);
      expect(save.content, 'passport');

      final arrow = parseDropTarget('report draft -> Work Tasks', titles);
      expect(arrow.index, 1);
      expect(arrow.content, 'report draft');
    });

    test('1-edit fuzzy title matching tolerates single typos >= 5 chars', () {
      const titles = ['Alışveriş Listesi', 'Project Notes'];
      final trTypo = parseDropTarget('alisvers: süt', titles);
      expect(trTypo.index, 0);
      expect(trTypo.content, 'süt');

      final enTypo = parseDropTarget('add specs to projct notes', titles);
      expect(enTypo.index, 1);
      expect(enTypo.content, 'specs');
    });

    test('parseNewSmartListCommand detects TR & EN list creation commands', () {
      final trCmd = parseNewSmartListCommand(
        'yeni bavul listesi: pasaport, şarj',
      );
      expect(trCmd?.kind, SmartListKind.packing);
      expect(trCmd?.content, 'pasaport, şarj');

      final enCmd = parseNewSmartListCommand('new workout list: Squat, Plank');
      expect(enCmd?.kind, SmartListKind.workout);
      expect(enCmd?.content, 'Squat, Plank');

      expect(parseNewSmartListCommand('normal not içeriği'), isNull);
    });

    test('extractQuickDropModifiers extracts #tags & !urgent cleanly', () {
      final m = extractQuickDropModifiers('Süt al #ev !acil #market');
      expect(m.urgent, isTrue);
      expect(m.tags, ['ev', 'market']);
      expect(m.text, 'Süt al');

      final en = extractQuickDropModifiers('Call doctor !urgent #health');
      expect(en.urgent, isTrue);
      expect(en.tags, ['health']);
      expect(en.text, 'Call doctor');
    });

    test('quickDropFields extracts inline prices into ShopItemMeta', () {
      const note = Note(
        id: 'shop-1',
        type: NoteType.checklist,
        title: 'Market',
        listKind: 'shopping',
      );
      final res = quickDropFields(note, 'Süt 45 TL', locale: 'tr');
      final rawItems = res.fields['items'] as List;
      final saved = NoteItem.fromMap(rawItems.single as Map<String, dynamic>);
      expect(saved.text, 'Süt');
      expect(ShopItemMeta.fromItem(saved).unitPrice, 45.0);
    });
  });

  group('QuickDropSheet v2 widget flows', () {
    testWidgets(
      'creates smart list via command and supports keep-open toggle',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = _DropV2Repo();
        const notes = [
          Note(id: 'n1', type: NoteType.text, title: 'Genel Notlar'),
        ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              notesRepositoryProvider.overrideWithValue(repo),
              notesStreamProvider.overrideWithValue(const AsyncData(notes)),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('tr'),
              home: Scaffold(
                body: Builder(
                  builder: (ctx) => Center(
                    child: ElevatedButton(
                      onPressed: () => showQuickDropSheet(ctx),
                      child: const Text('open'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // Enable Keep Open in settings menu
        await tester.tap(find.byKey(const ValueKey('quick-drop-settings')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('quick-drop-keep-open')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('quick-entry-field')),
          'yeni bavul listesi: pasaport #tatil !acil',
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('quick-drop-target-smart')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('quick-drop-add')));
        await tester.pumpAndSettle();

        expect(repo.richCreated, hasLength(1));
        final created = repo.richCreated.single;
        expect(created.listKind, 'packing');
        expect(created.urgent, isTrue);
        expect(created.tags, ['tatil']);

        // Sheet remains open because Keep Open was enabled!
        expect(find.byKey(const ValueKey('quick-entry-field')), findsOneWidget);
      },
    );
  });
}
