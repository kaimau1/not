import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/core/app_icons.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/friends/data/friends_repository.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// **YAVAŞ DEPO**: Firestore'un çevrimdışı/yavaş ağ davranışı — yazım yerel
/// kopyaya (akışa) HEMEN düşer, dönen Future (sunucu onayı) HİÇ tamamlanmaz.
/// Arayüz bu Future'ı bekliyorsa test takılır/kırılır.
class _SlowRepo extends NotesRepository {
  _SlowRepo(this.notes) : super(FakeFirebaseFirestore(), 'ben');

  List<Note> notes;
  final out = StreamController<List<Note>>.broadcast();
  int pending = 0;

  Stream<List<Note>> watch() async* {
    // Gerçek akış gibi (NotesRepository.watchNotes): çöptekiler dışarıda.
    List<Note> live(List<Note> all) => [
      for (final n in all)
        if (n.deletedAt == null) n,
    ];
    yield live(notes);
    yield* out.stream.map(live);
  }

  Note note(String id) => notes.firstWhere((n) => n.id == id);

  Future<void> _apply(Map<String, Map<String, dynamic>> byId) {
    notes = [
      for (final n in notes)
        byId[n.id] == null
            ? n
            : Note.fromMap(
                n.id,
                // Sunucu damgası yerel kopyada henüz yok (bkz. Note.fromMap).
                {...n.toMap(), ...byId[n.id]!}
                  ..removeWhere((_, v) => v is FieldValue),
              ),
    ];
    out.add(notes);
    pending++;
    return Completer<void>().future; // sunucu onayı gelmiyor
  }

  @override
  Future<void> updateFieldsAndWait(
    String noteId,
    Map<String, dynamic> fields,
  ) => _apply({noteId: fields});

  @override
  Future<void> batchUpdateEach(Map<String, Map<String, dynamic>> fieldsById) =>
      _apply(fieldsById);
}

/// DENEYIM F78.5 — iyimser işlemler: sabitle, yıldızla, arşivle, çöpe at,
/// madde işaretle, klasöre taşı arayüzde AĞ BEKLEMEDEN görünür.
void main() {
  Future<(_SlowRepo, ProviderContainer)> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _SlowRepo(const [
      Note(id: 'a', type: NoteType.text, title: 'Birinci not'),
      Note(id: 'b', type: NoteType.text, title: 'İkinci not'),
      Note(id: 'c', type: NoteType.text, title: 'Üçüncü not'),
    ]);
    addTearDown(repo.out.close);
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(repo),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith((ref) => repo.watch()),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value(const <NoteFolder>[]),
        ),
        sharedFolderRefsProvider.overrideWith(
          (ref) => Stream.value(const <SharedFolderRef>[]),
        ),
        folderUnreadProvider.overrideWith((ref, key) => 0),
        myNoteSharesProvider.overrideWith((ref) => Stream.value(const {})),
        sharedNotesWithMeProvider.overrideWith(
          (ref) => Stream.value(const <NoteShare>[]),
        ),
        inboxNotesProvider.overrideWith(
          (ref) => Stream.value(const <InboxNote>[]),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const DashboardScreen())],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return (repo, container);
  }

  Future<void> select(
    WidgetTester tester,
    ProviderContainer container,
    String id,
  ) async {
    container.read(selectedNoteIdsProvider.notifier).toggle(id);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('arşivle / sabitle / yıldızla / çöpe at: sunucu onayı gelmeden '
      'arayüz değişir', (tester) async {
    final (repo, container) = await pumpHome(tester);
    final l10n = lookupAppLocalizations(const Locale('tr'));
    expect(find.text('Birinci not'), findsOneWidget);

    // ARŞİVLE — dokunuşu izleyen karede seçim kapanır, kart gider, geri al çıkar.
    await select(tester, container, 'a');
    await tester.tap(find.byIcon(AppIcons.archive));
    await tester.pump();
    await tester.pump();
    expect(container.read(selectedNoteIdsProvider), isEmpty);
    expect(repo.note('a').archivedAt, isNotNull);
    expect(find.text(l10n.notesArchivedCount(1)), findsOneWidget);
    expect(repo.pending, 1, reason: 'yazım hâlâ sunucuda bekliyor');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Birinci not'), findsNothing);

    // SABİTLE + YILDIZLA (⋮ seçim menüsü).
    for (final (label, check) in [
      (l10n.pin, () => repo.note('b').pinned),
      (l10n.star, () => repo.note('b').starred),
    ]) {
      await select(tester, container, 'b');
      await tester.tap(find.byIcon(Icons.more_vert).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text(label).last);
      await tester.pump();
      await tester.pump();
      expect(check(), isTrue, reason: label);
      expect(container.read(selectedNoteIdsProvider), isEmpty, reason: label);
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(repo.pending, 3);

    // ÇÖPE AT — kart küçülüp solar (220 ms), sonra yazım; onay beklenmez.
    await select(tester, container, 'c');
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pump();
    expect(container.read(selectedNoteIdsProvider), isEmpty);
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    expect(repo.note('c').deletedAt, isNotNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Üçüncü not'), findsNothing);
    expect(repo.pending, 4);
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('kartta madde işaretle: kutu sunucu onayı gelmeden dolar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'card_show_checked': true});
    final prefs = await SharedPreferences.getInstance();
    final repo = _SlowRepo(const [
      Note(
        id: 'n',
        type: NoteType.checklist,
        title: 'Liste',
        items: [NoteItem(id: 'a', text: 'bekliyor')],
      ),
    ]);
    addTearDown(repo.out.close);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: StreamBuilder<List<Note>>(
              stream: repo.watch(),
              builder: (_, snap) => snap.data == null
                  ? const SizedBox()
                  : SizedBox(
                      width: 300,
                      child: NoteCard(note: snap.data!.single),
                    ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
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
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byIcon(Icons.check_box_outline_blank));
    await tester.pump();
    await tester.pump();
    expect(find.byIcon(Icons.check_box), findsOneWidget);
    expect(repo.pending, 1);
    await tester.pump(const Duration(seconds: 2));
  });

  // Klasöre taşıma ve öbür toplu işler aynı yoldan (`batchUpdate`,
  // `updateFields`) gider. Sunucu onayını BEKLEYEN bir çağrı çevrimdışıyken
  // arayüzü sonsuza dek bekletir — kaynakta yasak.
  test('arayüz toplu yazımın sunucu onayını beklemez (kaynak bekçisi)', () {
    final bad = RegExp(
      r'await\s+[\w.!?()]*\.(batchUpdate|batchUpdateEach|setArchivedAll|'
      r'softDeleteAll|restoreAll)\(',
    );
    final hits = <String>[];
    for (final f in Directory('lib/features').listSync(recursive: true)) {
      if (f is! File ||
          !f.path.replaceAll(r'\', '/').contains('/presentation/')) {
        continue;
      }
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (bad.hasMatch(lines[i])) hits.add('${f.path}:${i + 1}');
      }
    }
    expect(hits, isEmpty);
  });
}
