# Not Uygulaması — Hafızası

Tarihli, append-only. İş başında oku; iş sonunda kalıcı karar/bug-kök/tuzak varsa ekle. Sır/anahtar/kişisel veri YAZILMAZ.

## Kararlar (tarihli, append-only)

- 2026-07-16: **Proje kuruldu** — Flutter + Firebase not uygulaması (dal: `claude/notes-firebase-sync-app-ihwzev`). Firebase `notlar-kaimau` projesi gerçek değerlerle bağlandı; Firestore/Storage kuralları `firebase.json` üzerinden CLI ile yayınlanabilir.
- 2026-07-16: **Özellik paketi**: hatırlatıcılar, etiketler, arşiv/çöp, ses+çizim, AI sohbet, OCR, widget. **AI paketi**: asistan, sesli komut, semantik arama, günlük brifing, otomatik etiket, notu geliştir, PDF sohbet. **Çeviri**: Gemini 3.5 Live Translate ile canlı konuşma çevirisi. **Sesli hızlı yakalama**: "Hey Google, Notlar'ı aç" + tek dokunuş akışı.
- 2026-07-16: **CI imzalı APK** GitHub Secrets üzerinden kalıcı imza. TUZAK: workflow'da `secrets` bağlamı step `if:` içinde kullanılamaz → kontrol bash adımına taşındı. (Runner arızası yaşandı, yeniden tetiklemeyle çözüldü.)
- 2026-07-16: graphify kod grafı + otomatik tazelik hook'ları kuruldu (usta paketi); CLAUDE.md + bu HAFIZA eklendi.

## Bilinen Riskler / Tuzaklar

- **Keystore repo dışında** (`Desktop\notlar-keystore\`): kaybolursa aynı imzayla güncelleme yayınlanamaz — ayrı yere yedekle.
- Firestore/Storage kural değişikliği deploy edilmeden canlıya yansımaz (`firebase deploy`).
