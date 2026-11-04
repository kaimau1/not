import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment_sync.dart';

void main() {
  final t0 = DateTime.utc(2026, 11, 4, 3);

  AttachState uploading() => nextAttachState(
    nextAttachState(const AttachState.local(), const EnqueueUpload()),
    const UploadStarted(),
  );

  group('geçişler', () {
    test('mutlu yol: local → queued → uploading → synced', () {
      var s = const AttachState.local();
      s = nextAttachState(s, const EnqueueUpload());
      expect(s.phase, AttachPhase.queued);
      s = nextAttachState(s, const UploadStarted());
      expect(s.phase, AttachPhase.uploading);
      s = nextAttachState(
        s,
        const UploadSucceeded(
          driveFileId: 'd1',
          thumbPath: 'users/u/thumbs/a.jpg',
        ),
      );
      expect(s.phase, AttachPhase.synced);
      expect(s.driveFileId, 'd1');
      expect(s.isInCloud, isTrue);
    });

    test('hata üstel bekler, tavanda durur, RetryNow atlar', () {
      var s = nextAttachState(uploading(), UploadFailed('ağ', t0));
      expect(s.phase, AttachPhase.failed);
      expect(s.attempts, 1);
      expect(s.nextRetryAt, t0.add(const Duration(minutes: 1)));
      expect(s.wantsUpload(t0), isFalse);
      expect(s.wantsUpload(t0.add(const Duration(minutes: 1))), isTrue);

      s = nextAttachState(
        nextAttachState(s, const UploadStarted()),
        UploadFailed('ağ', t0),
      );
      expect(s.attempts, 2);
      expect(s.nextRetryAt, t0.add(const Duration(minutes: 2)));

      expect(syncRetryDelay(30), kSyncRetryMax);

      s = nextAttachState(s, const RetryNow());
      expect(s.phase, AttachPhase.queued);
      expect(s.nextRetryAt, isNull);
    });

    test('geçersiz olay aynı nesneyi döndürür', () {
      const s = AttachState.local();
      expect(identical(nextAttachState(s, const UploadStarted()), s), isTrue);
      expect(identical(nextAttachState(s, const Downloaded()), s), isTrue);
      final q = nextAttachState(s, const EnqueueUpload());
      expect(
        identical(
          nextAttachState(q, const UploadSucceeded(driveFileId: 'x')),
          q,
        ),
        isTrue,
        reason: 'uploading olmadan başarı sayılmaz',
      );
      expect(
        nextAttachState(
          uploading(),
          const UploadSucceeded(driveFileId: ''),
        ).phase,
        AttachPhase.uploading,
        reason: 'boş Drive kimliği başarı değil',
      );
    });

    test('yerel kopya kaybı: synced → remote, bulutta değilse missing', () {
      final synced = nextAttachState(
        uploading(),
        const UploadSucceeded(driveFileId: 'd'),
      );
      final remote = nextAttachState(synced, const LocalFileLost());
      expect(remote.phase, AttachPhase.remote);
      expect(
        nextAttachState(remote, const Downloaded()).phase,
        AttachPhase.synced,
      );
      expect(
        nextAttachState(const AttachState.local(), const LocalFileLost()).phase,
        AttachPhase.missing,
      );
    });

    test('hesaptan çıkış bekleyeni yerele döndürür, buluttakine dokunmaz', () {
      final failed = nextAttachState(uploading(), UploadFailed('x', t0));
      expect(
        nextAttachState(failed, const AccountUnlinked()).phase,
        AttachPhase.local,
      );
      final synced = nextAttachState(
        uploading(),
        const UploadSucceeded(driveFileId: 'd'),
      );
      expect(
        identical(nextAttachState(synced, const AccountUnlinked()), synced),
        isTrue,
      );
    });
  });

  group('kalıcılık', () {
    test('gidiş-dönüş; uploading kalıcı değil (queued okunur)', () {
      final failed = nextAttachState(uploading(), UploadFailed('ağ', t0));
      expect(AttachState.fromMap(failed.toMap(), hasLocalFile: true), failed);
      expect(
        AttachState.fromMap(uploading().toMap(), hasLocalFile: true).phase,
        AttachPhase.queued,
      );
    });

    test('aynı kayıt: dosyası olan cihazda synced, olmayanda remote', () {
      final m = nextAttachState(
        uploading(),
        const UploadSucceeded(driveFileId: 'd', thumbPath: 'p'),
      ).toMap();
      expect(
        AttachState.fromMap(m, hasLocalFile: true).phase,
        AttachPhase.synced,
      );
      final r = AttachState.fromMap(m, hasLocalFile: false);
      expect(r.phase, AttachPhase.remote);
      expect(r.thumbPath, 'p');
    });

    test('kayıt yok: dosya varsa local, yoksa missing', () {
      expect(
        AttachState.fromMap(null, hasLocalFile: true).phase,
        AttachPhase.local,
      );
      expect(
        AttachState.fromMap(null, hasLocalFile: false).phase,
        AttachPhase.missing,
      );
      expect(
        AttachState.fromMap({'phase': 'queued'}, hasLocalFile: false).phase,
        AttachPhase.missing,
      );
      expect(
        AttachState.fromMap({'phase': 'bilinmeyen'}, hasLocalFile: true).phase,
        AttachPhase.local,
      );
    });
  });

  test('pickUploads: eşzamanlılık tavanı, önce az denenen', () {
    final failedOld = nextAttachState(uploading(), UploadFailed('x', t0));
    final states = {
      'c': failedOld,
      'b': nextAttachState(const AttachState.local(), const EnqueueUpload()),
      'a': nextAttachState(const AttachState.local(), const EnqueueUpload()),
      'u': uploading(),
      'l': const AttachState.local(),
    };
    final later = t0.add(const Duration(hours: 1));
    expect(pickUploads(states, later), ['a']);
    expect(pickUploads(states, later, maxConcurrent: 4), ['a', 'b', 'c']);
    expect(pickUploads(states, t0, maxConcurrent: 4), [
      'a',
      'b',
    ], reason: 'vakti gelmemiş hata seçilmez');
  });

  test('önizleme yolu ve tavanlar', () {
    expect(thumbStoragePath('u1', 'e1'), 'users/u1/thumbs/e1.jpg');
    expect(kThumbMaxBytes, 40 * 1024);
  });
}
