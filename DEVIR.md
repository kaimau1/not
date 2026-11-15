# DEVIR — oto/model-sirasi (kullanıcı isteği 2026-11-15)

Kullanıcı: "Modeller alanımızda güncellemesi gerekli, model sıralamasını baştan yap, otomatik modu ayarla". Ayarlar → Modeller seçicisi (görev başına sayfa; "Otomatik (önerilen)", "Önerilen", "Tümünü göster", "Model ara").

Durum: önceki işçi limitle kesildi; WIP abe04f4f (`model_catalog.dart`, `gemini_service.dart` değişti, test yok, CI denenmedi). Diff'i oku, devam et.

## Şu an uygulamada görünen (ekran görüntüsü)
Önerilen her görevde aynı: 3.5 Flash Lite, 3.1 Flash Lite Preview, Nano Banana 2 Lite, 3.1 Flash Lite, 2.5 Flash-Lite, 3.8 Flash, 3.7 Flash, 3.6 Flash. Sorunlar: Podcast anlatısı (TTS) metin modeli öneriyor; Nano Banana 2 Lite görüntü modeli, kota 0; 3.7 Flash ve 3.1 Flash Lite Preview hesabın tablosunda YOK; "Tümünü göster" kapalıyken bile Omni 1.1 Flash, Nano Banana 2.1, Gemini 4 Argon/Carbon, 3.1 Pro Preview, Nano Banana Pro (×2 yinelenen), 2.5 Pro, 2.5 Computer Use listeleniyor.

## Hesabın AI Studio limitleri (ücretsiz; RPM / TPM / RPD; parantez = ay tepe kullanım)
Metin: 3.5 Flash Lite 15/250K/500 (7,26) · 3.1 Flash Lite 15/250K/500 (8,320) · 2.5 Flash Lite 10/250K/20 · 3.8 Flash 5/250K/20 (18 RPD) · 3.6 Flash 5/250K/20 (AŞILDI 5/5, 23/20) · 3 Flash 5/250K/20 · 2.5 Flash 5/250K/20 · Gemini 4 Hydrogen 5/250K/20 (AŞILDI 6/5) · Robotics ER 2 Preview 5/250K/20 (önerme) · Gemma 4 31B ve 26B 30/16K/14.4K (yalnız kısa işler).
KOTA 0: 2 Flash, 2 Flash Lite, 2.5 Pro, 3.1 Pro, Gemini 4 Argon, 4 Carbon, Computer Use, Deep Research Pro, Omni 1.1/1.2 Flash, tüm Nano Banana'lar, Lyria 3, 2.5 Pro TTS.
TTS: 3.8 Flash TTS, 3.8 Flash Lite TTS, 3.1 Flash TTS, 2.5 Flash TTS — hepsi 3/10K/10.
Döküm: 3.5 Transcribe 3/10K/25.
Live (RPM sınırsız): 2.5 Flash Native Audio Dialog (1M TPM), 3 Flash Live (65K), 3.5 Live Translate (20K), 3.5 Transcribe Live (20K), 3.8 Live (65K), 3.8 Live Extended Thinking (65K).
Embedding 2 / 1: 100/30K/1K. (Decision 1, Antigravity: kullanma.)

## Yapılacak
1. Katalog + görev→model + otomatik zincir (grep "3.5 Flash Lite", "flash-lite", "Önerilen", "Otomatik"). API kimliğini katalogdan doğrula; bilinmeyeni UYDURMA, raporla.
2. Görev başına otomatik sıra:
   - Metin (özet/başlık/etiket/sohbet/asistan/brifing): 3.5 Flash Lite → 3.1 Flash Lite → 3.8 Flash → 3 Flash → 2.5 Flash → 2.5 Flash Lite → 3.6 Flash → 4 Hydrogen. Kısa işlerde Gemma 4 31B → 26B Flash Lite'lardan sonra yedek (16K TPM aşan girdide atla).
   - Görsel/PDF/OCR: Flash Lite + Flash (Gemma yok).
   - Podcast/TTS: 3.8 Flash TTS → 3.8 Flash Lite TTS → 3.1 Flash TTS → 2.5 Flash TTS.
   - Döküm: 3.5 Transcribe (+ mevcut metin düşüşü).
   - Canlı çeviri/ses: 3.5 Live Translate → 3.8 Live → 3 Flash Live → 2.5 Flash Native Audio Dialog (mevcut Live kullanımına göre).
   - Semantik arama: Embedding 2 → Embedding 1.
3. 429/kota hatasında sıradakine geç; RPD dolanı o gün (Pasifik gece yarısı), RPM'e takılanı kısa süre atla (var olan mekanizma ya da bellekte zaman damgası).
4. "Önerilen" görev türüne göre; "Tümünü göster" kapalıyken kota 0 ve uyumsuzlar gizli; yinelenenler tekil; listede olmayan elle seçim sessizce Otomatik'e düşsün.
5. Liste tek yerde (katalog sabiti), "2026-11-15" yorumlu.
6. Testler: görev başına sıra, 429 geçişi, gizleme/tekilleştirme, eski seçim → Otomatik. Çeviri gerekirse .arb TR+EN.
- CI yeşil (`gh run list -b oto/model-sirasi`); main'e birleştirme yok; telefona dokunma; `docs/hafiza/ai_ses.md`'ye yaz; anahtar/kişisel veri yazma. Bitince bu dosyayı sil.
