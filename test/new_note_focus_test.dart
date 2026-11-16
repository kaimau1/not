import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/dashboard_scroll_memory.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Yeni not → ana ekrana dönüş: kart görünür alana gelir, kısa süre yanıp
/// söner (kullanıcı isteği 2026-11-16). Oluşturma yolu fark etmez: hepsi
/// [NotesRepository.lastCreatedId]'den geçer, vurgu editör kapanışında.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _now = DateTime.now();

/// 40 not; yeni not EN ALTTA (tembel listede kurulmamış olsun).
List<Note> _list({String body = 'yeni gövde'}) => [
  for (var i = 0; i < 39; i++)
    Note(
      id: 'n$i',
      type: NoteType.text,
      title: 'Not $i',
      body: 'gövde $i\nikinci satır\nüçüncü satır',
      orderIndex: i.toDouble(),
      updatedAt: _now,
    ),
  Note(
    id: 'yeni',
    type: NoteType.text,
    title: body.isEmpty ? '' : 'Yeni not',
    body: body,
    orderIndex: 99,
    updatedAt: _now,
  ),
];

Future<(ProviderContainer, GoRouter)> _pump(
  WidgetTester tester, {
  String body = 'yeni gövde',
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final db = FakeFirebaseFirestore();
  final notes = _list(body: body);
  final col = db.collection('users').doc('u').collection('notes');
  for (final n in notes) {
    await col.doc(n.id).set(n.toMap());
  }
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (c, s, child) => AppFrame(child: child),
        routes: [
          ShellRoute(
            builder: (c, s, child) => SplitShell(child: child),
            routes: [
              GoRoute(
                path: '/',
                builder: (c, s) => SplitScope.activeOf(c)
                    ? const SizedBox.shrink()
                    : const DashboardScreen(),
              ),
              GoRoute(
                path: '/note/:id',
                builder: (c, s) => NoteEditorScreen(
                  key: ValueKey('note-${s.pathParameters['id']}'),
                  noteId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(_NoAuth()),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(NotesRepository(db, 'u')),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (c, child) => MediaQuery(
          data: MediaQuery.of(c).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
  return (container, router);
}

/// Yeni notu "oluşturulmuş" say, editörünü aç, ana ekrana dön.
Future<void> _createOpenReturn(
  WidgetTester tester,
  GoRouter router,
  ProviderContainer container,
) async {
  NotesRepository.lastCreatedId = 'yeni';
  unawaited(router.push('/note/yeni'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  router.pop();
  // Kalkış animasyonu + editör dispose + ertelenmiş odak (en çok 3 sn).
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (container.read(focusedNoteProvider) != null) break;
  }
  // Kaydırma kareleri.
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Yeni notun kartı kurulu ve ekranın içinde mi.
bool _onScreen(WidgetTester tester) {
  final f = find.byKey(const ValueKey('yeni'));
  if (f.evaluate().isEmpty) return false;
  final r = tester.getRect(f);
  return r.top >= 0 && r.bottom <= tester.view.physicalSize.height;
}

/// Yeni notun kartını saran halenin kenarlık opaklığı (yoksa null).
double? _haloAlpha(WidgetTester tester) {
  final halos = find.ancestor(
    of: find.text('Yeni not'),
    matching: find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).border is Border &&
          ((w.decoration! as BoxDecoration).border! as Border).top.width == 2,
    ),
  );
  if (halos.evaluate().isEmpty) return null;
  final b =
      (tester.widget<Container>(halos.first).decoration! as BoxDecoration)
              .border!
          as Border;
  return b.top.color.a;
}

Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  tearDown(() {
    NotesRepository.lastCreatedId = null;
    // Önceki testin kaydırması sonraki panoya taşınmasın.
    DashboardScrollMemory.clear();
  });

  testWidgets('yeni not: dönüşte kart görünür, yanıp söner, sonra söner', (
    tester,
  ) async {
    final (container, router) = await _pump(tester);
    // Başta en alttaki yeni not ekranda değil.
    expect(_onScreen(tester), isFalse);
    await _createOpenReturn(tester, router, container);
    expect(container.read(focusedNoteProvider), 'yeni');
    expect(_onScreen(tester), isTrue);
    // Nabız: opaklık zamanla değişir.
    final a1 = _haloAlpha(tester);
    await tester.pump(const Duration(milliseconds: 150));
    final a2 = _haloAlpha(tester);
    expect(a1, isNotNull);
    expect(a1, isNot(a2));
    // ~1,2 sn sonra vurgu biter.
    await tester.pump(FocusedNoteNotifier.briefHold);
    await tester.pump();
    expect(container.read(focusedNoteProvider), isNull);
    expect(_haloAlpha(tester), 0);
    expect(NotesRepository.lastCreatedId, isNull);
    await _end(tester);
  });

  // Hızlı liste / liste şablonu "Bitti": not EDİTÖRSÜZ doğar
  // (`createFromTemplate`, open: false) — editör kapanış tetiği yok, odak
  // `focusCreated` ile ana ekrana dönüşte gelir (kullanıcı hatası 2026-11-16).
  testWidgets('editörsüz doğan not (hızlı liste → Bitti): kart odaklanır, tek '
      'tetik', (tester) async {
    final (container, _) = await _pump(tester);
    expect(_onScreen(tester), isFalse);
    NotesRepository.lastCreatedId = 'yeni';
    final focus = container.read(focusedNoteProvider.notifier);
    expect(focus.focusCreated('yeni'), isTrue);
    // İkinci tetik (ör. editör yolu da çalışsa) hiçbir şey yapmaz.
    expect(focus.focusCreated('yeni'), isFalse);
    expect(NotesRepository.lastCreatedId, isNull);
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(container.read(focusedNoteProvider), 'yeni');
    expect(_onScreen(tester), isTrue);
    expect(_haloAlpha(tester), isNotNull);
    await _end(tester);
  });

  // Şablon önizleme → Oluştur (open: true) editörü açar: editör yolu tüketir,
  // ardından gelen ikinci tetik vurguyu yinelemez.
  testWidgets('editör yolu tükettikten sonra ikinci tetik yok', (tester) async {
    final (container, router) = await _pump(tester);
    await _createOpenReturn(tester, router, container);
    expect(container.read(focusedNoteProvider), 'yeni');
    expect(
      container.read(focusedNoteProvider.notifier).focusCreated('yeni'),
      isFalse,
    );
    await _end(tester);
  });

  testWidgets('boş bırakılıp atılan yeni not: vurgu yok', (tester) async {
    final (container, router) = await _pump(tester, body: '');
    await _createOpenReturn(tester, router, container);
    expect(container.read(focusedNoteProvider), isNull);
    await _end(tester);
  });

  testWidgets('hareketi azalt: yanıp sönme yok, tek sabit vurgu', (
    tester,
  ) async {
    final (container, router) = await _pump(tester, reduceMotion: true);
    await _createOpenReturn(tester, router, container);
    expect(container.read(focusedNoteProvider), 'yeni');
    await tester.pump(const Duration(milliseconds: 100));
    final a1 = _haloAlpha(tester);
    await tester.pump(const Duration(milliseconds: 150));
    expect(a1, 1.0);
    expect(_haloAlpha(tester), 1.0);
    await tester.pump(FocusedNoteNotifier.briefHold);
    await tester.pump();
    expect(container.read(focusedNoteProvider), isNull);
    await _end(tester);
  });
}
