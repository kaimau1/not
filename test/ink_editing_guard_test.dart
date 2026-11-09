import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **KALEM KATMANI DÜZENLEME KİPİNDE KURULUR** (cihazda doğrulandı
/// 2026-11-10: sabit PDF, gömülü PDF ve not paketinde kalem kipi açılıyor ama
/// ne kalem ne parmak iz bırakıyordu). `InkPageLayer` `editing` kapalıyken
/// `IgnorePointer` ile bütün dokunuşları yok sayar; üç yüzeyde denetleyici
/// kurulup `setEditing` hiç çağrılmıyordu. Denetleyici kuran her dosya onu
/// düzenleme kipine de almalı (salt okunur yüzey `setEditing(false)` der).
void main() {
  test('InkController kuran her dosya setEditing çağırır', () {
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      // Sınıfın kendi dosyası (tanım + fabrika) dışarıda.
      if (f.uri.pathSegments.last == 'ink_layer.dart') {
        continue;
      }
      final src = f.readAsStringSync();
      if (!src.contains('InkController(')) continue;
      if (!src.contains('setEditing(')) offenders.add(f.path);
    }
    expect(offenders, isEmpty);
  });
}
