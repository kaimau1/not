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
import 'package:notlar/features/notes/presentation/card_preview.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F74.4 (K-D5): kartta işaretsiz madde varken işaretliler tek satır
/// "✓ N tamamlandı"; hepsi işaretliyse ilk 2 üstü çizili + "✓ Hepsi tamam
/// (N)". `card_show_checked` açıkken bugünkü görünüm.
void main() {
  const open1 = NoteItem(id: 'a', text: 'süt');
  const open2 = NoteItem(id: 'b', text: 'ekmek');
  const done1 = NoteItem(id: 'c', text: 'yumurta', checked: true);
  const done2 = NoteItem(id: 'd', text: 'peynir', checked: true);
  const done3 = NoteItem(id: 'e', text: 'zeytin', checked: true);

  group('cardItemSlice', () {
    test('işaretsiz varken işaretliler özete iner', () {
      final s = cardItemSlice([
        open1,
        open2,
        done1,
        done2,
      ], 5, collapseChecked: true);
      expect(s.shown, [open1, open2]);
      expect(s.done, 2);
      expect(s.allDone, isFalse);
      expect(s.more, 0);
    });

    test('dilim sınırı yalnız işaretsizlere uygulanır', () {
      final s = cardItemSlice([
        open1,
        open2,
        done1,
      ], 1, collapseChecked: true);
      expect(s.shown, [open1]);
      expect(s.more, 1);
      expect(s.done, 1);
    });

    test('hepsi işaretli: ilk iki madde + hepsi tamam', () {
      final s = cardItemSlice([
        done1,
        done2,
        done3,
      ], 5, collapseChecked: true);
      expect(s.shown, [done1, done2]);
      expect(s.allDone, isTrue);
      expect(s.done, 3);
    });

    test('tercih açıkken bugünkü görünüm', () {
      final s = cardItemSlice([
        open1,
        done1,
        done2,
      ], 2, collapseChecked: false);
      expect(s.shown, [open1, done1]);
      expect(s.more, 1);
      expect(s.done, 0);
    });
  });

  Future<void> pumpCard(
    WidgetTester tester,
    Note note, {
    bool showChecked = false,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (showChecked) 'card_show_checked': true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('ben'),
          notesRepositoryProvider.overrideWithValue(
            NotesRepository(FakeFirebaseFirestore(), 'ben'),
          ),
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
                builder: (_, _) => Scaffold(
                  body: SizedBox(width: 300, child: NoteCard(note: note)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('kartta işaretliler tek satır', (tester) async {
    await pumpCard(
      tester,
      const Note(
        id: 'n',
        type: NoteType.checklist,
        title: 'Alışveriş',
        items: [done1, open1, done2, open2],
      ),
    );
    expect(find.text('süt'), findsOneWidget);
    expect(find.text('ekmek'), findsOneWidget);
    expect(find.text('yumurta'), findsNothing);
    expect(find.text('✓ 2 tamamlandı'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('hepsi işaretli: hepsi tamam', (tester) async {
    await pumpCard(
      tester,
      const Note(
        id: 'n',
        type: NoteType.text,
        title: 'Bitti',
        items: [done1, done2, done3],
      ),
    );
    expect(find.text('yumurta'), findsOneWidget);
    expect(find.text('peynir'), findsOneWidget);
    expect(find.text('zeytin'), findsNothing);
    expect(find.text('✓ Hepsi tamam (3)'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('card_show_checked açıkken bugünkü görünüm', (tester) async {
    await pumpCard(
      tester,
      const Note(
        id: 'n',
        type: NoteType.checklist,
        title: 'Alışveriş',
        items: [done1, open1],
      ),
      showChecked: true,
    );
    expect(find.text('yumurta'), findsOneWidget);
    expect(find.textContaining('tamamlandı'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
  });
}
