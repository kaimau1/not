// HIZ GÜNLÜĞÜ BEKÇİSİ (PLAN §1.5 PL12).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/frame_timing_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profil/beta bayrağı yokken kapalı: geri çağırma KAYITLI DEĞİL', () {
    // `flutter test` hata ayıklama kipi, bayrak yok → kişisel release APK
    // gibi kapalı olmalı.
    expect(FrameTimingLog.enabled, isFalse);
    FrameTimingLog.start();
    expect(FrameTimingLog.started, isFalse);
  });

  test('açılış kapısı derleme sabiti (release ağacından düşsün)', () {
    final src = File('lib/core/utils/frame_timing_log.dart').readAsStringSync();
    expect(
      src,
      contains(
        "static const bool enabled =\n"
        "      kProfileMode || bool.fromEnvironment('NOTLAR_HIZ_GUNLUGU');",
      ),
    );
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('FrameTimingLog.start()'),
    );
  });

  test('özet: ortanca/p90 ve takılan kare', () {
    // 10 kare: build 1..10 ms, raster hep 2 ms; bütçe 8,3 ms (120 Hz).
    final build = [for (var i = 1; i <= 10; i++) i * 1000];
    final raster = List.filled(10, 2000);
    final s = FrameTimingSummary.of(build, raster, budgetUs: 8333);
    expect(s.frames, 10);
    expect(s.buildP50, 5000);
    expect(s.buildP90, 9000);
    expect(s.rasterP50, 2000);
    expect(s.janky, 2); // 9 ve 10 ms
    expect(s.line, contains('takılan 2 (%20.0)'));
  });

  test('halka tampon: kayıt yokken boş, kapasiteyi aşmaz', () {
    FrameTimingLog.reset();
    expect(FrameTimingLog.summary(budget: 16667), isEmpty);
    for (var i = 0; i < FrameTimingLog.capacity + 50; i++) {
      FrameTimingLog.add(20000, 1000);
    }
    expect(
      FrameTimingLog.summary(budget: 16667),
      contains('son ${FrameTimingLog.capacity} kare'),
    );
    FrameTimingLog.reset();
  });
}
