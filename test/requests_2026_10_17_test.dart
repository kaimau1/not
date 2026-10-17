import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/media_transcriber.dart';
import 'package:notlar/features/notes/data/notes_repository.dart'
    show attachmentsDigest;
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card_media.dart';
import 'package:notlar/features/notes/presentation/viewers/transcript_screen.dart';
import 'package:notlar/features/notes/domain/transcript.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

/// 2026-10-17 istekleri: ses/video/görsel TRANSKRİPTİ (metin eki, okuma,
/// seçip nota ekleme) ve ses dosyası biçim tespiti.
void main() {
  const audio = Attachment(
    id: 'a1',
    kind: AttachmentKind.audio,
    fileName: 'kayit_12s.m4a',
    mimeType: 'audio/mp4',
  );

  group('Transcripts', () {
    test('yalnız ses, video ve görsel metne dökülür', () {
      expect(Transcripts.canTranscribe(audio), isTrue);
      for (final kind in [AttachmentKind.video, AttachmentKind.image]) {
        expect(
          Transcripts.canTranscribe(
            Attachment(id: 'x', kind: kind, fileName: 'f', mimeType: ''),
          ),
          isTrue,
        );
      }
      for (final kind in [
        AttachmentKind.pdf,
        AttachmentKind.slide,
        AttachmentKind.text,
      ]) {
        expect(
          Transcripts.canTranscribe(
            Attachment(id: 'x', kind: kind, fileName: 'f', mimeType: ''),
          ),
          isFalse,
        );
      }
    });

    test('yeni transkript kaynağa bağlı metin ekidir', () {
      final t = Transcripts.create(
        audio,
        '  [0:00] Merhaba  ',
        fileSuffix: 'transkript',
      );
      expect(t.kind, AttachmentKind.text);
      expect(t.transcriptOf, 'a1');
      expect(t.text, '[0:00] Merhaba');
      expect(t.fileName, 'kayit_12s (transkript).txt');
      expect(t.mimeType, 'text/plain');
      expect(t.sizeBytes, '[0:00] Merhaba'.length);
      // Metin eki dosyasız: kuyruk atlar, "senkronlanmadı" çarkı dönmez.
      expect(t.skipsUpload, isTrue);
      expect(t.isSynced, isTrue);
      expect(t.floatsOnPage, isFalse);
    });

    test('Türkçe karakterler UTF-8 bayt olarak sayılır', () {
      final t = Transcripts.create(audio, 'ığş', fileSuffix: 't');
      expect(t.sizeBytes, 6);
    });

    test('kayıtlı transkript bulunur, en yenisi seçilir', () {
      final older = Transcripts.create(
        audio,
        'eski',
        fileSuffix: 't',
      ).copyWith();
      final newer = Attachment(
        id: 'n',
        kind: AttachmentKind.text,
        fileName: 'n.txt',
        mimeType: 'text/plain',
        text: 'yeni',
        transcriptOf: 'a1',
        createdAt: DateTime.now().add(const Duration(minutes: 1)),
      );
      expect(Transcripts.of([audio, older, newer], audio)?.text, 'yeni');
      const other = Attachment(
        id: 'b',
        kind: AttachmentKind.audio,
        fileName: 'b.m4a',
        mimeType: 'audio/mp4',
      );
      expect(Transcripts.of([audio, older, newer], other), isNull);
    });

    test('tavanı aşan metin kesilir ve "…" ile biter', () {
      final long = 'a' * (Attachment.maxTextChars + 50);
      final clamped = Transcripts.clamp(long);
      expect(clamped.length, Attachment.maxTextChars + 1);
      expect(clamped.endsWith('…'), isTrue);
    });

    test('zaman damgaları tanınır, atılır ve düz biçime çevrilir', () {
      const text = '[0:00] Merhaba\n[1:02:03] Sonra\nDamga yok 4:05';
      expect(Transcripts.hasTimestamps(text), isTrue);
      expect(Transcripts.hasTimestamps('Damga yok 4:05'), isFalse);
      expect(
        Transcripts.stripTimestamps(text),
        'Merhaba\nSonra\nDamga yok 4:05',
      );
      expect(
        Transcripts.plainTimestamps(text),
        '0:00 Merhaba\n1:02:03 Sonra\nDamga yok 4:05',
      );
    });

    test('dosya adı yol ayırıcısı taşımaz', () {
      const web = Attachment(
        id: 'y',
        kind: AttachmentKind.video,
        fileName: 'Ders 1/2: Giriş',
        mimeType: 'video/mp4',
        webUrl: 'https://www.youtube.com/watch?v=abc',
      );
      expect(
        Transcripts.fileNameFor(web, 'transkript'),
        'Ders 1_2_ Giriş (transkript).txt',
      );
    });
  });

  group('Attachment metin alanları', () {
    test('toMap/fromMap metni ve kaynağı korur', () {
      final t = Transcripts.create(audio, 'metin', fileSuffix: 't');
      final map = t.toMap()..remove('createdAt');
      expect(map['kind'], 'text');
      expect(map['text'], 'metin');
      expect(map['transcriptOf'], 'a1');
      final back = Attachment.fromMap(map);
      expect(back.kind, AttachmentKind.text);
      expect(back.text, 'metin');
      expect(back.transcriptOf, 'a1');
    });

    test('öbür eklerin şeması büyümez', () {
      final map = audio.toMap();
      expect(map.containsKey('text'), isFalse);
      expect(map.containsKey('transcriptOf'), isFalse);
    });
  });

  group('audioMimeOf', () {
    List<int> ascii(String s) => s.codeUnits;

    test('Google sesli girişinin AMR kaydı tanınır', () {
      expect(audioMimeOf(ascii('#!AMR\n....'), 'audio/mp4'), 'audio/amr');
    });

    test('yaygın biçimler baytlardan', () {
      expect(audioMimeOf(ascii('....ftypM4A '), ''), 'audio/mp4');
      expect(audioMimeOf(ascii('ID3....'), ''), 'audio/mpeg');
      expect(audioMimeOf([0xFF, 0xFB, 0x90], ''), 'audio/mpeg');
      expect(audioMimeOf([0xFF, 0xF1, 0x50], ''), 'audio/aac');
      expect(audioMimeOf(ascii('RIFF....WAVEfmt '), ''), 'audio/wav');
      expect(audioMimeOf(ascii('OggS....'), ''), 'audio/ogg');
      expect(audioMimeOf(ascii('fLaC....'), ''), 'audio/flac');
      expect(audioMimeOf([0x1A, 0x45, 0xDF, 0xA3], ''), 'audio/webm');
    });

    test('tanınmayan baytta bildirilen tür', () {
      expect(audioMimeOf([1, 2, 3], 'audio/x-test'), 'audio/x-test');
      expect(audioMimeOf(const [], ''), 'audio/mp4');
    });

    test('dosya adından tür', () {
      expect(audioMimeFromName('Toplanti.MP3'), 'audio/mpeg');
      expect(audioMimeFromName('a.wav'), 'audio/wav');
      expect(audioMimeFromName('a.opus'), 'audio/opus');
      expect(audioMimeFromName('a.m4a'), 'audio/mp4');
    });
  });

  test('kart transkript sayısını gösterir', () {
    final note = Note(
      id: 'n',
      type: NoteType.text,
      attachments: [
        audio,
        Transcripts.create(audio, 'x', fileSuffix: 't'),
      ],
    );
    final plan = CardMediaPlan.of(note);
    expect(plan.audioCount, 1);
    expect(plan.transcriptCount, 1);
    expect(plan.isEmpty, isFalse);
  });

  group('TranscriptScreen', () {
    Future<void> pump(
      WidgetTester tester, {
      required Attachment transcript,
      ValueChanged<String>? onInsert,
      TranscriptSave? onSave,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            home: TranscriptScreen(
              source: audio,
              transcript: transcript,
              onInsert: onInsert,
              onSave: onSave,
              onCreateNote: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('kayıtlı metin okunur; "Tümünü nota ekle" düz damgayla ekler', (
      tester,
    ) async {
      final t = Transcripts.create(
        audio,
        '[0:00] Merhaba dünya\n[0:15] İkinci paragraf',
        fileSuffix: 'transkript',
      );
      String? inserted;
      await pump(tester, transcript: t, onInsert: (s) => inserted = s);
      expect(find.textContaining('Merhaba dünya'), findsOneWidget);
      expect(find.text('Tümünü nota ekle'), findsOneWidget);
      await tester.tap(find.text('Tümünü nota ekle'));
      await tester.pump();
      expect(inserted, '0:00 Merhaba dünya\n0:15 İkinci paragraf');
      // Yeniden döküm başlamaz (AI çağrılmaz): metin kayıtlıydı.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('düzenlenen metin kaydedilir', (tester) async {
      final t = Transcripts.create(audio, 'yanlis sozcuk', fileSuffix: 't');
      Attachment? saved;
      await pump(
        tester,
        transcript: t,
        onInsert: (_) {},
        onSave: (text, current) =>
            saved = Transcripts.withText(current ?? t, text),
      );
      await tester.tap(find.byTooltip('Diğer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Düzenle'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'doğru sözcük');
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();
      expect(saved?.text, 'doğru sözcük');
      expect(saved?.id, t.id);
      expect(find.textContaining('doğru sözcük'), findsOneWidget);
    });
  });

  group('attachmentsDigest (değişmeyen ek listesi yazılmaz)', () {
    List<Map<String, dynamic>> maps(String text) => [
      {
        ...Transcripts.create(audio, text, fileSuffix: 't').toMap(),
        'createdAt': Timestamp(100, 5),
      },
    ];

    test('aynı içerik aynı özet, yeni liste örneği olsa da', () {
      final a = maps('bir');
      final b = [
        for (final m in a) {...m},
      ];
      expect(identical(a, b), isFalse);
      expect(attachmentsDigest(a), attachmentsDigest(b));
    });

    test('içerik değişince özet değişir', () {
      final a = maps('bir');
      final b = [
        {...a.first, 'text': 'iki'},
      ];
      expect(attachmentsDigest(a), isNot(attachmentsDigest(b)));
      final c = [
        {...a.first, 'createdAt': Timestamp(100, 6)},
      ];
      expect(attachmentsDigest(a), isNot(attachmentsDigest(c)));
    });

    test('boş ve eksik liste de özetlenir', () {
      expect(attachmentsDigest(null), isNotEmpty);
      expect(attachmentsDigest(const []), isNot(attachmentsDigest(null)));
    });
  });
}
