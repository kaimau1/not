# DEVIR — oto/model-sirasi (kullanıcı isteği 2026-11-15)
Yapılan: WIP abe04f4f tamamlandı. Çağrı yerleri `task:` ile zincire bağlı (commit "Model sırası: görev zincirleri…"), TTS sırası + 429 geçişi, seçicide görev başına Önerilen / gizleme / eski seçim→Otomatik; testler `test/model_chain_test.dart` (17 yeşil); sürüm notu TR+EN 2026-11-15; `docs/hafiza/ai_ses.md`.
Şu an: CI bekleniyor (`gh run list -b oto/model-sirasi -L 1`). Yeşilse bu dosyayı sil, push.
Test: `flutter test test/model_chain_test.dart test/gemini_models_test.dart test/transcribe_media_test.dart --reporter failures-only`.
