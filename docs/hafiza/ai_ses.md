# Hafıza — Ses ve yapay zekâ

HAFIZA.md'den cümle değiştirilmeden taşındı (F58.2, 2026-11-10). Tam eski hâl: `HAFIZA_ARSIV_3.md`.

## Ses ve yapay zekâ
- Seslendirme tek kapı `SpeechService`; Antalia ONNX isteğe bağlı, yalnız
  Android + tr.
- Sohbet tek ekran `AiChatScreen` (Tüm notlar / Bu not / Bu belge).
  **"Tüm notlar" getirmeli** (F18.18): soruyla alakalı en çok 12 not
  (anlamsal arama; dahili modda gömme yok → kelime örtüşmesi
  `keywordRelevant`) bağlamın başında 1500 karakterle, kalan son notlar
  300 karakterle (toplam 80); yanıtta kaynak not çipleri (`ChatTurn.sources`,
  modele gitmez). İlgili notlar (F18.17) `relatedNotesProvider` aynı yol.
- AI isteği içeride Gemini `contents`; HTTP tek istemci `package:http`
  (`StreamedRequest` gövdesi `addStream` + `whenComplete(close)`).
- Asistan araçlarında `reminderRepeat` argümanı var; tarih ve tekrar
  cümleden yerelde de çıkarılır (`parseSpokenDateTimeNow`,
  `parseSpokenRepeat` tr+en).
- **AI kotası** (kullanıcı kararı 2026-11-02, F18.2/F18.3): sayaç istemcide
  kalır, `aiQuota/{uid}` sunucu saatli YUVARLANAN 24 saat; koruma web App
  Check + Google Cloud kota/bütçe (F19.A1/A2). Ayarlar yenilenme saatini
  gösterir (`aiQuotaRenewsAtProvider`). Sunucu kotası yalnız Play'e çıkılırsa
  (F18.28).
- **App Check** (F18.1): Android Play Integrity (debug sağlayıcısı debug'da),
  web reCAPTCHA Enterprise yalnız `RECAPTCHA_SITE_KEY` derlemeye verildiyse;
  firebase_ai jetonu kendiliğinden taşır. Zorlama konsolda, önce izle
  (elle kurulan APK'yı Play Integrity doğrulayamaz).
- **Google girişi yedeği** (tablet bulgusu 2026-11-02): yerel seçici
  (Credential Manager) yapılandırma hatası verir ya da < 1,5 sn'de "iptal"
  dönerse (seçici hiç açılmadı) Firebase tarayıcı akışına
  (`signInWithProvider`/`linkWithProvider`) düşer
  (`AndroidGoogleAuth.shouldUseBrowserFlow`). Web'de seçici hep
  `prompt: select_account`.
- AI çıktıları `AiCache`te (cihazda). Ek metni indeksi
  `attachment_text_<uid>.json`.

## Merkezi asistan bırakıldı (2026-11-02)
- Kullanıcı: asistan (`com.ses.asistan`) çok pil yiyordu; ses her uygulamanın içinde. Kişisel alıcıdan
  `ASISTAN_SORGU` ve asistan sertifikası silindi; `HARITA_NOT` (Harita, Kanallarım) aynen. `image` eki
  şimdilik gönderen yok (yalnız asistan yolluyordu) — Kanallarım/Dosya Okuyucu notunda kullanılabilir.

## 2026-11-08 — Oturum B (arama, yazı tipi, Gmail, takvim pratikliği)
- **Dikte:** `_writeDictationAtCaret` sonunda `_revealCaretSoon()`; panel açılışında da.


## Dikte klonu (2026-11-10)
- Kök: tanıyıcı duraklamada `onEndOfSpeech` deyip AYNI sesi yeniden döküyor; MainActivity yeni segment sayıp
  `X\nX'` yazıyordu. Final birebir aynıysa `commitPartial` geri alıyordu, kısa/farklıysa klon kalıyordu; Dart
  `dictationMerge` kısalmayı yok saydığından geri alınan klon da ekranda kalıyordu.
- Düzeltme: `core/utils/speech_segments.dart` `collapseRepeatedSegments` — `VoiceListenSession` her olayda
  uygular (levha + editör): ardışık parça öbürünün baş tekrarıysa ya da kelimelerin ≥%75'i aynıysa uzun olan
  kalır (önceki <3 kelimeyse dokunulmaz). `dictationMerge` kısalmayı, düşen kuyruk yeni metinde varsa kabul
  eder (`droppedTailIsRepeat`). Kotlin `commitPartial` önceki satırın baş kısmı olan parçayı eklemez.
  Test `test/speech_segments_test.dart`. Cihazda doğrulanmadı.

## Tablette dikte çalışmıyordu (2026-11-13)
- Huawei (GMS'siz) tablet: `isRecognitionAvailable` true ama varsayılan servis ya hiç `onReadyForSpeech` demiyor (error=11 gürültü diye yutuluyordu → panel açık, metin yok) ya da metinden önce ölümcül hata veriyor. Ses kaydı (record) çalışıyor.
- Çözüm (MainActivity): tanıyıcı ADAYLARI (varsayılan + `queryIntentServices(RecognitionService)`); oturum hazır olmadan 4 sn bekçi, metin gelmeden ölümcül hata (ağ/meşgul/izin hariç) ya da metinsiz hızlı restart döngüsü → sıradaki aday; hepsi düşerse `speech_unavailable` + `notlar_speech/broken_at` (7 gün `speechAvailable` false; ilk metinde silinir). Dart: `VoiceListenSession.onUnavailable` → editör dikteyi kapatıp `_captureVoice` (levha kayıt yoluna), levha `_fallBackToRecording`. Kasma: dikte kartının nabız/dalga animasyonu RepaintBoundary'siz editör gövdesini her kare boyuyordu → `_DictationPanel`, `ListeningWaveform`, `ListeningBadge` kendi katmanında (bekçi `voice_unavailable_test`). Cihazda doğrulanmadı (KALANLAR L13).

## 2026-11-15 — P63 PB5 dinleme kartı (G4)
- `ListeningWaveform` silindi → `VoiceLevelWave` (oturumun `level`'ı; kayıt yolunda `reportLevel`). Kabuk `ListeningSurface` (dikte kartı + levhanın bütün evreleri), başlık `ListeningHeader`. Anahtar `listening-card-<kip>` yüzeyin kendisinde (`surfaceKey`; dış `Align` tam en).
- Sessizlik: kart `silence` notifier'ı alır, 2 dp çizgi yuvası hep ayrılmış (boy sabit); `silenceHint` verilirse alt yazı değişir (editör `voiceAutoStopSoon`); levha `setState`'i yalnız 0 ↔ > 0.
- Testte dikte: `DeviceSpeech.debugAvailable = true` + `EventChannel('dev.kaimau.notlar/speech')` taklidi + `dev.kaimau.notlar/system` yöntem taklidi; bitişte kanal iptali gerçek zaman ister (`tester.runAsync`). Bütçe S43.

## 2026-11-15 — Görev başına model sırası (dal oto/model-sirasi)
- Kök neden: otomatik zincir ve "Önerilen" `rankModels` desenlerinden (`flash-lite`→`flash`) geliyordu; desen kotayı bilmiyor → Nano Banana 2 Lite (görüntü, kota 0) ve hesapta olmayan 3.1 Flash Lite Preview öneriliyordu, zincir TTS/embedding dahil HER kimliği deniyordu.
- Artık tek tablo: `model_catalog.dart` `geminiChains` (ModelChain: general/long/voice/tts/transcribe; desen kimliğe ya da görünen ada, ek ` preview| latest| sayı`). Kaynak kullanıcının AI Studio ücretsiz limit tablosu; kota değişince YALNIZ bu tablo güncellenir. Katalogda olmayan satır atlanır (kimlik uydurulmaz).
- `GeminiService.chainOf(AiTask)`; çağrı yerleri `task:` geçer (`preferModel` yalnız istisna). Gemma (shortOnly) yalnız general + JSON'suz + düz metin < 24K karakter. Transcribe ve Gemma 400'de de sıradakine geçer.
- `ModelCooldown` (bellek): 429 gövdesinde `PerDay` ya da 404 → Pasifik gece yarısına dek (sabit UTC-8), diğer 429 → 1 dk. "Son çalışan modeli hatırla" (`_activeModel`) kaldırıldı. TTS (`speech`) de 429'da sıradakine geçer.
- Seçici: `pickerModels` (Tümünü göster kapalı → yalnız zincir; açık → `dedupeByLabel`), `validChoice` (katalogda olmayan seçim → Otomatik; servis de yok sayar). Test `test/model_chain_test.dart`.
- Yapılmayanlar: Live API uygulamada yok (canlı çeviri metin yolu, `translate` → long). Embedding → aşağıdaki K-S2 bölümü. Dahili (Firebase) yolun `geminiModelPreference` listesi değişmedi.
- **Kısa işler ayrı görev** (`AiTask.short`, anahtar `model_short`, zincir `ModelChain.short`; Ayarlar → Modeller "Başlık ve etiket"; eski "Özet, başlık, etiket ve sohbet" → "Özet ve sohbet"): sıra Gemma 4 31B → 26B → 3.5/3.1 Flash Lite → Flash zinciri. Bağlı: `generateTitle`, `suggestTags`, `matchSettings` (girdi küçük, çıktı birkaç kelime; Gemma'nın 14.4K RPD'si Flash Lite'ın 500'ünü özete/sohbete bırakır). Gemma JSON kipini desteklemez → etiket ve ayar arama artık DÜZ METİN ister ("a, b"); `parseTagList`/`parseIndexList` JSON da kabul eder. Etiket girdisi `shortTaskInputChars`=4000'e kırpılır (16K TPM); 24K'yı aşan girdide Gemma zaten atlanır (`_isShortText`). Flash Lite önde kalanlar: özet/analiz/brifing/yeniden yazma/e-posta/çalışma kartı/taslak (çıktı uzun ya da kalite), `tidyCapture` (çıktı = tüm metin, JSON), PDF/OCR/sohbet/çeviri (long).
- Göç (`AiTaskModelsNotifier.build`): `model_short_migrated` bayrağı yoksa ve `model_chat` elle seçilmişse `model_short`'a bir kez kopyalanır; Otomatik → Otomatik. Bayrak, sonra Otomatik'e alınan kısa işin geri göçmesini önler.

## 2026-11-15 — K-S2 Embedding 2 (dal oto/embedding-2)
- Kimlik resmî belgeden (aistudio.google.com/docs/embeddings, ai.google.dev yönlendiriyor): `gemini-embedding-2`. Girdi 8.192 belirteç (001: 2.048), boyut 128–3072 (biz 256), `taskType` ALANI YOK → önek: sorgu `task: search result | query: …`, belge `title: none | text: …`. Kesilmiş boyutu kendisi normalize eder (biz yine normalize ederiz). 001 ile vektörler UYUMSUZ. Ücretli: 2 $0,20 / 001 $0,15 / 1M belirteç; ücretsiz katmanda ikisi de bedava. Hesap kotası ikisinde de 100 RPM / 30K TPM / 1K RPD.
- Gerçek: vektörler KALICI DEĞİL (yalnız `SemanticIndex` belleği; Firestore'da yok) → "aşamalı göç / eski vektörü sil / kota ile ertesi gün sür / Ayarlar ilerleme satırı" gereksiz, yapılmadı; rules-test gerekmedi. Her açılışta zaten tümü yeniden gömülüyor.
- Yapılan: `embedTexts(model:, query:)`; `SemanticIndex` her vektörde model kimliği, skor yalnız aynı modelin sorgu vektörüyle, model farklıysa bayat sayılıp yeniden gömülür. Embedding 2 404/429/400-403/boş → oturum boyunca 001 (o çağrıdaki notlar 001 ile yeniden gömülür); bağlantı hatası düşürmez. Test: `test/semantic_index_model_test.dart`.
- ~~Bilinen sınır: her açılışta tüm notlar gömülür~~ → aşağıdaki kalıcı önbellekle çözüldü.

## 2026-11-15 — Kalıcı arama vektör önbelleği (dal oto/arama-onbellek)
- Kök neden: `SemanticIndex` yalnız bellekteydi → her açılışta ilk arama tüm defteri gömüyordu (450 not ≈ 170K belirteç > 30K TPM; günlük 1K istek her açılışta). İkinci kusur: Embedding 2'de tek 429 (RPM bile) oturumu 001'e kilitliyordu.
- Depo: `<appSupport>/semantic_vectors_<uid>.bin` (özel dizin, ikili: 'SVC1' + kayıt = anahtar `id|model|boyut` + gömülen metnin md5'i + Float32 LE). İlk aramada tembel yüklenir (açılış yolu dokunulmadı). Web: dosya yok → yalnız bellek (localStorage'a yazılmadı: SharedPreferences web'de açılışta hepsini okur). Yeni bağımlılık yok (`crypto`, `path_provider` zaten vardı).
- Bayatlık: metin özeti (md5) — `updatedAt` değişip metin aynıysa yeniden gömme YOK. `_digests` (updatedAt+ek boyu → özet) toPlainText'i her aramada tekrar etmemek için. Silinen + KİLİTLENEN notun kaydı silinir (`pruneTo` kilitlileri dışarıda bırakır). Embedding 2 ile dolum bitince başka model/boyut kayıtları silinir.
- Kota: `_Pacer` dakikalık sabit pencere, payın %80'i (80 istek / 24K belirteç, ~3 karakter/belirteç tahmini); kalan pay sorgulara. Eksikler tek parçaya sığıyorsa arama bekler (küçük defter = eski davranış), sığmıyorsa önbellektekilerle hemen döner, parçalar arka planda; her parçada `revision` (ValueNotifier) artar → `semanticSearchProvider`/`scoped…` `invalidateSelf`.
- Model seçimi ortak `GeminiService.cooldown`dan: `embedTexts` 429/404'te `cooldown.hit` yazar (gövdede PerDay → gün). `ModelCooldown.remaining()` eklendi; Embedding 2 soğuması > 2 dk (RPD/404/400-403/boş yanıt) → 001 o gün; RPM 429 → aynı modelle bekle (en çok 3 kez), bekleme başlayınca bekleyen arama bırakılır (o arama sorgusu 429 alırsa düz metne düşer).
- Çıkış: `confirmAndSignOut`, `confirmAndSwitchAccount`, hesap silme → `SemanticIndex.deleteStore(uid)` (statik `_wiped` kümesi süren dolumun dosyayı geri yazmasını engeller).
- Test: `test/semantic_index_model_test.dart` (isabet, içerik değişimi, silinen not, model göçü, RPM 429 kilitlemez, çıkış temizliği). Arka planda çok parçalı dolum (>80 not, 60 sn pencere) birim testte yok — cihazda bakılacak.
- **Çöp ↔ budama döngüsü (T14, 2026-11-17):** ana `semanticSearchProvider` `pruneTo`'ya yalnız aktif notları veriyordu → çöpteki notun vektörü her ana aramada silinip çöpte anlamca arama onu yeniden gömüyordu (iki arama açıkken `revision` dinleyicisiyle birbirini tetikleyen döngü, kapalıyken boşa API isteği). Kök düzeltme: canlı küme = aktif + ÇÖP (`trashStreamProvider` izlenir; cihazda hatırlatıcı servisi zaten dinler, yeni okuma yok); çöp listesi yüklenmemişse o tur budama YOK (kalıcı silinenle çöptekini ayıramayız). Bekçi `test/semantic_trash_cache_test.dart` (önce 2 gömme, sonra 1).

## 2026-11-18 — AI-S2 ✨ levhası 3 bölüm (P72, PLAN §1.6)
- Bölüm FİİLE göre (not/ek ayrımı değil): **Yaz** (sesli not en üstte — kullanıcı isteği 2026-10-20 korunur; Düzelt, Geliştir, Çevir) · **Sor** (Sohbet = A1; her PDF için "Sor" satırı = A4, PDF açılır satırından taşındı) · **Dönüştür** (Özet = A7; PDF/slayt özet + dinle, görselde metin tanı = A5, ses/video döküm = A2; kayıtlı özet en altta). l10n: `aiSectionNote/Attachments` → `aiSectionWrite/Ask/Transform`.
- Levhada Play'den kalkan yetenek yok → `PlayBuild` kapısı gerekmedi. Bütçe S54: aç/kapa editör gövdesi 0, `AiSheet` kökü 1. Sohbet satırı anahtarı `ai-sheet-chat`.

## 2026-11-18 — AI-S0/AI-S1 sadeleştirme (dal oto/P68-ai-sadelestirme, PLAN §1.6)
- **Altın set (AI-S0):** `tool/ai_altin/set/*.json` — 10 yetenek (A1…A8, KART, OZET) × 10–12 Türkçe örnek; her örnek `girdi` + makinece ölçüt (`icermeli`, `icermemeli`, `birini_icermeli`, uzunluk/oran, madde, liste, `arac`, `dil`) + insan için `beklenen`. Puan = geçen ölçüt / toplam; yetenek puanı örnek ortalaması. Kural: AI-S3…S10 her değişiklikten ÖNCE ve SONRA koşulur, fark DEVIR'e.
- Koşu: `GEMINI_API_KEY=... flutter test tool/ai_altin/altin_kos_test.dart` (anahtar yalnız env; yoksa test atlanır; `ALTIN_YETENEK=A7,A8` süzer; `ALTIN_ONCEKI=<json>` önce/sonra farkı). Rapor `build/ai_altin/sonuc_<zaman>.json`. Dahili (Firebase) yol kullanılmaz. Bekçi (anahtarsız): `test/ai_altin_set_test.dart`.
- Vekiller (bugün ayrı işlevi olmayan adımlar, ilgili AI-S fazında değişir): A2 = döküm metni → `summarizeNote` (ses dosyası yok); A4 soru = belge metni → `askAboutNoteText` (PDF baytı yok, sayfa kaynağı AI-S6); A5 = cihaz OCR metni → `rewriteText` yapılandırma yönergesi.
- **Tümden kalkanlar (AI-S1):** `analyzeNote` (✨ "Analiz et" döşemesi; aynı soru A1 Sohbet "bu not"), `analyzeTrash` (çöp levhasında yalnız cihaz kuralları; `TrashReason.ai` ve `trashDigest` silindi), `summarizeArchive` (arşiv levhasında yalnız cihaz özeti), `matchSettings` (ayar araması yalnız yerel anahtar kelime; ✨ düğmesi ve katalog gitti), ölü `tidyCapture`. 14 l10n anahtarı silindi. `model_chain_test` "24K → Gemma atla" testi `pickDropTarget`'a taşındı.
- **Play'den kalkanlar:** `PlayBuild.aiPodcast` (Dinle ekranında podcast düğmeleri), `PlayBuild.aiVoice` (Gemini seslendirme: ayar seçicisinde yok, `TtsEngineNotifier` → cihaz, `SpeechService.aiAvailable` false), `PlayBuild.videoNote` (ek menüsünde "Videodan not", video satırı AI toparlama → yerel kesit). E-postadan not Gmail ekranında → `PlayBuild.gmail` ile zaten gizli. Kişisel APK'da hepsi aynen. Bekçi `test/play_build_test.dart` (bayraklı/bayraksız).


## 2026-11-18 — P70 AI kullanıcı yüzü + istemci korumaları (dal oto/P70-ai-riza, PLAN §1.5 PL3/PL2)
- **Tek kapı:** `lib/features/ai/data/ai_policy.dart` `AiAdmission.check` — sıra: kullanıcı kapattı (`aiTurnedOff`) → `config/app.aiKillSwitch` (`aiPaused`) → Play rızası (`aiConsentNeeded`) → yerel hız sınırı (`rateLimited`, detail `local`). `GeminiService` ağa çıkan HER yolda `_admittedKey()` / `_apiKey()` ile önce bunu çağırır; doğrudan `_keyStore.read` yalnız yardımcıda ve iki model listesinde (bekçi sayar: 3). Yeni AI yolu eklerken `_admittedKey()` kullan.
- **Durum:** `AiAvailability.turnedOff / paused / consentNeeded` (`aiAvailabilityProvider` başta). `looksLocked`: rıza kilit sayılmaz (✨ kalır, dokununca rıza kartı). `AiStatusCard`: kapalı → "Yapay zekâyı aç"; rıza → ne/nereye/yanılabilir/nasıl kapatılır + Kabul/Vazgeç; acil kapatmada anahtar düğmesi yok. `showAiStatusSheet` kaydırılabilir (rıza dört paragraf).
- **Gizleme:** `Personalize.aiOff` (kayıt `ai_user_off`, `attach`'ta okunur) `UiPrefs.shows`'ta Yapay zekâ eklentisini (`barAi`, `homeAi`) gizler; kayıttaki seçim `storedShows` (düzen modu/eklenti durumu onu kullanır). Ray'daki AI bölümü gizlenmedi (dizin eşlemesi) → kilitli; hub kartı açıklar.
- **Rıza KARAR (en güvenli, sabah bakılacak):** `PlayBuild.aiConsent` = yalnız Play; kişisel APK/web sorulmaz. Kabul `ai_consent_v1` (metin özü değişirse sürüm artır).
- **Bildir:** eskiden yanıt METNİ `users/{uid}/aiReports`'a yazılıyordu (not içeriği sunucuya kopyası) → artık yalnız `ErrorLog` (`ai-report`, kaynak + uzunluk). `AiResultNote` ("AI yanılabilir" + Bildir): AI levhası sonucu, sohbet (alt satır, bildir balonda), `AiTextResult` (brifing).
- **Acil kapatma:** `lib/core/ai_kill_switch.dart`, değer `saveCadenceSyncProvider` dinleyicisinden (ayrı okuma yok; istemci yazmaz). Hız sınırı `AiRateLimiter` dakikada 30 / saatte 300, gömmeler sayılmaz. Sunucu tarafı eksikleri `docs/play_hazirlik.md` "AI korumaları".
- Bütçe: S29 toplam 474 → 502, S36 toplam 1038 → 1051 ([butce]; yeni ayar satırı, ilk/en ağır kare aynı). S16 bayt (448 940 > 448 925) bu dalın tabanında da kırmızı — bu işle ilgisiz.
- Bekçi `test/ai_policy_test.dart` (bayraksız + `--dart-define=NOTLAR_PLAY=true` yeşil). Cihazda doğrulanmadı.

## 2026-11-18 — P76 Gemini Decisions API (dal oto/P76-decisions, PLAN U8, `docs/plan_decisions_api.md`)
- **Tek servis:** `lib/features/ai/data/decisions/decision_service.dart` — `POST /v1beta/decisions`, `gemini-decision-1` (uzaktan `aiDecisionsModel`). ASLA istisna atmaz: bayrak kapalı / anahtar yok (dahili kip vekili YOK) / kapı reddi / 400 / 429 / 5xx / 1,5 sn zaman aşımı → `null` → çağıran BUGÜNKÜ yoluna düşer (`ErrorLog` `decision-fallback`, içerik yok). 429/5xx sonrası 1 dk susar. Bellek içi önbellek 32 kayıt / 5 dk. Kendi hız sınırı (30/dk), AI isteklerinin sayacını yemez.
- **Tek kapı korunur:** anahtar `GeminiService.admittedDecisionKey()` (`_admittedKey(metered:false)` → AI'ı kapat / kill switch / rıza; yalnız `AiProvider.gemini`). Yeni dosyada `keyStore` YOK (`test/decision_service_test.dart` bekçisi).
- **Bayraklar** (`config/app`, istemci yazmaz, `AiDecisionsFlag.apply` ← `saveCadenceSyncProvider`): `aiDecisionsFeatures` (canlı), `aiDecisionsShadow` (gölge: eski yol aynen, karar yalnız `ErrorLog` `decision-shadow`; Play'de yok sayılır). Kimlikler: `dropTarget`, `noteTriage`, `titleOk`, `spellFixOk`. Alan yok = hepsi kapalı.
- **Profiller** `decision_profiles.dart` (eşikler orada): DA-1 hedef `choice` (≥0,80 uygula, 0,50–0,80 seçili gelir ama sorulur, altı eski `pickDropTarget`; sondaki ad `stripDropTargetWords` ile yerelde ayıklanır); DA-2 yalnız "Etiket öner" çipinde (kendi etiketlerin noul ≥0,70, klasör ≥0,75 ortak/gizli hariç, başlık/hatırlatıcı ≥0,75 — hepsi öneri çipi, dokunulmadan uygulanmaz; etiket çıkmazsa üretken öneri); DA-13 `checkedTitle` (AI başlığı noul; hayırsa `generateTitle(avoid:)` bir kez; elle başlık gelmez); DA-14 Hızlı ekle geri sayımında bulanık düzeltmeler N noul, ≤0,50 → o eklemede uygulanmaz (`quickDropVetoed`, kalıcı hafızaya yazılmaz).
- **Gerçek API biçimi (canlı koşu 2026-11-18):** `score.probabilities` ve `legend` NESNE (anahtar "0","1"…); `usage`: `total_tokens`, `total_input_tokens`, `total_output_tokens` (0), `input_tokens_by_modality`; 429 gövdesi `error.code = too_many_requests` (ücretsiz katman, ~84 ardışık çağrı / 50K TPM). Fikstür `test/fixtures/decisions/probe_noul_choice_score.json`. Gecikme bilgisayardan P50 ~270–400 ms, P95 0,5–1 s.
- **Altın set:** `tool/ai_altin/decisions/*.json` (4×30) + `decisions_puan.dart` + `decisions_kos_test.dart` (`GEMINI_API_KEY` yoksa atlanır). Sonuç: dropTarget/titleOk 30/30, triage %98, spellFix 29/30 ama ECE 0,15 (> 0,10) → kapalı kalır. Üretken taban koşulmadı; set kendi yazdığımız → iyimser. Bayrak açmadan önce gölge kip ölçümü (sabah bakılacak).
