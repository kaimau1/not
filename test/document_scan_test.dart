import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/document_scan.dart';

/// 2026-11-07: tarama kamera izni SORMADAN Google tarayıcısını açar
/// (dosya-okuyucu'nun davranışı). Eklentinin `getPictures`'ı önce izin
/// istiyordu; reddedince tarama hiç açılmıyordu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cunning_document_scanner');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('kanal doğrudan çağrılır, sayfalar döner', () async {
    MethodCall? seen;
    messenger.setMockMethodCallHandler(channel, (call) async {
      seen = call;
      return ['/a.jpg', '/b.jpg'];
    });
    final pages = await DocumentScan.scanPages(maxPages: 5);
    expect(pages, ['/a.jpg', '/b.jpg']);
    expect(seen?.method, 'getPictures');
    expect((seen?.arguments as Map)['noOfPages'], 5);
    expect((seen?.arguments as Map)['isGalleryImportAllowed'], isTrue);
  });

  test('vazgeçilirse (boş liste) null', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => <String>[]);
    expect(await DocumentScan.scanPages(), isNull);
  });
}
