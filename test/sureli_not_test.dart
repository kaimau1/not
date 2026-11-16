import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/expiry_sheet.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/l10n/generated/app_localizations_tr.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ZAMANLI NOT (kullanıcı isteği 2026-11-16): süre dolunca not arşive taşınır,
/// süre temizlenir.
void main() {
  final now = DateTime(2026, 11, 16, 12);

  test('expiresAt kaydedilir ve okunur; kaldırma null yazar', () {
    FakeFirebaseFirestore(); // FieldValue fabrikası sahte olsun.
    final at = DateTime(2026, 11, 20, 9);
    final map = Note(id: 'n', type: NoteType.text, expiresAt: at).toMap();
    expect((map['expiresAt'] as Timestamp).toDate(), at);
    expect(
      Note.fromMap('n', {
        'type': 'text',
        'expiresAt': map['expiresAt'],
      }).expiresAt,
      at,
    );
    final cleared = Note(
      id: 'n',
      type: NoteType.text,
      expiresAt: at,
    ).copyWith(clearExpiresAt: true);
    // Boş süre yazılmaz (bayt bütçesi); kaldırma açık null yazımıyla.
    expect(cleared.toMap().containsKey('expiresAt'), isFalse);
    expect(Note.knownKeys, contains('expiresAt'));
  });

  test('expiredNotes yalnız süresi geçmiş, arşivlenmemiş notlar', () {
    final notes = [
      Note(id: 'gecti', type: NoteType.text, expiresAt: now),
      Note(
        id: 'gelecek',
        type: NoteType.text,
        expiresAt: now.add(const Duration(minutes: 1)),
      ),
      Note(
        id: 'arsivde',
        type: NoteType.text,
        expiresAt: now.subtract(const Duration(days: 1)),
        archivedAt: now,
      ),
      const Note(id: 'suresiz', type: NoteType.text),
    ];
    expect(expiredNotes(notes, now).map((n) => n.id), ['gecti']);
  });

  test('archiveExpired arşive taşır, süreyi temizler, idempotent', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db, 'ben');
    final at = now.subtract(const Duration(hours: 1));
    final doc = db.collection('users').doc('ben').collection('notes').doc('n');
    await doc.set({
      'type': 'text',
      'title': 'x',
      'expiresAt': Timestamp.fromDate(at),
    });
    final note = Note.fromMap('n', (await doc.get()).data()!);
    await repo.archiveExpired([note], now: now);
    var data = (await doc.get()).data()!;
    expect((data['archivedAt'] as Timestamp).toDate(), at);
    expect(data['expiresAt'], isNull);
    // İkinci cihaz bayat listeyle aynı yazımı yapsa da sonuç aynı.
    await repo.archiveExpired([note], now: now);
    data = (await doc.get()).data()!;
    expect((data['archivedAt'] as Timestamp).toDate(), at);
    // Arşivden geri alınan not (süresiz) yeniden arşivlenmez.
    repo.setArchived('n', false);
    final restored = Note.fromMap('n', (await doc.get()).data()!);
    expect(expiredNotes([restored], now.add(const Duration(days: 9))), isEmpty);
  });

  test('setExpiry kurar ve kaldırır', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db, 'ben');
    final doc = db.collection('users').doc('ben').collection('notes').doc('n');
    await doc.set({'type': 'text'});
    final at = DateTime(2026, 12, 1, 9);
    repo.setExpiry('n', at);
    await Future<void>.delayed(Duration.zero);
    expect(((await doc.get()).data()!['expiresAt'] as Timestamp).toDate(), at);
    repo.setExpiry('n', null);
    await Future<void>.delayed(Duration.zero);
    expect((await doc.get()).data()!['expiresAt'], isNull);
  });

  test('elle arşivleme süreyi temizler', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db, 'ben');
    final doc = db.collection('users').doc('ben').collection('notes').doc('n');
    await doc.set({'type': 'text', 'expiresAt': Timestamp.fromDate(now)});
    repo.setArchived('n', true);
    await Future<void>.delayed(Duration.zero);
    expect((await doc.get()).data()!['expiresAt'], isNull);
  });

  test('kalan süre etiketi', () {
    final l10n = AppLocalizationsTr();
    expect(
      noteExpiryLeft(l10n, now.add(const Duration(days: 2, hours: 3)), now),
      '2 g',
    );
    expect(
      noteExpiryLeft(l10n, now.add(const Duration(hours: 5)), now),
      '5 sa',
    );
    expect(
      noteExpiryLeft(l10n, now.add(const Duration(seconds: 20)), now),
      '1 dk',
    );
  });

  testWidgets('kartta kum saati ve kalan süre', (tester) async {
    SharedPreferences.setMockInitialValues({});
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
                  body: SizedBox(
                    width: 300,
                    child: NoteCard(
                      note: Note(
                        id: 'n',
                        type: NoteType.text,
                        title: 'Süreli',
                        body: 'gövde',
                        expiresAt: DateTime.now().add(
                          const Duration(days: 3, minutes: 5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.hourglass_bottom), findsOneWidget);
    expect(find.text('3 g'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
