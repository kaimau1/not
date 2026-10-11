import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/youtube.dart';
import 'package:notlar/features/notes/data/note_package.dart';
import 'package:notlar/features/notes/data/web_video.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/pinned_media_pane.dart';
import 'package:notlar/l10n/generated/app_localizations.dart';

void main() {
  group('youTubeVideoId', () {
    test('yaygın biçimler tanınır', () {
      const id = 'dQw4w9WgXcQ';
      for (final url in [
        'https://www.youtube.com/watch?v=$id',
        'https://youtube.com/watch?v=$id&list=PL123&index=2',
        'https://m.youtube.com/watch?v=$id',
        'https://music.youtube.com/watch?v=$id',
        'https://youtu.be/$id',
        'https://youtu.be/$id?si=AbCdEf',
        'youtu.be/$id',
        'https://www.youtube.com/shorts/$id',
        'https://www.youtube.com/live/$id?feature=share',
        'https://www.youtube.com/embed/$id',
        'https://www.youtube-nocookie.com/embed/$id',
      ]) {
        expect(youTubeVideoId(url), id, reason: url);
      }
    });

    test('video olmayan bağlantılar null', () {
      for (final url in [
        '',
        'https://www.youtube.com/',
        'https://www.youtube.com/@kanal',
        'https://www.youtube.com/playlist?list=PL123',
        'https://www.youtube.com/watch?v=kisa',
        'https://example.com/watch?v=dQw4w9WgXcQ',
        'https://notyoutube.com/watch?v=dQw4w9WgXcQ',
      ]) {
        expect(youTubeVideoId(url), isNull, reason: url);
      }
    });

    test('metindeki ilk video bağlantısı bulunur (noktalama atılır)', () {
      expect(
        firstYouTubeUrl('Şuna bak: https://youtu.be/dQw4w9WgXcQ.'),
        'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(
        firstYouTubeUrl(
          'kanal https://www.youtube.com/@x ve video '
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
      expect(firstYouTubeUrl('bağlantı yok'), isNull);
    });

    test('başlangıç saniyesi okunur', () {
      expect(youTubeStartSeconds('https://youtu.be/dQw4w9WgXcQ?t=90'), 90);
      expect(youTubeStartSeconds('https://youtu.be/dQw4w9WgXcQ?t=90s'), 90);
      expect(
        youTubeStartSeconds('https://youtube.com/watch?v=dQw4w9WgXcQ&t=1m30s'),
        90,
      );
      expect(youTubeStartSeconds('https://youtu.be/dQw4w9WgXcQ'), 0);
    });

    test('gömülü sayfa uygulama kökenini bildirir (Hata 153)', () {
      final html = youTubeEmbedHtml('dQw4w9WgXcQ', start: 12);
      expect(html, contains('/embed/dQw4w9WgXcQ?'));
      expect(
        html,
        contains('origin=${Uri.encodeQueryComponent(youTubeEmbedOrigin)}'),
      );
      expect(html, contains('start=12'));
      expect(html, contains('playsinline=1'));
    });
  });

  group('YouTube eki', () {
    test('bağlantıdan dosyasız video eki kurulur', () {
      final a = webVideoAttachment(
        'https://youtu.be/dQw4w9WgXcQ?si=izleme&t=42',
        title: 'Başlık',
      )!;
      expect(a.kind, AttachmentKind.video);
      expect(a.isWebVideo, isTrue);
      expect(a.fileName, 'Başlık');
      // İzleme parametresi atılır, başlangıç korunur.
      expect(a.webUrl, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=42');
      expect(a.isUploaded, isFalse);
      expect(a.floatsOnPage, isTrue);
      expect(webVideoAttachment('https://example.com'), isNull);
    });

    test('alanlar senkron kaydında ve not paketinde korunur', () {
      final a = webVideoAttachment(
        'https://youtu.be/dQw4w9WgXcQ',
      )!.copyWith(pinHeight: 220);
      final map = a.toMap();
      expect(map['webUrl'], a.webUrl);
      expect(map['pinHeight'], 220);
      final back = Attachment.fromMap(map);
      expect(back.webUrl, a.webUrl);
      expect(back.pinHeight, 220);

      final note = Note(id: 'n', type: NoteType.text, attachments: [a]);
      final decoded = decodeNoteJson(encodeNoteJson(note));
      expect(decoded.attachments.single.webUrl, a.webUrl);
      expect(decoded.attachments.single.pinHeight, 220);
    });

    test('dosyalı eklerin kaydı büyümez', () {
      const a = Attachment(
        id: 'g',
        kind: AttachmentKind.image,
        fileName: 'g.jpg',
        mimeType: 'image/jpeg',
      );
      final map = a.toMap();
      expect(map.containsKey('webUrl'), isFalse);
      expect(map.containsKey('pinHeight'), isFalse);
    });
  });

  group('üste sabitli medya', () {
    const image = Attachment(
      id: 'g',
      kind: AttachmentKind.image,
      fileName: 'g.jpg',
      mimeType: 'image/jpeg',
      width: 1000,
      height: 500,
    );

    test('sabitli medya sayfada yüzmez', () {
      expect(image.floatsOnPage, isTrue);
      final pinned = image.copyWith(pinHeight: 200);
      expect(pinned.isPinnedTop, isTrue);
      expect(pinned.floatsOnPage, isFalse);
      // Sayfaya geri: 0.
      expect(pinned.copyWith(pinHeight: 0).floatsOnPage, isTrue);
    });

    test('sabitten çıkınca bölme yüksekliği ve sayfadaki yer hatırlanır', () {
      final placed = image.copyWith(x: 0.4, pageY: 120, displayWidth: 0.5);
      final pinned = placed.copyWith(pinHeight: 260);
      // Sabitlemeden çık: işaret döner, yer/genişlik dokunulmadan kalır.
      final released = pinned.copyWith(pinHeight: -pinned.pinHeight);
      expect(released.isPinnedTop, isFalse);
      expect(released.floatsOnPage, isTrue);
      expect(released.rememberedPinHeight, 260);
      expect(released.x, 0.4);
      expect(released.pageY, 120);
      expect(released.displayWidth, 0.5);
      // Kayıtta da kalır (cihazlar arası).
      final back = Attachment.fromMap(released.toMap()..remove('createdAt'));
      expect(back.rememberedPinHeight, 260);
      expect(back.isPinnedTop, isFalse);
      expect(image.rememberedPinHeight, isNull);
    });

    test('PDF/ses sabitlenmiş sayılmaz', () {
      const pdf = Attachment(
        id: 'p',
        kind: AttachmentKind.pdf,
        fileName: 'a.pdf',
        mimeType: 'application/pdf',
        pinHeight: 200,
      );
      expect(pdf.isPinnedTop, isFalse);
    });

    test('ilk yükseklik medyanın oranından, ekranın %45inde tavan', () {
      const screen = Size(400, 800);
      expect(defaultPinnedHeight(image, screen), 200);
      final tall = image.copyWith(width: 500, height: 1000);
      expect(defaultPinnedHeight(tall, screen), 360);
      final video = webVideoAttachment('https://youtu.be/dQw4w9WgXcQ')!;
      expect(defaultPinnedHeight(video, screen), closeTo(225, 0.01));
    });

    testWidgets('bölme medyayı üstte, notu altta çizer; ayraç boyutlar', (
      tester,
    ) async {
      double? saved;
      var unpinned = false;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('tr'),
          home: Scaffold(
            body: PinnedMediaPane(
              media: image.copyWith(pinHeight: 200),
              onHeightChanged: (h) => saved = h,
              onUnpin: () => unpinned = true,
              onOpen: () {},
              child: const Text('not gövdesi'),
            ),
          ),
        ),
      );
      final body = tester.getTopLeft(find.text('not gövdesi'));
      expect(body.dy, greaterThanOrEqualTo(200));

      // Ayraç tutamacını 60 dp aşağı çek: yükseklik kaydedilir.
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('pinned-media-bar'))),
        const Offset(0, 60),
      );
      await tester.pumpAndSettle();
      expect(saved, isNotNull);
      expect(saved!, greaterThan(240));
      expect(unpinned, isFalse);

      // En üste çekip bırakmak sayfaya geri koyar.
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('pinned-media-bar'))),
        const Offset(0, -200),
      );
      await tester.pumpAndSettle();
      expect(unpinned, isTrue);
    });
  });
}
