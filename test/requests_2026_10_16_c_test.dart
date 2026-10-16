import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/widgets/customizable.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/editor/attach_sheet.dart';
import 'package:notlar/features/notes/presentation/editor/editor_bar_layout.dart';
import 'package:notlar/features/notes/presentation/editor/note_images.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/features/notes/presentation/editor/video_hub_scope.dart';
import 'package:notlar/features/notes/presentation/editor/video_transport.dart';
import 'package:notlar/features/notes/presentation/editor/view_mode_switch.dart';
import 'package:notlar/features/notes/presentation/quick_add_fab.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/core/utils/video_time.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('tr'),
  builder: (context, child) => CustomizeModeHost(child: child!),
  home: Scaffold(body: child),
);

/// 2026-10-16 (3. tur) kullanıcı istekleri: araç panelinde sil/⋮ basılmıyor,
/// sabit videoyu kaldırma, ayrı geri/ileri sarma süresi, karışık notta
/// bölüm kaldırma, balona yazarken odak/klavye, ek şeridinde önizleme,
/// kişiselleştirme + düzenleme modu.
void main() {
  setUp(Personalize.debugReset);
  tearDown(Personalize.debugReset);

  group('sayfadaki ekin araç paneli', () {
    const image = Attachment(
      id: 'g',
      kind: AttachmentKind.image,
      fileName: 'g.jpg',
      mimeType: 'image/jpeg',
      width: 100,
      height: 100,
      x: 0.3,
      pageY: 200,
      displayWidth: 0.3,
    );

    testWidgets('ALT satırdaki sil ve ⋮ basılır (panel kapanmaz)', (
      tester,
    ) async {
      // KÖK NEDEN (kullanıcı ekran görüntüsü): "dışarı dokunuldu" alanı
      // sabit 64 dp idi; görünüm anahtarı panele ikinci satır olarak gelince
      // alt satır bu alanın DIŞINDA kaldı ve parmak inerken seçim düşüyordu.
      final removed = <String>[];
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: NotePageCanvas(
                images: const [image],
                minHeight: 900,
                onRemove: (a) => removed.add(a.id),
                onChanged: (_) {},
                onCopy: (_) {},
                onViewChange: (_, _) {},
                child: const SizedBox(width: 400, height: 400),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('page-image-g')));
      await tester.pumpAndSettle();
      // Panelde iki satır var: görünüm anahtarı + araçlar.
      expect(
        find.byKey(const ValueKey('attachment-view-switch')),
        findsOneWidget,
      );
      final switchRect = tester.getRect(
        find.byKey(const ValueKey('attachment-view-switch')),
      );
      final delete = find.byIcon(Icons.delete_outline);
      expect(tester.getRect(delete).top, greaterThan(switchRect.bottom));

      // ⋮ menüsü açılır.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.byType(PopupMenuItem<String>), findsWidgets);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      // Sil çalışır.
      await tester.tap(delete);
      await tester.pumpAndSettle();
      expect(removed, ['g']);
    });
  });

  group('sabit bölmenin ⋮ menüsü', () {
    const video = Attachment(
      id: 'v',
      kind: AttachmentKind.video,
      fileName: 'v.mp4',
      mimeType: 'video/mp4',
      pinHeight: 180,
    );

    Future<List<String>> pump(WidgetTester tester) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _app(
          PinnedMediaPane(
            media: video,
            onHeightChanged: (_) {},
            onUnpin: () => calls.add('unpin'),
            onOpen: () {},
            onRemove: () => calls.add('remove'),
            onDetach: () => calls.add('detach'),
            viewSwitch: AttachmentViewSwitch(
              current: AttachmentView.pinned,
              available: availableViews(video),
              dense: true,
              onChanged: (_) {},
            ),
            child: const Text('not'),
          ),
        ),
      );
      return calls;
    }

    testWidgets('Sayfaya göm · Ek olarak taşı · Kaldır yazılı', (tester) async {
      final calls = await pump(tester);
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      for (final (label, call) in [
        (l10n.pinnedEmbedOnPage, 'unpin'),
        (l10n.moveImageToAttachments, 'detach'),
        (l10n.removeAttachment, 'remove'),
      ]) {
        await tester.tap(find.byKey(const ValueKey('pinned-media-menu')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(calls.last, call);
      }
    });

    testWidgets('dar ekranda taşmaz', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pump(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('pinned-media-menu')), findsOneWidget);
    });
  });

  group('kişiselleştirme', () {
    test('tercih JSON gidiş-dönüşü, bozuk kayıt varsayılana düşer', () {
      const prefs = UiPrefs(
        hidden: {'editor.bar.ai', 'quickadd.qr'},
        seekBack: 5,
        seekForward: 30,
      );
      expect(UiPrefs.fromJson(prefs.toJson()), prefs);
      expect(UiPrefs.fromJson('çöp'), const UiPrefs());
      expect(UiPrefs.fromJson({'seekBack': 99999}).seekBack, 600);
      expect(UiPrefs.fromJson({'seekForward': -3}).seekForward, 1);
    });

    test('eklenti öğelerinin hepsini açar/kapatır; karışık durum null', () {
      var prefs = const UiPrefs();
      expect(prefs.moduleState(UiModule.video), isTrue);
      prefs = prefs.withModule(UiModule.video, false);
      expect(prefs.moduleState(UiModule.video), isFalse);
      for (final id in UiModule.video.items) {
        expect(prefs.shows(id), isFalse);
      }
      prefs = prefs.withVisible('quickadd.youtube', true);
      expect(prefs.moduleState(UiModule.video), isNull);
      prefs = prefs.withModule(UiModule.video, true);
      expect(prefs.hidden, isEmpty);
    });

    test(
      'düzenleme modu TASLAKTA çalışır: Vazgeç atar, Kaydet yazar',
      () async {
        SharedPreferences.setMockInitialValues({});
        final store = await SharedPreferences.getInstance();
        Personalize.attach(store);
        Personalize.startEditing();
        Personalize.toggle(UiItem.barShare);
        expect(Personalize.current.shows(UiItem.barShare), isFalse);
        expect(Personalize.prefs.value.shows(UiItem.barShare), isTrue);
        expect(Personalize.dirty, isTrue);
        Personalize.cancel();
        expect(Personalize.editing, isFalse);
        expect(Personalize.current.shows(UiItem.barShare), isTrue);

        Personalize.startEditing();
        Personalize.toggle(UiItem.barShare);
        Personalize.save();
        expect(Personalize.editing, isFalse);
        expect(Personalize.prefs.value.shows(UiItem.barShare), isFalse);
        // Kalıcı: yeniden bağlanınca okunur.
        Personalize.prefs.value = const UiPrefs();
        Personalize.attach(store);
        expect(Personalize.prefs.value.shows(UiItem.barShare), isFalse);
      },
    );

    testWidgets('gizli öğe yer kaplamaz; düzenleme modunda çerçeveli görünür '
        've dokunmak işini DEĞİL gizle/göster yapar', (tester) async {
      var taps = 0;
      Personalize.prefs.value = const UiPrefs(hidden: {'x'});
      await tester.pumpWidget(
        _app(
          Center(
            child: Customizable(
              id: 'x',
              child: ElevatedButton(
                onPressed: () => taps++,
                child: const Text('düğme'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('düğme'), findsNothing);

      Personalize.startEditing();
      await tester.pump();
      expect(find.text('düğme'), findsOneWidget);
      expect(find.byType(CustomizeFrame), findsOneWidget);
      // Çocuk IgnorePointer altında: dokunuşu çerçeve alır (uyarı beklenir).
      await tester.tap(find.text('düğme'), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
      expect(Personalize.current.shows('x'), isTrue);

      // Şeritten Kaydet.
      await tester.tap(find.byKey(const ValueKey('customize-save')));
      await tester.pumpAndSettle();
      expect(Personalize.editing, isFalse);
      expect(find.byType(CustomizeFrame), findsNothing);
      await tester.tap(find.text('düğme'));
      expect(taps, 1);
    });

    testWidgets('düzenleme modu açılıp kapanınca ekranların durumu KORUNUR', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const _Counter()));
      await tester.tap(find.byKey(const ValueKey('counter')));
      await tester.tap(find.byKey(const ValueKey('counter')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
      Personalize.startEditing();
      await tester.pump();
      expect(find.byKey(const ValueKey('customize-cancel')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('customize-cancel')));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);
    });

    test('+ menüsü ve Ekle levhası kimlikleri tekil', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('tr'));
      final quick = [for (final m in quickAddCatalog(l10n)) m.key];
      expect(quick.toSet().length, quick.length);
      expect(quick, containsAll(['text', 'checklist', 'youtube', 'archive']));
      final attach = [for (final e in attachSheetCatalog(l10n)) e.id];
      expect(attach.toSet().length, attach.length);
      // Eklentilerin saydığı her öğe gerçekten bir yerde var.
      final known = {
        for (final k in quick) UiItem.quickAdd(k),
        for (final a in attach) UiItem.attach(a),
        UiItem.barAi,
        UiItem.barVoiceAi,
        UiItem.barDictation,
        UiItem.editorTags,
        UiItem.topCollab,
        UiItem.homeAi,
        UiItem.homeVoiceAi,
        UiItem.homeDictation,
      };
      for (final module in UiModule.all) {
        for (final id in module.items) {
          // Tarama/QR test ortamında (platform) olmayabilir.
          if (id.endsWith('scan') || id.endsWith('qr')) continue;
          expect(known, contains(id), reason: '${module.id}: $id');
        }
      }
    });

    test('alt çubuk: gizlenen AI düğmeleri yer açar', () {
      final full = planEditorBar(
        width: 300,
        fixedSegments: 2,
        attachments: false,
        pen: false,
      );
      final noAi = planEditorBar(
        width: 300,
        fixedSegments: 2,
        attachments: false,
        pen: false,
        aiButtons: 0,
      );
      expect(noAi.share, isTrue);
      expect(full.share, isFalse);
    });
  });

  group('sarma süreleri', () {
    testWidgets('geri ve ileri AYRI süreler; hız gizlenebilir', (tester) async {
      Personalize.prefs.value = const UiPrefs(
        seekBack: 5,
        seekForward: 30,
        hidden: {UiItem.videoSpeed},
      );
      final hub = NoteVideoHub();
      final source = _FakeSource('v');
      hub.register(source);
      const video = Attachment(
        id: 'v',
        kind: AttachmentKind.video,
        fileName: 'v.mp4',
        mimeType: 'video/mp4',
      );
      await tester.pumpWidget(
        _app(
          VideoHubScope(
            hub: hub,
            child: const VideoTransportControls(video: video, showSpeed: true),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('video-speed')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('video-back-10')));
      await tester.tap(find.byKey(const ValueKey('video-forward-10')));
      expect(source.calls, ['seek -5', 'seek 30']);

      // Ayar değişince çubuk kendiliğinden tazelenir.
      Personalize.update((p) => p.copyWith(seekForward: 15));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('video-forward-10')));
      expect(source.calls.last, 'seek 15');
      // 15 sn'nin Material simgesi yok: sayı yazılır.
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('balon yazma kartı', () {
    testWidgets('okuma kartından "Düzenle" klavyeyi AÇAR (odak istenir)', (
      tester,
    ) async {
      // KÖK NEDEN: alanlar okuma kipinde aynı balonla dolduğu için
      // düzenlemeye geçişte erken dönülüyor, odak hiç istenmiyordu.
      final controller = BubbleController(
        initial: [
          PageBubble(
            id: 'b',
            page: 1,
            x: 0.5,
            y: 0.5,
            color: BubbleController.palette.first,
            text: 'yazılı',
            collapsed: true,
          ),
        ],
        onChanged: (_) {},
      );
      addTearDown(controller.dispose);
      final editing = <bool>[];
      controller.onEditingChanged = editing.add;
      await tester.pumpWidget(_app(BubbleDock(controller: controller)));
      controller.openOnly('b');
      await tester.pumpAndSettle();
      expect(controller.editMode, isFalse);
      expect(find.byType(TextField), findsNothing);

      controller.beginEdit();
      await tester.pumpAndSettle();
      final body = tester.widget<TextField>(
        find.byKey(const ValueKey('bubble-dock-text')),
      );
      expect(body.focusNode!.hasFocus, isTrue);
      // İmleç metnin sonunda.
      expect(body.controller!.selection.baseOffset, 'yazılı'.length);
      expect(editing, [true]);
    });

    testWidgets('kart klavyenin ARKASINDA kalmaz: gövde kısalmasa da '
        'klavyenin üstünde çizilir ve dokunulur', (tester) async {
      // Not editörü klavye açılırken gövdeyi bilerek tam boyda tutar
      // (KeyboardSnap); burada da gövde kısalmıyor.
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = BubbleController(initial: const [], onChanged: (_) {});
      addTearDown(controller.dispose);
      controller.add(1, 0.5, 0.5);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Column(
              children: [
                const Expanded(child: SizedBox()),
                BubbleDock(controller: controller),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final done = find.byKey(const ValueKey('bubble-dock-done'));
      final before = tester.getRect(done);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pump();
      final after = tester.getRect(done);
      expect(after.top, closeTo(before.top - 300, 1));
      // İsabet testi de kayar: "Bitti" klavyenin üstündeki yerinde basılır.
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(controller.openBubble, isNull);
    });

    testWidgets('yazma kipi ODAĞA değil karta bağlı: odak gidip gelince '
        'yerleşim değişmez', (tester) async {
      final controller = BubbleController(initial: const [], onChanged: (_) {});
      addTearDown(controller.dispose);
      final editing = <bool>[];
      controller.onEditingChanged = editing.add;
      controller.add(1, 0.5, 0.5);
      await tester.pumpWidget(_app(BubbleDock(controller: controller)));
      await tester.pumpAndSettle();
      expect(editing, [true]);
      // Odak düşer (sayfaya dokunuldu): kip SÜRER.
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(editing, [true]);
      // "Bitti": kart kapanır, kip biter.
      await tester.tap(find.byKey(const ValueKey('bubble-dock-done')));
      await tester.pumpAndSettle();
      expect(editing, [true, false]);
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _n = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      key: const ValueKey('counter'),
      onPressed: () => setState(() => _n++),
      child: Text('$_n'),
    ),
  );
}

class _FakeSource extends VideoTimeSource {
  _FakeSource(this.attachmentId);

  @override
  final String attachmentId;

  final calls = <String>[];
  final _changes = ValueNotifier<int>(0);

  @override
  Listenable get changes => _changes;

  @override
  Duration? get lastPosition => const Duration(seconds: 83);

  @override
  Duration? get duration => const Duration(minutes: 4);

  @override
  Future<Duration?> position() async => lastPosition;

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> seekBy(Duration delta) async {
    calls.add('seek ${delta.inSeconds}');
  }
}
