# DEVIR — oto/P70-ai-riza (P70: PLAN §1.5 PL3 + PL2 istemci)

Taban: `ccr-bde27ee2-8r5lmj` (7791606b). PUSH YOK (bulut gece işçisi).

## Yapılanlar
- a66be7f9 `[butce]` PL3: tek kapı `AiAdmission` (lib/features/ai/data/ai_policy.dart), "Yapay zekâyı tümden kapat"
  (Ayarlar → Yapay zekâ ilk satır; `Personalize.aiOff` editör ✨ + ⋮ Yapay zekâ gizler), Play'de rıza kartı
  (`PlayBuild.aiConsent`), `AiResultNote` "AI yanılabilir" + Bildir (artık yalnız yerel ErrorLog, metin yok).
- 4d869d7a PL2: `config/app.aiKillSwitch` (lib/core/ai_kill_switch.dart, saveCadenceSync dinleyicisinden),
  `AiRateLimiter` 30/dk 300/sa (gömmeler hariç), docs/play_hazirlik.md "AI korumaları (PL2)".
- Belgeler: docs/hafiza/ai_ses.md (P70 bölümü), docs/regresyon_listesi.md satırı, bu dosya.

## Kanıt / kök neden
- Eski "Bildir" yanıt metnini `users/{uid}/aiReports`'a yazıyordu (lib/features/ai/data/ai_report.dart) → kaldırıldı.
- Ağa çıkan yollar: gemini_service.dart `_generateFromContents`, `transcribeMedia`, `speech`, `embedTexts`,
  `assistantVoiceNote`, `assistantChat` → hepsi `_admittedKey()`/`_apiKey()`.

## Testler
- `flutter test test/ai_policy_test.dart test/play_build_test.dart --reporter failures-only` (+ `--dart-define=NOTLAR_PLAY=true`) yeşil.
- ai_availability, ai_status_card, terminology, ayar/düzen testleri, model_chain, transcribe_media, semantic_* yeşil.
- perf_budget: S29 toplam 474→502, S36 toplam 1038→1051 (budgets.json `[butce]`, neden yazılı). S16 bayt
  (448940 > 448925) TABANDA da kırmızı — bu işle ilgisiz, sabah bakılacak.
- `flutter analyze` temiz.

## Kalan / sabah bakılacak
- Rıza yalnız Play'de (KARAR en güvenli). Ray'daki AI bölümü gizlenmiyor, kilitli (dizin eşlemesi riskli).
- Sunucu: App Check zorlaması, Function arkasında kota/hız, bütçe tavanı (docs/play_hazirlik.md).
- Cihazda doğrulanmadı: anahtar aç → ✨/⋮ kayboluyor mu, AI ray kilidi, rıza levhası küçük ekranda.
