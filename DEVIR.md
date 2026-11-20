# DEVIR — P83 yazım denetimi v3 (dal oto/P83-yazim-v3)

**Bitti (CI yeşil):** Y-0 ölçüm seti (6a1a3407) · Y-1 ek çözücü + kök sözlüğü (42067e11) · Y-2 harfsiz yazım (faa0c61b) · Y-3 kural tablosu 356 + `kContextFixes` 31 (9437a243). Taban → şimdi: yanlış düzeltme 17 → 0/500, yakalama 124 → 273/300.
- YANLIŞ YOL (Y-1): `kCommonTurkish`'i kök saymak, bağlaçları kök saymak, her yumuşamayı kabul. `quickStem` değişmedi; açık lisanslı büyük kök listesi eklenmedi (ikisi sabah bakılacak).

**Y-4 motor (563f66c8, CI 44754622006 yeşil):** WIP 9d749522 işe yarar → sürdü. `SpellEngine.suggestions` + `tokens`. KANIT düzyazı (`test/spell_corpus/duzyazi.txt`, 9252 doğru kelime): 82 yanlış çizgi (gerçek→gerek, şablon→salon, kısım→kışım, koyu→köyü; otomatik kip de bunları DEĞİŞTİRİYORDU) → harfsiz yazım yalnız Türkçe harfsiz kelimede + 31 kök → 3. 500 doğru: sert çizgi 0, ipucu 8; 300 yanlış: 277'sinde doğru öneride.

**Y-4 arayüz (bu commit):** `AutoSpell.mode` (Kapalı/Yalnız göster/Otomatik; `spell_mode`; yoksa `auto_spell_on` → otomatik, değilse göster; yüklenene dek kapalı) + `revision` (hafıza/notta-dokunma değişince önbellek boşalır). `spell_underline.dart` `SpellMarks` (denetleyici başına, `AppMotion.medium` duraklama, kelime + paragraf önbelleği, 4 ms dilim — kendi Timer'ı, alan kapanınca iptal; yazımda işaret kayar, değen/bitişen düşer; ek etiketi adı süzülür). `tag_chips.dart` CustomPaint `painter:` dalgalı/noktalı çizgi (ağaç şekli aynı; IME oluşturma aralığı ve son yazılan kelime çizilmez). Dokunuş → `showSpellMenuAfterTap` → `spellContextMenu` (öneriler · Sözlüğe ekle · Hep böyle düzelt: x · Bu notta dokunma). `SpellModePicker` levhada ve Ayarlar'da (eski "Otomatik düzelt" anahtarının yerine). Hızlı satır düğmesi otomatik ↔ göster.
- YANLIŞ YOL: dilim arası `Future.delayed(Duration.zero)` — sahipsiz zamanlayıcı, alan kapanınca iptal edilemez → testte "Timer still pending" (her editör testi riskte); çözüm: dilim kendi `_timer`'ını kurar, baştan başlar (biten kelime önbellekte).
- Karar: `runHeavy` yerine dilimli ana iş parçacığı taraması (web'de izole yok + `SpellMemory` kopyası) — sabah bakılacak. Düz çizilen (dokunulmamış) madde satırında çizgi yok, başlıkta denetim yok.
- Ölçüm: S57 "denetim açıkken 5 tuş" kök 0 / satır 0; S1–S56 yeşil (yerelde tam `perf_budget_test`). kasma-kontrol 8 madde: yeni alan yok, satır önbelleği girdisi yok, kök setState yok, sarmalayıcı yok, boy animasyonu yok. Cihaz A/B YAPILAMADI (cihaz yok).

**Sıradaki:** belgeler (OTOMASYON P83 bitti, PLAN 1.4/2, regresyon, hafıza editor.md, KONTROL "Telefonda bak", sürüm notu 20 Kasım TR/EN) → push → CI.
**Ölçüm:** `flutter test test/spell_corpus_test.dart test/spell_underline_test.dart` · `flutter test test/perf_budget_test.dart --plain-name S57`.
**Not:** Flutter `C:/src` altında YOK; 3.47.9 scratchpad'de (`flutter analyze` SDK klasörünü tarayıp düşüyor → `dart analyze --fatal-infos lib test tool`). main (1d750105) dala birleştirildi (0fb13fe2).
