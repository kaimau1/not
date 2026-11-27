import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/display_rate.dart';

/// 120 Hz kararı (kullanıcı isteği 2026-11-16): pil tasarrufu → sistemin
/// seçimi, değilse yüksek hız; yerel köprü yoksa sessizce geçer.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const system = MethodChannel('dev.kaimau.notlar/system');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> native;

  void kur({required bool saving, bool nativeVar = true}) {
    native = [];
    messenger.setMockMethodCallHandler(system, (call) async {
      native.add(call);
      if (call.method == 'powerSaveMode') return saving;
      if (!nativeVar) throw MissingPluginException();
      if (call.method == 'refreshRate') return 120.0;
      return 'ozet';
    });
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(system, null);
  });

  Object? high() =>
      (native.singleWhere((c) => c.method == 'setRefreshRate').arguments
          as Map)['high'];

  test('pil tasarrufu kapalı: yerel köprüden yüksek hız ister', () async {
    kur(saving: false);
    await DisplayRate.apply();
    expect(high(), true);
  });

  test('pil tasarrufu açık: sistemin seçimi (high=false)', () async {
    kur(saving: true);
    await DisplayRate.apply();
    expect(high(), false);
  });

  test('yerel köprü yoksa hata fırlatmaz, sessizce geçer', () async {
    kur(saving: true, nativeVar: false);
    await DisplayRate.apply();
    expect(await DisplayRate.activeHz(), isNull);

    kur(saving: false, nativeVar: false);
    await DisplayRate.apply();
    expect(await DisplayRate.activeHz(), isNull);
  });

  test('kanal hiç kayıtlı değilse sessiz', () async {
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
