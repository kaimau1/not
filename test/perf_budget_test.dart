import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/calendar/presentation/calendar_views.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/note_open_route.dart';
import 'package:notlar/app/second_note.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/features/notes/data/upload_queue.dart'
    show pendingUploadsProvider;
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/notes/presentation/dashboard_scroll_memory.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/utils/firestore_size.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note_heavy.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/editor/format_bar.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/pdf_page_box.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';

import 'support/editor_harness.dart';

/// **AKICILIK BÜTÇESİ** (OTURTMA F59.2, senaryolar Ek A). Sayılan şey süre
/// değil SAYI (kök kurulum, kayıt): makineden bağımsız. Bütçeler
/// `perf_budget/budgets.json`'da; mandal kuralı orada.
///
/// PDF'i çizdirmek pdfium ister (testte yok): kalem katmanı kurulmaz, ama
/// kutuya verilen [InkController] gerçek olanıdır — çizgi ona işlenir, yol
/// (denetleyici → bölme/tuval → editör → depo) cihazdakiyle aynıdır.
final Map<String, dynamic> _budgets = jsonDecode(
  File('test/perf_budget/budgets.json').readAsStringSync(),
) as Map<String, dynamic>;

int _budget(String scenario, String key) =>
    (_budgets[scenario] as Map<String, dynamic>)[key] as int;

const _pdf = Attachment(
  id: 'p',
  kind: AttachmentKind.pdf,
  fileName: 'belge.pdf',
  mimeType: 'application/pdf',
  width: 600,
  height: 800,
);

Note _noteWith(Attachment a) => Note(
  id: 'n',
  type: NoteType.text,
  title: 'Başlık',
  body: 'yazı',
  attachments: [a],
);

final _pinnedPdf = _pdf.copyWith(pinHeight: 300);
final _embeddedPdf = _pdf.copyWith(onPage: true);

void _stylusDevice() {
  InkToolMemory.autoStylus = true;
  InkToolMemory.stylusEver = true;
  addTearDown(() => InkToolMemory.stylusEver = false);
}

InkController _inkOf(WidgetTester tester) =>
    tester.widget<PdfPageBox>(find.byType(PdfPageBox)).ink!;

int _pointer = 100;

/// Kalemle tek çizgi (katmanın yaptığı çağrılar) + 300 ms.
Future<void> _stroke(WidgetTester tester, InkController c, int i) async {
  const size = Size(300, 400);
  final p = _pointer++;
  final y = 20.0 + i * 12;
  c.pointerDown(
    1,
    Offset(20, y),
    size,
    pointer: p,
    kind: PointerDeviceKind.stylus,
  );
  c.pointerMove(1, Offset(80, y + 4), size, pointer: p);
  c.pointerMove(1, Offset(140, y + 8), size, pointer: p);
  c.pointerUp(pointer: p, kind: PointerDeviceKind.stylus);
  await tester.pump(const Duration(milliseconds: 300));
}

List<InkStroke> _savedInk(CountingNotesRepository repo) =>
    repo.lastSaved!.attachments.single.ink;

/// S6/S7 gövdesi: 10 çizgi → kök kurulum ve kayıt sayısı; sonra tuzak
/// (başka nedenle kök kurulumu çizgileri silmez) ve kapanışta veri kaybı yok.
Future<void> _tenStrokes(
  WidgetTester tester,
  String scenario,
  Attachment pdf,
) async {
  _stylusDevice();
  final repo = CountingNotesRepository();
  await pumpEditor(tester, _noteWith(pdf), repo: repo);
  final ink = _inkOf(tester);
  repo.resetCounts();
  final counter = BuildCounter()..start();
  addTearDown(counter.stop);

  for (var i = 0; i < 10; i++) {
    await _stroke(tester, ink, i);
  }
  // Kayıt gecikmesi (2 sn) dolsun.
  await tester.pump(const Duration(seconds: 3));
  final roots = counter.of('NoteEditorScreen');
  final saves = repo.updateNoteCalls;
  counter.stop();
  // ignore: avoid_print
  print('$scenario: kök kurulum $roots, updateNote $saves');
  expect(ink.ink, hasLength(10));
  expect(saves, greaterThan(0), reason: 'mürekkep kaydedilmeli');
  expect(_savedInk(repo), hasLength(10));
  expect(roots, lessThanOrEqualTo(_budget(scenario, 'kok_kurulum')));
  expect(saves, lessThanOrEqualTo(_budget(scenario, 'update_note')));

  // TUZAK 1: kök kurulmadığı için kutunun elindeki ek BAYAT (en çok ilk
  // çizgiyi bilir). Kutudan gelen mürekkep dışı değişiklik (sayfa çevirme)
  // o bayat listeyi geri yazıp çizgileri silmez.
  final stale = tester.widget<PdfPageBox>(find.byType(PdfPageBox));
  expect(stale.attachment.ink.length, lessThan(10));
  counter.start();
  stale.onChanged(stale.attachment.copyWith(pdfPage: 2));
  await tester.pump(const Duration(milliseconds: 300));
  counter.stop();
  expect(repo.lastSaved!.attachments.single.pdfPage, 2);
  expect(_savedInk(repo), hasLength(10));
  // TUZAK 2: başka nedenle gelen kök kurulumu (sayfa değişti) çizgileri ne
  // siler ne denetleyiciyi yeniler.
  expect(counter.of('NoteEditorScreen'), greaterThan(0));
  expect(identical(_inkOf(tester), ink), isTrue);
  expect(ink.ink, hasLength(10));
  expect(
    tester.widget<PdfPageBox>(find.byType(PdfPageBox)).attachment.ink,
    hasLength(10),
  );

  // KAPANIŞ: bekleyen (debounce'taki) çizgi not kapanırken yazılır.
  await _stroke(tester, ink, 10);
  expect(_savedInk(repo), hasLength(10), reason: 'henüz bekliyor');
  await endEditor(tester);
  expect(_savedInk(repo), hasLength(11));
}

// ── S1–S5, S8, S9, S11–S16 (F59.2–F59.4) ───────────────────────────────

/// [body] boyunca tür başına kurulum sayıları.
Future<Map<String, int>> _count(Future<void> Function() body) async {
  final counter = BuildCounter()..start();
  try {
    await body();
  } finally {
    counter.stop();
  }
  return counter.counts;
}

void _expectBudget(String scenario, Map<String, int> measured) {
  // ignore: avoid_print
  print('$scenario: $measured');
  for (final e in measured.entries) {
    expect(
      e.value,
      lessThanOrEqualTo(_budget(scenario, e.key)),
      reason: '$scenario ${e.key}',
    );
  }
}

/// Madde satırının metin yuvası (satır başına bir tane).
const _row = '_LazyItemField';

/// Editör gövdesi sayılan türler (S8).
const _bodyTypes = [
  'NoteEditorScreen',
  'NotePageCanvas',
  'ItemsEditor',
  'EditableText',
];

/// Uzun listenin kademeli kurulumu (`ItemsEditor._growBudget`) bitsin —
/// ölçülen işin değil; ölçüm penceresine girerse satır sayısını şişirir.
Future<void> _settleGrowth(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Levha/panel animasyonu otursun (ilk pump saati başlatır).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Odaktaki alana klavyeden tek tek [n] karakter.
Future<void> _type(WidgetTester tester, String base, {int n = 20}) async {
  for (var i = 1; i <= n; i++) {
    tester.testTextInput.enterText(base + 'a' * i);
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _text = Note(id: 'n', type: NoteType.text, title: 'Kısa', body: 'yazı');

final _list30 = Note(
  id: 'n',
  type: NoteType.checklist,
  title: 'Liste',
  items: [for (var i = 0; i < 30; i++) NoteItem(id: 'i$i', text: 'madde $i')],
);

/// Sentetik el yazısı: [n] çizgi, her biri 12 nokta.
List<InkStroke> _ink(int n) => [
  for (var i = 0; i < n; i++)
    InkStroke(
      page: 1,
      color: 0xFF000000,
      width: 0.004,
      points: [
        for (var k = 0; k < 12; k++) ...[
          (i % 40) / 50 + k * 0.004,
          (i ~/ 40) / 60 + (k.isEven ? 0.0 : 0.006),
        ],
      ],
    ),
];

DocumentReference<Map<String, dynamic>> _noteDoc(FirebaseFirestore db) =>
    db.collection('users').doc('u').collection('notes').doc('n');

/// Gerçek [NotesRepository] (sahte Firestore): kendi yazımını hatırlar
/// (`isOwnEcho`), yazılan not [watchNote] akışından geri gelir.
class _LiveRepo extends NotesRepository {
  _LiveRepo(this.db) : super(db, 'u');
  final FakeFirebaseFirestore db;
  int updateNoteCalls = 0;
  void Function(Note note)? onSaved;

  @override
  Future<void> updateNote(Note note, {bool clientTime = false}) {
    updateNoteCalls++;
    final f = super.updateNote(note, clientTime: clientTime);
    onSaved?.call(note);
    return f;
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

/// Ana ekran (ve geniş pencerede bölünmüş kabuk) — tur düzeneğiyle aynı rota.
Future<void> _pumpHome(
  WidgetTester tester, {
  required Size size,
  required Stream<List<Note>> notes,
  String location = '/',
  NotesRepository? repo,
  Map<String, Object> prefsValues = const {},
  // Gerçek uygulamanın not sayfası (karttan büyüyen geçiş, S18/S19).
  bool openPage = false,
  // false: yalnız ilk kare (S24 soğuk açılış).
  bool settle = true,
  double dpr = 1,
  List<Override> overrides = const [],
  // Uygulamanın bildirim şeridi ([AppNoticeHost]) Navigator'ın üstünde (S31).
  bool notices = false,
}) async {
  // Oturum durağanları (önceki testten kalan kaydırma, ipucu hakkı)
  // ölçümü test sırasına bağlamasın.
  DashboardScrollMemory.clear();
  TipOnce.resetSession();
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: location,
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
                pageBuilder: (c, s) {
                  final editor = NoteEditorScreen(
                    key: ValueKey(s.pathParameters['id']),
                    noteId: s.pathParameters['id']!,
                  );
                  return openPage
                      ? NoteOpenPage<void>(
                          key: s.pageKey,
                          noteId: s.pathParameters['id']!,
                          child: editor,
                        )
                      : MaterialPage<void>(key: s.pageKey, child: editor);
                },
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
      notesRepositoryProvider.overrideWithValue(repo),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      notesStreamProvider.overrideWith((ref) => notes),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        builder: notices ? (c, child) => AppNoticeHost(child: child!) : null,
        locale: const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  if (!settle) return;
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
}

CollectionReference<Map<String, dynamic>> _noteCol(FirebaseFirestore db) =>
    db.collection('users').doc('u').collection('notes');

int _sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);

/// [action]'dan sonraki [frames] karenin (16 ms) kurulum sayıları.
typedef _FrameStats = ({
  Map<String, int> counts,
  int first,
  int worst,
  int worstAfterFirst,
  int total,
});

Future<_FrameStats> _frames(
  WidgetTester tester,
  Future<void> Function() action, {
  int frames = 30,
}) async {
  final counter = BuildCounter()..start();
  final perFrame = <int>[];
  try {
    await action();
    var last = 0;
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final now = _sum(counter.counts);
      perFrame.add(now - last);
      last = now;
    }
  } finally {
    counter.stop();
  }
  final rest = perFrame.skip(1);
  return (
    counts: Map.of(counter.counts),
    first: perFrame.first,
    worst: perFrame.reduce(max),
    worstAfterFirst: rest.isEmpty ? 0 : rest.reduce(max),
    total: _sum(counter.counts),
  );
}

/// Takvim ekranı (telefon, 21 etkinlik, 6 Kasım 2026) — S22 ve S35 düzeneği.
Future<void> _pumpCalendar(WidgetTester tester, String view) async {
  await initializeDateFormatting('tr');
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'calendar_pinch_hint_v1': true,
    'calendar_view': view,
  });
  final prefs = await SharedPreferences.getInstance();
  final events = [
    for (var d = 0; d < 21; d++)
      CalendarEvent(
        id: 'e$d',
        title: 'Etkinlik $d',
        start: DateTime(2026, 11, 2 + d, 10),
        end: DateTime(2026, 11, 2 + d, 11),
      ),
  ];
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        calendarRepositoryProvider.overrideWithValue(
          CalendarRepository(FakeFirebaseFirestore(), 'u'),
        ),
        eventsStreamProvider.overrideWith((ref) => Stream.value(events)),
        tasksStreamProvider.overrideWith(
          (ref) => Stream.value(const <TaskItem>[]),
        ),
        calendarReminderNotesProvider.overrideWithValue(const []),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalendarScreen(now: DateTime(2026, 11, 6, 12)),
      ),
    ),
  );
}

/// Ayarlar ekranı (misafir) — S29, S36. Kurulacak ağacı döndürür: S29
/// açılışı pompanın kendisini sayar.
Future<Widget> _settingsApp(
  WidgetTester tester,
  Size size, {
  String? area,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(_NoAuth()),
      currentUidProvider.overrideWithValue(null),
      isAnonymousProvider.overrideWithValue(true),
      notesRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
    ],
  );
  addTearDown(container.dispose);
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('tr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(initialArea: area),
    ),
  );
}

/// [finder]'ın boyunun değiştiği kare sayısı, [frames] kare (S9 kalıbı).
Future<int> _resizedFrames(
  WidgetTester tester,
  Finder finder, {
  int frames = 30,
}) async {
  var resized = 0;
  var last = tester.getSize(finder).height;
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
    final h = tester.getSize(finder).height;
    if (h != last) resized++;
    last = h;
  }
  return resized;
}

void main() {
  test('her bütçenin nedeni yazılı (mandal kuralı)', () {
    for (final e in _budgets.entries) {
      if (e.key.startsWith('_')) continue;
      final neden = (e.value as Map<String, dynamic>)['neden'];
      expect(neden, isA<String>(), reason: e.key);
      expect((neden as String).trim(), isNotEmpty, reason: e.key);
    }
  });

  testWidgets('S6: sabit PDF\'e 10 çizgi — kök kurulum ve kayıt bütçesi', (
    tester,
  ) async {
    await _tenStrokes(tester, 'S6', _pinnedPdf);
  });

  testWidgets('S7: gömülü PDF\'e 10 çizgi — kök kurulum ve kayıt bütçesi', (
    tester,
  ) async {
    await _tenStrokes(tester, 'S7', _embeddedPdf);
  });

  testWidgets('S1: kısa metin notu, gövdeye 20 karakter', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _text, repo: repo);
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    await tester.pump(const Duration(milliseconds: 400));
    repo.resetCounts();
    final c = await _count(() async {
      await _type(tester, 'yazı');
      await tester.pump(const Duration(seconds: 3));
    });
    expect(repo.lastSaved!.body, 'yazı${'a' * 20}');
    _expectBudget('S1', {
      'kok_kurulum': c['NoteEditorScreen'] ?? 0,
      'update_note': repo.updateNoteCalls,
    });
    await endEditor(tester);
  });

  testWidgets('S2: 30 maddeli liste, bir maddeye 20 karakter', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _list30, repo: repo);
    await _settleGrowth(tester);
    await tester.tap(find.text('madde 7'));
    await tester.pump(const Duration(milliseconds: 400));
    final c = await _count(() async {
      await _type(tester, 'madde 7');
      await tester.pump(const Duration(seconds: 3));
    });
    expect(repo.lastSaved!.items[7].text, 'madde 7${'a' * 20}');
    _expectBudget('S2', {
      'items_editor': c['ItemsEditor'] ?? 0,
      'satir': c[_row] ?? 0,
    });
    await endEditor(tester);
  });

  testWidgets('S3: 30 maddeli liste, bir kutucuğu işaretle', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _list30, repo: repo);
    await _settleGrowth(tester);
    final c = await _count(() async {
      await tester.tap(find.byType(Checkbox).at(7));
      await tester.pump(const Duration(seconds: 3));
    });
    expect(repo.lastSaved!.items.where((i) => i.checked), hasLength(1));
    _expectBudget('S3', {
      'kok_kurulum': c['NoteEditorScreen'] ?? 0,
      'satir': c[_row] ?? 0,
    });
    await endEditor(tester);
  });

  testWidgets('S4: maddede Enter (yeni madde)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _list30, repo: repo);
    await _settleGrowth(tester);
    await tester.tap(find.text('madde 7'));
    await tester.pump(const Duration(milliseconds: 400));
    final c = await _count(() async {
      tester.testTextInput.enterText('madde 7\n');
      await tester.pump(const Duration(seconds: 3));
    });
    expect(repo.lastSaved!.items, hasLength(31));
    _expectBudget('S4', {
      'kok_kurulum': c['NoteEditorScreen'] ?? 0,
      'satir': c[_row] ?? 0,
    });
    await endEditor(tester);
  });

  testWidgets('S5: kalem kipi, sayfaya 10 çizgi', (tester) async {
    _stylusDevice();
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _text, repo: repo);
    final page = tester.getRect(find.byType(PageInkStack));
    Future<void> stroke(int i) async {
      final pen = await tester.startGesture(
        page.topLeft + Offset(60, 200.0 + i * 25),
        kind: PointerDeviceKind.stylus,
      );
      await tester.pump();
      await pen.moveBy(const Offset(60, 6));
      await tester.pump();
      await pen.moveBy(const Offset(60, 6));
      await tester.pump();
      await pen.up();
      await tester.pump(const Duration(milliseconds: 300));
    }

    // İlk çizgi kalem kipini açar (çekmece, ipucu); sayılan sonraki 10.
    await stroke(0);
    await tester.pump(const Duration(seconds: 8));
    repo.resetCounts();
    final c = await _count(() async {
      for (var i = 1; i <= 10; i++) {
        await stroke(i);
      }
      await tester.pump(const Duration(seconds: 3));
    });
    expect(repo.lastSaved!.pageInk, hasLength(11));
    _expectBudget('S5', {
      'kok_kurulum': c['NoteEditorScreen'] ?? 0,
      'update_note': repo.updateNoteCalls,
    });
    await endEditor(tester);
  });

  testWidgets('S8: klavye aç/kapa ×3 (inset kareleri)', (tester) async {
    await pumpEditor(
      tester,
      _list30.copyWith(body: List.generate(30, (i) => 'Satır $i').join('\n')),
    );
    // Uzun listenin kademeli kurulumu (ItemsEditor._growBudget: açılıştan
    // 500 ms sonra kare başına 2 satır) bitsin — klavyenin işi değil; eskiden
    // bu senaryonun 15 kurulumu oydu (F60.S5).
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final counter = BuildCounter()..start();
    addTearDown(counter.stop);
    int body() => _bodyTypes.fold(0, (n, t) => n + counter.of(t));
    var moving = 0;
    var settling = 0;
    Future<void> frames(List<double> insets) async {
      var before = body();
      for (final inset in insets) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        tester.view.padding = FakeViewPadding(
          top: 30,
          bottom: (48 - inset).clamp(0.0, 48.0),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      moving += body() - before;
      before = body();
      await tester.pump(const Duration(milliseconds: 300));
      settling += body() - before;
    }

    for (var i = 0; i < 3; i++) {
      await frames([20, 60, 120, 200, 300]);
      await frames([200, 120, 60, 20, 0]);
    }
    counter.stop();
    _expectBudget('S8', {'govde_kurulum': moving, 'oturma_kurulum': settling});
    await endEditor(tester);
  });

  testWidgets('S9: Biçim panelini aç → kapat', (tester) async {
    await pumpEditor(tester, _text);
    // Gövdenin (kaydırma görünümü) boyunun değiştiği kare sayısı: boy TEK
    // ADIMDA değişmeli (kasma listesi md. 6) — açılış 1 + kapanış 1.
    final body = find
        .ancestor(
          of: find.byType(NotePageCanvas),
          matching: find.byType(Scrollable),
        )
        .first;
    var resized = 0;
    Future<void> frames() async {
      var last = tester.getSize(body).height;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final h = tester.getSize(body).height;
        if (h != last) resized++;
        last = h;
      }
    }

    final c = await _count(() async {
      await tester.tap(find.byTooltip('Biçim'));
      await frames();
      await _settle(tester);
      expect(find.byType(FormatBar), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('format-close')));
      await frames();
      await _settle(tester);
    });
    expect(find.byTooltip('Biçim'), findsOneWidget, reason: 'panel kapandı');
    _expectBudget('S9', {
      'tuval_kurulum': c['NotePageCanvas'] ?? 0,
      'govde_boy_karesi': resized,
    });
    await endEditor(tester);
  });

  testWidgets('S11: kendi kaydının akış yankısı', (tester) async {
    final repo = _LiveRepo(FakeFirebaseFirestore());
    await _noteDoc(repo.db).set(_text.toMap());
    await pumpEditor(
      tester,
      _text,
      repo: repo,
      noteStream: repo.watchNote('n'),
    );
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    await tester.pump(const Duration(milliseconds: 400));
    await _type(tester, 'yazı');
    // Kayıt çıkana dek bekle; sayılan yalnız ondan SONRA gelen yankı.
    for (var i = 0; i < 40 && repo.updateNoteCalls == 0; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(repo.updateNoteCalls, 1);
    final c = await _count(() => tester.pump(const Duration(seconds: 2)));
    final saved = await _noteDoc(repo.db).get();
    expect(saved.data()!['body'], 'yazı${'a' * 20}', reason: 'yankı gerçek');
    _expectBudget('S11', {'kok_kurulum': c['NoteEditorScreen'] ?? 0});
    await endEditor(tester);
  });

  testWidgets('S12: 1280×800 bölünmüş — açık nota 20 karakter + kayıt', (
    tester,
  ) async {
    // Hepsi bugün düzenlenmiş: kayıt notu başka tarih bölümüne taşımasın
    // (bölüm değişimi bütün ızgarayı yeniden dizer — ölçülen o değil).
    final now = DateTime.now();
    final all = [
      Note(
        id: 'n',
        type: NoteType.text,
        title: 'Kısa',
        body: 'yazı',
        updatedAt: now,
      ),
      for (var i = 0; i < 12; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i',
          updatedAt: now,
        ),
    ];
    final list = StreamController<List<Note>>.broadcast();
    addTearDown(list.close);
    final repo = _LiveRepo(FakeFirebaseFirestore());
    await _noteDoc(repo.db).set(_text.toMap());
    // Firestore'daki gibi: kayıt liste akışına da yansır.
    repo.onSaved = (n) => list.add([n, ...all.skip(1)]);
    await _pumpHome(
      tester,
      size: const Size(1280, 800),
      notes: list.stream,
      location: '/note/n',
      repo: repo,
    );
    list.add(all);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    expect(find.byType(NoteCard), findsWidgets);
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    await tester.pump(const Duration(milliseconds: 400));
    // Yazarken + kayıt (2 sn boşluk): liste açık notun ESKİ örneğini tutar.
    final c = await _count(() async {
      await _type(tester, 'yazı');
      await tester.pump(const Duration(milliseconds: 2500));
    });
    expect(repo.updateNoteCalls, greaterThan(0));
    // Yazma durunca (son tuştan 3 sn) tutma bırakılır: yalnız o kart.
    final after = await _count(() async {
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
    });
    _expectBudget('S12', {
      'dashboard_kurulum': c['DashboardScreen'] ?? 0,
      'note_card': c['NoteCard'] ?? 0,
      'durunca_dashboard_kurulum': after['DashboardScreen'] ?? 0,
      'durunca_note_card': after['NoteCard'] ?? 0,
    });
    final card = tester
        .widgetList<NoteCard>(find.byType(NoteCard))
        .firstWhere((w) => w.note.id == 'n');
    expect(
      card.note.body,
      startsWith(
        'yazı'
        'a',
      ),
      reason: 'kart güncel',
    );
    await endEditor(tester);
  });

  // F68.2 kapısı: ızgara girdisi (liste örneği, sütun, kipler) değişmeyen bir
  // gezinme panoyu kurmamalı — kurarsa gövdeyi bölmenin kanıtı budur.
  testWidgets('S12b: 1280×800 bölünmüş — açık nottan başka nota geç', (
    tester,
  ) async {
    final now = DateTime.now();
    final all = [
      for (var i = 0; i < 13; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i',
          updatedAt: now,
        ),
    ];
    final repo = _LiveRepo(FakeFirebaseFirestore());
    final col = repo.db.collection('users').doc('u').collection('notes');
    await col.doc('x3').set(all[3].toMap());
    await col.doc('x5').set(all[5].toMap());
    await _pumpHome(
      tester,
      size: const Size(1280, 800),
      notes: Stream.value(all),
      location: '/note/x3',
      repo: repo,
    );
    await tester.pump(const Duration(seconds: 1));
    final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
    final c = await _count(() async {
      router.go('/note/x5');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    });
    expect(
      tester.widget<NoteEditorScreen>(find.byType(NoteEditorScreen)).noteId,
      'x5',
    );
    _expectBudget('S12b', {
      'dashboard_kurulum': c['DashboardScreen'] ?? 0,
      'hucre': c['_ReorderableNoteCell'] ?? 0,
      'note_card': c['NoteCard'] ?? 0,
    });
    await endEditor(tester);
  });

  // P59 (HIZ SÖZLEŞMESİ 1): geniş düzende nottan listeye dönüş. Bölme
  // geçiş süresince yerinde bekler, liste tek adımda tam genişliğe geçer.
  testWidgets('S26: 1280×800 bölünmüş — nottan listeye dön', (tester) async {
    final now = DateTime.now();
    final all = [
      for (var i = 0; i < 13; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i',
          updatedAt: now,
        ),
    ];
    final repo = _LiveRepo(FakeFirebaseFirestore());
    final col = repo.db.collection('users').doc('u').collection('notes');
    await col.doc('x3').set(all[3].toMap());
    await _pumpHome(
      tester,
      size: const Size(1280, 800),
      notes: Stream.value(all),
      location: '/note/x3',
      repo: repo,
    );
    await tester.pump(const Duration(seconds: 1));
    final router = GoRouter.of(tester.element(find.byType(DashboardScreen)));
    final c = await _count(() async {
      router.go('/');
      await tester.pump();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(seconds: 1));
    });
    expect(find.byType(NoteEditorScreen), findsNothing);
    _expectBudget('S26', {
      'dashboard_kurulum': c['DashboardScreen'] ?? 0,
      'note_card': c['NoteCard'] ?? 0,
    });
  });

  // K32 (A5): iki not yan yana — birincile yazmak yandaki editörü ve panoyu
  // kurmamalı (yankı yalıtımı). Klavye kareleri iki bölmede de kurulumsuz
  // (S8 tek not 0 → iki not ≤ 2 × 0).
  testWidgets('S27: 1280×800 iki not — birincile 20 karakter + kayıt', (
    tester,
  ) async {
    final now = DateTime.now();
    final all = [
      Note(
        id: 'n',
        type: NoteType.text,
        title: 'Kısa',
        body: 'yazı',
        updatedAt: now,
      ),
      Note(
        id: 's',
        type: NoteType.text,
        title: 'Yan',
        body: 'yandaki',
        updatedAt: now,
      ),
      for (var i = 0; i < 11; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i',
          updatedAt: now,
        ),
    ];
    final list = StreamController<List<Note>>.broadcast();
    addTearDown(list.close);
    final repo = _LiveRepo(FakeFirebaseFirestore());
    await _noteDoc(repo.db).set(_text.toMap());
    await _noteCol(repo.db).doc('s').set(all[1].toMap());
    repo.onSaved = (n) => list.add([n, ...all.skip(1)]);
    await _pumpHome(
      tester,
      size: const Size(1280, 800),
      notes: list.stream,
      location: '/note/n',
      repo: repo,
    );
    list.add(all);
    await tester.pump(const Duration(seconds: 1));
    ProviderScope.containerOf(
      tester.element(find.byType(DashboardScreen, skipOffstage: false)),
      listen: false,
    ).read(secondNoteProvider.notifier).open(const SecondNote('s'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NoteEditorScreen), findsNWidgets(2));
    expect(find.byType(DashboardScreen), findsOneWidget);
    // Yandaki editörün kök kurulumu ayrı sayılır (aynı tür iki örnek).
    var side = 0;
    final counter = BuildCounter()..start();
    final base = debugOnRebuildDirtyWidget!;
    debugOnRebuildDirtyWidget = (e, builtOnce) {
      base(e, builtOnce);
      final w = e.widget;
      if (w is NoteEditorScreen && w.noteId == 's') side++;
    };
    addTearDown(counter.stop);
    await tester.tap(find.widgetWithText(TextField, 'yazı').first);
    await tester.pump(const Duration(milliseconds: 400));
    final before = Map.of(counter.counts);
    side = 0;
    await _type(tester, 'yazı');
    await tester.pump(const Duration(milliseconds: 2500));
    expect(repo.updateNoteCalls, greaterThan(0));
    int delta(String t) => (counter.counts[t] ?? 0) - (before[t] ?? 0);
    final typing = (
      side: side,
      dash: delta('DashboardScreen'),
      card: delta('NoteCard'),
    );
    // Klavye aç/kapa (S8 kalıbı): iki bölmenin gövde kurulumu.
    int body() => _bodyTypes.fold(0, (n, t) => n + counter.of(t));
    final kb0 = body();
    for (final insets in [
      [20.0, 120.0, 300.0],
      [120.0, 20.0, 0.0],
    ]) {
      for (final inset in insets) {
        tester.view.viewInsets = FakeViewPadding(bottom: inset);
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    final keyboard = body() - kb0;
    counter.stop();
    _expectBudget('S27', {
      'yandaki_kok_kurulum': typing.side,
      'dashboard_kurulum': typing.dash,
      'note_card': typing.card,
      'klavye_govde_kurulum': keyboard,
    });
    await endEditor(tester);
  });

  testWidgets('S13: ana ekran, 300 not, 3 ekran kaydır', (tester) async {
    final all = [
      for (var i = 0; i < 300; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i\nikinci satır',
        ),
    ];
    await _pumpHome(
      tester,
      size: const Size(400, 800),
      notes: Stream.value(all),
    );
    String firstCard() =>
        tester.widget<NoteCard>(find.byType(NoteCard).first).note.id;
    final top = firstCard();
    final c = await _count(() async {
      for (var i = 0; i < 3; i++) {
        await tester.dragFrom(const Offset(200, 650), const Offset(0, -500));
        await tester.pump(const Duration(milliseconds: 500));
      }
    });
    expect(firstCard(), isNot(top), reason: 'liste kaydı');
    _expectBudget('S13', {'note_card': c['NoteCard'] ?? 0});
    await endEditor(tester);
  });

  testWidgets('S14: yıldızla (⋮ levhasından)', (tester) async {
    final repo = CountingNotesRepository();
    await pumpEditor(tester, _text, repo: repo);
    final c = await _count(() async {
      await tester.tap(find.byKey(const ValueKey('editor-more')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('menu-quick-star')));
      await _settle(tester);
      await tester.pump(const Duration(seconds: 3));
    });
    expect(repo.lastSaved!.starred, isTrue);
    _expectBudget('S14', {'tuval_kurulum': c['NotePageCanvas'] ?? 0});
    await endEditor(tester);
  });

  // F59.3 → F62.1: kalem 1 nokta ilerleyince BOYANAN iş. Bitmiş katman
  // yalnız `committedRev` artarsa boyanır (o zaman onun çağrıları da sayılır);
  // etkin katman her harekette.
  test('S15: 2000 çizgi varken etkin çizgiye 1 nokta — çizim çağrısı', () {
    InkToolMemory.reset();
    final ink = InkController(initial: _ink(2000), onChanged: (_) {});
    addTearDown(ink.dispose);
    const size = Size(400, 600);
    ink.pointerDown(
      1,
      const Offset(200, 300),
      size,
      kind: PointerDeviceKind.mouse,
    );
    ink.pointerMove(1, const Offset(204, 304), size);
    final rev = ink.committedRev.value;
    ink.pointerMove(1, const Offset(208, 306), size);
    final canvas = TestRecordingCanvas();
    if (ink.committedRev.value != rev) {
      CommittedInkPainter(ink, 1).paint(canvas, size);
    }
    ActiveInkPainter(ink, 1, Colors.blue).paint(canvas, size);
    _expectBudget('S15', {'cizim_cagrisi': canvas.invocations.length});
    ink.pointerUp(kind: PointerDeviceKind.mouse);
  });

  // F59.4
  test('S16: 2000 çizgi varken 1 çizgi ekle + kaydet — belge / bayt', () async {
    final db = FakeFirebaseFirestore();
    final repo = NotesRepository(db, 'u');
    final note = _text.copyWith(pageInk: _ink(2000));
    final main = _noteDoc(db);
    // Belge yolu → içerik. Değişen belge = yazılan belge (`updatedAt`
    // istemci saatiyle her yazımda değişir).
    Future<Map<String, Map<String, dynamic>>> docs() async => {
      'not': (await main.get()).data()!,
      for (final d in (await main.collection(kHeavyCollection).get()).docs)
        '$kHeavyCollection/${d.id}': d.data(),
    };

    await repo.updateNote(note, clientTime: true);
    final before = await docs();
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.updateNote(
      note.copyWith(pageInk: [...note.pageInk, ..._ink(1)]),
      clientTime: true,
    );
    final after = await docs();
    final written = [
      for (final e in after.entries)
        if (e.value.toString() != before[e.key].toString()) e.key,
    ];
    expect(written, contains('not'));
    _expectBudget('S16', {
      'belge': written.length,
      'bayt': written.fold(0, (n, k) => n + estimateValueBytes(after[k])),
    });
  });

  // ── S18–S25 (HIZ_PLANI F82.1) ─────────────────────────────────────────

  // S18 + S19: telefonda karttan not aç (gerçek NoteOpenPage geçişi), sonra
  // geri. Geçişte ana ekran kartları yeniden kurulmamalı; geçiş kareleri
  // (ilk kare editörün kendisini kurar — o ayrı) hafif olmalı.
  testWidgets('S18/S19: ana ekran → not açma → geri (telefon)', (tester) async {
    final now = DateTime.now();
    final all = [
      for (var i = 0; i < 30; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i\nikinci satır',
          updatedAt: now,
        ),
    ];
    final repo = _LiveRepo(FakeFirebaseFirestore());
    for (final n in all) {
      await _noteCol(repo.db).doc(n.id).set(n.toMap());
    }
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(all),
      repo: repo,
      openPage: true,
    );
    expect(find.byType(NoteEditorScreen), findsNothing);
    final open = await _frames(tester, () async {
      // İlk sıra üst çubuğun altında kalabiliyor: ortadan bir kart.
      await tester.tap(find.byType(NoteCard).at(4));
    }, frames: 40);
    expect(find.byType(NoteEditorScreen), findsOneWidget);
    _expectBudget('S18', {
      'note_card': open.counts['NoteCard'] ?? 0,
      'dashboard_kurulum': open.counts['DashboardScreen'] ?? 0,
      'ilk_kare_kurulum': open.first,
      'gecis_karesi_kurulum': open.worstAfterFirst,
    });
    await tester.pump(const Duration(seconds: 1));
    final close = await _frames(tester, () async {
      await tester.binding.handlePopRoute();
    }, frames: 40);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(NoteEditorScreen), findsNothing);
    _expectBudget('S19', {
      'note_card': close.counts['NoteCard'] ?? 0,
      'dashboard_kurulum': close.counts['DashboardScreen'] ?? 0,
      'kare_kurulum': close.worst,
    });
    await endEditor(tester);
  });

  // S20: ⋮ levhası açılıp kapanırken editör gövdesi kurulmaz.
  testWidgets('S20: not menüsü (⋮) levhasını aç → kapat', (tester) async {
    await pumpEditor(tester, _list30);
    await _settleGrowth(tester);
    final c = await _count(() async {
      await tester.tap(find.byKey(const ValueKey('editor-more')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('menu-quick-star')), findsOneWidget);
      await tester.binding.handlePopRoute();
      await _settle(tester);
    });
    expect(find.byKey(const ValueKey('menu-quick-star')), findsNothing);
    _expectBudget('S20', {
      'govde_kurulum': _bodyTypes.fold(0, (n, t) => n + (c[t] ?? 0)),
    });
    await endEditor(tester);
  });

  // S21: arama kutusuna 5 harf — harf başına kurulan kart ≤ görünür kart.
  testWidgets('S21: arama kutusuna 5 harf (telefon, 60 not)', (tester) async {
    final all = [
      for (var i = 0; i < 60; i++)
        Note(id: 'x$i', type: NoteType.text, title: 'Not $i', body: 'gövde'),
    ];
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(all),
    );
    final visible = find.byType(NoteCard).evaluate().length;
    await tester.tap(find.byType(TextField).first);
    await tester.pump(const Duration(milliseconds: 400));
    var worst = 0;
    var dashboard = 0;
    for (final q in ['N', 'No', 'Not', 'Not ', 'Not 1']) {
      final c = await _count(() async {
        tester.testTextInput.enterText(q);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 400));
      });
      final cards = c['NoteCard'] ?? 0;
      if (cards > worst) worst = cards;
      dashboard += c['DashboardScreen'] ?? 0;
    }
    // "Not 1": Not 1, Not 10–19 → süzgeç gerçekten uygulandı.
    final ids = tester
        .widgetList<NoteCard>(find.byType(NoteCard))
        .map((c) => c.note.id);
    expect(ids, everyElement(startsWith('x1')), reason: 'arama süzdü');
    // ignore: avoid_print
    print('S21: görünür kart $visible');
    _expectBudget('S21', {
      'harf_basina_kart': worst,
      'dashboard_kurulum': dashboard,
    });
    await endEditor(tester);
  });

  // S22: takvim haftalık görünümde bir hafta ileri kaydır.
  testWidgets('S22: takvim hafta kaydırma (telefon)', (tester) async {
    await _pumpCalendar(tester, 'week');
    await tester.pumpAndSettle();
    final before = tester.widget<WeekPage>(find.byType(WeekPage)).weekStart;
    final swipe = await _frames(tester, () async {
      await tester.fling(find.byType(WeekPage), const Offset(-300, 0), 1500);
    }, frames: 40);
    await tester.pumpAndSettle();
    expect(
      tester.widget<WeekPage>(find.byType(WeekPage)).weekStart,
      before.add(const Duration(days: 7)),
      reason: 'bir hafta ileri',
    );
    _expectBudget('S22', {
      'hafta_sayfasi': swipe.counts['WeekPage'] ?? 0,
      'toplam_kurulum': swipe.total,
      'kare_kurulum': swipe.worst,
    });
  });

  // S23: ana ekranda yana çekişle süzgeç değiştir (Tümü → sonraki) ve geri.
  testWidgets('S23: klasör/süzgeç yana kaydırma (telefon)', (tester) async {
    final all = [
      for (var i = 0; i < 30; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          body: 'gövde $i',
          starred: i.isEven,
        ),
    ];
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(all),
      prefsValues: {'swipe_mode': 'filters'},
    );
    final visible = find.byType(NoteCard).evaluate().length;
    List<String> ids() => [
      for (final c in tester.widgetList<NoteCard>(find.byType(NoteCard)))
        c.note.id,
    ];
    final top = ids();
    final forward = await _frames(tester, () async {
      await tester.fling(
        find.byType(NoteCard).at(4),
        const Offset(-300, 0),
        1500,
      );
    }, frames: 40);
    await tester.pump(const Duration(seconds: 1));
    expect(ids(), isNot(top), reason: 'süzgeç değişti');
    final back = await _frames(tester, () async {
      await tester.fling(
        find.byType(NoteCard).at(4),
        const Offset(300, 0),
        1500,
      );
    }, frames: 40);
    await tester.pump(const Duration(seconds: 1));
    expect(ids(), top, reason: 'Tümü\'ne döndü');
    // ignore: avoid_print
    print('S23: görünür kart $visible');
    _expectBudget('S23', {
      'ileri_kart': forward.counts['NoteCard'] ?? 0,
      'geri_kart': back.counts['NoteCard'] ?? 0,
      'ileri_dashboard_kurulum': forward.counts['DashboardScreen'] ?? 0,
      'kare_kurulum': max(forward.worst, back.worst),
    });
    await endEditor(tester);
  });

  // S24: soğuk açılış — ilk karede ve kartlar görünene dek kurulan widget.
  testWidgets('S24: soğuk açılış (telefon, 30 not)', (tester) async {
    final all = [
      for (var i = 0; i < 30; i++)
        Note(id: 'x$i', type: NoteType.text, title: 'Not $i', body: 'gövde'),
    ];
    final counter = BuildCounter()..start();
    addTearDown(counter.stop);
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(all),
      settle: false,
    );
    final first = _sum(counter.counts);
    var frames = 0;
    while (find.byType(NoteCard).evaluate().isEmpty && frames < 60) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    final untilCards = _sum(counter.counts);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    final settled = _sum(counter.counts);
    counter.stop();
    expect(find.byType(NoteCard), findsWidgets);
    // ignore: avoid_print
    print('S24: kartlar $frames karede');
    _expectBudget('S24', {
      'ilk_kare_kurulum': first,
      'kartlara_dek_kurulum': untilCards,
      'iki_sn_kurulum': settled,
    });
    await endEditor(tester);
  });

  // S25: görsel ekli 50 not — kart küçük resmi kart boyu × dpr'den büyük
  // çözülmesin (`cacheWidth`/`memCacheWidth` unutulmasın).
  testWidgets('S25: görselli 50 not listesi — çözme boyu', (tester) async {
    const dpr = 2.625;
    Attachment image(int i) => Attachment(
      id: 'g$i',
      kind: AttachmentKind.image,
      fileName: 'g$i.jpg',
      mimeType: 'image/jpeg',
      width: 3000,
      height: 2000,
      // İki kaynak: Storage'a yüklenmiş, yalnız Drive küçük resmi.
      downloadUrl: i.isEven ? 'https://x.invalid/g$i.jpg' : '',
      thumbUrl: i.isOdd ? 'https://x.invalid/t$i.jpg' : '',
    );
    final all = [
      for (var i = 0; i < 50; i++)
        Note(
          id: 'x$i',
          type: NoteType.text,
          title: 'Not $i',
          attachments: [image(i)],
        ),
    ];
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(all),
      dpr: dpr,
    );
    final over = <String>{};
    final seen = <String>{};
    void inspect() {
      for (final e in find.byType(CachedNetworkImage).evaluate()) {
        final w = e.widget as CachedNetworkImage;
        final box = (e.renderObject as RenderBox?)?.size.width ?? 0;
        seen.add(w.imageUrl);
        // Kart boyu × dpr; küçük kartta 480 px tabanı (3x ekran) serbest.
        final limit = max((box * dpr).ceil(), 480);
        if (w.memCacheWidth == null || w.memCacheWidth! > limit) {
          over.add(w.imageUrl);
        }
      }
      for (final e in find.byType(Image).evaluate()) {
        final p = (e.widget as Image).image;
        if (p is NetworkImage || p is FileImage) {
          seen.add('$p');
          over.add('$p');
        }
      }
    }

    inspect();
    for (var i = 0; i < 6; i++) {
      await tester.dragFrom(const Offset(200, 650), const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 500));
      inspect();
    }
    tester.takeException();
    // ignore: avoid_print
    print('S25: incelenen ${seen.length}, sınırsız ${over.length}: $over');
    expect(seen, isNotEmpty, reason: 'kart küçük resmi kuruldu');
    _expectBudget('S25', {'sinirsiz_cozum': over.length});
    await endEditor(tester);
  });
  // ── S29–S36 (P62 plan_tasarim_A §7.3; tabanı PA0) ──────────────────────

  List<Note> notes30() => [
    for (var i = 0; i < 30; i++)
      Note(id: 'x$i', type: NoteType.text, title: 'Not $i', body: 'gövde'),
  ];

  // S29: ayar alanı açılışı — satırlar karelere yayılıyor (_StaggeredRows).
  testWidgets('S29: ayar alanı açılışı (telefon, ai)', (tester) async {
    final app = await _settingsApp(tester, const Size(412, 915), area: 'ai');
    var firstRows = -1;
    final open = await _frames(tester, () async {
      await tester.pumpWidget(app);
      // İlk karede kurulan satır sayısı (yayma: 2).
      final rows = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_StaggeredRows',
      );
      firstRows = tester
          .widget<Column>(
            find.descendant(of: rows, matching: find.byType(Column)).first,
          )
          .children
          .length;
    }, frames: 40);
    // ignore: avoid_print
    print('S29: ilk karede satır $firstRows');
    _expectBudget('S29', {
      'ilk_kare_kurulum': open.first,
      'kare_kurulum': open.worstAfterFirst,
      'toplam_kurulum': open.total,
    });
  });

  // S30: hesap levhası aç → geri: kartlar ve pano kurulmaz.
  testWidgets('S30: hesap levhası aç → kapat (telefon)', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(notes30()),
    );
    final open = await _frames(tester, () async {
      await tester.tap(find.byKey(const ValueKey('home-account-avatar')));
    });
    expect(find.byType(BottomSheet), findsOneWidget, reason: 'levha açık');
    final close = await _frames(tester, () async {
      await tester.binding.handlePopRoute();
    });
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BottomSheet), findsNothing, reason: 'levha kapandı');
    _expectBudget('S30', {
      'kart_kurulum':
          (open.counts['NoteCard'] ?? 0) + (close.counts['NoteCard'] ?? 0),
      'dashboard_kurulum':
          (open.counts['DashboardScreen'] ?? 0) +
          (close.counts['DashboardScreen'] ?? 0),
      'kare_kurulum': max(open.worst, close.worst),
    });
    await endEditor(tester);
  });

  // S31: bildirim şeridi (iskelet) — ileti, ipucu, boş şeritte klavye.
  testWidgets('S31: bildirim şeridi (telefon, iskelet)', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(notes30()),
      notices: true,
    );
    const message = AppNoticeData(text: 'Kaydedildi');
    final shown = await _frames(tester, () async {
      appNotice.show(message);
    });
    expect(find.text('Kaydedildi'), findsOneWidget);
    // Kendiliğinden kalkış (4 sn).
    final gone = await _frames(tester, () async {
      await tester.pump(message.duration);
    });
    expect(appNotice.current, isNull, reason: 'ileti kalktı');
    final tip = await _frames(tester, () async {
      appNotice.show(
        const AppNoticeData(text: 'İpucu', kind: AppNoticeKind.tip),
      );
    });
    expect(find.text('İpucu'), findsOneWidget);
    // Dokunuşla kalkış: iptal edilen dokunuş (alttaki karta dokunmasın).
    final touched = await _frames(tester, () async {
      final g = await tester.startGesture(const Offset(200, 450));
      await g.cancel();
    });
    expect(appNotice.current, isNull, reason: 'ipucu dokunuşla kalktı');
    final all = [shown, gone, tip, touched];
    // Şerit BOŞKEN klavye 0 → 300 → 0 (10 adım): adım başına şeritten
    // (_NoticeLane ve altı) kurulan widget, en kötü adım.
    var laneWorst = 0;
    var lane = 0;
    debugOnRebuildDirtyWidget = (e, _) {
      var inLane = e.widget.runtimeType.toString() == '_NoticeLane';
      if (!inLane) {
        e.visitAncestorElements((a) {
          inLane = a.widget.runtimeType.toString() == '_NoticeLane';
          return !inLane;
        });
      }
      if (inLane) lane++;
    };
    try {
      for (final b in <double>[60, 120, 180, 240, 300, 240, 180, 120, 60, 0]) {
        lane = 0;
        tester.view.viewInsets = FakeViewPadding(bottom: b);
        await tester.pump(const Duration(milliseconds: 16));
        laneWorst = max(laneWorst, lane);
      }
    } finally {
      debugOnRebuildDirtyWidget = null;
    }
    _expectBudget('S31', {
      'kart_kurulum': all.fold(0, (n, f) => n + (f.counts['NoteCard'] ?? 0)),
      'dashboard_kurulum': all.fold(
        0,
        (n, f) => n + (f.counts['DashboardScreen'] ?? 0),
      ),
      'kare_kurulum': all.map((f) => f.worst).reduce(max),
      'klavye_karesi_kurulum': laneWorst,
    });
    await endEditor(tester);
  });

  // S32: bekleyen ek şeridi belirip kalkarken ızgaranın boyu kaç karede
  // değişiyor (TEK ADIM hedefi, kasma listesi md. 6).
  testWidgets('S32: kalıcı şerit belirişi (telefon)', (tester) async {
    final pending = ValueNotifier(0);
    addTearDown(pending.dispose);
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(notes30()),
      overrides: [
        pendingUploadsProvider.overrideWith((ref) {
          void changed() => ref.invalidateSelf();
          pending.addListener(changed);
          ref.onDispose(() => pending.removeListener(changed));
          return (pending: pending.value, failed: 0, needsDrive: false);
        }),
      ],
    );
    final grid = find
        .ancestor(
          of: find.byType(NoteCard).first,
          matching: find.byType(Scrollable),
        )
        .first;
    var resized = 0;
    final c = await _count(() async {
      pending.value = 2;
      resized += await _resizedFrames(tester, grid);
      expect(
        find.byIcon(Icons.cloud_upload_outlined),
        findsOneWidget,
        reason: 'şerit göründü',
      );
      pending.value = 0;
      resized += await _resizedFrames(tester, grid);
    });
    _expectBudget('S32', {
      'izgara_boy_karesi': resized,
      'kart_kurulum': c['NoteCard'] ?? 0,
    });
    await endEditor(tester);
  });

  // S33: ana ekranda karttan eşik altı yana çekiş — süzgeç değişmez.
  testWidgets('S33: ana ekran yana çekiş, eşik altı (telefon)', (tester) async {
    await _pumpHome(
      tester,
      size: const Size(412, 915),
      notes: Stream.value(notes30()),
      prefsValues: {'swipe_mode': 'filters'},
    );
    List<String> ids() => [
      for (final c in tester.widgetList<NoteCard>(find.byType(NoteCard)))
        c.note.id,
    ];
    final top = ids();
    final counter = BuildCounter()..start();
    var worst = 0;
    var last = 0;
    void frame() {
      final now = _sum(counter.counts);
      worst = max(worst, now - last);
      last = now;
    }

    try {
      final g = await tester.startGesture(
        tester.getCenter(find.byType(NoteCard).at(4)),
      );
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(-10, 0));
        await tester.pump(const Duration(milliseconds: 16));
        frame();
      }
      await g.up();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        frame();
      }
    } finally {
      counter.stop();
    }
    await tester.pump(const Duration(seconds: 1));
    expect(ids(), top, reason: 'eşik altı: süzgeç değişmedi');
    _expectBudget('S33', {
      'kart_kurulum': counter.of('NoteCard'),
      'dashboard_kurulum': counter.of('DashboardScreen'),
      'kare_kurulum': worst,
    });
    await endEditor(tester);
  });

  // S35: takvim ajandasında mini ay aç → kapat; ajanda listesinin boyu
  // kaç karede değişiyor (TEK ADIM hedefi).
  testWidgets('S35: mini ay aç → kapat (telefon, ajanda)', (tester) async {
    await _pumpCalendar(tester, 'agenda');
    await tester.pumpAndSettle();
    // Ay kapalıyken son kaydırma görünümü ajanda listesi (_AgendaList);
    // elemanı tutulur (ay açılınca önüne başka kaydırma görünümleri girer).
    final listElement = find.byType(Scrollable).last.evaluate().single;
    final agenda = find.byElementPredicate((e) => e == listElement);
    final toggle = find.byKey(const ValueKey('calendar-month-toggle'));
    var resized = 0;
    final c = await _count(() async {
      await tester.tap(toggle);
      resized += await _resizedFrames(tester, agenda);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget, reason: 'açık');
      await tester.tap(toggle);
      resized += await _resizedFrames(tester, agenda);
      await tester.pumpAndSettle();
    });
    expect(
      find.byIcon(Icons.arrow_drop_down),
      findsOneWidget,
      reason: 'kapalı',
    );
    // ignore: avoid_print
    print('S35: toplam kurulum ${_sum(c)}');
    _expectBudget('S35', {'liste_boy_karesi': resized});
  });

  // S36: geniş ekranda ayar alanları arasında geçiş.
  testWidgets('S36: geniş ekran ayar alanı geçişi (1280×800)', (tester) async {
    await tester.pumpWidget(await _settingsApp(tester, const Size(1280, 800)));
    await tester.pump(const Duration(seconds: 1));
    // Kategori listesi 800 dp'ye sığmıyor: döşeme önce görünüre kaydırılır
    // (ölçüm dışında).
    Future<_FrameStats> select(String id) async {
      final tile = find.byKey(ValueKey('settings-cat-$id'));
      await tester.ensureVisible(tile);
      await tester.pump(const Duration(seconds: 1));
      final f = await _frames(tester, () => tester.tap(tile), frames: 40);
      expect(find.byKey(ValueKey('settings-area-$id')), findsOneWidget);
      return f;
    }

    final ai = await select('ai');
    final sound = await select('sound');
    // ignore: avoid_print
    print(
      'S36: ilk kare ${ai.first} / ${sound.first}, sonraki en ağır '
      '${ai.worstAfterFirst} / ${sound.worstAfterFirst}',
    );
    _expectBudget('S36', {
      'kare_kurulum': max(ai.worst, sound.worst),
      'toplam_kurulum': ai.total + sound.total,
    });
  });
}
