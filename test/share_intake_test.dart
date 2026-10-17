import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/share_intake.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

SharedMediaFile _shared(String path, {String? mime, SharedMediaType? type}) =>
    SharedMediaFile(
      path: path,
      type: type ?? SharedMediaType.file,
      mimeType: mime,
    );

void main() {
  group('shareAttachmentKind', () {
    test('uzantısız gelen PDF MIME ile tanınır', () {
      // Asıl hata buydu: Drive/Gmail dosyayı uzantısız adla kopyalatınca
      // uzantıya bakan sürüm dosyayı atlıyor, paylaşım not oluşturmuyordu.
      final f = _shared('/data/cache/Belge', mime: 'application/pdf');
      expect(shareAttachmentKind(f), AttachmentKind.pdf);
    });

    test('MIME yoksa uzantı yedek ölçüt olur', () {
      expect(shareAttachmentKind(_shared('/c/rapor.pdf')), AttachmentKind.pdf);
      expect(
        shareAttachmentKind(_shared('/c/sunum.pptx')),
        AttachmentKind.slide,
      );
    });

    test('sunum MIME ile tanınır', () {
      final f = _shared(
        '/data/cache/Sunum',
        mime:
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      );
      expect(shareAttachmentKind(f), AttachmentKind.slide);
    });

    test('görsel ek kalır', () {
      final f = _shared('/c/foto', mime: 'image/png', type: SharedMediaType.image);
      expect(shareAttachmentKind(f), AttachmentKind.image);
    });

    test('metin, link ve .txt dosyası ek değildir (gövdeye gider)', () {
      expect(shareAttachmentKind(_shared('düz yazı', type: SharedMediaType.text)), isNull);
      expect(shareAttachmentKind(_shared('https://a.b', type: SharedMediaType.url)), isNull);
      expect(
        shareAttachmentKind(_shared('/c/notlar.txt', mime: 'text/plain', type: SharedMediaType.text)),
        isNull,
      );
    });

    test('video ek olur (MIME ya da eklentinin türü ile)', () {
      expect(
        shareAttachmentKind(_shared('/c/klip', mime: 'video/mp4')),
        AttachmentKind.video,
      );
      expect(
        shareAttachmentKind(_shared('/c/klip.mov', type: SharedMediaType.video)),
        AttachmentKind.video,
      );
    });

    test('ses dosyası ek olur (sesli mesaj, kayıt) — MIME ya da uzantı', () {
      expect(
        shareAttachmentKind(_shared('/c/PTT-2026', mime: 'audio/ogg')),
        AttachmentKind.audio,
      );
      expect(
        shareAttachmentKind(_shared('/c/kayit.m4a')),
        AttachmentKind.audio,
      );
      expect(
        shareAttachmentKind(_shared('/c/sesli.opus')),
        AttachmentKind.audio,
      );
    });

    test('YouTube bağlantısı METİN olarak gelir (video ekine sonra çevrilir)', () {
      expect(
        shareAttachmentKind(
          _shared('https://youtu.be/dQw4w9WgXcQ', type: SharedMediaType.text),
        ),
        isNull,
      );
    });
  });
}
