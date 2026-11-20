# DEVIR — P83 yazım denetimi v3 (dal oto/P83-yazim-v3)

**Yapılanlar:**
- Y-0 ölçüm seti: `test/spell_corpus/dogru.txt` (500), `yanlis.tsv` (300, tür sütunlu), `test/spell_corpus_test.dart` (mandal).

**Taban (Y-0, davranış değişmedi, boş bellek):**
- Yanlış düzeltme 17/500 (%3,40): listemde→liste de, yazdım→yazım, çalışmıyor→çalışıyor, gelmiyor→geliyor, yapmıyor→yapıyor, almaz→al az, yapmaz→yap az, alıp→alış, gelerek→gelecek, bekliyor→geliyor, koşu→kolu, gerekecek→gelecek, bunda→bu da, buraya→burada, nereye→nerede, başkası→başladı, yanı→yani.
- Yakalama 124/300 (%41,3): harfsiz 18/65, komsu 37/45, eksik 15/35, fazla 2/35, yer 14/30, bitisik 14/35, kural 11/30, agiz 13/25.

- Y-1 (42067e11) ek çözücü `lib/core/utils/tr_morph.dart` (sağdan sola kök+ek, ünlü uyumu, D/C benzeşmesi, k→ğ, kökte yumuşama/ünlü düşmesi/ikizleşme, -yor daralması) + elle kök sözlüğü `tr_roots.dart`; `SpellMemory.known` = sıklık ≥3 ∨ keep ∨ ek çözücü (önbellekli), `knownToken` (özel ad + kesme). Yanlış düzeltme 17→0/500, yakalama 124→152/300, 500 doğrunun hepsi bilinir; ~33 µs/kelime.
- YANLIŞ YOL: `kCommonTurkish`'i kök saymak ("geldi" → "geldimi" bilinir), bağlaçları kök saymak ("yinede"), her yumuşamayı kabul ("icin" ← iç) → kapatıldı (tek heceli yumuşama listesi, g yalnız n'den sonra, ikizleşme listesi, -ki yalnız hâl ekinden sonra, istek "-(y)A" atıldı).
- `quickStem` DEĞİŞTİRİLMEDİ (ASCII katlı metinde çalışır, ı/i ayrımı yok; P84 paralelde) — tek kök bulucu sabah bakılacak. Açık lisanslı kök listesi eklenmedi (lisans/APK boyu sabah bakılacak).

- Y-2 `SpellEngine.asciiRestore` (c/g/i/o/s/u → Türkçe harf, 2^n ≤ 8 konum; tek bilinen karşılık → `SpellReason.ascii`, çoksa dokunma, cihaz önerisi seçerse o; kural tablosu biçimi de sayılır "hersey" → "her şey") + sonda yinelenen harf ("kitapp" → "kitap", bulanığın kök/uzantı körlüğü). Kısa İngilizce kelimeler `kCommonEnglish`'e ("one" → "öne" olmasın). Yakalama 152→216/300 (harfsiz 31→64/65, fazla 2→33/35), yanlış düzeltme 0/500. Sıcak `nearest` ~0,2 ms/kelime (test makinesi; ön dizin Y-6'da).

**Şu anki adım:** Y-3 kural tablosu.

**Sıradaki:** Y-1 → Y-2 → Y-3 → Y-4 (her biri ayrı commit + push).

**Ölçüm komutu:** `flutter test test/spell_corpus_test.dart` (çıktıda YANLIŞ DÜZELTME / YAKALAMA satırları).

**Not:** Flutter bu makinede `C:/src` altında YOK; 3.47.9 scratchpad'e indirildi (CLAUDE.md bulut yolu).
