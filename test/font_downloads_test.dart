import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:notlar/core/utils/font_downloads.dart';
import 'package:notlar/core/utils/font_sources.dart';
import 'package:notlar/core/utils/note_fonts.dart';

/// PL10: paketten çıkarılan yazı tipi seçilince indirilir, önbelleklenir;
/// başarısızlık (çevrimdışı, 500, bozuk içerik) sessiz kalır ve çökme yapmaz.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final body400 = Uint8List.fromList(utf8.encode('sahte-ttf-400'));
  final body500 = Uint8List.fromList(utf8.encode('sahte-ttf-500!'));
  String sha(Uint8List b) => sha256.convert(b).toString();
  final sources = <String, List<FontSource>>{
    'Lato': [
      (weight: 400, sha256: sha(body400), length: body400.length),
      (weight: 500, sha256: sha(body500), length: body500.length),
    ],
  };

  late Directory tmp;
  late List<Uri> requests;
  late Map<String, Uint8List> registered;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('fonts_test');
    requests = [];
    registered = {};
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  FontDownloads make(http.Client client, {bool cache = true}) => FontDownloads(
    client: client,
    sources: sources,
    cacheDir: () => cache ? tmp.path : null,
    register: (family, bytes) async => registered[family] = bytes,
  );

  MockClient serving({int status = 200, Uint8List? corrupt}) =>
      MockClient((req) async {
        requests.add(req.url);
        final name = req.url.pathSegments.last;
        final body = name == '${sha(body400)}.ttf' ? body400 : body500;
        return http.Response.bytes(corrupt ?? body, status);
      });

  test('başarılı indirme: iki kesim doğru adla kaydolur, hazır olur', () async {
    final d = make(serving());
    expect(d.isReady('Lato'), isFalse);
    expect(await d.ensure('Lato'), isTrue);
    expect(d.isReady('Lato'), isTrue);
    expect(registered.keys, ['dl:Lato:400', 'dl:Lato:500']);
    expect(requests.map((u) => u.host).toSet(), {
      'fonts.gstatic.com',
    }, reason: 'yalnız Google Fonts statik adresi');
    expect(requests.first.path, '/s/a/${sha(body400)}.ttf');
  });

  test('ikinci açılışta önbellekten yüklenir, ağ istenmez', () async {
    await make(serving()).ensure('Lato');
    requests.clear();
    registered.clear();
    final again = make(
      MockClient((_) async => throw const SocketException('çevrimdışı')),
    );
    expect(await again.ensure('Lato'), isTrue);
    expect(registered.keys, ['dl:Lato:400', 'dl:Lato:500']);
    expect(requests, isEmpty);
  });

  test('çevrimdışı: false döner, çökmez, hazır olmaz', () async {
    final d = make(
      MockClient((_) async => throw const SocketException('çevrimdışı')),
    );
    expect(await d.ensure('Lato'), isFalse);
    expect(d.isReady('Lato'), isFalse);
    expect(d.isFetching('Lato'), isFalse);
    expect(registered, isEmpty);
  });

  test('sunucu hatası ve bozuk içerik reddedilir (özet doğrulaması)', () async {
    expect(await make(serving(status: 500)).ensure('Lato'), isFalse);
    final bad = make(serving(corrupt: Uint8List.fromList([1, 2, 3])));
    expect(await bad.ensure('Lato'), isFalse);
    expect(registered, isEmpty);
    // Bozuk içerik önbelleğe YAZILMAZ.
    expect(tmp.listSync(), isEmpty);
  });

  test(
    'başarısız aile otomatik yeniden denenmez; seçimde (retry) denenir',
    () async {
      var online = false;
      final d = make(
        MockClient((req) async {
          requests.add(req.url);
          if (!online) throw const SocketException('çevrimdışı');
          final isRegular = req.url.pathSegments.last == '${sha(body400)}.ttf';
          return http.Response.bytes(isRegular ? body400 : body500, 200);
        }),
      );
      expect(await d.ensure('Lato'), isFalse);
      expect(d.isReady('Lato'), isFalse);
      final first = requests.length;
      d.request('Lato'); // başarısız → sessizce atlanır
      expect(await d.ensure('Lato'), isFalse);
      expect(requests.length, first);
      online = true;
      expect(await d.ensure('Lato', retry: true), isTrue);
      expect(d.isReady('Lato'), isTrue);
    },
  );

  test(
    'eşzamanlı istekler tek indirmeye iner; dinleyiciler haberdar olur',
    () async {
      final d = make(serving());
      var notified = 0;
      d.addListener(() => notified++);
      final a = d.ensure('Lato');
      final b = d.ensure('Lato');
      expect(d.isFetching('Lato'), isTrue);
      expect(await Future.wait([a, b]), [true, true]);
      expect(requests.length, 2, reason: 'iki kesim, bir kez');
      expect(notified, greaterThanOrEqualTo(2));
      expect(d.isFetching('Lato'), isFalse);
    },
  );

  test('bilinmeyen / çekirdek aile için ağ açılmaz', () async {
    final d = make(serving());
    expect(await d.ensure('Roboto'), isFalse);
    d.request('Inter Tight');
    await Future<void>.delayed(Duration.zero);
    expect(requests, isEmpty);
  });

  test('applyNoteFont: indirilebilir aile kendi adı + varsayılan yedek', () {
    final saved = fontDownloads;
    fontDownloads = make(serving());
    addTearDown(() => fontDownloads = saved);

    final regular = applyNoteFont(
      const TextStyle(fontSize: 14),
      'Lato',
      fetch: false,
    );
    expect(regular.fontFamily, 'dl:Lato:400');
    expect(regular.fontFamilyFallback, ['InterTight_regular']);
    // Lato'nun 500 kesimi yok (gerçek tabloda): kalın metin 400'den kalınlaşır.
    final bold = applyNoteFont(
      const TextStyle(fontWeight: FontWeight.w700),
      'Lato',
      fetch: false,
    );
    expect(bold.fontFamily, 'dl:Lato:400');
    expect(bold.fontWeight, FontWeight.w700);
    // 500'ü olan ailede 500 kesimi, yedek de varsayılanın 500'ü.
    final medium = applyNoteFont(
      const TextStyle(fontWeight: FontWeight.w500),
      'Open Sans',
      fetch: false,
    );
    expect(medium.fontFamily, 'dl:Open Sans:500');
    expect(medium.fontFamilyFallback, ['InterTight_500']);
  });

  test(
    'applyNoteFont: fetch:false indirme başlatmaz, fetch:true başlatır',
    () async {
      final saved = fontDownloads;
      final d = make(serving());
      fontDownloads = d;
      addTearDown(() => fontDownloads = saved);

      applyNoteFont(const TextStyle(), 'Lato', fetch: false);
      await Future<void>.delayed(Duration.zero);
      expect(requests, isEmpty);

      applyNoteFont(const TextStyle(), 'Lato');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(d.isReady('Lato'), isTrue);
    },
  );

  test(
    'appFontTextTheme: indirilebilir ailede tüm metin biçimleri dönüşür',
    () {
      final saved = fontDownloads;
      fontDownloads = make(
        MockClient((_) async => throw const SocketException('çevrimdışı')),
      );
      addTearDown(() => fontDownloads = saved);

      final theme = appFontTextTheme(ThemeData().textTheme, 'Open Sans');
      for (final s in [
        theme.displayLarge,
        theme.titleMedium,
        theme.bodyMedium,
        theme.labelSmall,
      ]) {
        expect(s!.fontFamily, startsWith('dl:Open Sans:'));
        expect(s.fontFamilyFallback, isNotEmpty);
      }
      // Bozuk / bilinmeyen ad varsayılana döner.
      expect(
        appFontTextTheme(ThemeData().textTheme, 'Yok').bodyMedium!.fontFamily,
        startsWith('InterTight'),
      );
    },
  );
}
