import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/settings/presentation/privacy_screen.dart';

/// KW-7 (web keşfi 2026-11-18): uygulama içi gizlilik ekranı ham metindi —
/// sert satır sonları dar ekranda yarım satır bırakıyordu.
void main() {
  final blocks = privacyBlocks(File('PRIVACY_POLICY.md').readAsStringSync());

  test('başlıklar ayrı, satır sonları birleşik, maddeler ayrı', () {
    expect(blocks.first.kind, 'heading');
    expect(blocks.first.level, 1);
    expect(
      blocks
          .where((b) => b.kind == 'heading' && b.level == 2)
          .map((b) => b.text),
      containsAll(['Toplanan veriler', 'Veri saklama ve silme', 'İletişim']),
    );
    for (final b in blocks) {
      expect(b.text, isNot(contains('\n')));
      expect(b.text, isNot(startsWith('#')));
    }
    final first = blocks.firstWhere((b) => b.text.startsWith('1. Hesap'));
    expect(first.kind, 'item');
    expect(
      first.text,
      contains('e-posta adresiniz'),
      reason: 'satırlar birleşti',
    );
    expect(blocks.where((b) => b.kind == 'bullet'), isNotEmpty);
  });

  test('küçük örnek: paragraf + iç madde', () {
    final b = privacyBlocks('# T\n\nbir\niki\n\n- a\n  devam\n   - iç\n');
    expect(b.map((e) => (e.kind, e.level, e.text)).toList(), [
      ('heading', 1, 'T'),
      ('paragraph', 0, 'bir iki'),
      ('bullet', 1, 'a devam'),
      ('bullet', 2, 'iç'),
    ]);
  });
}
