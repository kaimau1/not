# Güvenlik

Açık bildirimi: herkese açık issue AÇMADAN, GitHub'da bu deponun **Security → Report a
vulnerability** (özel bildirim) yolunu kullanın. Yeniden üretme adımlarını ve etkilenen
sürümü (Ayarlar → Hakkında) ekleyin.

- Tehdit modeli: `docs/guvenlik.md`
- Son denetim ve açık bulgular: `docs/guvenlik_denetimi.md`
- Kalıcı kapılar: `rules-test/` (kural testleri), `test/security_guard_test.dart`,
  CI `guvenlik` işi (gitleaks + osv-scanner).

Depoya asla girmeyenler: imza anahtarı (`*.jks`), `android/key.properties`, `env.json`,
servis hesabı dosyaları, kullanıcı jetonları.
