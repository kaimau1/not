import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/reorder_hover_gate.dart';

/// P56: iki sütun sınırında sürüklerken kart sağ/sol gidip gelmesin.
void main() {
  late DateTime now;
  late ReorderHoverGate gate;

  setUp(() {
    now = DateTime(2026, 11, 13, 12);
    gate = ReorderHoverGate(clock: () => now);
  });

  void advance(int ms) => now = now.add(Duration(milliseconds: ms));

  test('sınırda titreşim (A/B her 16 ms) → en çok 1 yer değişimi', () {
    // Eski davranış: her onMove anında yer değiştiriyordu → 60 karede 60
    // değişim. Parmak iki kartın sınırında titriyor: hedef her karede değişir.
    var commits = 0;
    for (var frame = 0; frame < 60; frame++) {
      if (gate.offer(frame.isEven ? 'A' : 'B')) commits++;
      advance(16);
    }
    expect(commits, lessThanOrEqualTo(1));
  });

  test('yer değişimi sonrası itilen kart geri çekmez (komşuya geçiş)', () {
    // A'nın üstünde dur → değişim; ardından parmak hep A'nın üstünde kalsa
    // da A kilitli: geri değişim yok.
    var commits = 0;
    for (var i = 0; i < 20; i++) {
      if (gate.offer('A')) commits++;
      advance(16);
    }
    expect(commits, 1);
    // Değişimden sonra yerleşim kaydı: parmağın altına A ile B sırayla
    // geliyor (kartlar oturuyor) — soğuma ve kilit ikisini de yutar.
    for (var i = 0; i < 10; i++) {
      if (gate.offer(i.isEven ? 'A' : 'B')) commits++;
      advance(16);
    }
    expect(commits, 1);
  });

  test('bilinçli hareket: B üstünde durunca yer değişir', () {
    for (var i = 0; i < 10; i++) {
      gate.offer('A');
      advance(16);
    }
    advance(300); // soğuma doldu
    var commits = 0;
    for (var i = 0; i < 12; i++) {
      if (gate.offer('B')) commits++;
      advance(16);
    }
    expect(commits, 1);
  });

  test('itilen karttan çıkıp yeniden girince geri alınabilir', () {
    for (var i = 0; i < 10; i++) {
      gate.offer('A');
      advance(16);
    }
    advance(300);
    expect(gate.offer('A'), isFalse, reason: 'kilitli');
    gate.leave('A');
    gate.offer('A');
    advance(130);
    expect(gate.offer('A'), isTrue);
  });

  test('durgun parmak: remaining() kalan durma süresini verir', () {
    expect(gate.remaining(), isNull);
    gate.offer('A');
    advance(50);
    expect(gate.remaining(), const Duration(milliseconds: 70));
    advance(100);
    expect(gate.remaining(), Duration.zero);
    expect(gate.offer('A'), isTrue);
  });

  test('reset her şeyi temizler', () {
    for (var i = 0; i < 10; i++) {
      gate.offer('A');
      advance(16);
    }
    gate.reset();
    gate.offer('A');
    advance(130);
    expect(gate.offer('A'), isTrue);
  });
}
