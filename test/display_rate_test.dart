import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/display_rate.dart';

/// 120 Hz kararı (kullanıcı isteği 2026-11-16): pil tasarrufu → sistemin
/// seçimi, değilse yüksek hız; yerel köprü yoksa eklentiye sessizce düşer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const system = MethodChannel('dev.kaimau.notlar/system');
  const plugin = MethodChannel('flutter_display_mode');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> native;
  late List<MethodCall> eklenti;

  void kur({required bool saving, bool nativeVar = true}) {
    native = [];
    eklenti = [];
    messenger.setMockMethodCallHandler(system, (call) async {
      native.add(call);
      if (call.method == 'powerSaveMode') return saving;
      if (!nativeVar) throw MissingPluginException();
      if (call.method == 'refreshRate') return 120.0;
      return 'ozet';
    });
    messenger.setMockMethodCallHandler(plugin, (call) async {
      eklenti.add(call);
      return null;
    });
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(system, null);
    messenger.setMockMethodCallHandler(plugin, null);
  });

  Object? high() =>
      (native.singleWhere((c) => c.method == 'setRefreshRate').arguments
          as Map)['high'];

  test('pil tasarrufu kapalı: yerel köprüden yüksek hız, eklentiye gidilmez',
      () async {
    kur(saving: false);
    await DisplayRate.apply();
    expect(high(), true);
    expect(eklenti, isEmpty);
  });

  test('pil tasarrufu açık: sistemin seçimi (high=false)', () async {
    kur(saving: true);
    await DisplayRate.apply();
    expect(high(), false);
    expect(eklenti, isEmpty);
  });

  test('yerel köprü yoksa eklentiye düşer, hata fırlatmaz', () async {
    kur(saving: true, nativeVar: false);
    await DisplayRate.apply();
    // Tasarrufta eklentiye auto (mod 0) gider.
    expect(eklenti.single.method, 'setPreferredMode');
    expect((eklenti.single.arguments as Map)['mode'], 0);

    kur(saving: false, nativeVar: false);
    await DisplayRate.apply(); // eklenti boş yanıt verse de sessiz
    expect(eklenti, isNotEmpty);
    expect(await DisplayRate.activeHz(), isNull);
  });

  test('iki kanal da yoksa sessiz', () async {
    native = [];
    await DisplayRate.apply();
    expect(await DisplayRate.activeHz(), isNull);
  });

  test('etkin hız okunur; Android dışında null', () async {
    kur(saving: false);
    expect(await DisplayRate.activeHz(), 120.0);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await DisplayRate.activeHz(), isNull);
    await DisplayRate.apply();
    expect(native.where((c) => c.method == 'setRefreshRate'), isEmpty);
  });
}
