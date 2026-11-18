import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/features/ai/data/antalia/antalia_engine.dart';

/// PL7 bekçisi (tedarik riski): Antalia dosyaları sabit bir commit'ten iner
/// ve her dosyanın SHA-256'sı doğrulanır; tutmayan dosya kurulmaz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('antalia_dl');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    tmp.deleteSync(recursive: true);
  });

  test('adres sabit commit, her dosyanın özeti var', () {
    expect(AntaliaModelFiles.baseUrl, isNot(contains('/resolve/main')));
    expect(
      AntaliaModelFiles.baseUrl,
      endsWith('/resolve/${AntaliaModelFiles.revision}'),
    );
    expect(
      AntaliaModelFiles.sha256s.keys.toSet(),
      AntaliaModelFiles.all.toSet(),
    );
    for (final h in AntaliaModelFiles.sha256s.values) {
      expect(h, matches(RegExp(r'^[0-9a-f]{64}$')));
    }
  });

  test('özeti tutmayan dosya kurulmaz, yarım dosya kalmaz', () async {
    final requested = <Uri>[];
    final client = MockClient((req) async {
      requested.add(req.url);
      return http.Response('sahte içerik', 200);
    });
    await expectLater(
      AntaliaModelFiles.download(onProgress: (_, _) {}, client: client),
      throwsA(
        isA<HttpException>().having(
          (e) => e.message,
          'message',
          contains('SHA-256'),
        ),
      ),
    );
    expect(
      requested.every(
        (u) => u.toString().startsWith(AntaliaModelFiles.baseUrl),
      ),
      isTrue,
    );
    final d = await AntaliaModelFiles.dir();
    final left = d.listSync().map((e) => e.uri.pathSegments.last).toList();
    expect(left, isEmpty, reason: 'kalan: $left');
    expect(await AntaliaModelFiles.installed(), isFalse);
  });
}
