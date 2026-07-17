# Not Uygulaması — Hafızası

Tarihli, append-only. İş başında oku; iş sonunda kalıcı karar/bug-kök/tuzak varsa ekle. Sır/anahtar/kişisel veri YAZILMAZ.

## Kararlar (tarihli, append-only)

- 2026-07-16: **Proje kuruldu** — Flutter + Firebase not uygulaması (dal: `claude/notes-firebase-sync-app-ihwzev`). Firebase `notlar-kaimau` projesi gerçek değerlerle bağlandı; Firestore/Storage kuralları `firebase.json` üzerinden CLI ile yayınlanabilir.
- 2026-07-16: **Özellik paketi**: hatırlatıcılar, etiketler, arşiv/çöp, ses+çizim, AI sohbet, OCR, widget. **AI paketi**: asistan, sesli komut, semantik arama, günlük brifing, otomatik etiket, notu geliştir, PDF sohbet. **Çeviri**: Gemini 3.5 Live Translate ile canlı konuşma çevirisi. **Sesli hızlı yakalama**: "Hey Google, Notlar'ı aç" + tek dokunuş akışı.
- 2026-07-16: **CI imzalı APK** GitHub Secrets üzerinden kalıcı imza. TUZAK: workflow'da `secrets` bağlamı step `if:` içinde kullanılamaz → kontrol bash adımına taşındı. (Runner arızası yaşandı, yeniden tetiklemeyle çözüldü.)
- 2026-07-16: graphify kod grafı + otomatik tazelik hook'ları kuruldu (usta paketi); CLAUDE.md + bu HAFIZA eklendi.

- 2026-07-17: **Mobil kullanılabilirlik paketi** (dal: `claude/mobile-notes-improvements-8ofm7j`): (1) Liste editöründe Enter'da klavyenin kapanıp açılmasının kökü, `TextInputAction.next`'in varsayılan odak geçişinin metin dışı öğeye gitmesiydi → `onEditingComplete` ile bastırıldı. (2) Dar ekranda arama odaklanınca AppBar aksiyonları gizlenir. (3) Uzun basış artık pin/sil sayfası değil çoklu seçim modu açar; toplu silme + tek "Geri Al". Silme snackbar'ları `fixed` + 3 sn (floating olan FAB'ların üstünde/ortada duruyordu). (4) AI otomatik başlık: editör kapanırken başlıksız nota `fastGeminiModel` (flash-lite) ile başlık; ayarı `auto_title`, varsayılan AÇIK. (5) Hatırlatıcılar ekranı `/reminders` (listele/düzenle/kaldır/manuel ekle). (6) Sesli not bitişinde "Notu aç" — asistan araç yanıtındaki `noteId` yakalanır. (7) Gmail bağlarken `authenticate(scopeHint:)` ile hesap seçici açılır (yalnız `authorizeScopes` seçici göstermeden giriş hesabını kullanıyordu); bağlı e-posta prefs'te (`gmail_account_email`) ve Ayarlar'da gösterilir. TUZAK: OAuth "Testing" modunda 2. Gmail hesabı, Cloud Console'da test kullanıcısı olarak eklenmeden çalışmaz.
- 2026-07-17: pubspec.lock'ta `just_audio_windows` eksikti (pubspec.yaml'a eklenmiş ama lock commit'lenmemiş) → `pub get` ile lock ve Windows plugin registrant dosyaları tazelendi.

## Bilinen Riskler / Tuzaklar

- **Keystore repo dışında** (`Desktop\notlar-keystore\`): kaybolursa aynı imzayla güncelleme yayınlanamaz — ayrı yere yedekle.
- Firestore/Storage kural değişikliği deploy edilmeden canlıya yansımaz (`firebase deploy`).
