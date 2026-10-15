import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/presentation/editor/tag_tap.dart';

/// Seçim menüsünün sırası (kullanıcı bulgusu 2026-10-15: "metin seçim
/// mantığı ve kalitesi düzeltilmeli"). Gövdede uzun "Seçili yazıya ek göm"
/// listenin başına ekleniyor, Kopyala/Yapıştır Android'in dar çubuğunda
/// taşma menüsüne itiliyordu; Biçim ise hep "Paylaş"tan sonra, ⋮'nin
/// içinde kalıyordu.
void main() {
  ContextMenuButtonItem platform(ContextMenuButtonType type) =>
      ContextMenuButtonItem(type: type, onPressed: () {});
  ContextMenuButtonItem custom(String label) =>
      ContextMenuButtonItem(label: label, onPressed: () {});

  String name(ContextMenuButtonItem item) =>
      item.label ?? item.type.name;

  test('birincil iş → kes/kopyala/yapıştır → bizimkiler → tümünü seç → '
      'platformun ekleri → sondakiler', () {
    final menu = arrangeSelectionMenu(
      platform: [
        platform(ContextMenuButtonType.cut),
        platform(ContextMenuButtonType.copy),
        platform(ContextMenuButtonType.paste),
        platform(ContextMenuButtonType.share),
        platform(ContextMenuButtonType.selectAll),
        platform(ContextMenuButtonType.searchWeb),
      ],
      leading: [custom('Önizle')],
      afterClipboard: [custom('Biçim'), custom('Ek göm')],
      trailing: [custom('Tüm notu kopyala')],
    );
    expect([for (final i in menu) name(i)], [
      'Önizle',
      'cut',
      'copy',
      'paste',
      'Biçim',
      'Ek göm',
      'selectAll',
      'share',
      'searchWeb',
      'Tüm notu kopyala',
    ]);
  });

  test('platform öğesi kaybolmaz, çoğalmaz', () {
    final items = [
      platform(ContextMenuButtonType.paste),
      platform(ContextMenuButtonType.selectAll),
      platform(ContextMenuButtonType.lookUp),
    ];
    final menu = arrangeSelectionMenu(platform: items);
    expect(menu.toSet(), items.toSet());
    expect(menu.length, items.length);
  });
}
