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

