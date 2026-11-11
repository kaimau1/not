import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
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
                builder: (c, s) => NoteEditorScreen(
                  key: ValueKey(s.pathParameters['id']),
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
      notesRepositoryProvider.overrideWithValue(repo),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      notesStreamProvider.overrideWith((ref) => notes),
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
  await tester.pump(const Duration(seconds: 1));
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
    final c = await _count(() async {
      await tester.tap(find.byTooltip('Biçim'));
      await _settle(tester);
      expect(find.byType(FormatBar), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('format-close')));
      await _settle(tester);
    });
    expect(find.byTooltip('Biçim'), findsOneWidget, reason: 'panel kapandı');
    _expectBudget('S9', {'tuval_kurulum': c['NotePageCanvas'] ?? 0});
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
    final all = [
      _text,
      for (var i = 0; i < 12; i++)
        Note(id: 'x$i', type: NoteType.text, title: 'Not $i', body: 'gövde $i'),
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
    final c = await _count(() async {
      await _type(tester, 'yazı');
      await tester.pump(const Duration(seconds: 4));
    });
    expect(repo.updateNoteCalls, greaterThan(0));
    _expectBudget('S12', {
      'dashboard_kurulum': c['DashboardScreen'] ?? 0,
      'note_card': c['NoteCard'] ?? 0,
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
}
