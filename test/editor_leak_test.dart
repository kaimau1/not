import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/note_open_route.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notlar/core/utils/hard_keyboard.dart';
import 'package:notlar/core/widgets/note_route_closing.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

import 'support/editor_harness.dart';

/// **BİRİKİM (SIZINTI) BEKÇİSİ** (OTURTMA F60.S2; kullanıcı 2026-11-09:
/// "klavye açılırken alt panel kasıyor; en başta yok gibi, notlara gir-çık
/// yaptıkça artıyor"). Editör 15 kez rota olarak açılıp kapanır; sonra:
/// atılmamış nesne (State / ChangeNotifier / Ticker…) birikmemiş, genel
/// dinleyiciler geri alınmış, klavye turunun kurulum sayıları ilk turla aynı.
final _note = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Başlık',
  body: List.generate(30, (i) => 'Satır $i').join('\n'),
  items: const [
    NoteItem(id: 'a', text: 'açık'),
    NoteItem(id: 'b', text: 'bitti', checked: true),
  ],
);

/// Yaratılıp `dispose` edilmemiş nesneler (Flutter'ın bellek olayları).
class _Live {
  final _objects = Map<Object, String>.identity();
  final stacks = Map<Object, StackTrace>.identity();
  static const traces = bool.fromEnvironment('LEAK_TRACES');

  void _on(ObjectEvent e) {
    if (e is ObjectCreated) {
      _objects[e.object] = e.className;
      if (traces) stacks[e.object] = StackTrace.current;
    } else if (e is ObjectDisposed) {
      _objects.remove(e.object);
    }
  }

  void start() => FlutterMemoryAllocations.instance.addListener(_on);
  void stop() => FlutterMemoryAllocations.instance.removeListener(_on);

  /// Tanı (`--dart-define=LEAK_TRACES=true`): [classes] türünden, [skip]
  /// dışında kalan canlı nesnelerin yaratıldığı yer.
  void dump(Set<Object> skip, Set<String> classes) {
    final seen = <String>{};
    for (final e in _objects.entries) {
      if (skip.contains(e.key) || !classes.contains(e.value)) continue;
      final lines = stacks[e.key].toString().split('\n');
      final own = lines.where((l) => l.contains('package:notlar')).take(4);
      final key =
          '${e.value} ${e.key.runtimeType}\n  ${own.join('\n  ')}'
          '\n  --\n  ${lines.skip(3).take(6).join('\n  ')}';
      // ignore: avoid_print
      if (seen.add(key)) print(key);
    }
  }

  Map<String, int> snapshot() {
    final out = <String, int>{};
    for (final c in _objects.values) {
      out[c] = (out[c] ?? 0) + 1;
    }
    return out;
  }
}

/// Tür başına artan canlı nesneler. Layer/Picture sayılmaz: ekrandaki
/// sahnenin parçaları, o an hangi kartın boyandığına göre oynar.
Map<String, String> _grown(Map<String, int> early, Map<String, int> late) => {
  for (final e in late.entries)
    if (e.key != 'Layer' && e.key != 'Picture' && e.value > (early[e.key] ?? 0))
      e.key: '${early[e.key] ?? 0} → ${e.value}',
};

/// Genel (uygulama ömürlü) dinlenebilirlerin durumu: editör kapanınca
/// açılmadan önceki hâle dönmeli.
Map<String, Object> _globals() => {
  // ignore: invalid_use_of_protected_member
  'FocusManager': FocusManager.instance.hasListeners,
  // ignore: invalid_use_of_protected_member
  'autoStylus': InkToolMemory.autoStylusListenable.hasListeners,
  // ignore: invalid_use_of_protected_member
  'noteRouteClosing': noteRouteClosing.hasListeners,
  // ignore: invalid_use_of_protected_member
  'HardKeyboard.present': HardKeyboard.present.hasListeners,
  // ignore: invalid_use_of_protected_member
  'HardKeyboard.softWanted': HardKeyboard.softWanted.hasListeners,
  // ignore: invalid_use_of_protected_member
  'AutoSpell.enabled': AutoSpell.enabled.hasListeners,
  // ignore: invalid_use_of_protected_member
  'AutoSpell.learning': AutoSpell.learning.hasListeners,
  'globalRoutes': GestureBinding.instance.pointerRouter.debugGlobalRouteCount,
};

void main() {
  testWidgets('15 gir-çık: nesne ve dinleyici birikmez, klavye turu aynı', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await pumpEditor(
      tester,
      _note,
      repo: CountingNotesRepository(),
      home: Navigator(
        key: nav,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('ana ekran')),
        ),
      ),
    );
    final counter = BuildCounter();
    addTearDown(counter.stop);

    Future<void> frame(double inset) async {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      tester.view.padding = FakeViewPadding(
        top: 30,
        bottom: (48 - inset).clamp(0.0, 48.0),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    /// Klavye aç → kapa; HAREKET sırasındaki kurulum sayıları.
    Future<Map<String, int>> keyboardTour() async {
      counter.start();
      for (final i in [20.0, 60.0, 120.0, 200.0, 300.0]) {
        await frame(i);
      }
      final moving = Map<String, int>.of(counter.counts);
      counter.stop();
      await tester.pump(const Duration(milliseconds: 300));
      for (final i in [200.0, 120.0, 60.0, 20.0, 0.0]) {
        await frame(i);
      }
      await tester.pump(const Duration(milliseconds: 300));
      return moving;
    }

    Future<Map<String, int>> open() async {
      unawaited(
        nav.currentState!.push(
          MaterialPageRoute<void>(
            builder: (_) => NoteEditorScreen(noteId: _note.id),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      // Gövdeye dokun (odak + klavye), yaz, klavye turu.
      await tester.tap(find.textContaining('Satır 3').first);
      await tester.pump(const Duration(milliseconds: 100));
      final tour = await keyboardTour();
      return tour;
    }

    Future<void> close() async {
      nav.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      // Kapanıştan sonraki gecikmeli işler (kayıt, öneri, ipucu) bitsin.
      await tester.pump(const Duration(seconds: 30));
    }

    final before = _globals();
    // Isınma: ilk açılışın tek seferlik kurulumları (önbellek, ipucu).
    for (var i = 0; i < 3; i++) {
      await open();
      await close();
    }
    expect(_globals(), before, reason: 'ısınma sonrası genel dinleyiciler');
    final firstTour = await open();
    await close();

    // Doğrusal birikim: 5. kapanıştan 15. kapanışa canlı nesne sayısı
    // (tür başına) artmaz. (Sabit kalıntı — ana ekranın yeniden kurulan
    // bariyeri gibi — sızıntı değil.)
    final live = _Live()..start();
    addTearDown(live.stop);
    for (var i = 0; i < 5; i++) {
      await open();
      await close();
    }
    final early = live.snapshot();
    final earlyObjects = live._objects.keys.toSet();
    for (var i = 0; i < 10; i++) {
      await open();
      await close();
    }
    live.stop();
    final late = live.snapshot();
    final grown = _grown(early, late);
    if (_Live.traces) live.dump(earlyObjects, grown.keys.toSet());
    expect(grown, isEmpty, reason: 'gir-çıkla biriken atılmamış nesneler');
    expect(_globals(), before, reason: 'genel dinleyiciler geri alınmalı');
    expect(tester.binding.transientCallbackCount, 0);

    final lateTour = await open();
    expect(lateTour, firstTour, reason: '19. açılışın klavye turu');
    expect(lateTour, isNot(contains('NoteEditorScreen')));
    await close();
  });

  testWidgets('kabukla 15 gir-çık (ana ekran + yönlendirici): birikmez', (
    tester,
  ) async {
    // Kalemli cihaz: mürekkep katmanları da kurulsun (tablet yolu).
    InkToolMemory.autoStylus = true;
    InkToolMemory.stylusEver = true;
    addTearDown(() => InkToolMemory.stylusEver = false);
    const pdf = Attachment(
      id: 'p',
      kind: AttachmentKind.pdf,
      fileName: 'belge.pdf',
      mimeType: 'application/pdf',
      width: 600,
      height: 800,
    );
    const image = Attachment(
      id: 'g',
      kind: AttachmentKind.image,
      fileName: 'foto.jpg',
      mimeType: 'image/jpeg',
      width: 800,
      height: 600,
    );
    // Karışık küme: liste, düz metin, sabit PDF, gömülü PDF, görsel, sayfalı.
    final kinds = <Note Function(Note)>[
      (n) => n,
      (n) => n.copyWith(type: NoteType.text, items: const []),
      (n) => n.copyWith(attachments: [pdf.copyWith(pinHeight: 300)]),
      (n) => n.copyWith(attachments: [pdf.copyWith(onPage: true)]),
      (n) => n.copyWith(attachments: [image]),
      (n) => n.copyWith(type: NoteType.text, items: const [], paged: true),
    ];
    final notes = [
      for (final (i, kind) in kinds.indexed)
        kind(
          Note(
            id: 'n$i',
            type: NoteType.checklist,
            title: 'Not $i',
            body: _note.body,
            items: _note.items,
            updatedAt: DateTime(2026, 11, 1 + i),
          ),
        ),
    ];
    SharedPreferences.setMockInitialValues({
      TipOnce.prefsKey: const [
        TipOnce.listGestures,
        TipOnce.gridSwipe,
        TipOnce.homeMicHold,
        TipOnce.semanticSearch,
      ],
    });
    final sp = await SharedPreferences.getInstance();
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 30, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 48);
    addTearDown(tester.view.reset);
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
                      : withoutHeroWalk(const DashboardScreen()),
                ),
                GoRoute(
                  path: '/note/:id',
                  pageBuilder: (c, s) => NoteOpenPage<void>(
                    key: s.pageKey,
                    noteId: s.pathParameters['id']!,
                    child: NoteEditorScreen(
                      key: ValueKey('note-${s.pathParameters['id']}'),
                      noteId: s.pathParameters['id']!,
                    ),
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
        sharedPreferencesProvider.overrideWithValue(sp),
        authRepositoryProvider.overrideWithValue(_NoAuth()),
        currentUidProvider.overrideWithValue(null),
        updateRequiredProvider.overrideWithValue(false),
        notesRepositoryProvider.overrideWithValue(CountingNotesRepository()),
        attachmentRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
        trashStreamProvider.overrideWith((ref) => Stream.value(const [])),
        inboxNotesProvider.overrideWith((ref) => Stream.value(const [])),
        foldersStreamProvider.overrideWith((ref) => Stream.value(const [])),
        for (final n in notes)
          noteStreamProvider(n.id).overrideWith((ref) => Stream.value(n)),
        sharedFolderRefsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              fixedTypography(context, child ?? const SizedBox(), 1),
        ),
      ),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 150));
    }
    final counter = BuildCounter();
    addTearDown(counter.stop);

    Future<void> frame(double inset) async {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      tester.view.padding = FakeViewPadding(
        top: 30,
        bottom: (48 - inset).clamp(0.0, 48.0),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    var turn = 0;
    Future<Map<String, int>> openTourClose() async {
      // Karta dokunarak (genişleyen geçiş); sırayla farklı notlar.
      final title = find.text('Not ${turn++ % notes.length}');
      expect(title, findsWidgets);
      await tester.tap(title.first);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      await tester.tap(find.textContaining('Satır 3').last);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(
        find.byType(EditableText).last,
        '${_note.body} ek$turn',
      );
      await tester.pump(const Duration(milliseconds: 100));
      counter.start();
      for (final i in [20.0, 60.0, 120.0, 200.0, 300.0]) {
        await frame(i);
      }
      final moving = Map<String, int>.of(counter.counts);
      counter.stop();
      await tester.pump(const Duration(milliseconds: 300));
      for (final i in [200.0, 120.0, 60.0, 20.0, 0.0]) {
        await frame(i);
      }
      await tester.pump(const Duration(milliseconds: 300));
      // pdfrx'in kendi hata kutusu (testte pdfium yok) testi düşürmesin.
      tester.takeException();
      router.pop();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
      await tester.pump(const Duration(seconds: 30));
      expect(find.byType(NoteEditorScreen), findsNothing);
      return moving;
    }

    // Isınma: her not türü bir kez (tek seferlik önbellek/ipucu kurulumları).
    for (var i = 0; i < 9; i++) {
      await openTourClose();
    }
    final before = _globals();
    final firstTour = await openTourClose();
    final live = _Live()..start();
    addTearDown(live.stop);
    // Kümenin tam turları (6 not): karşılaştırılan anlar aynı notta biter.
    for (var i = 0; i < 6; i++) {
      await openTourClose();
    }
    final early = live.snapshot();
    final earlyObjects = live._objects.keys.toSet();
    // 18 açılış sonra `firstTour` ile AYNI notun (n3) klavye turu.
    late Map<String, int> lateTour;
    for (var i = 0; i < 12; i++) {
      lateTour = await openTourClose();
    }
    live.stop();
    final late = live.snapshot();
    final grown = _grown(early, late);
    if (_Live.traces) live.dump(earlyObjects, grown.keys.toSet());
    expect(grown, isEmpty, reason: 'gir-çıkla biriken atılmamış nesneler');
    expect(_globals(), before, reason: 'genel dinleyiciler geri alınmalı');
    expect(lateTour, firstTour, reason: 'klavye turu kurulum sayıları');
    expect(tester.binding.transientCallbackCount, 0);
    tester.takeException();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
