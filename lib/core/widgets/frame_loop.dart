import 'package:flutter/scheduler.dart';

/// Ekran yenilemesine (vsync) bağlı döngü — `Timer.periodic(16 ms)`un yerine
/// (F2.2).
///
/// Zamanlayıcı kare sınırını bilmez: 120 Hz ekranda en fazla 60 adım atar,
/// adımlar karelere düzensiz düşer (titreme), bazen bir karede iki adım.
/// Burada her KARE tek adım; [onFrame]'e geçen `scale`, geçen sürenin 60 Hz
/// karesine (16,7 ms) oranıdır — 60 Hz için yazılmış piksel/adım değerleri
/// her yenileme hızında aynı HIZI verir.
///
/// [vsync] verilmezse çıplak bir [Ticker] kurulur (durum nesnesi olmayan
/// yardımcılar için); verilirse ekran görünmezken (TickerMode) susar.
class FrameLoop {
  FrameLoop(this.onFrame, {TickerProvider? vsync}) {
    _ticker = vsync?.createTicker(_tick) ?? Ticker(_tick);
  }

  /// `scale`: bu kareye kadar geçen süre / 16,7 ms (en çok 4 — takılan bir
  /// karede sıçrama olmasın).
  final void Function(double scale) onFrame;

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  bool get isActive => _ticker.isActive;

  /// Döngü zaten dönüyorsa bir şey yapmaz.
  void start() {
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) _ticker.stop();
  }

  void dispose() => _ticker.dispose();

  void _tick(Duration elapsed) {
    final dt = elapsed - _last;
    _last = elapsed;
    // İlk tık (elapsed = 0) bir adım saymaz: başlatıldığı kare.
    if (dt <= Duration.zero) return;
    onFrame((dt.inMicroseconds / 16667).clamp(0.0, 4.0));
  }
}
