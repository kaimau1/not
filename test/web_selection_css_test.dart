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
}
