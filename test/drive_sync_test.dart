import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/notes/data/drive_store.dart';
import 'package:notlar/features/notes/data/upload_queue.dart';
import 'package:notlar/features/notes/domain/attachment.dart';

/// EKLERİN GOOGLE DRIVE SENKRONU (kullanıcı isteği 2026-10-15: "eklerin ve
/// görsellerin senkronizasyonu Google Drive'a bağlansın, oradaki kota
/// kullanılsın — Google ile giriş yapanlarda; diğerlerinde sadece metin").
class _FakeAuth implements DriveAuth {
  _FakeAuth(this.tokens);

  final List<String> tokens;
  final invalidated = <String>[];

  @override
  Future<String?> accessToken() async => tokens.isEmpty ? null : tokens.first;

  @override
  Future<bool> connect() async => true;

  @override
  Future<void> invalidate(String token) async {
    invalidated.add(token);
    tokens.remove(token);
  }

  @override
  Future<void> disconnect() async {}
}

void main() {
  group('kip ve hedef', () {
    test('Google hesabı → Drive, misafir → yalnız metin, web → Storage', () {
      expect(
        attachmentSyncModeFor(web: false, googleUser: true),
        AttachmentSyncMode.drive,
      );
      expect(
        attachmentSyncModeFor(web: false, googleUser: false),
        AttachmentSyncMode.textOnly,
      );
      expect(
        attachmentSyncModeFor(web: true, googleUser: true),
        AttachmentSyncMode.storage,
      );
    });

    test('paylaşılan not Storage\'a (ortak çalışan Drive\'ıma erişemez)', () {
      expect(
        uploadTargetFor(
          mode: AttachmentSyncMode.drive,
          localOnly: false,
          shared: false,
        ),
        UploadTarget.drive,
      );
      expect(
        uploadTargetFor(
          mode: AttachmentSyncMode.drive,
          localOnly: false,
          shared: true,
        ),
        UploadTarget.storage,
      );
      // Misafir: hiçbir yer (yalnız metin senkronlanır).
      expect(
        uploadTargetFor(
          mode: AttachmentSyncMode.textOnly,
          localOnly: false,
          shared: false,
        ),
        isNull,
      );
      // Yalnız bu cihazdaki not hiçbir kipte buluta gitmez.
      expect(
        uploadTargetFor(
          mode: AttachmentSyncMode.drive,
          localOnly: true,
          shared: false,
        ),
        isNull,
      );
    });

    test('Drive kimliği kayda yazılır, okunur ve yüklemeyle taşınır', () {
      const a = Attachment(
        id: 'a',
        kind: AttachmentKind.image,
        fileName: 'f.jpg',
        mimeType: 'image/jpeg',
        driveId: 'drv1',
      );
      expect(a.isInDrive, isTrue);
      expect(a.isUploaded, isFalse);
      expect(a.isSynced, isTrue);
      expect(syncedTo(a, UploadTarget.drive), isTrue);
      expect(syncedTo(a, UploadTarget.storage), isFalse);
      final map = Map<String, dynamic>.from(a.toMap())..remove('createdAt');
      expect(map['driveId'], 'drv1');
      expect(Attachment.fromMap(map).driveId, 'drv1');
      // Drive'sız ekin şeması büyümez.
      const plain = Attachment(
        id: 'b',
        kind: AttachmentKind.pdf,
        fileName: 'x.pdf',
        mimeType: 'application/pdf',
      );
      expect(plain.toMap().containsKey('driveId'), isFalse);
      // Yükleme sonucu düzeni ezmeden geçer.
      final moved = plain.copyWith(x: 0.4, pageY: 80);
      final merged = moved.withUploadOf(plain.copyWith(driveId: 'drv2'));
      expect(merged.driveId, 'drv2');
      expect(merged.x, 0.4);
    });
  });

  group('DriveStore', () {
    late Directory dir;
    setUp(() async {
      dir = await Directory.systemTemp.createTemp('drive_test');
    });
    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test(
      'sürdürülebilir yükleme: önce oturum, sonra dosya; kimlik döner',
      () async {
        final requests = <http.BaseRequest>[];
        final client = MockClient.streaming((request, body) async {
          requests.add(request);
          final bytes = await body.toBytes();
          if (request.method == 'POST') {
            expect(request.url.queryParameters['uploadType'], 'resumable');
            expect(request.headers['Authorization'], 'Bearer t1');
            final meta = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
            expect(meta['parents'], ['appDataFolder']);
            expect(meta['name'], 'n_a_f.jpg');
            return http.StreamedResponse(
              const Stream.empty(),
              200,
              headers: {'location': 'https://upload.example/session'},
            );
          }
          expect(request.method, 'PUT');
          expect(request.url.toString(), 'https://upload.example/session');
          expect(utf8.decode(bytes), 'görsel');
          return http.StreamedResponse(
            Stream.value(utf8.encode('{"id":"drv9"}')),
            200,
          );
        });
        final store = DriveStore(_FakeAuth(['t1']), client: client);
        final file = File('${dir.path}/f.jpg')..writeAsStringSync('görsel');
        final id = await store.upload(
          file,
          name: driveFileName(
            noteId: 'n',
            attachmentId: 'a',
            fileName: 'f.jpg',
          ),
          mimeType: 'image/jpeg',
        );
        expect(id, 'drv9');
        expect(requests, hasLength(2));
      },
    );

    test(
      'indirme yerel kopyaya yazılır; 401\'de jeton yenilenip denenir',
      () async {
        final auth = _FakeAuth(['eski', 'yeni']);
        final client = MockClient((request) async {
          expect(request.url.queryParameters['alt'], 'media');
          if (request.headers['Authorization'] == 'Bearer eski') {
            return http.Response('', 401);
          }
          return http.Response.bytes(utf8.encode('pdf-baytları'), 200);
        });
        final store = DriveStore(auth, client: client);
        final target = File('${dir.path}/sub/x.pdf');
        await store.download('drv1', target);
        expect(target.readAsStringSync(), 'pdf-baytları');
        expect(File('${target.path}.part').existsSync(), isFalse);
        expect(auth.invalidated, ['eski']);
      },
    );

    test('jeton yoksa DriveUnavailableException', () async {
      final store = DriveStore(
        _FakeAuth([]),
        client: MockClient((_) async => http.Response('', 200)),
      );
      expect(
        () => store.download('x', File('${dir.path}/y')),
        throwsA(isA<DriveUnavailableException>()),
      );
    });

    test('Drive API kapalıysa sınama sunucunun yanıtını döner', () async {
      final store = DriveStore(
        _FakeAuth(['t']),
        client: MockClient(
          (_) async => http.Response(
            '{"error":{"errors":[{"reason":"accessNotConfigured"}]}}',
            403,
          ),
        ),
      );
      expect(await store.probe(), contains('accessNotConfigured'));
    });
  });
}
