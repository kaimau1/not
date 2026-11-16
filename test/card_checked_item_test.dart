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

/// Kullanıcı bulgusu 2026-11-16 ("dashboard'da iken madde tiklenebiliyor, bu
/// olmamalı"): ana ekran kartında kutucuklar SALT GÖRÜNÜM. Boş ya da işaretli
/// kutuya dokunmak notu değiştirmez; kart dokunuşu gibi notu açar.
void main() {
  testWidgets('kart kutucuğu notu değiştirmez, notu açar', (tester) async {
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
    for (final icon in [Icons.check_box_outline_blank, Icons.check_box]) {
      // Her tur taze ağaç (yeni anahtar): rota yığını sıfırlansın.
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey(icon),
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
                GoRoute(
                  path: '/note/:id',
                  builder: (_, s) => Text('editör ${s.pathParameters['id']}'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(icon));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(repo.writes, isEmpty, reason: '$icon notu değiştirmez');
      expect(find.text('editör n'), findsOneWidget, reason: '$icon notu açar');
    }
    await tester.pump(const Duration(seconds: 2));
  });
}
