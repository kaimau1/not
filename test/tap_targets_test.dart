import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
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
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/editor_harness.dart';

/// **DOKUNMA HEDEFİ TARAMASI** (DENEYIM F80.4): ana ekran, not ekranı
/// (klavyeli/klavyesiz), not menüsü, takvim, ayarlar — dokunulabilir her
/// semantik düğüm en az 48×48 dp. `accessibility_test`'teki
/// `androidTapTargetGuideline` kalıbı, ama istisna listesiyle: bilinçli
/// küçük kalanlar aşağıda GEREKÇELİ. Listeye ekleme yapan, gerekçe yazar.
///
/// Ekranın kenarına değen (kaydırılan listenin yarım görünen öğesi)
/// düğümler ve metin alanları (dokunma alanı kutunun tamamı — semantik düğüm
/// yalnız yazı satırı) sayılmaz.
///
/// İSTİSNALAR (2026-11-12 taraması) — anahtar `sahne/etiketin son satırı`.
/// Hepsi ya kullanıcının bilinçli istediği sıkı yerleşim ya da başka paketin
/// dosyası (DENEYIM Ek D); düzeltme o pakette, burada yalnız sayılır.
/// YENİ bir küçük hedef bu listede yoksa test kırılır.
const _exempt = <String, String>{
  // Arama hapı (§4 Y1, `dashboard_widgets.dart`): "boştayken AI tuşu hep
  // görünür" + "arama çubuğu profil ve 3 noktayı da kapsasın" — dört
  // düğme tek hapın içinde; 48'e büyütmek hapı taşırır. P35 alanı.
  'ana ekran/Anlam': 'arama hapı sıkı (Y1)',
  'ana ekran/Hesap': 'arama hapı sıkı (Y1)',
  'ana ekran/Diğer': 'arama hapı sıkı (Y1)',
  'ana ekran/?': 'arama hapının büyüteci 41×48, hap dokunulur (Y1)',
  // Klasör şeridi çipleri 32 dp: şerit yüksekliği sabit (K-D3, Y2 "görünür
  // alana en çok klasör sığsın"); sabah bakılacak.
  'ana ekran/Tümü': 'klasör şeridi (Y2, K-D3)',
  'ana ekran/Gelen': 'klasör şeridi (Y2, K-D3)',
  'ana ekran/İş': 'klasör şeridi (Y2, K-D3)',
  // Not alt çubuğu 40 dp → 48: P36 (F75, Ek A satırı) — editör dosyası.
  'not ekranı/Biçim': 'alt çubuk P36',
  'not ekranı/Ekle': 'alt çubuk P36',
  'not ekranı/Notta ara': 'alt çubuk P36',
  'not ekranı/Paylaş': 'alt çubuk P36 (K-D6 kaleme dönecek)',
  'not ekranı/Seç': 'alt çubuk P36',
  'not ekranı/Yapay zekâ': 'alt çubuk P36',
  'not ekranı/Ses kaydı': 'alt çubuk P36 (Y9)',
  'not ekranı/Dikte': 'alt çubuk P36 (Y9)',
  // Editörün içi (P20 sonrası; ölçüm kapısı bulutta koşmaz):
  'not ekranı/Etiket · Alarm · Klasör': 'başlık "+" (Y7), editör',
  'not ekranı/Ara başlık': 'madde satırı içi, editör',
  'not ekranı/Ekmek': 'madde kutucuğu 40 dp (satır 44), editör',
  'not ekranı/Süt': 'madde kutucuğu 40 dp (satır 44), editör',
  'not ekranı/13 Nov 09:00': 'hatırlatıcı çipi, editör',
  'not ekranı/Sil': 'hatırlatıcı çipinin ✕, editör',
  'not ekranı/#ev': 'etiket hapı (Y5), editör',
  // Klavyeli hızlı satır (P25 ayarları, editör):
  'not ekranı/Kalemle yaz · basılı tut: kalem ayarları': 'hızlı satır',
  'not ekranı/Yazım düzelt: kapalı': 'hızlı satır',
  'not ekranı/Pakete al': 'hızlı satır',
  // Takvim ‹ › sıkı (kullanıcı isteği 2026-11-07, §4 Y13 + "ay başlığı
  // görünmüyordu", `calendar_screen.dart:504`).
  'takvim/Önceki': 'ay başlığı sığsın (Y13)',
  'takvim/Sonraki': 'ay başlığı sığsın (Y13)',
};

const _screen = Size(412, 915);
var _seen = 0;

List<String> _smallTargets(WidgetTester tester, String scene) {
  final root =
      tester.binding.renderViews.first.owner?.semanticsOwner?.rootSemanticsNode;
  final out = <String>[];
  _seen = 0;
  expect(root, isNotNull, reason: 'semantik ağacı yok');
  if (root == null) return out;
  void visit(SemanticsNode node, Matrix4 transform) {
    final t = transform.clone();
    if (node.transform != null) t.multiply(node.transform!);
    final data = node.getSemanticsData();
    if (data.hasAction(SemanticsAction.tap)) _seen++;
    if (!node.isInvisible &&
        !node.isMergedIntoParent &&
        !data.flagsCollection.isHidden &&
        !data.flagsCollection.isTextField &&
        (data.hasAction(SemanticsAction.tap) ||
            data.hasAction(SemanticsAction.longPress))) {
      final rect = MatrixUtils.transformRect(t, node.rect);
      // Fiziksel → mantıksal (dpr 1 kurulur; yine de böl).
      final dpr = tester.view.devicePixelRatio;
      final r = Rect.fromLTRB(
        rect.left / dpr,
        rect.top / dpr,
        rect.right / dpr,
        rect.bottom / dpr,
      );
      final atEdge =
          r.left <= 0.5 ||
          r.top <= 0.5 ||
          r.right >= _screen.width - 0.5 ||
          r.bottom >= _screen.height - 0.5;
      // Küçük yuvarlama payı (rehber de 48'i tam sayar).
      if (!atEdge && (r.width < 47.5 || r.height < 47.5)) {
        final label = [
          data.label,
          data.tooltip,
          data.value,
        ].firstWhere((s) => s.isNotEmpty, orElse: () => '?').split('\n').last;
        if (!_exempt.containsKey('$scene/$label')) {
          out.add(
            '"$label" ${r.width.toStringAsFixed(0)}×'
            '${r.height.toStringAsFixed(0)} @ ${r.topLeft}',
          );
        }
      }
    }
    node.visitChildren((child) {
      visit(child, t);
      return true;
    });
  }

  visit(root, Matrix4.identity());
  expect(_seen, greaterThan(5), reason: 'sahne kurulmadı');
  return out;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _notes = [
  Note(
    id: 'n1',
    type: NoteType.checklist,
    title: 'Alışveriş',
    pinned: true,
    tags: const ['ev'],
    reminderAt: DateTime(2026, 11, 13, 9),
    updatedAt: DateTime(2026, 11, 12, 9),
    items: const [
      NoteItem(id: 'a', text: 'Süt'),
      NoteItem(id: 'b', text: 'Ekmek', checked: true),
    ],
  ),
  Note(
    id: 'n2',
    type: NoteType.text,
    title: 'Toplantı',
    body: 'Gündem: bütçe',
    color: NoteColor.amber,
    folderId: 'f1',
    updatedAt: DateTime(2026, 11, 11, 9),
  ),
];

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('ana ekran', (tester) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue('ben'),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
        friendsRepositoryProvider.overrideWithValue(null),
        // Hatırlatıcısız: zamanı gelen şeridi gerçek saate zamanlayıcı kurar.
        notesStreamProvider.overrideWith(
          (ref) => Stream.value([
            for (final n in _notes) n.copyWith(clearReminderAt: true),
          ]),
        ),
        foldersStreamProvider.overrideWith(
          (ref) => Stream.value(const [
            NoteFolder(id: 'f1', name: 'İş', ownerId: 'ben'),
          ]),
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
    await _settle(tester);
    expect(_smallTargets(tester, 'ana ekran'), isEmpty);
    semantics.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 5));
  });

  for (final keyboard in [false, true]) {
    testWidgets('not ekranı${keyboard ? ' (klavyeli)' : ''}', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpEditor(tester, _notes.first);
      if (keyboard) {
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await _settle(tester);
      }
      expect(_smallTargets(tester, 'not ekranı'), isEmpty);
      semantics.dispose();
      await endEditor(tester);
    });
  }

  testWidgets('not menüsü', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpEditor(tester, _notes[1]);
    await tester.tap(find.byTooltip('Not menüsü'));
    await _settle(tester);
    expect(find.text('Sil'), findsWidgets);
    expect(_smallTargets(tester, 'not menüsü'), isEmpty);
    semantics.dispose();
    await endEditor(tester);
  });

  testWidgets('takvim', (tester) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarRepositoryProvider.overrideWithValue(
            CalendarRepository(FakeFirebaseFirestore(), 'u1'),
          ),
          eventsStreamProvider.overrideWith(
            (ref) => Stream.value(const <CalendarEvent>[]),
          ),
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
    await _settle(tester);
    expect(_smallTargets(tester, 'takvim'), isEmpty);
    semantics.dispose();
  });

  testWidgets('ayarlar', (tester) async {
    _phone(tester);
    final semantics = tester.ensureSemantics();
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUidProvider.overrideWithValue(null),
        isAnonymousProvider.overrideWithValue(true),
        notesRepositoryProvider.overrideWithValue(null),
        foldersRepositoryProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SettingsScreen(),
        ),
      ),
    );
    await _settle(tester);
    expect(_smallTargets(tester, 'ayarlar'), isEmpty);
    semantics.dispose();
  });
}
