import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/save_cadence.dart';

/// Senkron maliyeti S2 + korkuluk 5 (2026-11-17): otomatik kayıt sıklığı ve
/// `config/app` uzaktan freni.
void main() {
  tearDown(SaveCadence.reset);

  test('varsayılan 2 sn / 20 sn', () {
    SaveCadence.apply(null);
    expect(SaveCadence.delay, const Duration(seconds: 2));
    expect(SaveCadence.maxWait, const Duration(seconds: 20));
    SaveCadence.apply({'minClient': 3});
    expect(SaveCadence.delay, const Duration(seconds: 2));
  });

  test('uzaktan değer sınırlanır', () {
    SaveCadence.apply({'saveDelaySec': 30, 'saveMaxWaitSec': 90});
    expect(SaveCadence.delay, const Duration(seconds: 30));
    expect(SaveCadence.maxWait, const Duration(seconds: 90));
    // JS'ten ondalık gelebilir; alt/üst sınırlar.
    SaveCadence.apply({'saveDelaySec': 0.5, 'saveMaxWaitSec': 9999});
    expect(SaveCadence.delay, const Duration(seconds: 2));
    expect(SaveCadence.maxWait, const Duration(seconds: 300));
    // Üst sınır sessizlikten kısa olamaz.
    SaveCadence.apply({'saveDelaySec': 60, 'saveMaxWaitSec': 10});
    expect(SaveCadence.maxWait, const Duration(seconds: 60));
    // Yalnız sessizlik verilirse üst sınır en az o kadar.
    SaveCadence.apply({'saveDelaySec': 45});
    expect(SaveCadence.maxWait, const Duration(seconds: 45));
  });
}
