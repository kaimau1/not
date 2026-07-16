# CLAUDE.md — Not (Flutter not uygulaması)

Flutter + Firebase (Firestore/Storage senkron) not uygulaması; Android + Windows hedefli. AI özellikleri Gemini tabanlı: asistan, sesli komut, canlı konuşma çevirisi, semantik arama, OCR, PDF sohbet, günlük brifing. Dil: Türkçe.

> 🔐 **İmza anahtarı repo DIŞINDA**: `Desktop\notlar-keystore\` — asla commit'leme, grafa/zip'e katma; **kaybolursa aynı imzayla güncelleme yayınlanamaz, yedeğini ayrı yerde tut.** CI imzası GitHub Secrets üzerinden.

## Komutlar
- Kurulum: `flutter pub get` · Çalıştır: `flutter run` · Test: `flutter test`
- APK: CI push'ta imzalı üretir (`.github/workflows/`); elle: `flutter build apk`
- Firestore/Storage kural değişince: `firebase deploy` (yapılandırma `firebase.json`)

## Hafıza (usta koordineli — 3 katman)
- Kod yapısı        → graphify-out/     (oku: GRAPH_REPORT.md · güncelle: commit'te hook otomatik, elle `graphify update .`)
- Proje ne/niye     → HAFIZA.md         (oku: iş başı · yaz: iş sonu karar/bug-kök/tuzak, tarihli append-only)
- Kullanıcı tercihi → .claude memory/   (otomatik, projeler-arası — proje bilgisi buraya YAZILMAZ)
Yaz kuralı: usta rule 12 / YAZ — tetikleyici (kalıcı karar, bug kök nedeni, yanlış yol) oluştuysa iş bitmeden yaz. Sır/anahtar/kişisel veri hafızaya YAZILMAZ.
