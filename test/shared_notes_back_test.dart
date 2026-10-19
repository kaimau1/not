import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/notes/data/note_shares_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/data/shared_note_activity.dart';
import 'package:notlar/features/notes/data/upload_queue.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/shared_notes_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:notlar/l10n/generated/app_localizations_tr.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-10-17 (5. tur) — paylaşılan notlardaki eksikler:
/// geri tuşunda uygulamanın kapanması, "yeni" izinin olmaması, yükleme
/// sırasındaki sessizlik.
void main() {
  group('Geri tuşu: paylaşılanlar sayfasından dönüş', () {
    /// Uygulamanın yönlendirici ŞEKLİ: dış kabuk (AppFrame) → iç kabuk
    /// (SplitShell) → `/`; kabuk dışı not yolu dış kabukta. "Benimle
    /// paylaşılanlar" iç Navigator'a SAYFASIZ rota olarak açılır.
    GoRouter buildRouter() => GoRouter(
      routes: [
        ShellRoute(
          builder: (c, s, child) => child,
          routes: [
            ShellRoute(
              builder: (c, s, child) => child,
              routes: [
                GoRoute(
                  path: '/',
                  builder: (c, s) => Scaffold(
                    body: Builder(
                      builder: (c) => TextButton(
                        onPressed: () => Navigator.of(c).push(
                          MaterialPageRoute<void>(
                            builder: (c2) => Scaffold(
                              body: TextButton(
                                onPressed: () =>
                                    GoRouter.of(c2).push('/open/note/1'),
                                child: const Text('SHARED'),
                              ),
                            ),
                          ),
                        ),
                        child: const Text('HOME'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/open/note/:id',
              builder: (c, s) => const Scaffold(body: Text('NOTE')),
            ),
          ],
        ),
      ],
    );

    Future<List<String>> run(
      WidgetTester tester, {
      required NotificationListenerCallback<NavigationNotification>? handler,
      bool backFromHome = false,
    }) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') calls.add('exit');
          if (call.method == 'SystemNavigator.setFrameworkHandlesBack') {
            calls.add('handles:${call.arguments}');
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: buildRouter(),
          onNavigationNotification: handler,
        ),
      );
      if (backFromHome) {
        calls.clear();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        return calls;
      }
      await tester.tap(find.text('HOME'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SHARED'));
      await tester.pumpAndSettle();
      expect(find.text('NOTE'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('SHARED'), findsOneWidget);
      return calls;
    }

    testWidgets('KÖK NEDEN: varsayılanla platforma en son "karşılamam" gider', (
      tester,
    ) async {
      final calls = await run(tester, handler: null);
      // Paylaşılanlar sayfası açıkken Android'e son söylenen "Flutter geri
      // tuşunu karşılamıyor" — FlutterFragmentActivity sonraki geri tuşunda
      // Activity'yi bitiriyordu (uygulama kapanıyordu).
      expect(
        calls.where((c) => c.startsWith('handles:')).last,
        'handles:false',
      );
    });

    testWidgets('düzeltme: platforma hep "çerçeve karşılar" gider', (
      tester,
    ) async {
      final calls = await run(tester, handler: alwaysHandleBack);
      expect(calls, isNotEmpty);
      expect(calls.where((c) => c.startsWith('handles:')).toSet(), {
        'handles:true',
      });
      // Geri tuşu artık paylaşılanlar sayfasını kapatır, uygulamayı değil.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
      expect(calls, isNot(contains('exit')));
    });

    testWidgets('ana ekranda geri tuşu uygulamadan yine çıkar', (
      tester,
    ) async {
      final calls = await run(
        tester,
        handler: alwaysHandleBack,
        backFromHome: true,
      );
      expect(calls, contains('exit'));
    });
  });

  group('Paylaşılan notta "yeni" kuralı', () {
    final at = DateTime(2026, 10, 17, 12);
    Note note({String by = 'ayse', DateTime? updated}) => Note(
      id: 'n1',
      type: NoteType.text,
      updatedBy: by,
      updatedAt: updated ?? at,
    );

    test('izleme başlamadan rozet yok', () {
      expect(
        isSharedNoteUnread(
          note: note(),
          seenMs: null,
          baselineMs: null,
          me: 'ben',
        ),
        isFalse,
      );
    });

    test('hiç bakılmamış paylaşım = beni yeni eklediler', () {
      expect(
        isSharedNoteUnread(note: note(), seenMs: null, baselineMs: 1, me: 'ben'),
        isTrue,
      );
    });

    test('bakıştan sonra başkasının değişikliği yeni, benimki değil', () {
      final seen = at.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch;
      expect(
        isSharedNoteUnread(note: note(), seenMs: seen, baselineMs: 1, me: 'ben'),
        isTrue,
      );
      expect(
        isSharedNoteUnread(
          note: note(by: 'ben'),
          seenMs: seen,
          baselineMs: 1,
          me: 'ben',
        ),
        isFalse,
      );
      final later = at.add(const Duration(minutes: 1)).millisecondsSinceEpoch;
      expect(
        isSharedNoteUnread(note: note(), seenMs: later, baselineMs: 1, me: 'ben'),
        isFalse,
      );
    });

    test('sağlayıcı: ilk görüş benimsenir, sonra gelen paylaşım yenidir', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      const old = NoteShare(
        ownerId: 'mehmet',
        noteId: 'eski',
        ownerName: 'Mehmet',
        sharedWith: ['ben'],
      );
      const fresh = NoteShare(
        ownerId: 'ayse',
        noteId: 'yeni',
        ownerName: 'Ayşe',
        sharedWith: ['ben'],
      );
      final shares = StreamController<List<NoteShare>>();
      addTearDown(shares.close);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('ben'),
          sharedNotesWithMeProvider.overrideWith((ref) => shares.stream),
          ownedNoteStreamProvider.overrideWith(
            (ref, key) => Stream.value(
              Note(
                id: key.noteId,
                type: NoteType.text,
                updatedBy: key.ownerId,
                updatedAt: DateTime(2026),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      Future<void> settle() async {
        for (var i = 0; i < 5; i++) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      container.listen(sharedNoteUnreadProvider, (_, _) {});
      shares.add([old]);
      await settle();
      // İzleme başlamadı: hiçbir şey yeni değil.
      expect(container.read(sharedNoteUnreadProvider), isEmpty);
      container.read(sharedNoteSeenProvider.notifier).adopt([old.id]);
      await settle();
      expect(container.read(sharedNoteUnreadProvider), isEmpty);

      // Ayşe beni yeni bir notuna ekledi.
      shares.add([old, fresh]);
      await settle();
      expect(container.read(sharedNoteUnreadProvider), {fresh.id});

      // Notu açtım (editör damgayı basar): rozet söner, kalıcıdır.
      container.read(sharedNoteSeenProvider.notifier).markSeen(fresh.id);
      expect(container.read(sharedNoteUnreadProvider), isEmpty);
      expect(prefs.getString('shared_note_seen_v1'), contains(fresh.id));
    });

    test('kart satırı: ortak çalışanın düzenlemesi adıyla görünür', () {
      final l10n = AppLocalizationsTr();
      const share = NoteShare(
        ownerId: 'mehmet',
        noteId: 'n1',
        ownerName: 'Mehmet',
        sharedWith: ['ben', 'ayse'],
        names: {'ben': 'Ben', 'ayse': 'Ayşe'},
      );
      expect(
        sharedNoteCaption(l10n, share, note(by: 'ayse')),
        'Ayşe güncelledi',
      );
      expect(
        sharedNoteCaption(l10n, share, note(by: 'mehmet')),
        'Mehmet paylaştı',
      );
    });
  });

  group('Yükleme ilerlemesi', () {
    Attachment att(String id) => Attachment(
      id: id,
      kind: AttachmentKind.image,
      fileName: '$id.jpg',
      mimeType: 'image/jpeg',
    );

    test('özet: sayı ve ortalama oran; Drive (oran yok) belirsiz', () {
      final list = [att('a'), att('b'), att('c')];
      expect(uploadSummaryFor(list, const {}), (count: 0, fraction: null));
      expect(uploadSummaryFor(list, const {'a': 0.2, 'b': 0.6}), (
        count: 2,
        fraction: 0.4,
      ));
      expect(uploadSummaryFor(list, const {'a': 0.2, 'c': -1}), (
        count: 2,
        fraction: null,
      ));
    });

    test('aynı yüzde yeniden yayınlanmaz, bitince kayıt düşer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var emits = 0;
      container.listen(uploadProgressProvider, (_, _) => emits++);
      final notifier = container.read(uploadProgressProvider.notifier);
      notifier.set('a', 0.101);
      notifier.set('a', 0.105);
      notifier.set('a', 0.109);
      expect(emits, 1);
      notifier.set('a', 0.5);
      expect(emits, 2);
      notifier.done('a');
      expect(container.read(uploadProgressProvider), isEmpty);
    });
  });

  testWidgets('Benimle paylaşılanlar: yeni not başta ve "Yeni" etiketli', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'shared_note_seen_v1': '{"":1,"mehmet_eski":${DateTime(2030).millisecondsSinceEpoch}}',
    });
    final prefs = await SharedPreferences.getInstance();
    const shares = [
      NoteShare(
        ownerId: 'mehmet',
        noteId: 'eski',
        ownerName: 'Mehmet',
        sharedWith: ['ben'],
      ),
      NoteShare(
        ownerId: 'ayse',
        noteId: 'yeni',
        ownerName: 'Ayşe',
        sharedWith: ['ben'],
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue('ben'),
          sharedNotesWithMeProvider.overrideWith((ref) => Stream.value(shares)),
          ownedNoteStreamProvider.overrideWith(
            (ref, key) => Stream.value(
              Note(
                id: key.noteId,
                type: NoteType.text,
                title: key.noteId == 'eski' ? 'Eski not' : 'Yeni not',
                updatedBy: key.ownerId,
                // Eski not DAHA YENİ değişmiş — yine de okunmamış başa gelir.
                updatedAt: key.noteId == 'eski'
                    ? DateTime(2026, 10, 17)
                    : DateTime(2026, 10, 1),
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SharedNotesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yeni'), findsOneWidget);
    expect(find.byTooltip('Tümünü okundu say'), findsOneWidget);
    final fresh = tester.getTopLeft(find.text('Yeni not'));
    final old = tester.getTopLeft(find.text('Eski not'));
    expect(fresh.dx < old.dx || fresh.dy < old.dy, isTrue);

    await tester.tap(find.byTooltip('Tümünü okundu say'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni'), findsNothing);
  });
}
