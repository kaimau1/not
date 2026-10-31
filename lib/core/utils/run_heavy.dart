import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Ağır, saf Dart işini UI iş parçacığından uzakta koşturur.
///
/// Android/masaüstünde `Isolate.run`. **Web'de izole YOK**
/// (`Unsupported operation: RawReceivePort`, 2026-10-30 — web'de PDF
/// eklemeyi, sayfa düzenlemeyi ve balonlu PDF'i kırıyordu, F10.1): orada iş
/// aynı iş parçacığında koşar; önce kısa bir bekleme yapılır ki çağıranın
/// gösterdiği "işleniyor" göstergesi bir kare çizilebilsin.
///
/// Kapanış yalnız GÖNDERİLEBİLİR değerleri yakalamalı (örnek alanı değil) —
/// web dalı bunu denetlemez, Android dalı denetler; ikisinde de aynı kural.
/// [web] yalnız testler içindir.
Future<R> runHeavy<R>(FutureOr<R> Function() task, {bool? web}) async {
  if (web ?? kIsWeb) {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    return await task();
  }
  return Isolate.run(task);
}
