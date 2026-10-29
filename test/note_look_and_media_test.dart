import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/app/note_open_route.dart';
import 'package:notlar/app/theme/note_colors.dart';
import 'package:notlar/app/theme/note_themes.dart';
import 'package:notlar/core/widgets/scale_settle.dart';
import 'package:notlar/features/notes/data/note_shortcut.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/audio_card_box.dart';
import 'package:notlar/features/notes/presentation/editor/voice_note_recorder.dart';

/// 2026-10-28 görünüm/medya turu: görsel açıklaması, ses dalgası, not
/// teması, ana ekran kısayolu harfi, yumuşak boyut geçişi ve karttan
/// genişleyen not açılışı.
/// Sunucu zaman damgası yer tutucuları (`FieldValue`) okuma yolunda yok.
Map<String, dynamic> _plain(Map<String, dynamic> map) =>
    {...map}..removeWhere((_, v) => v is FieldValue);

void main() {
  group('Attachment açıklama ve dalga', () {
    test('açıklama ve dalga kayıtta gidip gelir, boşken yazılmaz', () {
      const a = Attachment(
        id: 'img1',
        kind: AttachmentKind.image,
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
        caption: 'Annemin içli köftesi',
      );
      final map = _plain(a.toMap());
      expect(map['caption'], 'Annemin içli köftesi');
      expect(map.containsKey('wave'), isFalse);
      expect(Attachment.fromMap(map).caption, 'Annemin içli köftesi');

      const audio = Attachment(
        id: 'au1',
        kind: AttachmentKind.audio,
        fileName: 'kayit_4s.m4a',
        mimeType: 'audio/mp4',
        wave: [0, 50, 100],
      );
      final back = Attachment.fromMap(_plain(audio.toMap()));
      expect(back.wave, [0, 50, 100]);
      expect(back.toMap().containsKey('caption'), isFalse);
      // Açıklama silinebilir (boş dize alanı düşürür).
      expect(a.copyWith(caption: '').toMap().containsKey('caption'), isFalse);
    });

    test('yerel açıklama gelen eski yankıya karşı korunur', () {
      const remote = Attachment(
        id: 'i',
        kind: AttachmentKind.image,
        fileName: 'a.jpg',
        mimeType: 'image/jpeg',
        caption: 'eski',
      );
      final mine = remote.copyWith(caption: 'yeni yazılan');
      expect(remote.withLayoutOf(mine).caption, 'yeni yazılan');
    });

    test('compactWave sabit sayıda çubuğa tepe değerle indirger', () {
      final levels = [for (var i = 0; i < 500; i++) i == 250 ? 1.0 : 0.1];
      final wave = Attachment.compactWave(levels);
      expect(wave, hasLength(Attachment.waveBars));
      expect(wave.reduce((a, b) => a > b ? a : b), 100);
      expect(wave.where((v) => v == 100), hasLength(1));
      expect(Attachment.compactWave(const []), isEmpty);
      // Kısa kayıt (çubuktan az örnek) da tam sayıda çubuk verir.
      expect(Attachment.compactWave(const [0.5, 0.2]), hasLength(48));
    });

    test('dalgasız ses kimliğe bağlı kararlı desen çizer', () {
      const a = Attachment(
        id: 'kimlik-1',
        kind: AttachmentKind.audio,
        fileName: 'ders.mp3',
        mimeType: 'audio/mpeg',
      );
      expect(a.displayWave, hasLength(Attachment.waveBars));
      expect(a.displayWave, a.displayWave);
      expect(a.displayWave.every((v) => v >= 8 && v <= 100), isTrue);
    });

    test('kayıt süresi dosya adından okunur', () {
      const a = Attachment(
        id: 'x',
        kind: AttachmentKind.audio,
        fileName: 'kayit_12s.m4a',
        mimeType: 'audio/mp4',
      );
      expect(recordedDuration(a), const Duration(seconds: 12));
      expect(isVoiceRecording(a), isTrue);
      expect(
        recordedDuration(a.copyWith(fileName: 'ders.mp3')),
        isNull,
      );
      expect(formatClock(const Duration(seconds: 64)), '01:04');
      expect(formatClock(const Duration(hours: 1, seconds: 3)), '1:00:03');
    });

    test('genlik dB → 0–1', () {
      expect(VoiceNoteRecorder.levelOfDb(-160), 0);
      expect(VoiceNoteRecorder.levelOfDb(0), 1);
      expect(VoiceNoteRecorder.levelOfDb(double.nan), 0);
      final quiet = VoiceNoteRecorder.levelOfDb(-40);
      final loud = VoiceNoteRecorder.levelOfDb(-12);
      expect(quiet, greaterThan(0));
      expect(loud, greaterThan(quiet));
    });
  });

  group('Not teması', () {
    test('tema kayıtta gidip gelir ve KOŞULSUZ yazılır', () {
      const note = Note(id: 'n', type: NoteType.text, theme: NoteThemes.palm);
      expect(note.toMap()['theme'], 'palm');
      expect(Note.fromMap('n', _plain(note.toMap())).theme, 'palm');
      // Kaldırılan tema '' olarak yazılır (merge yazımında eski kalmasın).
      expect(note.copyWith(theme: '').toMap()['theme'], '');
      expect(Note.fromMap('n', const {'type': 'text'}).theme, '');
    });

    test('bilinmeyen tema kimliği zeminsiz çizilir', () {
      expect(NoteThemes.byId('uzay-2030'), isNull);
      expect(NoteThemes.byId(''), isNull);
      for (final t in NoteThemes.all) {
        expect(NoteThemes.byId(t.id), same(t));
      }
    });

    testWidgets('notun düz zemini temanın alt tonu', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        ),
      );
      const themed = Note(
        id: 'n',
        type: NoteType.text,
        color: NoteColor.red,
        theme: NoteThemes.lagoon,
      );
      expect(
        NoteColors.noteSurface(ctx, themed),
        NoteThemes.byId(NoteThemes.lagoon)!.light.base,
      );
      // Tema kalkınca renk geri gelir.
      expect(
        NoteColors.noteSurface(ctx, themed.copyWith(theme: '')),
        NoteColors.surface(ctx, NoteColor.red),
      );
    });

    testWidgets('her tema açık ve koyu çizilir', (tester) async {
      for (final dark in [false, true]) {
        for (final t in NoteThemes.all) {
          await tester.pumpWidget(
            Directionality(
              textDirection: TextDirection.ltr,
              child: CustomPaint(
                size: const Size(360, 640),
                painter: NoteThemePainter(t, dark: dark),
              ),
            ),
          );
        }
      }
      expect(tester.takeException(), isNull);
    });
  });

  test('kısayol simgesinin harfi başlıktan, yoksa gövdeden', () {
    expect(NoteShortcut.glyphOf('alışveriş', ''), 'A');
    expect(NoteShortcut.glyphOf('  ', '**ılık** süt'), 'I');
    expect(NoteShortcut.glyphOf('', ''), 'N');
  });

  testWidgets('yazı ölçeği değişince içerik yumuşakça oturur', (tester) async {
    Widget at(double v) => Directionality(
      textDirection: TextDirection.ltr,
      child: ScaleSettle(value: v, child: const SizedBox(width: 10, height: 10)),
    );
    await tester.pumpWidget(at(1));
    // Transform.scale z eksenini 1 bırakır: x ölçeği okunur.
    double scale() =>
        tester.widget<Transform>(find.byType(Transform)).transform.storage[0];
    expect(scale(), 1);
    await tester.pumpWidget(at(1.2));
    // Büyüyen yazı eski boyundan (1/1.2) başlar ve 1'e oturur.
    expect(scale(), closeTo(1 / 1.2, 0.01));
    await tester.pump(const Duration(milliseconds: 120));
    expect(scale(), greaterThan(1 / 1.2));
    expect(scale(), lessThan(1));
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });

  testWidgets('not karttan genişleyerek açılır, kapanınca karta döner', (
    tester,
  ) async {
    final cardKey = GlobalKey();
    final pages = ValueNotifier<List<Page<void>>>([]);
    late BuildContext cardContext;
    Page<void> home() => MaterialPage(
      key: const ValueKey('home'),
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Builder(
              builder: (context) {
                cardContext = context;
                return SizedBox(key: cardKey, width: 150, height: 120);
              },
            ),
          ),
        ),
      ),
    );
    pages.value = [home()];
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<List<Page<void>>>(
          valueListenable: pages,
          builder: (context, list, _) => Navigator(
            pages: list,
            onDidRemovePage: (page) => pages.value = [
              for (final p in pages.value)
                if (p != page) p,
            ],
          ),
        ),
      ),
    );
    NoteOpenOrigin.register(cardContext, 'n1', color: Colors.amber);
    pages.value = [
      ...pages.value,
      const NoteOpenPage<void>(
        key: ValueKey('note'),
        noteId: 'n1',
        child: Scaffold(body: Text('editör')),
      ),
    ];
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    // Yarı yolda: sayfa küçültülmüş (kartın genişliğinden büyüyor).
    final midScale = tester
        .widgetList<Transform>(
          find.ancestor(of: find.text('editör'), matching: find.byType(Transform)),
        )
        .map((t) => t.transform.storage[0])
        .reduce((a, b) => a < b ? a : b);
    expect(midScale, lessThan(1));
    await tester.pumpAndSettle();
    expect(find.text('editör'), findsOneWidget);
    // Kayıt bir kez alınır: ikinci açılış karttan değil.
    expect(NoteOpenOrigin.take('n1'), isNull);
    pages.value = [home()];
    await tester.pumpAndSettle();
    expect(find.text('editör'), findsNothing);
  });
}
