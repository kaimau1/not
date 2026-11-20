import 'dart:async';
import 'dart:convert';
import 'dart:developer' show reachabilityBarrier;
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show debugOnProfilePaint, debugPrintLayouts;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderBase;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/note_open_route.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/core/utils/hard_keyboard.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/core/widgets/focus_ring.dart';
import 'package:notlar/core/widgets/keyboard_snap.dart';
import 'package:notlar/core/widgets/note_route_closing.dart';
import 'package:notlar/core/widgets/undo_snackbar.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_scroll_memory.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/editor/auto_spell.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

/// **OTURUM BİRİKİMİ — S51** (kullanıcı bulgusu 2026-11-15, 1.2.80:
/// "uygulama kullanıldıkça kasma artıyor, sonda daha çok"). Ana ekrandan iki
/// liste + iki metin notu sırayla 20 kez aç → dokun → klavye aç/kapa →
/// geri. Ölçülen: aynı notun klavye karelerinin kurulum/dizilme/boyama
/// sayısı (ilk ↔ son açılış), atılmamış nesneler, atılıp TOPLANMAYAN
/// nesneler (bir dinleyicinin / zamanlayıcının tuttuğu), canlı Riverpod
/// sağlayıcıları ve kapanmış nota bağlı olanlar, not akışı aboneliği, genel
/// dinleyiciler, rota yığını, ticker. Bütçe `perf_budget/budgets.json` S51.
/// `editor_leak_test.dart`ın tamamlayıcısı (orada sağlayıcı ve GC yok).

class _CountingRepo extends NotesRepository {
  _CountingRepo(this.db) : super(db, 'u');
  final FakeFirebaseFirestore db;
  int listens = 0;
  int cancels = 0;

  @override
  Stream<Note?> watchNote(String noteId) {
    final inner = super.watchNote(noteId);
    late StreamSubscription<Note?> sub;
    late StreamController<Note?> c;
    c = StreamController<Note?>(
      onListen: () {
        listens++;
        sub = inner.listen(c.add, onError: c.addError, onDone: c.close);
      },
      onCancel: () {
        cancels++;
        return sub.cancel();
      },
    );
    return c.stream;
  }
}

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();
  @override
  Stream<Never> userChanges() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Canlı Riverpod sağlayıcıları (eklenen − atılan).
final class _Providers extends ProviderObserver {
  final alive = <ProviderBase<Object?>>{};

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) =>
      alive.add(context.provider);

  @override
  void didDisposeProvider(ProviderObserverContext context) =>
      alive.remove(context.provider);

  /// Argümanı [ids]'den birini içeren (bir nota bağlı) canlı sağlayıcılar.
  Set<String> boundTo(Iterable<String> ids) => {
    for (final p in alive)
      if (p.argument != null && ids.any('${p.argument}'.contains)) '$p',
  };
}

Map<String, Object> _globals() => {
  // ignore: invalid_use_of_protected_member
  'FocusManager': FocusManager.instance.hasListeners,
  // ignore: invalid_use_of_protected_member
  'appNotice': appNotice.hasListeners,
  // ignore: invalid_use_of_protected_member
  'noticeTopInset': noticeTopInset.hasListeners,
  // ignore: invalid_use_of_protected_member
  'snackBarBottomObstacle': snackBarBottomObstacle.hasListeners,
  // ignore: invalid_use_of_protected_member
  'KeyboardInset.moving': KeyboardInset.moving.hasListeners,
  // ignore: invalid_use_of_protected_member
  'Personalize.prefs': Personalize.prefs.hasListeners,
  // ignore: invalid_use_of_protected_member
  'Personalize.draft': Personalize.draft.hasListeners,
  // ignore: invalid_use_of_protected_member
  'noteRouteClosing': noteRouteClosing.hasListeners,
  // ignore: invalid_use_of_protected_member
  'HardKeyboard.present': HardKeyboard.present.hasListeners,
  // ignore: invalid_use_of_protected_member
  'AutoSpell.enabled': AutoSpell.enabled.hasListeners,
  // ignore: invalid_use_of_protected_member
  'AutoSpell.mode': AutoSpell.mode.hasListeners,
  // ignore: invalid_use_of_protected_member
  'AutoSpell.revision': AutoSpell.revision.hasListeners,
  // ignore: invalid_use_of_protected_member
  'autoStylus': InkToolMemory.autoStylusListenable.hasListeners,
  'globalRoutes': GestureBinding.instance.pointerRouter.debugGlobalRouteCount,
};

/// Çöp toplayıcıyı zorlar (`leak_tracker.forceGC` gibi, birkaç tam tur).
Future<void> _gc() async {
  final target = reachabilityBarrier + 8;
  final junk = <List<int>>[];
  while (reachabilityBarrier < target) {
    junk.add(List<int>.filled(1 << 16, 0));
    if (junk.length > 64) junk.clear();
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  testWidgets('S51: 20 tur gir-çık + klavye — kare maliyeti, sağlayıcı, '
      'dinleyici ve nesne sayıları sabit', (tester) async {
    final budget =
        (jsonDecode(File('test/perf_budget/budgets.json').readAsStringSync())
                as Map<String, dynamic>)['S51']
            as Map<String, dynamic>;
    DashboardScrollMemory.clear();
    TipOnce.resetSession();
    final now = DateTime.now();
    // Tur t'de notes[(t - 1) % 4]: aynı not tur 1 ↔ 17 (liste) ve
    // 4 ↔ 20 (metin) karşılaştırılır.
    final notes = [
      for (var k = 0; k < 4; k++)
        k.isEven
            ? Note(
                id: 'liste$k',
                type: NoteType.checklist,
                title: 'Liste notu $k',
                items: [
                  for (var j = 0; j < 30; j++)
                    NoteItem(id: 'i$k-$j', text: 'madde $j'),
                ],
                updatedAt: now.subtract(Duration(minutes: k)),
              )
            : Note(
                id: 'metin$k',
                type: NoteType.text,
                title: 'Metin notu $k',
                body: List.generate(30, (i) => 'Satır $i').join('\n'),
                updatedAt: now.subtract(Duration(minutes: k)),
              ),
    ];
    final ids = [for (final n in notes) n.id];
    final repo = _CountingRepo(FakeFirebaseFirestore());
    for (final n in notes) {
      await repo.db
          .collection('users')
          .doc('u')
          .collection('notes')
          .doc(n.id)
          .set(n.toMap());
    }
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 30, bottom: 48);
    tester.view.viewPadding = const FakeViewPadding(top: 30, bottom: 48);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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
                  pageBuilder: (c, s) => NoteOpenPage<void>(
                    key: s.pageKey,
                    noteId: s.pathParameters['id']!,
                    child: NoteEditorScreen(
                      key: ValueKey(s.pathParameters['id']),
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
    final providers = _Providers();
    final container = ProviderContainer(
      retry: (_, _) => null,
      observers: [providers],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_NoAuth()),
        currentUidProvider.overrideWithValue(null),
        updateRequiredProvider.overrideWithValue(false),
        notesRepositoryProvider.overrideWithValue(repo),
        attachmentRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        notesStreamProvider.overrideWith((ref) => Stream.value(notes)),
      ],
    );
    addTearDown(container.dispose);
    // Uygulamanın kökündeki sarmalayıcılar (app.dart): odak halkası, düzen
    // modu, bildirim şeridi.
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          builder: (c, child) => KeyboardFocusRing(
            child: CustomizeModeHost(
              onReorder: () {},
              child: AppNoticeHost(child: child!),
            ),
          ),
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final boundAtHome = providers.boundTo(ids);

    final live = Map<Object, String>.identity();
    final disposed = <WeakReference<Object>>[];
    void onEvent(ObjectEvent e) {
      if (e is ObjectCreated) live[e.object] = e.className;
      if (e is ObjectDisposed) {
        live.remove(e.object);
        disposed.add(WeakReference(e.object));
      }
    }

    FlutterMemoryAllocations.instance.addListener(onEvent);
    addTearDown(
      () => FlutterMemoryAllocations.instance.removeListener(onEvent),
    );

    var layouts = 0;
    var paints = 0;
    final oldPrint = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) {
      if (m != null && m.startsWith('Laying out')) layouts++;
    };
    addTearDown(() {
      debugPrint = oldPrint;
      debugPrintLayouts = false;
      debugOnProfilePaint = null;
    });

    Future<void> frame(double inset) async {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      tester.view.padding = FakeViewPadding(
        top: 30,
        bottom: (48 - inset).clamp(0.0, 48.0),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }

    /// Klavye aç → kapa: hareket karelerinin [kurulum, dizilme, boyama].
    Future<List<int>> keyboard() async {
      final counter = BuildCounter()..start();
      layouts = 0;
      paints = 0;
      debugPrintLayouts = true;
      debugOnProfilePaint = (_) => paints++;
      for (final i in [20.0, 60.0, 120.0, 200.0, 300.0]) {
        await frame(i);
      }
      await tester.pump(const Duration(milliseconds: 300));
      for (final i in [200.0, 120.0, 60.0, 20.0, 0.0]) {
        await frame(i);
      }
      debugPrintLayouts = false;
      debugOnProfilePaint = null;
      counter.stop();
      await tester.pump(const Duration(milliseconds: 300));
      return [counter.counts.values.fold(0, (a, b) => a + b), layouts, paints];
    }

    int depth() => router.routerDelegate.currentConfiguration.matches.length;

    final rows = <int, Map<String, Object>>{};
    for (var t = 1; t <= 20; t++) {
      final note = notes[(t - 1) % 4];
      await tester.tap(
        find.descendant(
          of: find.byType(NoteCard),
          matching: find.text(note.title),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      final depthOpen = depth();
      await tester.tap(
        find
            .textContaining(note.type == NoteType.text ? 'Satır 3' : 'madde 3')
            .first,
      );
      await tester.pump(const Duration(milliseconds: 200));
      final kb = await keyboard();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.binding.handlePopRoute();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // Kayıt gecikmesi ve kapanış işleri bitsin.
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(NoteEditorScreen), findsNothing);
      if (!const {1, 4, 17, 20}.contains(t)) continue;
      // Tek zorlamada eski kuşak hep boşalmıyor: sayı oturana dek tekrar.
      int retained() => disposed.where((d) => d.target != null).length;
      var before = -1;
      for (var i = 0; i < 6 && retained() != before; i++) {
        before = retained();
        await tester.runAsync(_gc);
      }
      rows[t] = {
        'kb': kb,
        'canli': live.length,
        'toplanmayan': retained(),
        'saglayici': providers.alive.length,
        'notaBagli': providers.boundTo(ids).difference(boundAtHome),
        'globals': _globals(),
        'ticker': tester.binding.transientCallbackCount,
        'rota': '$depthOpen/${depth()}',
        'abone': repo.listens - repo.cancels,
      };
      // ignore: avoid_print
      print('S51 tur $t: ${rows[t]}');
    }
    debugPrint = oldPrint;

    int n(int t, String k) => rows[t]![k]! as int;
    int kbDiff(int i) {
      List<int> kb(int t) => rows[t]!['kb']! as List<int>;
      final a = kb(17)[i] - kb(1)[i];
      final b = kb(20)[i] - kb(4)[i];
      return a > b ? a : b;
    }

    final measured = {
      'kare_kurulum_farki': kbDiff(0),
      'kare_dizilme_farki': kbDiff(1),
      'kare_boyama_farki': kbDiff(2),
      'canli_nesne_artisi': n(20, 'canli') - n(4, 'canli'),
      'toplanmayan_artisi': n(20, 'toplanmayan') - n(4, 'toplanmayan'),
      'saglayici_artisi': n(20, 'saglayici') - n(4, 'saglayici'),
      'kapali_nota_bagli_saglayici': (rows[20]!['notaBagli']! as Set).length,
      'abone_artisi': n(20, 'abone') - n(4, 'abone'),
      'ticker': n(20, 'ticker'),
    };
    // ignore: avoid_print
    print('S51: $measured');
    for (final e in measured.entries) {
      expect(
        e.value,
        lessThanOrEqualTo(budget[e.key] as int),
        reason: 'S51 ${e.key} — kapanmış nota bağlı: ${rows[20]!['notaBagli']}',
      );
    }
    expect(
      rows[20]!['globals'],
      rows[4]!['globals'],
      reason: 'genel dinleyici',
    );
    expect(rows[20]!['rota'], rows[4]!['rota'], reason: 'rota yığını');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  });
}
