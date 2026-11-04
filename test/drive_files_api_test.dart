import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/notes/data/drive_files_api.dart';

void main() {
  group('DriveTokenCache', () {
    test(
      'geçerli jeton yenilenmez; süresi yaklaşınca TEK sessiz yenileme',
      () async {
        var now = DateTime.utc(2026, 11, 4, 3);
        var calls = 0;
        final cache = DriveTokenCache(
          clock: () => now,
          silentRefresh: () async {
            calls++;
            await Future<void>.delayed(Duration.zero);
            return (
              token: 't$calls',
              expiry: now.add(const Duration(hours: 1)),
            );
          },
        );
        cache.put('t0', now.add(const Duration(minutes: 30)));
        expect(await cache.get(), 't0');
        expect(calls, 0);

        now = now.add(const Duration(minutes: 29)); // 1 dk kaldı < 2 dk pay
        final results = await Future.wait([
          cache.get(),
          cache.get(),
          cache.get(),
        ]);
        expect(results, ['t1', 't1', 't1']);
        expect(calls, 1, reason: 'eşzamanlı istekler aynı yenilemeyi bekler');
      },
    );

    test('sessiz yenileme olmazsa null (arayüz "bağla" der)', () async {
      final cache = DriveTokenCache(silentRefresh: () async => null);
      expect(await cache.get(), isNull);
      final throwing = DriveTokenCache(
        silentRefresh: () async => throw StateError('pencere gerekli'),
      );
      expect(await throwing.get(), isNull);
    });
  });

  group('DriveFilesApi', () {
    DriveTokenCache tokens() => DriveTokenCache(
      silentRefresh: () async =>
          (token: 'tok', expiry: DateTime.now().add(const Duration(hours: 1))),
    );

    test('klasör yoksa oluşturur, sonra önbellekten verir', () async {
      final requests = <http.Request>[];
      final client = MockClient((r) async {
        requests.add(r);
        if (r.method == 'GET') return http.Response('{"files":[]}', 200);
        return http.Response('{"id":"F1"}', 200);
      });
      final api = DriveFilesApi(client: client, tokens: tokens());
      expect(await api.ensureFolder(), 'F1');
      expect(await api.ensureFolder(), 'F1');
      expect(requests.length, 2);
      expect(requests[0].url.queryParameters['q'], contains("name = 'Notlar'"));
      expect(jsonDecode(requests[1].body)['name'], 'Notlar');
      expect(requests[1].headers['Authorization'], 'Bearer tok');
    });

    test('yükleme klasöre gider, ek kimliği appProperties’te', () async {
      late http.Request upload;
      final client = MockClient((r) async {
        if (r.method == 'GET') {
          return http.Response('{"files":[{"id":"F9"}]}', 200);
        }
        upload = r;
        return http.Response('{"id":"D1"}', 200);
      });
      final api = DriveFilesApi(client: client, tokens: tokens());
      final id = await api.upload(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'a.png',
        mimeType: 'image/png',
        attachmentId: 'e1',
      );
      expect(id, 'D1');
      final body = latin1.decode(upload.bodyBytes);
      expect(body, contains('"parents":["F9"]'));
      expect(body, contains('"notlarAttachmentId":"e1"'));
      expect(body, contains('Content-Type: image/png'));
    });

    test('401 → jeton yenilenip bir kez yeniden denenir', () async {
      var n = 0, refreshes = 0;
      final cache = DriveTokenCache(
        silentRefresh: () async {
          refreshes++;
          return (
            token: 'tok$refreshes',
            expiry: DateTime.now().add(const Duration(hours: 1)),
          );
        },
      );
      final client = MockClient((r) async {
        n++;
        if (r.headers['Authorization'] == 'Bearer tok1') {
          return http.Response('expired', 401);
        }
        return http.Response.bytes([7], 200);
      });
      final api = DriveFilesApi(client: client, tokens: cache);
      expect(await api.download('D1'), [7]);
      expect(n, 2);
      expect(refreshes, 2);
    });

    test('çöpe atma: 404 sessiz, diğer hata fırlar', () async {
      final ok404 = DriveFilesApi(
        client: MockClient((_) async => http.Response('', 404)),
        tokens: tokens(),
      );
      await ok404.trash('x');
      final bad = DriveFilesApi(
        client: MockClient((_) async => http.Response('', 500)),
        tokens: tokens(),
      );
      expect(bad.trash('x'), throwsA(isA<DriveApiException>()));
    });
  });
}
