import 'package:notlar/features/notes/presentation/notes_providers.dart'
    show sharedFolderNotesProvider;
// EKRAN TURU (TUTARLILIK_PLANI F36.1): gerçek ana ekran ve not ekranı,
// Firebase'siz sahte verilerle, telefon / tablet / masaüstü boyutlarında
// çizilir ve PNG olarak yazılır. CI'da KOŞMAZ (test/ dışında); elle:
//
//   flutter test tool/tour/screen_tour_test.dart
//   (çıktı: build/tour/*.png — TOUR_OUT ile değiştirilebilir)
//   TOUR_ONLY=ana,n1  süz · TOUR_DARK=1  koyu · TOUR_WEB=1  dar web
//   TOUR_COLUMNS=3  ana ekran sütun sayısı
//   TOUR_SIZES=telefon-yatay,matepad-yatay  yalnız bu boyutlar
//   TOUR_KEYBOARD=300  klavyeli hâl (viewInsets.bottom dp; ada `-klavye`)
//   TOUR_COMPARE=<eski klasör>  önce/sonra: her PNG için değişen piksel yüzdesi
//   basılır (`TOUR_FARK ad %x`), özet `<çıktı>/_fark.txt`.
//
// Ekli sahneler (F45.1) görseli gerçek PNG ile çizer. PDF ve videoda test
// ortamında pdfium/oynatıcı yok: kabuk (çubuk, anahtar, menü) gerçek, sayfa
// yerinde hata/yer tutucu görünür.
//
// Canlı sitede misafir hesap açmadan web/tablet düzenini görmenin yolu.
// Gerçek cihazın yerine geçmez: yazı tipleri ve simgeler gerçek, gölgeler
// yazılım çiziminde; klavye, sistem çubukları, kamera yok.
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:notlar/app/app.dart';
import 'package:notlar/app/app_commands.dart' show homeBarOnNarrow;
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/ai/presentation/ai_hub_screen.dart';
import 'package:notlar/features/folders/presentation/folders_screen.dart';
import 'package:notlar/features/inbox/data/inbox_repository.dart';
import 'package:notlar/features/inbox/presentation/shared_hub_screen.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/archive_screen.dart';
import 'package:notlar/features/notes/presentation/trash_screen.dart';
import 'package:notlar/features/settings/presentation/settings_screen.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/dashboard_screen.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoAuth implements AuthRepository {
  @override
  Stream<Never> authStateChanges() => const Stream.empty();

  @override
  Stream<Never> userChanges() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final _now = DateTime(2026, 11, 4, 15, 17);

List<NoteItem> _items(List<String> open, List<String> done) => [
  for (final (i, t) in open.indexed) NoteItem(id: 'o$i', text: t),
  for (final (i, t) in done.indexed)
    NoteItem(id: 'd$i', text: t, checked: true),
];

/// Kullanıcının ekran görüntüsündeki notlara benzeyen örnek küme.
final _notes = <Note>[
  Note(
    id: 'n1',
    type: NoteType.checklist,
    title: 'Not uygulaması geliştirme hataları',
    customColor: 0xFF1A0B1F,
    fontFamily: 'Patrick Hand',
    pinned: true,
    tags: const ['yazilim'],
    updatedAt: _now,
    items: _items(const [], const [
      'webte ayarlara gidemiyorum 3 noktadan',
      'balonlu ve sabit arasında görsel farklılık var düzenle',
      'ana sayfaya dön butonu olmalı webte ve tablette her zaman görünen',
      'ek senkronu olayını baştan yaz suanki durum silinsin',
      'gmail bağlantısı mailleri görme ve kaydedip içerikten not alabilme',
      'telefondaki drive da yedeklenmeiş ekler webe gelmiyor',
      'ekleri paylaş seçeneği ek menüsünde ve gömülmüş ek menüsünde olsun',
    ]),
  ),
  Note(
    id: 'n2',
    type: NoteType.checklist,
    title: 'dosya okuyucu',
    pinned: true,
    tags: const ['yazilim'],
    updatedAt: _now.subtract(const Duration(hours: 1)),
    items: _items(
      const ['kitaplık modunda açılan şeylerin'],
      const [
        'önemli dosyalara kopyalanmış her türlü dosyanın üzerinde yıldız',
        'videolarda sağa sola çevir butonu oynatma panelinde',
        'videolar kapatınca arka planda oynamasın',
        'slayt ve Excel iyileştirmeleri',
      ],
    ),
  ),
  Note(
    id: 'n3',
    type: NoteType.checklist,
    title: 'Bütçem',
    pinned: true,
    color: NoteColor.sage,
    updatedAt: _now.subtract(const Duration(days: 1)),
    items: _items(
      const ['hisselerde alım tarihi maliyet'],
      const ['varlıklarda geriye basınca', 'totalde tabloya yatırımlar'],
    ),
  ),
  Note(
    id: 'n4',
    type: NoteType.text,
    title: 'Toplantı notları',
    body:
        'Gündem: bütçe, yol haritası ve **yeni tema**.\n'
        'Karar: perşembe tekrar bakılacak.',
    color: NoteColor.amber,
    reminderAt: _now.add(const Duration(days: 1)),
    updatedAt: _now.subtract(const Duration(days: 2)),
  ),
  Note(
    id: 'n5',
    type: NoteType.text,
    title: 'Klinik asistan',
    body: 'gelince yapılacaklar\nhastaların eski boy kilo bilgileri',
    folderId: 'f2',
    updatedAt: _now.subtract(const Duration(days: 3)),
  ),
  Note(
    id: 'n6',
    type: NoteType.text,
    body: 'Başlıksız kısa not — market: süt, ekmek, yumurta',
    color: NoteColor.blue,
    updatedAt: _now.subtract(const Duration(days: 4)),
  ),
  Note(
    id: 'n7',
    type: NoteType.text,
    title: 'Arşivdeki not',
    body: 'Geçen yılın planı',
    archivedAt: _now.subtract(const Duration(days: 30)),
    updatedAt: _now.subtract(const Duration(days: 30)),
  ),
];

final _trash = [
  Note(
    id: 't1',
    type: NoteType.text,
    title: 'Silinen not',
    body: 'Çöp kutusundaki örnek',
    deletedAt: _now.subtract(const Duration(days: 2)),
    updatedAt: _now.subtract(const Duration(days: 2)),
  ),
];

const _inbox = [
  InboxNote(
    id: 'g1',
    fromUid: 'ayse',
    fromName: 'Ayşe',
    fromEmail: 'ayse@example.com',
    title: 'Toplantı özeti',
    body: 'Perşembeye kadar bak.',
    items: [],
    type: NoteType.text,
    tags: [],
    color: NoteColor.none,
  ),
];

// Sahte ek dosyaları (F45.1): dört görünüm × üç tür, `_attachmentNotes`.
late final String _pngPath;
late final String _pdfPath;
late final String _videoPath;

Future<void> _writeFakeFiles() async {
  final dir = Directory.systemTemp.createTempSync('tour_ek');
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 800, 500),
    Paint()
      ..shader = ui.Gradient.linear(Offset.zero, const Offset(800, 500), const [
        Color(0xFF4F7A6B),
        Color(0xFFE9C46A),
      ]),
  );
  final image = await recorder.endRecording().toImage(800, 500);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  _pngPath = (File(
    '${dir.path}/ornek.png',
  )..writeAsBytesSync(png!.buffer.asUint8List())).path;
  _pdfPath = (File(
    '${dir.path}/ornek.pdf',
  )..writeAsStringSync('%PDF-1.4\n%%EOF\n')).path;
  _videoPath = (File(
    '${dir.path}/ornek.mp4',
  )..writeAsBytesSync([0, 0, 0])).path;
}

Attachment _att(AttachmentKind kind, String view) {
  final (name, mime, path) = switch (kind) {
    AttachmentKind.pdf => ('rapor.pdf', 'application/pdf', _pdfPath),
    AttachmentKind.video => ('klip.mp4', 'video/mp4', _videoPath),
    _ => ('fotograf.png', 'image/png', _pngPath),
  };
  return Attachment(
    id: 'a-${kind.name}-$view',
    kind: kind,
    fileName: name,
    mimeType: mime,
    localPath: path,
    width: 800,
    height: 500,
    pinHeight: view == 'sabit' ? 240 : 0,
    onPage: view == 'yuzen' || view == 'balonlu',
    asFile: view == 'ek',
    x: view == 'yuzen' ? 0.2 : null,
    pageY: view == 'yuzen' ? 90 : null,
    displayWidth: view == 'yuzen' ? 0.6 : null,
    caption: kind == AttachmentKind.image ? 'Örnek açıklama' : '',
  );
}

/// Dört görünüm: sabit, yüzen, ek (şerit), balonlu (yalnız PDF: balonlu görsel
/// önce PDF'e çevrilir; video balonlu olamaz). Üst düzey `final` tembel:
/// dosya yolları `setUpAll`dan sonra okunur.
final _attachmentNotes = <Note>[
  for (final kind in const [
    AttachmentKind.image,
    AttachmentKind.pdf,
    AttachmentKind.video,
  ])
    for (final view in const ['sabit', 'yuzen', 'ek'])
      Note(
        id: 'e-${kind.name}-$view',
        type: NoteType.text,
        title: '${kind.name} · $view',
        body: 'Ekin yanında yazılan not metni.\nİkinci satır.',
        attachments: [_att(kind, view)],
        updatedAt: _now,
      ),
  Note(
    id: 'e-pdf-balonlu',
    type: NoteType.pdf,
    title: 'pdf · balonlu',
    attachments: [_att(AttachmentKind.pdf, 'balonlu')],
    updatedAt: _now,
  ),
];

const _folders = [
  NoteFolder(id: 'f1', name: 'Dualar', ownerId: 'u'),
  NoteFolder(id: 'f2', name: 'Genel', ownerId: 'u'),
  NoteFolder(id: 'f3', name: 'İş', ownerId: 'u'),
];

Future<void> _loadFonts() async {
  // Simgeler: SDK'nın Material Icons yazı tipi (testte yoksa kutu çizilir).
  final sdk = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final icons = File(
    '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
    await loader.load();
  }
  // Varsayılan sistem yazısı (Roboto) — tema dışı metinler için.
  for (final w in ['Regular', 'Medium', 'Bold']) {
    final f = File('$sdk/bin/cache/artifacts/material_fonts/Roboto-$w.ttf');
    if (!f.existsSync()) continue;
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    await loader.load();
  }
}

class _Size {
  const _Size(this.name, this.width, this.height);
  final String name;
  final double width;
  final double height;
}

const _sizes = [
  _Size('telefon', 412, 915),
  _Size('tablet-dikey', 800, 1280),
  _Size('tablet-yatay', 1280, 800),
  _Size('masaustu', 1440, 900),
  // Gerçek cihazlar (F67.2, Ek C): MatePad 11 ve telefonlar; yatay telefon
  // F66.7 (bölünme yok).
  _Size('matepad-yatay', 1024, 640),
  _Size('matepad-dikey', 640, 1024),
  _Size('telefon-kucuk', 360, 640),
  _Size('telefon-uzun', 393, 851),
  _Size('telefon-yatay', 851, 393),
];

Future<void> _shot(WidgetTester tester, GlobalKey key, String name) async {
  final out = Platform.environment['TOUR_OUT'] ?? 'build/tour';
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$out/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
    await _compare(name, file, out);
  });
}

/// TOUR_COMPARE: eski turla piksel farkı. Küçük kenar yumuşatma oynamaları
/// (kanal farkı ≤ 8) sayılmaz.
Future<void> _compare(String name, File current, String out) async {
  final dir = Platform.environment['TOUR_COMPARE'];
  if (dir == null || dir.isEmpty) return;
  final old = File('$dir/$name.png');
  String line;
  if (!old.existsSync()) {
    line = 'yeni';
  } else {
    Future<(ui.Image, ByteData)> decode(File f) async {
      final codec = await ui.instantiateImageCodec(f.readAsBytesSync());
      final image = (await codec.getNextFrame()).image;
      return (image, (await image.toByteData())!);
    }

    final (a, ab) = await decode(old);
    final (b, bb) = await decode(current);
    if (a.width != b.width || a.height != b.height) {
      line = 'boyut değişti';
    } else {
      var changed = 0;
      for (var i = 0; i < ab.lengthInBytes; i += 4) {
        for (var c = 0; c < 3; c++) {
          if ((ab.getUint8(i + c) - bb.getUint8(i + c)).abs() > 8) {
            changed++;
            break;
          }
        }
      }
      line = '%${(changed * 400 / ab.lengthInBytes).toStringAsFixed(2)}';
    }
  }
  // ignore: avoid_print
  print('TOUR_FARK $name $line');
  File('$out/_fark.txt')
      .writeAsStringSync('$name $line\n', mode: FileMode.append);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  // Ek görseli gerçek dosyadan: okuma + çözme gerçek zamanda ilerler.
  for (var i = 0; i < 6; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump(const Duration(milliseconds: 150));
  }
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _pumpApp(
  WidgetTester tester, {
  required _Size size,
  required String location,
  required GlobalKey key,
  Brightness brightness = Brightness.light,
}) async {
  // Araç bir TEST dosyası (flutter test ile koşar) ama test/ dışında.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({
    // Bir kez çıkan ipuçları turu örtmesin (bkz. TipOnce).
    TipOnce.prefsKey: const [
      TipOnce.listGestures,
      TipOnce.pdfBubble,
      TipOnce.mediaPin,
      TipOnce.pdfReadNote,
      TipOnce.gridSwipe,
      TipOnce.stylusCanvas,
      TipOnce.semanticSearch,
      TipOnce.homeMicHold,
    ],
    // TOUR_COLUMNS=3|4: dar sütunlu ana ekran (kart sıkışması).
    'grid_columns': ?int.tryParse(Platform.environment['TOUR_COLUMNS'] ?? ''),
  });
  final sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(size.width, size.height);
  tester.view.devicePixelRatio = 1;
  // TOUR_KEYBOARD=300: klavyeli hâl (viewInsets.bottom, dp).
  final keyboard = double.tryParse(
    Platform.environment['TOUR_KEYBOARD'] ?? '',
  );
  if (keyboard != null) {
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  }
  addTearDown(tester.view.reset);
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
          for (final (path, screen) in const <(String, Widget)>[
            ('/settings', SettingsScreen()),
            ('/folders', FoldersScreen()),
            ('/ai', AiHubScreen()),
            ('/archive', ArchiveScreen()),
            ('/trash', TrashScreen()),
            ('/inbox', SharedHubScreen()),
          ])
            GoRoute(path: path, builder: (c, s) => screen),
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
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      notesStreamProvider.overrideWith(
        (ref) => Stream.value([..._notes, ..._attachmentNotes]),
      ),
      trashStreamProvider.overrideWith((ref) => Stream.value(_trash)),
      inboxNotesProvider.overrideWith((ref) => Stream.value(_inbox)),
      foldersStreamProvider.overrideWith((ref) => Stream.value(_folders)),
      for (final n in [..._notes, ..._attachmentNotes])
        noteStreamProvider(n.id).overrideWith((ref) => Stream.value(n)),
      // Paylaşılan klasör (F43.2): salt okunur şeritle çizilir.
      sharedFolderRefsProvider.overrideWith(
        (ref) => Stream.value(const [
          SharedFolderRef(
            folderId: 'sf1',
            ownerId: 'ayse',
            name: 'Ortak işler',
            icon: NoteFolder.defaultIcon,
            role: FolderRole.read,
          ),
        ]),
      ),
      sharedFolderNotesProvider.overrideWith(
        (ref, key) => Stream.value(_notes.take(3).toList()),
      ),
      folderUnreadProvider.overrideWith((ref, key) => 0),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.of(ThemeFamily.sage, Brightness.light),
          darkTheme: AppTheme.of(ThemeFamily.sage, Brightness.dark),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          locale: const Locale('tr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) {
            // Uygulamadaki gibi: tarihler etkin dilde (bkz. app.dart).
            Intl.defaultLocale = Localizations.localeOf(context)
                .toLanguageTag();
            return fixedTypography(context, child ?? const SizedBox(), 1);
          },
        ),
      ),
    ),
  );
  await _settle(tester);
}

Future<void> _end(WidgetTester tester) async {
  // pdfrx'in kendi hata kutusu (testte pdfium yok): turu düşürmesin.
  tester.takeException();
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
    await _writeFakeFiles();
    // pdfrx açılışta önbellek klasörü ister (testte eklenti yok).
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => Directory.systemTemp.path,
        );
  });

  // Dar web (K5): telefon boyu + üst çubukta ev (TOUR_WEB=1).
  homeBarOnNarrow = Platform.environment['TOUR_WEB'] == '1';
  // Hangi ekranlar çekilsin: TOUR_ONLY=ana,n1 gibi süzülebilir.
  final only = (Platform.environment['TOUR_ONLY'] ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .toSet();
  bool wanted(String id) => only.isEmpty || only.contains(id);

  final dark = Platform.environment['TOUR_DARK'] == '1';
  // Sahne: (kimlik, adres, dokunulacak şey — null = yalnız ekran).
  final scenes = <(String, String, Finder Function()?)>[
    ('ana', '/', null),
    ('n1', '/note/n1', null),
    ('n2', '/note/n2', null),
    ('n4', '/note/n4', null),
    ('n1-menu', '/note/n1', () => find.byTooltip('Not menüsü')),
    ('n4-menu', '/note/n4', () => find.byTooltip('Not menüsü')),
    (
      'n4-ekle',
      '/note/n4',
      () => find.byKey(const ValueKey('editor-add-button')),
    ),
    ('n4-ai', '/note/n4', () => find.byTooltip('Yapay zekâ').last),
    ('n4-bicim', '/note/n4', () => find.byTooltip('Biçim').first),
    ('ana-menu', '/', () => find.byTooltip('Diğer').first),
    ('ana-kart-menu', '/', () => find.byIcon(Icons.more_vert).at(1)),
    ('ana-hizli', '/', () => find.byTooltip('Yeni not — tip seç')),
    ('paylasilan', '/', () => find.byKey(const ValueKey('shared-chip-sf1'))),
    // Dar telefonda (360) Paylaş üst çubukta değil, ⋮ menüsünde: `.first`
    // boş bulucuda atar, sahne "dokunulacak öğe yok" diye geçilsin (F66.4).
    ('n4-paylas', '/note/n4', () {
      final f = find.byTooltip('Paylaş');
      return f.evaluate().isEmpty ? f : f.first;
    }),
    ('ayarlar', '/settings', null),
    (
      'ayarlar-gorunum',
      '/settings',
      () => find.byKey(const ValueKey('settings-cat-appearance')),
    ),
    ('klasorler', '/folders', null),
    ('yapay-zeka', '/ai', null),
    ('arsiv', '/archive', null),
    ('cop', '/trash', null),
    ('gelen', '/inbox', null),
    for (final kind in const ['image', 'pdf', 'video'])
      for (final view in const ['sabit', 'yuzen', 'ek'])
        ('e-$kind-$view', '/note/e-$kind-$view', null),
    ('e-pdf-balonlu', '/note/e-pdf-balonlu', null),
  ];
  // TOUR_SIZES=telefon-yatay,matepad-yatay: yalnız bu boyutlar.
  final sizesWanted = (Platform.environment['TOUR_SIZES'] ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .toSet();
  final kb = Platform.environment['TOUR_KEYBOARD'];
  for (final size in _sizes) {
    if (sizesWanted.isNotEmpty && !sizesWanted.contains(size.name)) continue;
    for (final (id, location, tap) in scenes) {
      if (!wanted(id)) continue;
      testWidgets('${size.name} · $id', (tester) async {
        final key = GlobalKey();
        await _pumpApp(
          tester,
          size: size,
          location: location,
          key: key,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        if (tap != null) {
          final target = tap();
          if (target.evaluate().isEmpty) {
            // ignore: avoid_print
            print('TOUR: $id için dokunulacak öğe yok');
            await _end(tester);
            return;
          }
          await tester.tap(target, warnIfMissed: false);
          await _settle(tester);
        }
        await _shot(
          tester,
          key,
          '${size.name}-$id${dark ? '-koyu' : ''}${kb != null ? '-klavye' : ''}',
        );
        await _end(tester);
      });
    }
  }
}
