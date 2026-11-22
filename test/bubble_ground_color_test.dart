import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';

/// Kullanıcı bulgusu 2026-11-22: "siyah ekranda metin ekle görülmüyor,
/// arka plana göre renk almalı metin ekleme ve balon ekleme".
void main() {
  BubbleController make(double luma) =>
      BubbleController(initial: const [], onChanged: (_) {})
        ..lumaAt = (_, _) => luma;

  test('koyu zeminde açık metin beyaz, balon açık tonla doğar', () {
    final c = make(0.05)..setPlainMode(true);
    c.add(1, 0.5, 0.5);
    expect(c.bubbles.last.color, 0xFFFFFFFF);
    c
      ..setPlainMode(false)
      ..add(1, 0.2, 0.2);
    expect(c.bubbles.last.color, BubbleController.darkGroundColor);
  });

  test('açık zeminde varsayılanlar; seçilen renk hep korunur', () {
    final light = make(0.9)..setPlainMode(true);
    light.add(1, 0.5, 0.5);
    expect(light.bubbles.last.color, 0xFF000000);

    final dark = make(0.05)
      ..setPlainMode(true)
      ..setPlainColor(0xFFD32F2F);
    dark.add(1, 0.5, 0.5);
    expect(dark.bubbles.last.color, 0xFFD32F2F);
  });

  test('biçim kaydı gecikmeli, dispose bekleyeni yazar', () {
    var saves = 0;
    final c = BubbleController(initial: const [], onChanged: (_) => saves++)
      ..add(1, 0.5, 0.5);
    final before = saves;
    c.stepSize(c.bubbles.last.id, 1);
    expect(saves, before, reason: 'hemen yazılmaz');
    c.dispose();
    expect(saves, before + 1, reason: 'kapanışta bekleyen kayıt yazıldı');
  });
}
