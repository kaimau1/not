import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 2026-11-07 (kullanıcı: "sağa sola kaydırıp klasör geçişinde üst klasör
/// satırı çok hareket ediyor"). KÖK NEDEN: klasör şeridi yana kaydırılan
/// ızgaranın (segmentKey'li CustomScrollView) bir sliver'ıydı — çekişte
/// parmakla kayıyor, geçişte solup yeniden kuruluyor, yatay konumu sıfırdan
/// seçili çipe kayıyordu. Bekçi: şerit ızgaranın DIŞINDA, sabit başlıkta;
/// seçili çip ortalanmaz, en kısa yoldan görünür kılınır.
void main() {
  final screen = File('lib/features/notes/presentation/dashboard_screen.dart')
      .readAsStringSync();
  final widgets = File('lib/features/notes/presentation/dashboard_widgets.dart')
      .readAsStringSync();

  test('şerit sabit başlıkta, ızgara sınırından ÖNCE', () {
    final strip = screen.indexOf('if (shelfAsStrip)');
    final separator = screen.indexOf(
      '_HeaderSeparator(scrolled: _gridScrolled)',
    );
    final grid = screen.indexOf('child: _GridScrollView(');
    expect(strip, greaterThan(0));
    expect(strip, lessThan(separator));
    expect(separator, lessThan(grid));
    // Izgaranın içinde yalnız KARO rafı (şerit değil).
    expect(screen.contains('if (showShelf && !shelfAsStrip)'), isTrue);
  });

  test('seçili çip ORTALANMAZ (her geçişte şerit kaymasın)', () {
    final start = widgets.indexOf('class _EnsureVisibleState');
    final body = widgets.substring(start, widgets.indexOf('\n}\n', start));
    expect(body.contains('alignment: 0.5,'), isFalse);
    expect(body.contains('getOffsetToReveal'), isTrue);
  });
}
