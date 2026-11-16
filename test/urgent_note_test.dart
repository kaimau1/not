import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/add_catalog.dart';
import 'package:notlar/features/notes/presentation/editor/attach_sheet.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ACİL not (kullanıcı isteği 2026-11-16): sabit/yıldız gibi bir not bayrağı;
/// ana ekranda sabitlerin de üstünde, kartta ünlem, + ve ⋮ menüsünden.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('tr'));
  });

  Note mk(String id, {bool pinned = false, bool urgent = false}) => Note(
    id: id,
    type: NoteType.text,
    title: id,
    pinned: pinned,
    urgent: urgent,
  );

  test('alan kaydedilir ve geri okunur', () {
    expect(Note.knownKeys, contains('urgent'));
    final map = mk('a', urgent: true).toMap();
    expect(map['urgent'], isTrue);
    expect(Note.fromMap('a', {'urgent': true}).urgent, isTrue);
    expect(Note.fromMap('a', {'title': 'x'}).urgent, isFalse);
  });

  test(
    'ana ekran bölümleri: acil → sabit → diğer, acil+sabit yalnız acilde',
    () {
      final s = homeSections([
        mk('d'),
        mk('p', pinned: true),
        mk('u', urgent: true),
        mk('up', pinned: true, urgent: true),
      ]);
      expect(s.urgent.map((n) => n.id), ['u', 'up']);
      expect(s.pinned.map((n) => n.id), ['p']);
      expect(s.others.map((n) => n.id), ['d']);
    },
  );

  test('Acil yalnız not içindeki + levhasında', () {
    expect(
      addCatalog(l10n, AddContext.inNote).map((e) => e.id),
      contains('urgent'),
    );
    expect(
      addCatalog(l10n, AddContext.newNote).map((e) => e.id),
      isNot(contains('urgent')),
    );
  });

  testWidgets('+ levhası Acil seçince "urgent" döner', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await showAttachSheet(context),
            child: const Text('aç'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.urgentMark));
    await tester.tap(find.text(l10n.urgentMark));
    await tester.pumpAndSettle();
    expect(picked, 'urgent');
  });

  testWidgets('acil kartta ünlem görünür, acil olmayanda yok', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    Future<void> pump(Note note) async {
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

    await pump(mk('a', urgent: true));
    expect(find.byKey(const ValueKey('card-urgent')), findsOneWidget);
    await pump(mk('b'));
    expect(find.byKey(const ValueKey('card-urgent')), findsNothing);
  });
}
