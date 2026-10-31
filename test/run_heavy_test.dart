import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/run_heavy.dart';

/// F10.1: web'de `Isolate.run` yok ("Unsupported operation:
/// RawReceivePort") — PDF ekleme, sayfa düzenleme ve balonlu PDF web'de
/// kırıktı. `runHeavy` web'de işi aynı iş parçacığında koşar.
void main() {
  test(
    'web dalı izole AÇMAZ: gönderilemeyen değeri yakalayan iş de koşar',
    () async {
      // ReceivePort izole sınırından geçemez; Isolate.run bunu reddederdi.
      final port = ReceivePort();
      addTearDown(port.close);
      final result = await runHeavy(() => port.hashCode, web: true);
      expect(result, port.hashCode);
    },
  );

  test('web dalında hata çağırana olduğu gibi ulaşır', () async {
    await expectLater(
      runHeavy<int>(() => throw StateError('bozuk'), web: true),
      throwsA(isA<StateError>()),
    );
  });

  test('yerel dal izolede koşar ve sonucu döner', () async {
    final id = await runHeavy(() => Isolate.current.hashCode, web: false);
    expect(id, isNot(Isolate.current.hashCode));
  });

  test('web dalı async işi de bekler', () async {
    final v = await runHeavy(() async {
      await Future<void>.delayed(Duration.zero);
      return 7;
    }, web: true);
    expect(v, 7);
  });
}
