import 'dart:async';

import 'package:flutter/foundation.dart';

/// Ard arda gelen çağrıları [delay] süresi boyunca erteleyip yalnızca
/// sonuncusunu çalıştırır. Editördeki otomatik kayıt bunu kullanır.
class Debouncer {
  Debouncer({this.delay = const Duration(milliseconds: 500)});

  final Duration delay;
  Timer? _timer;
  VoidCallback? _pending;

  void call(VoidCallback action) {
    _pending = action;
    _timer?.cancel();
    _timer = Timer(delay, () {
      _pending = null;
      action();
    });
  }

  /// Bekleyen çağrı varsa hemen çalıştırır (ekran kapanırken flush için).
  void flush() {
    if (_timer?.isActive ?? false) {
      _timer!.cancel();
      final action = _pending;
      _pending = null;
      action?.call();
    }
  }

  /// Bekleyen çağrıyı çalıştırmadan iptal eder.
  void cancel() {
    _timer?.cancel();
    _pending = null;
  }

  void dispose() => cancel();
}
