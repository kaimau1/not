import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_commands.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/features/ai/data/ai_gate.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/editor/items_editor.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/notes/presentation/quick_add_actions.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TUTARLILIK F44: ray kapıları (K3, K4), klavye karşılıkları, dikey tablet
/// bölmesi, pencere boyu değişimi.
class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeDoors implements HomeDoors {
  final calls = <String>[];

  @override
  QuickAddActions get quickAddActions => throw UnimplementedError();

  @override
  void captureVoiceNote() => calls.add('voice');

  @override
  void cycleFolder(int direction) => calls.add('cycle$direction');

  @override
  void deleteSelection() => calls.add('delete');

  @override
  void dictateNote() => calls.add('dictate');

  @override
  void selectAllVisible() => calls.add('all');
}

/// Kaç kez kuruldu: pencere boyu değişince not yeniden açılmasın.
class _NoteProbe extends StatefulWidget {
  const _NoteProbe();

  static var inits = 0;

  @override
  State<_NoteProbe> createState() => _NoteProbeState();
}

class _NoteProbeState extends State<_NoteProbe> {
  @override
  void initState() {
    super.initState();
    _NoteProbe.inits++;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Builder(
      builder: (context) {
        final scope = SplitScope.maybeOf(context);
        return Column(
          children: [
            Text('gizli:${scope?.listHidden}'),
            const SizedBox(width: 200, child: TextField()),
          ],
        );
      },
    ),
  );
}

void main() {
  late ProviderContainer container;

  Future<GoRouter> pump(
    WidgetTester tester,
    Size size, {
    String initial = '/',
    List<Override> extra = const [],
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: initial,
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
                  builder: (c, s) => const _NoteProbe(),
                ),
              ],
            ),
            GoRoute(
              path: '/settings',
              builder: (c, s) => const Scaffold(body: Text('AYAR')),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(_NoAuth()),
        currentUidProvider.overrideWithValue(null),
        updateRequiredProvider.overrideWithValue(false),
        notesRepositoryProvider.overrideWithValue(null),
        attachmentRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        ...extra,
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
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    return router;
  }

  Future<void> end(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 30));
  }

  group('F44.1 ray', () {
    testWidgets('kapılar rayda, ana ekranda ikinci kopya yok (K3)', (
      tester,
    ) async {
      await pump(tester, const Size(1400, 900));
      expect(find.byKey(const ValueKey('rail-new-note')), findsOneWidget);
      expect(find.byKey(const ValueKey('home-mic')), findsOneWidget);
      expect(find.byTooltip('Yeni not — tip seç'), findsOneWidget);
      final rail = tester.getRect(find.byType(NavigationRail));
      expect(
        tester.getCenter(find.byKey(const ValueKey('home-mic'))).dx,
        lessThan(rail.right),
      );
      await end(tester);
    });

    testWidgets('telefonda kapılar ana ekranda (değişmedi)', (tester) async {
      await pump(tester, const Size(412, 915));
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(const ValueKey('home-mic')), findsOneWidget);
      expect(find.byTooltip('Yeni not — tip seç'), findsOneWidget);
      await end(tester);
    });

    testWidgets('not açıkken ray çekmece: kapılar listenin altında', (
      tester,
    ) async {
      await pump(tester, const Size(1400, 900), initial: '/note/n1');
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byKey(const ValueKey('home-mic')), findsOneWidget);
      await end(tester);
    });

    testWidgets(
      'raydaki mikrofon: bölümden notlara döner, ana ekranı çağırır',
      (tester) async {
        final router = await pump(tester, const Size(1400, 900));
        final fake = _FakeDoors();
        homeDoors = fake;
        addTearDown(() => homeDoors = null);
        unawaited(router.push('/settings'));
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byKey(const ValueKey('home-mic')));
        await tester.pump(const Duration(seconds: 1));
        expect(router.state.uri.path, '/');
        expect(fake.calls, ['dictate']);
        await end(tester);
      },
    );

    testWidgets('"Notlar" açık notu da kapatır (K4)', (tester) async {
      final router = await pump(tester, const Size(1400, 900));
      unawaited(router.push('/settings'));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byIcon(Icons.sticky_note_2_outlined));
      await tester.pump(const Duration(seconds: 1));
      expect(router.state.uri.path, '/');
      await end(tester);
    });

    testWidgets(
      'paylaşılan klasör: mikrofon ve "+" yok, salt okunurda kalem de',
      (tester) async {
        await pump(
          tester,
          const Size(1400, 900),
          extra: [
            sharedFolderRefsProvider.overrideWith(
              (ref) => Stream.value(const [
                SharedFolderRef(
                  folderId: 'sf1',
                  ownerId: 'ayse',
                  name: 'Ortak',
                  icon: NoteFolder.defaultIcon,
                  role: FolderRole.read,
                ),
              ]),
            ),
          ],
        );
        container.listen(sharedFolderRefsProvider, (_, _) {});
        await tester.pump(const Duration(milliseconds: 100));
        container.read(selectedSharedFolderProvider.notifier).set((
          ownerId: 'ayse',
          folderId: 'sf1',
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byKey(const ValueKey('home-mic')), findsNothing);
        expect(find.byTooltip('Yeni not — tip seç'), findsNothing);
        expect(find.byKey(const ValueKey('rail-new-note')), findsNothing);
        await end(tester);
      },
    );
  });

  group('F44.5 klavye', () {
    Future<void> combo(
      WidgetTester tester,
      LogicalKeyboardKey modifier,
      LogicalKeyboardKey key,
    ) async {
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(modifier);
      await tester.pump();
    }

    testWidgets('Alt+←/→ klasör geçer, yazarken geçmez', (tester) async {
      await pump(tester, const Size(1400, 900), initial: '/note/n1');
      final fake = _FakeDoors();
      homeDoors = fake;
      addTearDown(() => homeDoors = null);
      await combo(
        tester,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.arrowRight,
      );
      await combo(
        tester,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.arrowLeft,
      );
      expect(fake.calls, ['cycle1', 'cycle-1']);
      await tester.tap(find.byType(TextField).last);
      await tester.pump();
      await combo(
        tester,
        LogicalKeyboardKey.altLeft,
        LogicalKeyboardKey.arrowRight,
      );
      expect(fake.calls, ['cycle1', 'cycle-1']);
      await end(tester);
    });

    testWidgets('Ctrl+A ve Delete yalnız seçimde', (tester) async {
      await pump(tester, const Size(1400, 900));
      final fake = _FakeDoors();
      homeDoors = fake;
      addTearDown(() => homeDoors = null);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await combo(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.keyA,
      );
      expect(fake.calls, isEmpty);
      container.read(selectedNoteIdsProvider.notifier).selectAll(['a']);
      await tester.pump(const Duration(milliseconds: 100));
      await combo(
        tester,
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.keyA,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      expect(fake.calls, ['all', 'delete']);
      await end(tester);
    });

    testWidgets(
      'yardım penceresi yeni kısayolları listeler, kısa ekranda taşmaz',
      (tester) async {
        await pump(tester, const Size(1024, 520));
        await combo(
          tester,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.slash,
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(find.text('Alt + ← / →'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 30));
      },
    );
  });

  group('F44.7 dikey tablet', () {
    test('kural: dar ve dikey; menteşe ve yatay hariç', () {
      expect(listAutoHidesFor(const Size(800, 1280), hasHinge: false), isTrue);
      expect(listAutoHidesFor(const Size(800, 1280), hasHinge: true), isFalse);
      expect(listAutoHidesFor(const Size(1280, 800), hasHinge: false), isFalse);
      expect(
        listAutoHidesFor(const Size(1000, 1300), hasHinge: false),
        isFalse,
      );
    });

    testWidgets('not açılınca liste çekilir, ☰ yalnız bu not için açar', (
      tester,
    ) async {
      final router = await pump(
        tester,
        const Size(800, 1280),
        initial: '/note/n1',
      );
      expect(find.text('gizli:true'), findsOneWidget);
      container.read(listPeekLocationProvider.notifier).set('/note/n1');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('gizli:false'), findsOneWidget);
      // Başka nota geçince yine çekilir.
      router.go('/note/n2');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('gizli:true'), findsOneWidget);
      await end(tester);
    });

    testWidgets('yatay tablette liste yerinde (değişmedi)', (tester) async {
      await pump(tester, const Size(1280, 800), initial: '/note/n1');
      expect(find.text('gizli:false'), findsOneWidget);
      await end(tester);
    });
  });

  group('F44.8 pencere boyu', () {
    testWidgets('daralt/genişlet: açık not ve seçim korunur', (tester) async {
      _NoteProbe.inits = 0;
      final router = await pump(
        tester,
        const Size(1400, 900),
        initial: '/note/n1',
      );
      container.read(selectedNoteIdsProvider.notifier).selectAll(['a', 'b']);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_NoteProbe.inits, 1);
      // Ray, bölme ve dikey kesme noktalarının hepsinden geç.
      for (final size in const [
        Size(500, 900),
        Size(650, 900),
        Size(800, 1280),
        Size(1400, 900),
        Size(420, 800),
      ]) {
        tester.view.physicalSize = size;
        await tester.pump(const Duration(milliseconds: 400));
        expect(router.state.uri.path, '/note/n1', reason: '$size');
        expect(find.byType(_NoteProbe), findsOneWidget, reason: '$size');
      }
      expect(_NoteProbe.inits, 1);
      expect(container.read(selectedNoteIdsProvider), {'a', 'b'});
      await end(tester);
    });
  });

  group('F18.11 telefonu çevir (cihaz turu kök nedeni)', () {
    ScrollPosition grid(WidgetTester tester) => tester
        .stateList<ScrollableState>(find.byType(Scrollable))
        .where(
          (s) =>
              s.position.axis == Axis.vertical &&
              s.position.maxScrollExtent > 0,
        )
        .first
        .position;

    testWidgets('dar → geniş → dar: ana liste aynı bölgede kalır', (
      tester,
    ) async {
      final notes = [
        for (var i = 0; i < 80; i++)
          Note(
            id: 'k$i',
            type: NoteType.text,
            title: 'Not $i',
            body: 'içerik satırı\nikinci satır',
          ),
      ];
      await pump(
        tester,
        const Size(392, 850),
        extra: [notesStreamProvider.overrideWith((ref) => Stream.value(notes))],
      );
      await tester.pump(const Duration(milliseconds: 300));
      grid(tester).jumpTo(1500);
      await tester.pump(const Duration(milliseconds: 100));
      final before = grid(tester).pixels / grid(tester).maxScrollExtent;

      tester.view.physicalSize = const Size(850, 392);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      final wide = grid(tester).pixels / grid(tester).maxScrollExtent;
      expect(wide, closeTo(before, 0.2), reason: 'yatayda konum');

      tester.view.physicalSize = const Size(392, 850);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      final back = grid(tester).pixels / grid(tester).maxScrollExtent;
      expect(back, closeTo(before, 0.2), reason: 'dikeyde konum');
      await end(tester);
    });
  });

  testWidgets('aramada geri aramayı kapatır, uygulamadan çıkmaz', (
    tester,
  ) async {
    await pump(tester, const Size(392, 850));
    container.read(searchQueryProvider.notifier).set('yumurta');
    await tester.pump(const Duration(milliseconds: 100));
    final handled = await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 100));
    expect(handled, isTrue);
    expect(container.read(searchQueryProvider), '');
    await end(tester);
  });

  group('F44.3 okuma sütunu', () {
    Future<void> at(WidgetTester tester, Size size) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          currentUidProvider.overrideWithValue(null),
          updateRequiredProvider.overrideWithValue(false),
          notesRepositoryProvider.overrideWithValue(null),
          attachmentRepositoryProvider.overrideWithValue(null),
          foldersRepositoryProvider.overrideWithValue(null),
          noteStreamProvider('n1').overrideWith(
            (ref) => Stream.value(
              const Note(id: 'n1', type: NoteType.text, title: 'Başlık'),
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: NoteEditorScreen(noteId: 'n1'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('geniş ekranda üst ve alt çubuk 760 dp sütununda', (
      tester,
    ) async {
      await at(tester, const Size(1600, 900));
      const left = (1600 - kReadingWidth) / 2;
      const right = 1600 - left;
      final menu = tester.getRect(find.byTooltip('Not menüsü'));
      expect(menu.right, lessThanOrEqualTo(right));
      expect(menu.right, greaterThan(right - 56));
      final add = tester.getRect(
        find.byKey(const ValueKey('editor-add-button')),
      );
      expect(add.left, greaterThan(left));
      expect(add.left, lessThan(left + 160));
      await end(tester);
    });

    testWidgets('telefonda çubuklar kenarda (değişmedi)', (tester) async {
      await at(tester, const Size(412, 915));
      final menu = tester.getRect(find.byTooltip('Not menüsü'));
      expect(menu.right, greaterThan(412 - 56));
      await end(tester);
    });
  });

  group('F44.4 arama, F44.6 AI', () {
    testWidgets('arama kutusu en çok 720 dp; telefonda tam genişlik', (
      tester,
    ) async {
      await pump(tester, const Size(1440, 900));
      expect(tester.getSize(find.byType(TextField).first).width, lessThan(720));
      expect(
        tester
            .getRect(
              find
                  .ancestor(
                    of: find.byType(TextField).first,
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .width,
        720,
      );
      await end(tester);
    });

    testWidgets('yapay zekâ kapalıysa rayda kilit, açıksa ✨', (tester) async {
      await pump(
        tester,
        const Size(1400, 900),
        extra: [aiAvailabilityProvider.overrideWithValue(AiAvailability.ready)],
      );
      expect(find.byIcon(Icons.auto_awesome_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsNothing);
      await end(tester);
      await pump(
        tester,
        const Size(1400, 900),
        extra: [
          aiAvailabilityProvider.overrideWithValue(
            AiAvailability.webBuiltInOff,
          ),
        ],
      );
      expect(find.byIcon(Icons.auto_awesome_outlined), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      await end(tester);
    });
  });

  group('F44.5 madde sağ tık', () {
    testWidgets('sağ tık uzun basışla aynı menüyü açar', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: Scaffold(
              body: ItemsEditor(
                items: const [NoteItem(id: 'a', text: 'Öğe')],
                onChanged: (_) {},
                showCheckboxes: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      final box = tester.getTopLeft(find.byType(ItemsEditor));
      await tester.tapAt(box + const Offset(24, 24), buttons: kSecondaryButton);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('item-menu-highlight')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    });
  });

  group('F44.5 kart ⋮', () {
    Future<void> card(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUidProvider.overrideWithValue(null),
            notesRepositoryProvider.overrideWithValue(null),
            foldersRepositoryProvider.overrideWithValue(null),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('tr'),
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 300,
                  child: NoteCard(
                    note: Note(id: 'k', type: NoteType.text, title: 'Kart'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    bool shown(WidgetTester tester) => tester
        .widget<Visibility>(
          find.ancestor(
            of: find.byKey(const ValueKey('note-card-menu')),
            matching: find.byType(Visibility),
          ),
        )
        .visible;

    testWidgets('dokunmatikte hep görünür; farede üstüne gelince', (
      tester,
    ) async {
      await card(tester);
      expect(shown(tester), isTrue);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(700, 500));
      await tester.pump();
      expect(shown(tester), isFalse, reason: 'fare bağlandı, kart dışında');
      await mouse.moveTo(tester.getCenter(find.byType(NoteCard)));
      await tester.pump();
      expect(shown(tester), isTrue);
      await mouse.moveTo(const Offset(700, 500));
      await tester.pump();
      expect(shown(tester), isFalse);
      await mouse.removePointer();
      await tester.pump();
      expect(shown(tester), isTrue, reason: 'fare gitti');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 30));
    });
  });
}
