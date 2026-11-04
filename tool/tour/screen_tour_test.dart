// EKRAN TURU (TUTARLILIK_PLANI F36.1): gerçek ana ekran ve not ekranı,
// Firebase'siz sahte verilerle, telefon / tablet / masaüstü boyutlarında
// çizilir ve PNG olarak yazılır. CI'da KOŞMAZ (test/ dışında); elle:
//
//   flutter test tool/tour/screen_tour_test.dart
//   (çıktı: build/tour/*.png — TOUR_OUT ile değiştirilebilir)
//
// Canlı sitede misafir hesap açmadan web/tablet düzenini görmenin yolu.
// Gerçek cihazın yerine geçmez: yazı tipleri ve simgeler gerçek, gölgeler
// yazılım çiziminde; klavye, sistem çubukları, kamera yok.
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
import 'package:notlar/app/app_frame.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/app/theme/app_palette.dart';
import 'package:notlar/app/theme/app_theme.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
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
  });
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
  await tester.runAsync(() async {
    await GoogleFonts.pendingFonts();
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
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
    ],
  });
  final sp = await SharedPreferences.getInstance();
  tester.view.physicalSize = Size(size.width, size.height);
  tester.view.devicePixelRatio = 1;
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
      notesStreamProvider.overrideWith((ref) => Stream.value(_notes)),
      foldersStreamProvider.overrideWith((ref) => Stream.value(_folders)),
      for (final n in _notes)
        noteStreamProvider(n.id).overrideWith((ref) => Stream.value(n)),
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
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  // Hangi ekranlar çekilsin: TOUR_ONLY=ana,n1 gibi süzülebilir.
  final only = (Platform.environment['TOUR_ONLY'] ?? '')
      .split(',')
      .where((s) => s.isNotEmpty)
      .toSet();
  bool wanted(String id) => only.isEmpty || only.contains(id);

  final dark = Platform.environment['TOUR_DARK'] == '1';
  for (final size in _sizes) {
    for (final (id, location) in [
      ('ana', '/'),
      ('n1', '/note/n1'),
      ('n2', '/note/n2'),
      ('n4', '/note/n4'),
    ]) {
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
        await _shot(tester, key, '${size.name}-$id${dark ? '-koyu' : ''}');
        await _end(tester);
      });
    }
  }
}
