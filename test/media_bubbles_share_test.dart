import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/video_time.dart';
import 'package:notlar/core/utils/youtube.dart';
import 'package:notlar/features/notes/data/note_quick_export.dart';
import 'package:notlar/features/notes/data/pdf/pdf_page_ocr.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_share_text.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/data/pdf/ocr_page_text.dart';
import 'package:notlar/features/notes/presentation/editor/tag_tap.dart';
import 'package:notlar/features/notes/presentation/editor/video_hub_scope.dart';
import 'package:notlar/features/notes/presentation/editor/video_transport.dart';
import 'package:notlar/features/notes/presentation/note_grid.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// 2026-10-16 (2. tur) kullanıcı istekleri: damgaya dokununca klavye
/// açılmaz, video denetim çubuğu, balon boyu/gizle/basılı tut, kalıcı OCR,
/// paylaşım, tembel ana ekran ızgarası.
void main() {
  group('damga/etiket dokunuşu klavyeyi açmaz', () {
    Future<(FocusNode, List<String>)> pump(
      WidgetTester tester, {
      required bool link,
    }) async {
      final focus = FocusNode();
      final controller = TextEditingController(text: 'izle 1:23 sonra');
      final taps = <String>[];
      final tracker = TapPointTracker();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: tracker.wrap(
              TextField(
                controller: controller,
                focusNode: focus,
                onTap: () => taps.add('tap'),
              ),
              focusNode: focus,
              keepsKeyboardClosed: (_) => link,
            ),
          ),
        ),
      );
      return (focus, taps);
    }

    testWidgets('bağlantıya dokunuş odak ALMAZ, onTap yine çalışır', (
      tester,
    ) async {
      final (focus, taps) = await pump(tester, link: true);
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 50));
      expect(focus.hasFocus, isFalse);
      expect(taps, ['tap']);
      // Engel dokunuştan sonra kalkar: sıradaki dokunuş odaklayabilir.
      expect(focus.canRequestFocus, isTrue);
    });

    testWidgets('bağlantı dışına dokunuş eskisi gibi odaklar', (tester) async {
      final (focus, _) = await pump(tester, link: false);
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(focus.hasFocus, isTrue);
    });
  });

  group('video denetimi', () {
    test('kaydırma videonun sınırlarına kıstırılır', () {
      const d = Duration(seconds: 100);
      expect(
        shiftedPosition(
          const Duration(seconds: 5),
          const Duration(seconds: -10),
          d,
        ),
        Duration.zero,
      );
      expect(
        shiftedPosition(
          const Duration(seconds: 95),
          const Duration(seconds: 10),
          d,
        ),
        d,
      );
      expect(
        shiftedPosition(
          const Duration(seconds: 40),
          const Duration(seconds: 10),
          null,
        ),
        const Duration(seconds: 50),
      );
    });

    test('hız düğmesi sırayla döner, yazımı', () {
      expect(nextVideoSpeed(1), 1.25);
      expect(nextVideoSpeed(2), 0.5);
      expect(nextVideoSpeed(0.75), 1);
      expect(nextVideoSpeed(3), kVideoSpeeds.first);
      expect(formatVideoSpeed(1), '1×');
      expect(formatVideoSpeed(1.5), '1.5×');
    });

    test('merkez kayıt/ayrılmada revision artar', () {
      final hub = NoteVideoHub();
      final source = _FakeSource('v');
      final start = hub.revision.value;
      hub.register(source);
      expect(hub.revision.value, start + 1);
      hub.unregister(source);
      expect(hub.revision.value, start + 2);
      // Kayıtlı olmayanı çıkarmak bildirim üretmez.
      hub.unregister(source);
      expect(hub.revision.value, start + 2);
    });

    test('gömülü YouTube sayfası oynat/durdur/sar/hız köprüsünü taşır', () {
      final html = youTubeEmbedHtml('dQw4w9WgXcQ');
      expect(html, contains('window.notlarPlay'));
      expect(html, contains('window.notlarPause'));
      expect(html, contains('window.notlarSeekBy'));
      expect(html, contains('window.notlarRate'));
      expect(html, contains('NotlarBridge.postMessage'));
      expect(html, contains("func:'pauseVideo'"));
    });

    testWidgets('çubuk oynatır, durdurur ve ±10 sn sarar', (tester) async {
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
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: VideoHubScope(
              hub: hub,
              child: const VideoTransportControls(
                video: video,
                showSpeed: true,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('video-play-pause')));
      await tester.pump();
      expect(source.calls, ['play']);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('video-forward-10')));
      await tester.tap(find.byKey(const ValueKey('video-back-10')));
      await tester.tap(find.byKey(const ValueKey('video-play-pause')));
      await tester.tap(find.byKey(const ValueKey('video-speed')));
      await tester.pump();
      expect(source.calls, [
        'play',
        'seek 10',
        'seek -10',
        'pause',
        'speed 1.25',
      ]);
      expect(find.text('1.25×'), findsOneWidget);
    });

    testWidgets('oynatıcısı olmayan YouTube: ▶ oynatıcıyı kurar', (
      tester,
    ) async {
      final hub = NoteVideoHub();
      const video = Attachment(
        id: 'y',
        kind: AttachmentKind.video,
        fileName: 'YouTube',
        mimeType: 'video/youtube',
        webUrl: 'https://youtu.be/dQw4w9WgXcQ',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: VideoHubScope(
              hub: hub,
              child: const VideoTransportControls(video: video),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('video-play-pause')));
      expect(hub.startRequest.value?.id, 'y');
      expect(hub.startRequest.value?.seconds, isNull);
    });
  });

  group('balon boyu ve gizleme', () {
    test('boy adımları sınırlar içinde yürür', () {
      expect(PageBubble.stepSize(1, 1), 1.25);
      expect(PageBubble.stepSize(1, -1), 0.75);
      expect(PageBubble.stepSize(2.5, 1), PageBubble.maxPinSize);
      expect(PageBubble.stepSize(0.6, -1), PageBubble.minPinSize);
      // Açık metin kendi sınırlarıyla (köşeden 3 kat büyütülmüş yazı).
      expect(PageBubble.stepSize(3, 1, plain: true), 3.75);
      expect(PageBubble.stepSize(0.5, -1, plain: true), PageBubble.minSize);
    });

    test('gizle: açık balon kapanır, bildirim verilir; eklemek gösterir', () {
      final hidden = <bool>[];
      final c = BubbleController(
        initial: const [
          PageBubble(id: 'a', page: 1, x: 0.5, y: 0.5, text: 'x'),
        ],
        onChanged: (_) {},
        onHiddenChanged: hidden.add,
      );
      c.setHidden(true);
      expect(c.hidden, isTrue);
      expect(c.openBubble, isNull);
      expect(hidden, [true]);
      c.setAdding(true);
      expect(c.hidden, isFalse);
      expect(hidden, [true, false]);
      c
        ..setAdding(false)
        ..setHidden(true)
        ..openOnly('a');
      expect(c.hidden, isFalse);
      // Dışarıdan gelen değer kaydedilmez.
      c.syncHidden(true);
      expect(hidden, [true, false, true, false]);
      c.dispose();
    });

    test('stepSize balonu kaydeder', () {
      final saved = <List<PageBubble>>[];
      final c = BubbleController(
        initial: const [PageBubble(id: 'a', page: 1, x: 0.1, y: 0.1)],
        onChanged: saved.add,
      );
      c.stepSize('a', 1);
      expect(c.byId('a')!.size, 1.25);
      expect(saved.single.single.size, 1.25);
      c.dispose();
    });

    test('gizlilik ekte yalnız true iken yazılır, okunur', () {
      const a = Attachment(
        id: 'p',
        kind: AttachmentKind.pdf,
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
      );
      expect(a.toMap().containsKey('bubblesHidden'), isFalse);
      final hidden = a.copyWith(bubblesHidden: true);
      final map = hidden.toMap()..remove('createdAt');
      expect(map['bubblesHidden'], isTrue);
      expect(Attachment.fromMap(map).bubblesHidden, isTrue);
      expect(a.withLayoutOf(hidden).bubblesHidden, isTrue);
    });

    test('unplaceBubbles, placeBubbles\'ın tersidir', () {
      const frame = PageBubbleRect(0.1, 0.2, 0.9, 0.7);
      const original = [
        PageBubble(
          id: 'a',
          page: 1,
          x: 0.25,
          y: 0.75,
          rects: [PageBubbleRect(0.1, 0.1, 0.4, 0.2)],
        ),
      ];
      final back = unplaceBubbles(placeBubbles(original, frame), frame);
      expect(back.single.x, closeTo(0.25, 1e-9));
      expect(back.single.y, closeTo(0.75, 1e-9));
      expect(back.single.rects.single.right, closeTo(0.4, 1e-9));
      // Başka sayfanın balonu alınmaz.
      expect(
        unplaceBubbles(placeBubbles(original, frame, page: 2), frame),
        isEmpty,
      );
    });

    testWidgets('basılı tutmak o noktaya balon bırakır; gizliyken de', (
      tester,
    ) async {
      final c = BubbleController(initial: const [], onChanged: (_) {});
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 400,
                height: 400,
                child: BubblePageLayer(controller: c, page: 1),
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(const Offset(100, 200));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pump();
      expect(c.bubbles, hasLength(1));
      expect(c.bubbles.single.x, closeTo(0.25, 0.01));
      expect(c.bubbles.single.y, closeTo(0.5, 0.01));

      // Kısa dokunuş balon bırakmaz; kayan parmak da.
      await tester.tapAt(const Offset(300, 300));
      final drag = await tester.startGesture(const Offset(300, 100));
      await drag.moveBy(const Offset(0, 60));
      await tester.pump(const Duration(milliseconds: 600));
      await drag.up();
      await tester.pump();
      expect(c.bubbles, hasLength(1));

      c.setHidden(true);
      await tester.pump();
      final again = await tester.startGesture(const Offset(200, 100));
      await tester.pump(const Duration(milliseconds: 600));
      await again.up();
      await tester.pump();
      expect(c.bubbles, hasLength(2));
      expect(c.hidden, isFalse);
      c.dispose();
    });

    testWidgets('gizliyken tutamaç çizilmez', (tester) async {
      final c = BubbleController(
        initial: const [
          PageBubble(
            id: 'a',
            page: 1,
            x: 0.5,
            y: 0.5,
            title: 'Başlık',
            collapsed: true,
          ),
        ],
        onChanged: (_) {},
        hidden: true,
      );
      Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: BubblePageLayer(controller: c, page: 1),
          ),
        ),
      );
      await tester.pumpWidget(app());
      expect(find.text('Başlık'), findsNothing);
      c.setHidden(false);
      await tester.pump();
      expect(find.text('Başlık'), findsOneWidget);
      c.dispose();
    });
  });

  group('kalıcı OCR önbelleği', () {
    test('sözcük satırları JSON\'dan aynen geri gelir', () {
      final lines = [
        [
          const OcrWordBox('Merhaba', Rect.fromLTRB(1, 2, 30, 12)),
          const OcrWordBox('dünya', Rect.fromLTRB(34, 2, 60, 12)),
        ],
        [const OcrWordBox('2', Rect.fromLTRB(1, 20, 8, 30))],
      ];
      final back = PdfPageOcr.decodeWordLines(
        PdfPageOcr.encodeWordLines(lines),
      );
      expect(back, hasLength(2));
      expect(back.first.last.text, 'dünya');
      expect(back.first.last.box, const Rect.fromLTRB(34, 2, 60, 12));
      expect(PdfPageOcr.decodeWordLines('bozuk'), isEmpty);
    });

    test('dosya adı kaynağa, damgaya ve sayfaya bağlı', () {
      String name({String stamp = '1', int page = 1}) => PdfPageOcr.diskName(
        source: '/a/b.pdf',
        stamp: stamp,
        pageNumber: page,
        width: 595,
        height: 842,
      );
      expect(name(), name());
      expect(name(), isNot(name(stamp: '2')));
      expect(name(), isNot(name(page: 2)));
      expect(name(), endsWith('.json'));
    });
  });

  group('paylaşım', () {
    const video = Attachment(
      id: 'y',
      kind: AttachmentKind.video,
      fileName: 'Ders 1',
      mimeType: 'video/youtube',
      webUrl: 'https://youtu.be/dQw4w9WgXcQ',
    );
    final note = Note(
      id: 'n',
      type: NoteType.text,
      title: 'Başlık',
      body: '1:23 önemli',
      items: const [
        NoteItem(id: 'i1', text: 'açık'),
        NoteItem(id: 'i2', text: 'bitti', checked: true),
      ],
      tags: const ['iş'],
      attachments: const [video],
    );

    test('seçenekler saklanır ve geri okunur', () {
      const options = ShareTextOptions(
        title: false,
        tags: true,
        links: false,
      );
      final back = ShareTextOptions.decode(options.encode());
      expect(back.title, isFalse);
      expect(back.checked, isTrue);
      expect(back.tags, isTrue);
      expect(back.links, isFalse);
      expect(ShareTextOptions.decode(null).links, isTrue);
      expect(ShareTextOptions.decode('x').title, isTrue);
    });

    test('video bağlantıları metnin sonunda (seçenekle)', () {
      final text = noteShareText(note);
      expect(text, contains('▶ Ders 1\nhttps://youtu.be/dQw4w9WgXcQ'));
      final without = noteShareText(
        note,
        options: const ShareTextOptions(links: false),
      );
      expect(without, isNot(contains('youtu.be')));
    });

    test('hızlı PDF içeriği çiplere uyar', () {
      final all = NoteQuickExport.contentOf(
        note,
        const ShareTextOptions(tags: true),
      );
      expect(all, contains('[ ] açık'));
      expect(all, contains('[x] bitti'));
      expect(all, contains('#iş'));
      expect(all, contains('https://youtu.be/dQw4w9WgXcQ'));
      final open = NoteQuickExport.contentOf(
        note,
        const ShareTextOptions(checked: false, links: false),
      );
      expect(open, isNot(contains('bitti')));
      expect(open, isNot(contains('youtu.be')));
    });

    test('dosya olarak paylaşılacak ekler YouTube ve arka planı dışlar', () {
      const image = Attachment(
        id: 'img',
        kind: AttachmentKind.image,
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
      );
      const bg = Attachment(
        id: 'bg',
        kind: AttachmentKind.image,
        fileName: 'bg.jpg',
        mimeType: 'image/jpeg',
      );
      final n = Note(
        id: 'n',
        type: NoteType.text,
        attachments: const [video, image, bg],
        backgroundImageId: 'bg',
      );
      expect(shareableAttachments(n).map((a) => a.id), ['img']);
    });
  });

  group('tembel ana ekran ızgarası', () {
    final notes = [
      for (var i = 0; i < 120; i++)
        Note(id: 'n$i', type: NoteType.text, body: 'gövde $i'),
    ];

    test('sütun ataması eski (eager) ızgarayla aynı ve her kart bir kez', () {
      final buckets = balancedColumnAssignment(notes, 3, 120);
      final all = [for (final b in buckets) ...b]..sort();
      expect(all, [for (var i = 0; i < notes.length; i++) i]);
      expect(buckets.first.first, 0);
    });

    testWidgets('yalnız görünen kartlar kurulur', (tester) async {
      var built = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                sliverBalancedNoteColumns(
                  items: notes,
                  columns: 2,
                  cellWidth: 200,
                  cell: (context, index) {
                    built++;
                    return SizedBox(
                      height: 120,
                      child: Text('kart${notes[index].id}'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('kartn0'), findsOneWidget);
      expect(find.text('kartn1'), findsOneWidget);
      // 120 kartın hepsi DEĞİL — görünen + kaydırma payı.
      expect(built, lessThan(40));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await tester.pumpAndSettle();
      expect(find.text('kartn0'), findsNothing);
    });
  });
}

class _FakeSource extends VideoTimeSource {
  _FakeSource(this.attachmentId);

  @override
  final String attachmentId;

  final calls = <String>[];
  final _changes = ValueNotifier<int>(0);
  bool _playing = false;
  double _speed = 1;

  @override
  Listenable get changes => _changes;

  @override
  bool get isPlaying => _playing;

  @override
  Duration? get lastPosition => const Duration(seconds: 83);

  @override
  Duration? get duration => const Duration(minutes: 4);

  @override
  double get speed => _speed;

  @override
  Future<Duration?> position() async => lastPosition;

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<void> play() async {
    calls.add('play');
    _playing = true;
    _changes.value++;
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    _playing = false;
    _changes.value++;
  }

  @override
  Future<void> seekBy(Duration delta) async =>
      calls.add('seek ${delta.inSeconds}');

  @override
  Future<void> setSpeed(double value) async {
    calls.add('speed $value');
    _speed = value;
    _changes.value++;
  }
}
