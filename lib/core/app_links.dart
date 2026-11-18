/// Herkese açık adresler (PLAN §1.5 PL13): çeşide göre `SITE_URL` define'ı
/// (`env_play.json`); verilmezse kişisel web sitesi. Gizlilik ve hesap silme
/// sayfaları `PRIVACY_POLICY.md`'den üretilip sitede yayınlanır (PL4).
/// DİKKAT: `SITE_URL` env dosyasına BOŞ yazılırsa varsayılan değil "" gelir.
abstract final class AppLinks {
  static const String site = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://notlar-web.pages.dev',
  );
  static const String privacy = '$site/gizlilik.html';
  static const String deleteAccount = '$site/hesap-silme.html';
}
