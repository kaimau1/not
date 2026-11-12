import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Repo extends NotesRepository {
  _Repo() : super(FakeFirebaseFirestore(), 'ben');
  final writes = <Map<String, dynamic>>[];

  @override
  void updateFields(String noteId, Map<String, dynamic> fields) =>
      writes.add(fields);
}

/// F60.S14: ana ekran kartında işaretli madde tek dokunuşla geri alınmaz;
/// işaretsiz madde işaretlenmeye devam eder.
void main() {
  testWidgets('işaretli kutu işareti kaldırmaz, boş kutu işaretler', (
    tester,
  ) async {
    // İşaretli madde kartta görünsün (F74.4: varsayılan tek satır özet).
    SharedPreferences.setMockInitialValues({'card_show_checked': true});
    final prefs = await SharedPreferences.getInstance();
    final repo = _Repo();
    const note = Note(
      id: 'n',
      type: NoteType.checklist,
      title: 'Liste',
      items: [
        NoteItem(id: 'a', text: 'bitti', checked: true),
        NoteItem(id: 'b', text: 'bekliyor'),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('ben'),
          notesRepositoryProvider.overrideWithValue(repo),
          calendarRepositoryProvider.overrideWithValue(null),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(
                  body: SizedBox(width: 300, child: NoteCard(note: note)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pump();
    expect(repo.writes, hasLength(1), reason: 'boş kutu işaretlenir');

    repo.writes.clear();
    await tester.tap(find.byIcon(Icons.check_box));
    await tester.pump();
    expect(repo.writes, isEmpty, reason: 'işaretli kutu geri alınmaz');
    await tester.pump(const Duration(seconds: 2));
  });
}
