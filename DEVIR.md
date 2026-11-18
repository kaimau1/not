# DEVIR — oto/P68-ai-sadelestirme (P68: PLAN §1.6 AI-S0 + AI-S1)

Taban: P66 dalının PL1 commit'i `a8401c61` (PlayBuild) — main'e P66'dan SONRA birleşmeli.

- AI-S0 (ff6e191a): `tool/ai_altin/set/*.json` 10 yetenek × 10–12 örnek, `altin_puan.dart` (saf
  puanlayıcı), `altin_kos_test.dart` (canlı; `GEMINI_API_KEY` env, yoksa atlanır), bekçi
  `test/ai_altin_set_test.dart`. CANLI KOŞU YAPILMADI — anahtar bekliyor (taban puanı yok).
- AI-S1 tümden (5bc9c322): analyzeNote (ai_sheet döşemesi), analyzeTrash (çöp levhası AI düğmesi,
  TrashReason.ai, trashDigest), summarizeArchive (arşiv levhası AI kısmı), matchSettings (ayar
  araması ✨ kipi), tidyCapture silindi; 14 l10n anahtarı; guide_tr/en "Analiz et" satırı.
- AI-S1 Play (cdf09255): PlayBuild.aiPodcast / aiVoice / videoNote; e-posta → Gmail kapısı.
- Yapılmayan (kapsam dışı): AI-S2 ✨ levhası 3 bölüm, A1 öneri çipleri (outline/brainstorm),
  AI-S3…S10. Play'de ses ayarında tek segment (yalnız Cihaz) kalan SegmentedButton gizlenmedi.
- Test: `flutter test test/ai_altin_set_test.dart test/play_build_test.dart test/trash_analysis_test.dart
  test/archive_insights_test.dart test/settings_search_test.dart test/model_chain_test.dart
  test/perf_budget_test.dart --reporter failures-only` (+ play testi `--dart-define=NOTLAR_PLAY=true`).
- Canlı: `GEMINI_API_KEY=... flutter test tool/ai_altin/altin_kos_test.dart` → build/ai_altin/.
