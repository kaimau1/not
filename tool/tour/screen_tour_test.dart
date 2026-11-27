import 'package:notlar/core/widgets/app_notice.dart';
import 'package:notlar/app/second_note.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart'
    show searchQueryProvider, selectedFolderProvider, sharedFolderNotesProvider;
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:notlar/features/notes/data/upload_queue.dart'
    show pendingUploadsProvider;
// EKRAN TURU (TUTARLILIK_PLANI F36.1): gerçek ana ekran ve not ekranı,
// Firebase'siz sahte verilerle, telefon / tablet / masaüstü boyutlarında
// çizilir ve PNG olarak yazılır. CI'da KOŞMAZ (test/ dışında); elle:
//
//   flutter test tool/tour/screen_tour_test.dart
//   (çıktı: build/tour/*.png — TOUR_OUT ile değiştirilebilir)
//   TOUR_ONLY=ana,n1  süz · TOUR_DARK=1  koyu · TOUR_WEB=1  dar web
//   TOUR_COLUMNS=3  ana ekran sütun sayısı
//   TOUR_SIZES=telefon-yatay,matepad-yatay  yalnız bu boyutlar
//   TOUR_EMPTY=1  boş hâller (F79.5): ana, klasör, arşiv, çöp, Gelen, arama
//   TOUR_OFFLINE=1  çevrimdışı hâller (F79.6): bekleyen yazım/ek, AI, hata
//   TOUR_KEYBOARD=300  klavyeli hâl (viewInsets.bottom dp; ada `-klavye`)
//   TOUR_FONT=1.3  büyük yazı (F80.2): uygulama yazı ölçeği; ada `-yazi130`
//   TOUR_BG=aurora_bloom  ana ekran zemin görseli (hazır görsel kimliği)
//   TOUR_BARS=1  sistem çubukları: durum 24 dp + gezinme 48 dp (kenardan kenara)
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

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:notlar/features/notes/presentation/voice_capture_sheet.dart';
import 'package:notlar/features/notes/data/device_speech.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/editor/drawing_screen.dart';
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
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/features/settings/presentation/customize_hub.dart';
import 'package:notlar/features/settings/presentation/personalize_screen.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/features/auth/data/auth_repository.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/calendar/data/calendar_repository.dart';
import 'package:notlar/features/calendar/domain/calendar_event.dart';
import 'package:notlar/features/calendar/domain/task_item.dart';
import 'package:notlar/features/calendar/presentation/calendar_screen.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
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
import 'package:notlar/features/notes/presentation/note_template_sheet.dart';
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
  // P63 PBT: madde altı çizgileri — beş türden birer çizgi (biri renkli,
  // biri kalın). `cizgi-*` sahneleri bunu açar.
  Note(
    id: 'n8',
    type: NoteType.checklist,
    title: 'Hafta planı',
    updatedAt: _now.subtract(const Duration(days: 5)),
    items: const [
      NoteItem(id: 'c0', text: 'Pazartesi — rapor', divider: 'solid'),
      NoteItem(id: 'c1', text: 'Salı — toplantı', divider: 'dashed'),
      NoteItem(id: 'c2', text: 'Çarşamba — spor', divider: 'dotted|w:2'),
      NoteItem(id: 'c3', text: 'Perşembe — market', divider: 'double'),
      NoteItem(id: 'c4', text: 'Cuma — sinema', divider: 'wavy|c:FFE0A030'),
      NoteItem(id: 'c5', text: 'Hafta sonu — dinlen'),
    ],
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

/// Takvim sahneleri (P62 PA0): `_now`ın haftasında ve sonrasında günde bir
/// etkinlik (S22 düzeneğiyle aynı biçim).
final _events = [
  for (var d = 0; d < 21; d++)
    CalendarEvent(
      id: 'e$d',
      title: 'Etkinlik $d',
      start: DateTime(2026, 11, 2 + d, 10),
      end: DateTime(2026, 11, 2 + d, 11),
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

/// TOUR_EMPTY=1: not akışı, çöp ve Gelen boş (F79.5). `arama-bos` notlarla
/// çizilir (eşleşmeyen arama).
final _tourEmpty = Platform.environment['TOUR_EMPTY'] == '1';

/// TOUR_OFFLINE=1: bağlantı yok (F79.6) — not yazımları ve ekler sunucuyu
/// bekliyor, uzaktan okunan listeler `unavailable` hatası veriyor.
final _tourOffline = Platform.environment['TOUR_OFFLINE'] == '1';

/// TOUR_FONT=1.3: büyük yazı turu (F80.2) — Ayarlar'daki yazı ölçeği gibi
/// bütün arayüze uygulanır.
final _tourFont = double.tryParse(Platform.environment['TOUR_FONT'] ?? '');

/// Firestore'un çevrimdışı hatası (`friendlyError` → "bağlantı yok").
final _offlineError = FirebaseException(
  plugin: 'cloud_firestore',
  code: 'unavailable',
);

Future<void> _pumpApp(
  WidgetTester tester, {
  required _Size size,
  required String location,
  required GlobalKey key,
  String scene = '',
  Brightness brightness = Brightness.light,
}) async {
  final emptyData = _tourEmpty && scene != 'arama-bos';
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
    // TOUR_BG=<hazır görsel>: ana ekran zemini (tam ekran zemin, 2026-11-25).
    'dashboard_bg_preset': ?Platform.environment['TOUR_BG'],
    // Takvim sahneleri ajanda görünümünde, sıkıştırma ipucu gösterilmiş.
    if (scene.startsWith('takvim')) ...{
      'calendar_view': switch (scene) {
        'takvim-hafta' => 'week',
        'takvim-ay' => 'month',
        _ => 'agenda',
      },
      'calendar_pinch_hint_v1': true,
    },
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
  // TOUR_BARS=1: telefonun sistem çubukları (durum + üç tuşlu gezinme).
  if (Platform.environment['TOUR_BARS'] == '1') {
    const bars = FakeViewPadding(top: 24, bottom: 48);
    tester.view.padding = bars;
    tester.view.viewPadding = bars;
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
          GoRoute(
            path: '/settings',
            builder: (c, s) =>
                SettingsScreen(initialArea: s.uri.queryParameters['area']),
          ),
          GoRoute(
            path: '/calendar',
            builder: (c, s) => CalendarScreen(now: _now),
          ),
          for (final (path, screen) in const <(String, Widget)>[
            ('/folders', FoldersScreen()),
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
        (ref) => Stream.value(
          emptyData ? const <Note>[] : [..._notes, ..._attachmentNotes],
        ),
      ),
      trashStreamProvider.overrideWith(
        (ref) => _tourOffline
            ? Stream.error(_offlineError)
            : Stream.value(emptyData ? const <Note>[] : _trash),
      ),
      inboxNotesProvider.overrideWith(
        (ref) => _tourOffline
            ? Stream.error(_offlineError)
            : Stream.value(emptyData ? const <InboxNote>[] : _inbox),
      ),
      if (_tourOffline) ...[
        // Her not "sunucuya yazılmayı bekliyor" (editördeki bulut simgesi).
        pendingWritesProvider.overrideWith((ref, id) => Stream.value(true)),
        pendingUploadsProvider.overrideWithValue(
          (pending: 3, failed: 0, needsDrive: false),
        ),
      ],
      foldersStreamProvider.overrideWith((ref) => Stream.value(_folders)),
      for (final n in [..._notes, ..._attachmentNotes])
        noteStreamProvider(n.id).overrideWith((ref) => Stream.value(n)),
      // Paylaşılan klasör (F43.2): salt okunur şeritle çizilir.
      sharedFolderRefsProvider.overrideWith(
        (ref) => Stream.value(emptyData ? const <SharedFolderRef>[] : const [
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
        (ref, key) => Stream.value(
          emptyData ? const <Note>[] : _notes.take(3).toList(),
        ),
      ),
      folderUnreadProvider.overrideWith((ref, key) => 0),
      // Takvim (S22 düzeneği); öbür sahnelerin ana ekran şeridi değişmesin.
      if (scene.startsWith('takvim')) ...[
        calendarRepositoryProvider.overrideWithValue(
          CalendarRepository(FakeFirebaseFirestore(), 'u'),
        ),
        eventsStreamProvider.overrideWith((ref) => Stream.value(_events)),
        tasksStreamProvider.overrideWith(
          (ref) => Stream.value(const <TaskItem>[]),
        ),
        calendarReminderNotesProvider.overrideWithValue(const []),
      ],
    ],
  );
  addTearDown(container.dispose);
  // Boş hâl sahneleri: seçili klasör / eşleşmeyen arama pompadan ÖNCE
  // (arama kutusu açılışta sorguyu sağlayıcıdan okur).
  if (scene == 'klasor-bos') {
    container.read(selectedFolderProvider.notifier).set('f1');
  }
  // K32: iki not yan yana (yalnız yatay tablette çizilir; telefonda tek not).
  if (scene == 'iki-not') {
    container.read(secondNoteProvider.notifier).open(const SecondNote('n2'));
  }
  if (scene == 'arama-bos') {
    container.read(searchQueryProvider.notifier).set('zqxw');
  }
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
            return fixedTypography(
              context,
              // Uygulamadaki gibi bildirim şeridi (P62 PA5).
              // ve düzen modu şeridi (P63 G5).
              CustomizeModeHost(
                child: AppNoticeHost(child: child ?? const SizedBox()),
              ),
              _tourFont ?? 1,
            );
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

/// Şablon levhasını açık sayfanın üstünde açar (uygulamadaki "+" → Şablonlar
/// yolunun levhası; sonucu beklenmez).
Future<void> _openTemplates(WidgetTester tester) async {
  // Panonun öğesi ConsumerStatefulElement = WidgetRef (uygulamadaki çağrı
  // `pickTemplate(context, ref)` ile aynı).
  final element = tester.element(find.byType(DashboardScreen).first);
  unawaited(pickTemplate(element, element as WidgetRef));
  await _settle(tester);
}

/// Çizgili notta ilk maddeye odaklan → Biçim → çizgi tepsisi.
Future<void> _openDividerTray(WidgetTester tester) async {
  // Madde metni tembel yuvada boyanır (`_LazyItemField`); dokunuş onu açar.
  await tester.tap(
    find
        .byWidgetPredicate(
          (w) => w.runtimeType.toString() == '_LazyItemField',
        )
        .first,
    warnIfMissed: false,
  );
  await _settle(tester);
  await tester.tap(find.byTooltip('Biçim').first, warnIfMissed: false);
  await _settle(tester);
  await tester.tap(
    find.byKey(const ValueKey('format-divider-menu')),
    warnIfMissed: false,
  );
  await _settle(tester);
}

/// P63 PBT: ADIMLI sahneler (kimlik, adres, adımlar). Tek dokunuşlu ana
/// listeye DOKUNULMAZ (P62 aynı listeye satır ekliyor); çekim döngüsü aynı.
/// Bir sahnenin adımı bulunamazsa sahne "adım yok" diye geçilir.
final _stepScenes = <(String, String, Future<void> Function(WidgetTester))>[
  ('sablon-galeri', '/', _openTemplates),
  // Liste şablonu artık hızlı liste sayfasına açılır (T15: levha önizlemesinin
  // liste dalı silindi).
  ('sablon-hizli-liste', '/', (t) async {
    await _openTemplates(t);
    await t.tap(find.byKey(const ValueKey('tpl-card-b:shopping')).first);
    await _settle(t);
  }),
  ('sablon-onizleme-yazi', '/', (t) async {
    await _openTemplates(t);
    final card = find.byKey(const ValueKey('tpl-card-b:meeting'));
    await t.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).last);
    await t.tap(card);
    await _settle(t);
  }),
  ('sablon-bos', '/', (t) async {
    await _openTemplates(t);
    final mine = find.widgetWithIcon(ChoiceChip, Icons.bookmark_outline);
    await t.ensureVisible(mine);
    await _settle(t);
    await t.tap(mine);
    await _settle(t);
  }),
  ('sablon-duzenle', '/', (t) async {
    await _openTemplates(t);
    await t.tap(find.byKey(const ValueKey('tpl-new')));
    await _settle(t);
  }),
  // P62 PA5: bildirim şeridi — ipucu üstte (arama hapının altında), "Geri
  // al" dipte "+" satırının yanında, "Yenilikler" düğme satırının üstünde.
  ('ana-ipucu', '/', (t) async {
    appNotice.show(
      const AppNoticeData(
        kind: AppNoticeKind.tip,
        text: 'Klasörler arasında geçmek için ekranı yana kaydır',
      ),
    );
    await _settle(t);
  }),
  ('ana-gerial', '/', (t) async {
    appNotice.show(
      AppNoticeData(text: 'Not çöpe taşındı', actionLabel: 'Geri al', onAction: () {}),
    );
    await _settle(t);
  }),
  ('ana-yenilikler', '/', (t) async {
    appNotice.show(
      AppNoticeData(
        kind: AppNoticeKind.announce,
        text: 'Yenilikler — 1.2.40',
        details: const ['Bildirimler tek yerde', 'Kalıcı şeritler sade', '2 yenilik daha'],
        actionLabel: 'Tümünü gör',
        onAction: () {},
        duration: const Duration(seconds: 12),
      ),
    );
    await _settle(t);
  }),
  ('cizgi-satirlar', '/note/n8', (t) async {}),
  ('cizgi-tepsi', '/note/n8', _openDividerTray),
  ('cizgi-levha', '/note/n8', (t) async {
    await _openDividerTray(t);
    await t.tap(find.byKey(const ValueKey('format-divider-style')));
    await _settle(t);
  }),
  // P63 G4 (PB3): kalem seti — telefonda hap/kapsül/panel, tablette sütun,
  // çizim ekranında alt şerit.
  ('kalem-hap', '/note/n4', _penMode),
  ('kalem-kapsul', '/note/n4', _penDock),
  ('kalem-panel', '/note/n4', (t) => _penDock(t, tap: 'pen-tray-color')),
  ('kalem-sekil-panel', '/note/n4', (t) async {
    await _penDock(t, tap: 'pen-tray-shapes');
    await t.tap(find.byKey(const ValueKey('pen-tray-shapes')));
    await _settle(t);
  }),
  ('kalem-sutun', '/note/n4', _penMode),
  ('cizim-serit', '/note/n4', (t) async {
    unawaited(
      Navigator.of(t.element(find.byType(NoteEditorScreen))).push(
        MaterialPageRoute<void>(builder: (_) => const DrawingScreen()),
      ),
    );
    await _settle(t);
  }),
  // P63 G4 (PB5): sesle yazma — editörde dikte kartı, yapay zekâ levhasının
  // dinleme / gözden geçirme / hata evreleri (konuşma kanalı taklidi).
  ('dikte-kart', '/note/n4', (t) async {
    _mockSpeech(t);
    await t.tap(find.text('Toplantı notları').first, warnIfMissed: false);
    await _settle(t);
    await t.tap(find.byTooltip('Dikte').first);
    await _settle(t);
    _speechSink!.success({'text': 'yarın saat onda'});
    for (final lv in const [0.3, 0.8, 0.6, 0.9]) {
      _speechSink!.success({'level': lv});
      await t.pump(const Duration(milliseconds: 60));
    }
    await t.pump(const Duration(milliseconds: 200));
  }),
  ('ses-levha-dinliyor', '/note/n4', (t) async {
    await _openVoiceSheet(t);
  }),
  ('ses-levha-hazir', '/note/n4', (t) async {
    await _openVoiceSheet(t);
    await t.tap(find.byKey(const ValueKey('voice-listen-action')));
    await _settle(t);
  }),
  ('ses-levha-hata', '/note/n4', (t) async {
    await _openVoiceSheet(t, speak: false);
    // Dinlerken tanıma hatası: kart açık kalır, hata metni kartın içinde.
    // (Hata EVRESİ kayıt eklentisi ister — testte eklentinin kurucusu
    // yakalanmamış istisna atıyor; turda çekilmez.)
    _speechSink!.error(code: 'network', message: 'Bağlantı kurulamadı');
    await _settle(t);
  }),
  // P63 G5 (PB1/PB2): düzen modu şeridi + çerçeveler, Kişiselleştir ekranı.
  ('duzen-serit', '/note/n4', (t) async {
    // ignore: invalid_use_of_visible_for_testing_member
    addTearDown(Personalize.debugReset);
    Personalize.startEditing();
    await _settle(t);
    // Bir öğe gizli: kesikli çerçeve + gizli sayısı hapı görünsün.
    await t.tap(find.byType(CustomizeFrame).first);
    await _settle(t);
  }),
  // Turun yönlendiricisinde /personalize yok: ekran ana sayfadan itilir.
  ('kisisellestir', '/', (t) async {
    unawaited(
      Navigator.of(t.element(find.byType(Scaffold).first)).push(
        MaterialPageRoute<void>(builder: (_) => const PersonalizeScreen()),
      ),
    );
    await _settle(t);
  }),
  // PB2: düzen merkezi levhası (şeritteki "Sırala"), not ekranında.
  for (final (id, surface) in const [
    ('duzen-hub-altcubuk', CustomizeSurface.bottomBar),
    ('duzen-hub-hizli', CustomizeSurface.quickRow),
  ])
    (id, '/note/n4', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      addTearDown(Personalize.debugReset);
      Personalize.startEditing();
      await _settle(t);
      unawaited(
        showCustomizeHub(
          t.element(find.byType(Scaffold).last),
          initial: surface,
        ),
      );
      await _settle(t);
    }),
];

/// Konuşma kanalı taklidi: yerleşik tanıma var, olaylar [_speechSink]'ten.
MockStreamHandlerEventSink? _speechSink;
void _mockSpeech(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  const events = EventChannel('dev.kaimau.notlar/speech');
  const system = MethodChannel('dev.kaimau.notlar/system');
  messenger
    ..setMockStreamHandler(
      events,
      MockStreamHandler.inline(onListen: (_, sink) {
        _speechSink = sink;
      }),
    )
    ..setMockMethodCallHandler(system, (_) async => null);
  // ignore: invalid_use_of_visible_for_testing_member
  DeviceSpeech.debugAvailable = true;
  addTearDown(() {
    // ignore: invalid_use_of_visible_for_testing_member
    DeviceSpeech.debugAvailable = null;
    _speechSink = null;
    messenger
      ..setMockStreamHandler(events, null)
      ..setMockMethodCallHandler(system, null);
  });
}

/// Yapay zekâ ile sesli not levhası (dokunmalı kip: açılınca dinler).
Future<void> _openVoiceSheet(WidgetTester tester, {bool speak = true}) async {
  _mockSpeech(tester);
  final context = tester.element(find.byType(NoteEditorScreen).first);
  unawaited(
    showVoiceCaptureSheet(context, target: VoiceCaptureTarget.editor),
  );
  await _settle(tester);
  if (!speak) return;
  _speechSink!.success({'text': 'yarın saat onda toplantı var'});
  for (final lv in const [0.3, 0.8, 0.6, 0.9]) {
    _speechSink!.success({'level': lv});
    await tester.pump(const Duration(milliseconds: 60));
  }
  await tester.pump(const Duration(milliseconds: 200));
}

/// Kalem kipi: kalemle bir çizgi (kip açılır), ipucu ve çekmece insin.
Future<void> _penMode(WidgetTester tester) async {
  // Kalem metin alanına değerse Scribe sorulur (testte yanıt yok).
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.scribe,
    (_) async => false,
  );
  InkToolMemory.autoStylus = true;
  InkToolMemory.stylusEver = true;
  final page = tester.getRect(find.byType(PageInkStack).first);
  final pen = await tester.startGesture(
    page.topLeft + const Offset(60, 160),
    kind: PointerDeviceKind.stylus,
  );
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await pen.moveBy(const Offset(30, 8));
    await tester.pump();
  }
  await pen.up();
  for (var i = 0; i < 9; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
  await _settle(tester);
}

/// Kalem kipi → kapsülü aç → (isteğe bağlı) bir düğmeye dokun.
Future<void> _penDock(WidgetTester tester, {String? tap}) async {
  await _penMode(tester);
  await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
  await _settle(tester);
  if (tap != null) {
    await tester.tap(find.byKey(ValueKey(tap)));
    await _settle(tester);
  }
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
    // TOUR_EMPTY=1: boş hâller (F74.6, F79.5).
    if (_tourEmpty) ...[
      ('ana-bos', '/', null),
      ('klasor-bos', '/', null),
      ('arsiv-bos', '/archive', null),
      ('cop-bos', '/trash', null),
      ('gelen-bos', '/inbox', null),
      ('arama-bos', '/', null),
    ],
    // TOUR_OFFLINE=1: çevrimdışı hâller (F79.6, OTURTMA F66.6).
    if (_tourOffline && !_tourEmpty) ...[
      ('cevrimdisi-ana', '/', null),
      ('cevrimdisi-n1', '/note/n1', null),
      ('cevrimdisi-ek', '/note/e-image-ek', null),
      (
        'cevrimdisi-ai',
        '/note/n4',
        () => find.byTooltip('Yapay zekâ').last,
      ),
      ('cevrimdisi-cop', '/trash', null),
      ('cevrimdisi-gelen', '/inbox', null),
    ],
    if (!_tourEmpty && !_tourOffline) ...[
    ('ana', '/', null),
    ('n1', '/note/n1', null),
    ('n2', '/note/n2', null),
    ('iki-not', '/note/n1', null),
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
    ('ana-suz', '/', () => find.byKey(const ValueKey('home-filter-button'))),
    // 2026-11-27 menü denetimi: alt çubuk ⋯ ve hızlı satır ⋯.
    ('n4-alt-diger', '/note/n4', () {
      final f = find.byTooltip('Diğer işlemler');
      return f.evaluate().isEmpty ? f : f.last;
    }),
    ('n4-satir-diger', '/note/n4', () => find.byKey(const ValueKey('quick-row-more'))),
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
    // P62 (plan_tasarim_A): her ayar alanı kendi sayfasında + hesap levhası.
    for (final area in const [
      'account',
      'friends',
      'ai',
      'notes',
      'writing',
      'sound',
      'sync',
      'permissions',
      'updates',
    ])
      ('ayarlar-$area', '/settings?area=$area', null),
    (
      'hesap-levhasi',
      '/',
      () => find.byKey(const ValueKey('home-account-avatar')),
    ),
    // P62 PA0: takvim ajandası, mini ay kapalı / açık (başlığa dokunulmuş).
    ('takvim-ajanda', '/calendar', null),
    (
      'takvim-ajanda-ay',
      '/calendar',
      () => find.byKey(const ValueKey('calendar-month-toggle')),
    ),
    // 2026-11-21: hafta panosu ve görünüm düğmeleri; ay + gün paneli.
    ('takvim-hafta', '/calendar', null),
    ('takvim-ay', '/calendar', null),
    ('klasorler', '/folders', null),
    ('yapay-zeka', '/ai', null),
    ('arsiv', '/archive', null),
    ('cop', '/trash', null),
    ('gelen', '/inbox', null),
    for (final kind in const ['image', 'pdf', 'video'])
      for (final view in const ['sabit', 'yuzen', 'ek'])
        ('e-$kind-$view', '/note/e-$kind-$view', null),
    ('e-pdf-balonlu', '/note/e-pdf-balonlu', null),
    ],
  ];
  // TOUR_SIZES=telefon-yatay,matepad-yatay: yalnız bu boyutlar.
  final sizesWanted = (Platform.environment['TOUR_SIZES'] ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .toSet();
  final kb = Platform.environment['TOUR_KEYBOARD'];
  // TOUR_SIZES=telefon-tam: uzun sayfanın tamamı tek görüntüde (ayar
  // denetimi, 2026-11-27); varsayılan turda yok.
  for (final size in [
    ..._sizes,
    if (sizesWanted.contains('telefon-tam'))
      const _Size('telefon-tam', 412, 3200),
  ]) {
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
          scene: id,
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
          '${size.name}-$id${dark ? '-koyu' : ''}${kb != null ? '-klavye' : ''}'
          '${_tourFont != null ? '-yazi${(_tourFont! * 100).round()}' : ''}',
        );
        await _end(tester);
      });
    }
    for (final (id, location, steps) in _stepScenes) {
      if (!wanted(id)) continue;
      testWidgets('${size.name} · $id', (tester) async {
        final key = GlobalKey();
        await _pumpApp(
          tester,
          size: size,
          location: location,
          key: key,
          scene: id,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        try {
          await steps(tester);
        } catch (e) {
          // Bulucu boş (dar ekranda düğme ⋮'te vb.): sahne geçilir.
          // ignore: avoid_print
          print('TOUR: $id adım yok ($e)');
          await _end(tester);
          return;
        }
        await _shot(
          tester,
          key,
          '${size.name}-$id${dark ? '-koyu' : ''}${kb != null ? '-klavye' : ''}'
          '${_tourFont != null ? '-yazi${(_tourFont! * 100).round()}' : ''}',
        );
        await _end(tester);
      });
    }
  }
}
