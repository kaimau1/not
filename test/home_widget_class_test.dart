import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/widget_service.dart';

/// KT-21 (tablet turu 2026-11-18): ölçüm kimliğinde (`dev.kaimau.notlar.olcum`)
/// her açılışta "No Widget found with Name TodayWidgetProvider". KÖK NEDEN:
/// `home_widget` `androidName`'i UYGULAMA KİMLİĞİYLE birleştirip sınıf arar
/// (`<applicationId>.<ad>`); sınıflar ise hep `dev.kaimau.notlar` paketinde.
/// Kimliği farklı her derlemede (ölçüm, Play — `NOTLAR_PLAY_APP_ID`) ana
/// ekran araçları HİÇ güncellenmiyordu. Artık tam nitelikli sınıf adı.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('araç güncellemesi tam nitelikli sınıf adıyla gider', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (
          c,
        ) async {
          calls.add(c);
          return true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), null),
    );
    await updateHomeWidget('TodayWidgetProvider');
    final call = calls.single;
    expect(call.method, 'updateWidget');
    expect(
      (call.arguments as Map)['qualifiedAndroidName'],
      'dev.kaimau.notlar.TodayWidgetProvider',
    );
  });

  test('bekçi: lib içinde androidName ile araç güncellemesi yok', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.readAsStringSync().contains('updateWidget(androidName')) {
        offenders.add(f.path);
      }
    }
    expect(offenders, isEmpty);
  });

  test('sınıf adları Android kaynağında var', () {
    for (final name in kHomeWidgetProviders) {
      expect(
        File('android/app/src/main/kotlin/dev/kaimau/notlar/$name.kt')
            .existsSync(),
        isTrue,
        reason: name,
      );
    }
  });
}
