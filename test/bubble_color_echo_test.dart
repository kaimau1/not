import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/attachment.dart';
import 'package:notlar/features/notes/presentation/viewers/bubble_layer.dart';

/// Kullanıcı bulgusu 2026-11-22: "hızlı hızlı renk değiştirince bir
/// öncekine dönüyor". Gecikmeli kayıt beklerken ya da önceki kaydın yankısı
/// gelince yerel renk ezilmemeli.
void main() {
  const base = PageBubble(id: 'b', page: 1, x: 0.5, y: 0.5, text: 't');

  test('kaydedilmemiş renk dışarıdan gelen eski listeyle ezilmez', () {
    final saved = <List<PageBubble>>[];
    final c = BubbleController(initial: const [base], onChanged: saved.add);
    addTearDown(c.dispose);

    c.update(base.copyWith(color: 1));
    c.save(); // kırmızı kaydedildi
    c.update(base.copyWith(color: 2));
    c.saveSoon(); // mavi bekliyor

    // Kırmızının yankısı gelir: mavi kalmalı.
    c.replace(saved.last);
    expect(c.bubbles.single.color, 2);

    c.save(); // mavi kaydedildi
    // Gecikmiş eski yankı (kırmızı) yine mavi'yi ezmez.
    c.replace([base.copyWith(color: 1)]);
    expect(c.bubbles.single.color, 2);
  });

  test('bekleyen değişiklik yokken dışarıdan gelen yeni içerik benimsenir', () {
    final c = BubbleController(initial: const [base], onChanged: (_) {});
    addTearDown(c.dispose);
    c.replace([base.copyWith(color: 3)]);
    expect(c.bubbles.single.color, 3);
  });
}
