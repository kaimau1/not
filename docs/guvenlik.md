# Tehdit modeli (F71.1, 2026-11-11)

Tek sayfa: neyi, kimden, neyle koruyoruz. Bulgular ve durumları `docs/guvenlik_denetimi.md`.

## Varlıklar

| Varlık | Nerede | Koruyan |
|---|---|---|
| Notlar, klasörler, takvim/görev | Firestore `users/{uid}/…`, cihaz önbelleği | `firestore.rules` (yalnız sahip + dar paylaşım istisnaları), uygulama kilidi, not kilidi |
| Ekler | Storage `users/{uid}/…`, kullanıcının Drive'ı, cihaz | `storage.rules` (tür + boyut), Drive kapsamı |
| Drive / Gmail / Takvim jetonları | Android: şifreli depo (Keystore), uid'e bağlı; web: `sessionStorage` (sekmeyle ölür) | `google_scope_auth.dart` (uid eşleşmesi), `loopback_oauth.dart` (PKCE + state, yalnız 127.0.0.1) |
| AI anahtarları (Gemini vb.) | Yalnız cihazın şifreli deposu; Firestore'a yazılmaz | `api_key_store.dart` |
| İmza anahtarı | Depo DIŞINDA + GitHub Secrets | `.gitignore`, CI `guvenlik` işi (gitleaks), CLAUDE.md kuralı |
| CI sırları (servis hesabı, Cloudflare, OAuth) | GitHub Secrets | iş akışı en az yetki, SHA'ya sabit action'lar |

## Saldırganlar ve savunma

| Saldırgan | Ne dener | Savunma | Kalan risk |
|---|---|---|---|
| Başka hesap (giriş yapmış yabancı) | Başkasının notunu okumak/yazmak, e-posta dizinini ele geçirmek, kendini paylaşıma eklemek | Kurallar + `rules-test` (26 test), ayna sahiplik kanıtı (`exists()`), dizin kimliği = jetondaki doğrulanmış e-posta | E-postadan hesap var/yok öğrenilir (G-14) |
| Paylaşım ortağı / arkadaş | Rolünü yükseltmek, başkasının notunu silmek, gelen kutusunu doldurmak, sahte gönderen | Rol alanlarına üye dokunamaz, `createdBy`/`updatedBy` zorunlu, kalıcı silme yalnız sahipte, e-posta jetonla karşılaştırılır | Hız sınırı yok (G-13); 'both' rolü her notu düzenler (tasarım) |
| Cihazı eline geçiren | Kilitli notu okumak, bildirimden/widget'tan içerik görmek, yedeği almak | Uygulama kilidi, not kilidi, kilitli içerik kart/arama/widget/bildirim/AI'da gizli, `allowBackup=false`, jetonlar Keystore'da | Yedek dosyası şifresiz (G-11); kilitli notun BAŞLIĞI uygulama içinde görünür (tasarım) |
| Kötü niyetli dosya / bağlantı / paylaşım | Yol geçişli dosya adı, zip bombası, `intent:`/`file:` bağlantısı, sahte `.notpaket`, başka uygulamadan `notlar://` | Ad temizliği tek noktada (`basename`, `sanitize`), bağlantı açıcı yalnız http/https/mailto, derin bağlantı not kilidini atlamaz, FileProvider yalnız önbellek | Arşivler bellekte açılır (G-21); `notlar://new` boş not yaratır (G-20) |
| Kötü niyetli web sitesi | Uygulamayı çerçeveye alıp tıklatmak, jeton çalmak | `frame-ancestors 'none'`, jeton `sessionStorage`'da ve uid'e bağlı, App Check | Tam CSP yok (G-12) |
| Tedarik zinciri (paket, CI action) | Zararlı sürüm, etiketi taşınmış action, sır sızdırma | Kilit dosyaları, osv-scanner, action'lar commit SHA'sına sabit, `GITHUB_TOKEN` salt okunur, gitleaks | `functions/` kilit dosyasız, `npx firebase-tools` sürümsüz (G-19) |
| Güncelleme yolu | Sahte APK kurdurmak | APK yalnız deponun GitHub Release'inden (HTTPS); Android aynı paket adı + aynı imzayı zorlar (`ApkGuncelleme.kt`) | İmza anahtarı çalınırsa savunma yok → anahtar depo dışında |

## Kalıcı kapılar

- `rules-test/` (emülatör) + kapsam özeti — CI `rules` işi; kırmızıysa kural yayınlanmaz.
- `test/security_guard_test.dart` — dışa açık bileşen listesi, koşulsuz kural, CI yetkileri, çerçeve başlığı, bağlantı şeması, kilitli not sızıntı yolları.
- CI `guvenlik` işi — gitleaks (bütün geçmiş) + osv-scanner; uyarı düzeyi.

Yeni dışa açık bileşen, yeni kural eşleşmesi, yeni paylaşım yolu ya da kilitli notu gösteren yeni yüzey eklerken: önce bu sayfadaki satırı, sonra bekçi testini güncelle.
