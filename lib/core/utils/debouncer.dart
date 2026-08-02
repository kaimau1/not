import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ard arda gelen çağrıları [delay] süresi boyunca erteleyip yalnızca
/// sonuncusunu çalıştırır. Editördeki otomatik kayıt bunu kullanır.
class Debouncer {
  Debouncer({
    this.delay = const Duration(milliseconds: 500),
    this.maxWait = const Duration(seconds: 3),
  });

  final Duration delay;

  /// KÖK NEDEN (not kaybı): her çağrı zamanlayıcıyı SIFIRDAN başlattığı için,
  /// aralıksız yazan bir kullanıcıda [delay] hiç dolmuyordu — dakikalarca
  /// yazılan bir notta TEK bir kayıt bile yapılmıyor, uygulama o sırada
  /// kapatılınca yazılanların tamamı gidiyordu. [maxWait], bekleyen ilk
  /// çağrıdan bu kadar süre sonra eylemi daha fazla ertelemeden çalıştırır:
  /// yazma sürerken de en geç bu aralıkla kayıt olur.
  final Duration maxWait;

  Timer? _timer;
  Timer? _maxTimer;
  VoidCallback? _pending;

  /// Çalıştırılmayı bekleyen bir çağrı var mı?
  bool get hasPending => _pending != null;

  void call(VoidCallback action) {
    _pending = action;
    _timer?.cancel();
    _timer = Timer(delay, _run);
    // Zaten işleyen bir üst sınır varsa DOKUNMA — sıfırlamak maxWait'i
    // delay'in ikinci bir kopyasına çevirirdi.
    _maxTimer ??= Timer(maxWait, _run);
  }

  void _run() {
    final action = _pending;
    _clearTimers();
    _pending = null;
    action?.call();
  }

  void _clearTimers() {
    _timer?.cancel();
    _timer = null;
    _maxTimer?.cancel();
    _maxTimer = null;
  }

  /// Bekleyen çağrı varsa hemen çalıştırır (ekran kapanırken ya da uygulama
  /// arka plana alınırken flush için).
  void flush() {
    if (_pending != null) _run();
  }

  /// Bekleyen çağrıyı çalıştırmadan iptal eder.
  void cancel() {
    _clearTimers();
    _pending = null;
  }

  void dispose() => cancel();
}
