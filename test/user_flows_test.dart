import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/note_quick_export.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **Uçtan uca akışlar** (F18.8) — bulutta koşan hâli: sahte depo üstünde
/// kullanıcı akışının veri yolu. (2) PDF + balon paylaşımı
/// `media_bubbles_share_test`te, (5) tam yedek `backup_service_test`te.
void main() {
  late FakeFirebaseFirestore db;
  late NotesRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = NotesRepository(db, 'u1');
  });

  Future<Note> noteNow(String id) async =>
      (await repo.watchNote(id).firstWhere((n) => n != null))!;

  test('(1) + → Metin → yaz → paylaş metni gövdeyi taşır', () async {
    final id = await repo.createNote(NoteType.text);
    await repo.updateNote(
      (await noteNow(id)).copyWith(title: 'Toplantı', body: 'Gündem: bütçe'),
    );
    final text = NoteQuickExport.contentOf(
      await noteNow(id),
      const ShareTextOptions(),
    );
    expect(text, contains('Gündem: bütçe'));
  });

  test('(3) iki sayfalı not → kopyala: iki sayfa da gelir', () async {
    final id = await repo.createNote(NoteType.text);
    await repo.updateNote(
      (await noteNow(id)).copyWith(
        body: 'birinci sayfa',
        textPages: const [
          NoteTextPage(id: ''),
          NoteTextPage(
            id: 'p2',
            body: 'ikinci sayfa',
            items: [NoteItem(id: 'i1', text: 'madde')],
          ),
        ],
        activePage: 'p2',
      ),
    );
    final copyId = await repo.duplicateNote(await noteNow(id));
    final copy = await noteNow(copyId);
    expect(copy.body, 'birinci sayfa');
    expect(copy.textPages.map((p) => p.body), contains('ikinci sayfa'));
    final page2 = copy.textPages.firstWhere((p) => p.id == 'p2');
    expect(page2.items.single.text, 'madde');
    expect(page2.items.single.id, isNot('i1'));
    expect(copy.activePage, 'p2');
  });

  testWidgets('(4) liste → işaretle → işaretlileri sil', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var latest = const <NoteItem>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ItemsEditor(
              items: const [
                NoteItem(id: 'a', text: 'Süt'),
                NoteItem(id: 'b', text: 'Ekmek'),
                NoteItem(id: 'c', text: 'Yumurta'),
              ],
              onChanged: (items) => latest = items,
              showCheckboxes: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    // İşaretlenen madde alttaki blokta: sıradaki ilk kutu artık "Ekmek".
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    final deleteButton = find.byIcon(Icons.delete_sweep_outlined);
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(latest.where((i) => i.text.isNotEmpty).map((i) => i.text), [
      'Yumurta',
    ]);
  });
}
