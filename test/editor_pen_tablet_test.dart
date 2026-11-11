import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/split_shell.dart';
import 'package:notlar/features/auth/presentation/auth_providers.dart';
import 'package:notlar/features/folders/data/folders_repository.dart';
import 'package:notlar/core/app_update.dart';
import 'package:notlar/core/tips.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_editor_screen.dart';
import 'package:notlar/features/notes/presentation/editor/page_ink_layer.dart';
import 'package:notlar/features/notes/presentation/editor/pen_tray.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_layer.dart';
import 'package:notlar/features/notes/presentation/viewers/ink_tools.dart';
import 'package:notlar/core/widgets/note_route_closing.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';
import 'package:notlar/features/settings/settings_providers.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerçek editör, tablet penceresinde: kalem dokunuşundan başlayan bütün akış.
/// Gerçek cihazın yerine geçmez (basınç, avuç içi burada yok) ama derleme
/// sırasındaki hataları ve yerleşimi yakalar.
const _note = Note(id: 'n', type: NoteType.text, title: 'TEST', body: 'yazı');

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Note note = _note,
  Size size = const Size(1200, 800),
  bool startDrawing = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  InkToolMemory.autoStylus = true;
  final container = ProviderContainer(
    // Firebase'siz sağlayıcılar yeniden denemesin (bekleyen zamanlayıcı).
    retry: (_, _) => null,
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUidProvider.overrideWithValue(null),
      updateRequiredProvider.overrideWithValue(false),
      notesRepositoryProvider.overrideWithValue(null),
      attachmentRepositoryProvider.overrideWithValue(null),
      foldersRepositoryProvider.overrideWithValue(null),
      noteStreamProvider('n').overrideWith((ref) => Stream.value(note)),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: NoteEditorScreen(noteId: 'n', startDrawing: startDrawing),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
  return container;
}

Future<void> _write(WidgetTester tester, Offset at) async {
  final pen = await tester.startGesture(at, kind: PointerDeviceKind.stylus);
  await tester.pump();
  await pen.moveBy(const Offset(60, 8));
  await tester.pump();
  await pen.moveBy(const Offset(60, 8));
  await tester.pump();
  await pen.up();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Editörün gecikmeli işleri (kayıt, ipucu) testin sonunda bitsin.
Future<void> _end(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 30));
}

void main() {
  testWidgets('kalem değince sayfaya yazar, araçlar alttaki çekmecede', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.byType(PageInkStack), findsOneWidget);
    expect(find.byKey(const ValueKey('pen-tray-pen')), findsNothing);
    await _write(tester, tester.getCenter(find.byType(PageInkStack)));
    // Kalem kapsülü (yeniden tasarım 2026-11-07): çizim başlayınca yalnız
    // küçük hap kalır, kalemler gizlenir.
    await tester.pump(const Duration(milliseconds: 400));
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    final peek = find.byKey(const ValueKey('pen-dock-peek'));
    expect(peek, findsOneWidget);
    // 48 dp (2026-11-08: "azıcık genişlemeli, basınca karışıyor").
    expect(tester.getRect(peek).height, lessThanOrEqualTo(48));
    expect(tester.getRect(peek).bottom, greaterThan(screen.height - 60));
    expect(find.byKey(const ValueKey('pen-tray-pen')), findsNothing);
    // Dokununca kapsül açılır (önce ilk seferki ipucu kalksın).
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(peek);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(peek, findsNothing);
    final tool = find.byKey(const ValueKey('pen-tray-pen'));
    expect(tool, findsOneWidget);
    expect(tester.getRect(tool).top, greaterThan(screen.height - 100));
    // İlk çizgi kaybolmadı, alt çubuk yok: alt da sayfa.
    final ink = tester.widget<InkPageLayer>(find.byType(InkPageLayer));
    expect(ink.controller.ink, hasLength(1));
    expect(find.byType(BottomAppBar), findsNothing);
    await _end(tester);
  });

  testWidgets('kalemle yazıp parmakla gövdeye dokununca klavye yazısı', (
    tester,
  ) async {
    await _pump(tester);
    final body = find.widgetWithText(TextField, 'yazı').first;
    final at = tester.getCenter(body);
    await _write(tester, at);
    // Kalem kalktıktan hemen sonraki dokunuş avuç sayılır (avuç reddi).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 450)),
    );
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.testTextInput.isVisible, isTrue);
    final ink = tester.widget<InkPageLayer>(find.byType(InkPageLayer));
    expect(ink.controller.ink, hasLength(1));
    await _end(tester);
  });

  testWidgets('tam ekran: ray ve liste kalkar, not kapanınca biter', (
    tester,
  ) async {
    final container = await _pump(tester);
    await tester.tap(find.byKey(const ValueKey('note-fullscreen')));
    await tester.pump();
    expect(container.read(noteFullscreenProvider), isTrue);
    // Kalem + tam ekran: üst çubuk da sayfaya bırakılır.
    await _write(tester, tester.getCenter(find.byType(PageInkStack)));
    expect(find.byType(AppBar), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(container.read(noteFullscreenProvider), isFalse);
    await _end(tester);
  });

  testWidgets('telefonda kalemler altta, kapatınca alt çubuk döner', (
    tester,
  ) async {
    await _pump(tester, size: const Size(400, 800));
    await _write(tester, tester.getCenter(find.byType(PageInkStack)));
    expect(find.byType(PenTray), findsOneWidget);
    expect(tester.getRect(find.byType(PenTray)).bottom, 800);
    // İlk seferki ipucu tepsinin üstünden kalksın.
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    // Çizimden sonra çekmece aşağıda: önce aç, sonra kapat.
    await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const ValueKey('pen-done')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PenTray), findsNothing);
    await _end(tester);
  });

  testWidgets(
    'kalem kipinde geri: önce açık kapsül, sonra kip; not açık kalır',
    (tester) async {
      await _pump(tester, size: const Size(400, 800));
      await _write(tester, tester.getCenter(find.byType(PageInkStack)));
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('pen-dock-open')), findsOneWidget);
      // 1. geri: kapsül hapa iner.
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const ValueKey('pen-dock-closed')), findsOneWidget);
      // 2. geri: kalem kipi kapanır, not ekranı yerinde.
      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PenTray), findsNothing);
      expect(find.byType(NoteEditorScreen), findsOneWidget);
      await _end(tester);
    },
  );

  testWidgets('kalem sabitlenir, kapsülden tek dokunuşla seçilir', (
    tester,
  ) async {
    InkToolMemory.presets = [];
    await _pump(tester, size: const Size(400, 800));
    await _write(tester, tester.getCenter(find.byType(PageInkStack)));
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.byKey(const ValueKey('pen-dock-peek')));
    await tester.pump(const Duration(milliseconds: 400));
    final ink = tester.widget<PenTray>(find.byType(PenTray)).controller
      ..setColor(const Color(0xFFE53935));
    await tester.tap(find.byKey(const ValueKey('pen-tray-more')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pen-tray-pin')));
    await tester.pumpAndSettle();
    expect(InkToolMemory.presets, hasLength(1));
    ink.setColor(const Color(0xFF1E88E5));
    await tester.pump();
    await tester.tap(
      find.byKey(
        ValueKey('pen-preset-${InkToolMemory.presets.single.encode()}'),
      ),
    );
    await tester.pump();
    expect(ink.color.toARGB32(), 0xFFE53935);
    InkToolMemory.presets = [];
    await _end(tester);
  });

  testWidgets('kapanış animasyonunda sıralama tutması bırakılmaz (kasma)', (
    tester,
  ) async {
    final container = await _pump(tester, size: const Size(400, 800));
    expect(container.read(sortHeldNoteIdsProvider), contains('n'));
    noteRouteClosing.value = true;
    await tester.pump();
    await tester.pump();
    // Pano donuk: tutma kapanış boyunca sürer (ikinci hesap/kurulum yok).
    expect(container.read(sortHeldNoteIdsProvider), contains('n'));
    noteRouteClosing.value = false;
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(container.read(sortHeldNoteIdsProvider), isNot(contains('n')));
    await _end(tester);
  });

  // F63.5 (KALEM K5): telefonda parmakla yazma.
  testWidgets('telefonda parmakla kalem kipi: iki parmak ipucu bir kez çıkar, '
      'sayfa yazdıkça uzar', (tester) async {
    InkToolMemory.reset();
    TipOnce.resetSession();
    addTearDown(InkToolMemory.reset);
    await _pump(tester, size: const Size(400, 800), startDrawing: true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PenTray), findsOneWidget);
    // Parmak çiziyor: kaydırmanın yolu (iki parmak) söylenir.
    expect(find.byKey(const ValueKey('tip-pen_two_finger')), findsOneWidget);
    final l10n = lookupAppLocalizations(const Locale('tr'));
    expect(find.text(l10n.inkTwoFingerHint), findsOneWidget);
    // Sayfanın altında yazmaya yer var ve çizgi indikçe uzar.
    final page = find.byType(PageInkStack);
    final before = tester.getSize(page).height;
    expect(before, greaterThanOrEqualTo(800 * 0.7));
    final finger = await tester.startGesture(const Offset(200, 560));
    await tester.pump();
    await finger.moveBy(const Offset(60, 20));
    await tester.pump();
    await finger.up();
    await tester.pump(const Duration(milliseconds: 300));
    final ink = tester.widget<InkPageLayer>(find.byType(InkPageLayer));
    expect(ink.controller.ink, hasLength(1));
    expect(tester.getSize(page).height, greaterThan(before + 200));
    await _end(tester);
  });

  testWidgets('kalemli cihazda (parmak kaydırır) iki parmak ipucu çıkmaz', (
    tester,
  ) async {
    InkToolMemory.reset();
    InkToolMemory.stylusEver = true;
    TipOnce.resetSession();
    addTearDown(InkToolMemory.reset);
    await _pump(tester, startDrawing: true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PenTray), findsOneWidget);
    expect(find.byKey(const ValueKey('tip-pen_two_finger')), findsNothing);
    await _end(tester);
  });

  testWidgets('kayıtlı el yazısı açılışta görünür', (tester) async {
    await _pump(
      tester,
      note: _note.copyWith(
        pageInk: const [
          InkStroke(
            page: 1,
            color: 0xFF000000,
            width: 0.01,
            points: [0.1, 0.1, 0.4, 1.6],
          ),
        ],
      ),
    );
    final ink = tester.widget<InkPageLayer>(find.byType(InkPageLayer));
    expect(ink.controller.ink, hasLength(1));
    expect(ink.uniform, isTrue);
    await _end(tester);
  });
}
