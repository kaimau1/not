# DEVIR — oto/arama-onbellek

- Yapılan: kalıcı semantik arama vektör önbelleği (`lib/features/ai/data/semantic_search.dart`),
  kota temposu (`_Pacer`), `ModelCooldown.remaining` (`model_catalog.dart`), `embedTexts` 429/404 → cooldown
  (`gemini_service.dart`), çıkış/hesap silmede `SemanticIndex.deleteStore` (`sign_out_actions.dart`, `account_service.dart`).
- Kök neden: `SemanticIndex` yalnız bellekte (eski semantic_search.dart:144-166) → her açılışta tüm defter gömülüyordu;
  `_fallBack` tek 429'da oturumu 001'e kilitliyordu (eski :176-189).
- Kanıt: `test/semantic_index_model_test.dart` yeni grup (6 test) — isabet/değişim/silme/göç/RPM/çıkış; 11/11 yeşil.
  `perf_phase7_test` F7.5 (debugPut) düzeltildi; `perf_budget_test` yeşil (açılış yolu değişmedi).
- Doğrulama: `flutter test test/semantic_index_model_test.dart test/perf_phase7_test.dart --reporter failures-only`, `flutter analyze` temiz.
- Sıradaki: CI yeşil → yürütücü birleştirir (bu DEVIR silinir). Cihazda bakılmadı (KONTROL_LISTEM "Telefonda bak").
