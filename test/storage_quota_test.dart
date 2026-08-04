import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/constants.dart';
import 'package:notlar/core/utils/format_bytes.dart';
import 'package:notlar/features/notes/data/attachment_repository.dart';
import 'package:notlar/features/notes/data/notes_repository.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

Note _note(String id, List<Attachment> attachments) =>
    Note(id: id, type: NoteType.text, attachments: attachments);

Attachment _file(AttachmentKind kind, int bytes) => Attachment(
  id: '$kind-$bytes',
  kind: kind,
  fileName: 'a',
  mimeType: 'application/octet-stream',
  sizeBytes: bytes,
);

void main() {
  group('cloudAttachmentBytes', () {
    test('tüm notların eklerini toplar', () {
      final notes = [
        _note('1', [_file(AttachmentKind.image, 100)]),
        _note('2', [
          _file(AttachmentKind.pdf, 250),
          _file(AttachmentKind.audio, 50),
        ]),
      ];
      expect(cloudAttachmentBytes(notes), 400);
    });

    test('görüntülü not sayılmaz — buluta hiç yüklenmiyor', () {
      final notes = [
        _note('1', [
          _file(AttachmentKind.image, 100),
          _file(AttachmentKind.video, 900),
        ]),
      ];
      expect(cloudAttachmentBytes(notes), 100);
    });

    test('eksiz notlarda sıfır', () {
      expect(cloudAttachmentBytes([_note('1', const [])]), 0);
      expect(cloudAttachmentBytes(const []), 0);
    });
  });

  group('storageQuotaExceeded', () {
    test('tavanın altında kalan yükleme geçer', () {
      expect(
        storageQuotaExceeded(used: 40, incoming: 10, quota: 100),
        isFalse,
      );
    });

    test('tavana TAM oturan yükleme geçer', () {
      expect(
        storageQuotaExceeded(used: 90, incoming: 10, quota: 100),
        isFalse,
      );
    });

    test('tavanı bir bayt aşan yükleme durur', () {
      expect(storageQuotaExceeded(used: 90, incoming: 11, quota: 100), isTrue);
    });

    test('tavan 0 ise sınır yok', () {
      expect(
        storageQuotaExceeded(used: 10000, incoming: 10000, quota: 0),
        isFalse,
      );
    });

    // Kırpma: yeni dosya eskisinin yerini alıyor, fark eksi olabiliyor.
    // Bu düşülmezse tavana dayanmış kullanıcı görselini KIRPAMAZ.
    test('yerini aldığı ek düşüldüğünde tavandaki dosya küçültülebilir', () {
      expect(
        storageQuotaExceeded(used: 100, incoming: 30 - 50, quota: 100),
        isFalse,
      );
    });

    test('ücretsiz tavan premium tavanından küçük', () {
      expect(
        AppConstants.maxFreeStorageBytes,
        lessThan(AppConstants.maxPremiumStorageBytes),
      );
      // Tek dosya sınırı toplam tavanı aşamaz, yoksa ilk ek daha yüklenirken
      // reddedilirdi.
      expect(
        AppConstants.maxFreeAttachmentBytes,
        lessThanOrEqualTo(AppConstants.maxFreeStorageBytes),
      );
      expect(
        AppConstants.maxPremiumAttachmentBytes,
        lessThanOrEqualTo(AppConstants.maxPremiumStorageBytes),
      );
    });
  });

  group('formatBytes', () {
    test('yuvarlak değerlerde ondalık yazılmaz', () {
      expect(formatBytes(AppConstants.maxFreeStorageBytes), '50 MB');
      expect(formatBytes(AppConstants.maxPremiumStorageBytes), '2 GB');
    });

    test('ondalık virgülle yazılır', () {
      expect(formatBytes((1.5 * 1024 * 1024).round()), '1,5 MB');
    });

    test('küçük dosyalar KB', () {
      expect(formatBytes(2048), '2 KB');
      expect(formatBytes(0), '0 KB');
    });
  });
}
