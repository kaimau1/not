import 'package:flutter/services.dart';

/// Video için GERÇEK tam ekran: sistem çubukları gizlenir, yatay video
/// ekranı yan çevirir.
///
/// Kullanıcı bulgusu 2026-10-19: "video sabitken tam ekran yapma seçeneği
/// yok". Sabit bölmenin ⤢ düğmesi oynatıcı EKRANINI açıyordu — dikey
/// ekranda, üst çubuk ve durum çubuğuyla, üstelik video baştan başlıyordu;
/// kullanıcının beklediği (YouTube'daki gibi) yan dönen, kenarsız görüntü
/// değildi. Çıkışta her şey uygulamanın varsayılanına döner (main.dart:
/// edgeToEdge, yönelim serbest).
abstract final class ImmersiveVideo {
  static Future<void> enter({required bool landscape}) async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (landscape) {
      await SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  static Future<void> exit() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const []);
  }
}
