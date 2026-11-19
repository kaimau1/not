import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// P59 (kullanıcı 2026-11-14): webde seçili metin mavi kutuda, tarayıcı
/// yazı tipiyle görünüyordu — Flutter'ın gizli DOM metin alanının yerel
/// seçimi, sayfaya gelen genel bir `::selection !important` kuralıyla
/// (eklenti) görünür oluyordu. index.html'deki koruma kuralı kalmalı.
void main() {
  test('index.html gizli metin alanının yerel seçimini !important gizler', () {
    final html = File('web/index.html').readAsStringSync();
    for (final sel in [
      'flt-text-editing-host input::selection',
      'flt-text-editing-host textarea::selection',
      'flt-semantics input::selection',
      'flt-semantics textarea::selection',
    ]) {
      expect(html, contains(sel), reason: sel);
    }
    expect(html, contains('background: transparent !important'));
    expect(html, contains('color: transparent !important'));
  });

  // 2026-11-19: eşit özgüllükte SONRA gelen bir eklenti kuralı (ör.
  // `html body *::selection {…!important}`) birinci katı eziyordu
  // (Playwright'ta yeniden üretildi). Fareli cihazda gizli alan opacity 0.
  test('fareli cihazda gizli metin alanı tümden görünmez (2. kat)', () {
    final html = File('web/index.html').readAsStringSync();
    final media = html.indexOf('@media (hover: hover) and (pointer: fine)');
    expect(media, greaterThan(0));
    final block = html.substring(media, html.indexOf('</style>', media));
    expect(block, contains('flt-text-editing-host .flt-text-editing'));
    expect(block, contains('flt-semantics textarea'));
    expect(block, contains('opacity: 0 !important'));
  });
}
