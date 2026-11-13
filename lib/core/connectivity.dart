import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ağ bağlantısı yok mu — TEK KAYNAK (DENEYIM F79.6 (4)(5)).
///
/// Eskiden bağlantı algısı yalnız yükleme kuyruğundaydı; AI levhası
/// çevrimdışıyken düğmeleri etkin gösteriyor (hata ancak dokununca),
/// bekleyen ek şeridi bağlantı yokken de "yükleniyor" diyordu.
///
/// Yalnız arayüz İPUCU: "ağ arayüzü yok" (uçak kipi, Wi-Fi/veri kapalı)
/// demektir; Wi-Fi'ye bağlı ama internetsiz durumu yakalamaz — orada eski
/// davranış (dene, hata göster) sürer. Eklenti yoksa (test, desteklenmeyen
/// platform) ya da hata verirse "bağlı" sayılır: yanlış "bağlantı yok"
/// demek, düğmeyi kilitlemek, yanlış "yükleniyor" demekten kötüdür.
final connectivityOfflineProvider = StreamProvider<bool>((ref) {
  return _offlineStream(Connectivity());
});

/// Kolay okuma: bilinmiyorsa `false` (bağlı).
final isOfflineProvider = Provider<bool>(
  (ref) => ref.watch(connectivityOfflineProvider).value ?? false,
);

bool _isOffline(List<ConnectivityResult> results) =>
    results.isNotEmpty && results.every((r) => r == ConnectivityResult.none);

Stream<bool> _offlineStream(Connectivity connectivity) async* {
  try {
    yield _isOffline(await connectivity.checkConnectivity());
  } catch (_) {
    yield false;
    return;
  }
  try {
    await for (final results in connectivity.onConnectivityChanged) {
      yield _isOffline(results);
    }
  } catch (_) {
    // Olay kanalı yok/bozuk: son bilinen değer kalır.
  }
}
