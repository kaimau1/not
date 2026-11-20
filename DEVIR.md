# DEVIR — P83 yazım denetimi v3 (dal oto/P83-yazim-v3)

**Bitti (CI yeşil):** Y-0 ölçüm seti (6a1a3407) · Y-1 ek çözücü + kök sözlüğü (42067e11) · Y-2 harfsiz yazım (faa0c61b) · Y-3 kural tablosu 356 + `kContextFixes` 31 (9437a243). Taban → şimdi: yanlış düzeltme 17 → 0/500, yakalama 124 → 273/300.
- YANLIŞ YOL (Y-1): `kCommonTurkish`'i kök saymak, bağlaçları kök saymak, her yumuşamayı kabul. `quickStem` değişmedi (sabah bakılacak); açık lisanslı büyük kök listesi eklenmedi (sabah bakılacak).

**Y-4 motor (bu commit):** WIP 9d749522 incelendi, işe yarar → sürdü. `SpellEngine.suggestions` (öneri listesi, güven payı yok, bağlama bağlı = `hint`), `SpellEngine.tokens` (paragraf → denetim birimi; bağlantı/sayı/#etiket/kısaltma/cümle ortası özel ad/kesmeli yazım atlanır, sarma çapası kelimeyi bölmez).
- KANIT (düzyazı, `test/spell_corpus/duzyazi.txt` = kılavuz + sürüm notları kopyası, 9252 doğru kelime): boş bellekte 82 yanlış çizgi (bulanık 53: gerçek→gerek, şablon→salon, elektronik→elektrik; harfsiz 21: kısım→kışım, koyu→köyü, acil→açıl; bölme 5: aynen→ay en). Aynı kelimeleri otomatik düzelt kipi de DEĞİŞTİRİYORDU (Y-1'in 500'lük setinde yoktu).
- DÜZELTME: harfsiz yazım yalnız Türkçe harfi OLMAYAN kelimede (`_trLetter`); 31 eksik kök (`tr_roots.dart`). Sonuç 82 → 3/9252 (imleri, dolanı; yunurta bilerek). 500 doğru: sert çizgi 0, ipucu 8 (bende/oda/hala…). 300 yanlış: 279 çizili, 277'sinde doğru öneride. Yakalama 273, yanlış düzeltme 0 korunur.

**Sıradaki (Y-4 arayüz):** `AutoSpell.mode` (Kapalı/Yalnız göster/Otomatik; `spell_mode` int; yoksa `auto_spell_on` true → otomatik, değilse göster) + `revision`; `spell_underline.dart` `SpellMarks` (denetleyici başına, 350 ms duraklama, kelime + paragraf önbelleği, 4 ms dilimli tarama, yazımda işaretler kaydırılır); `tag_chips.dart` CustomPaint `painter:` (ağaç şekli aynı) dalgalı çizgi; dokununca `showToolbar` + menü (öneriler · Sözlüğe ekle · Hep böyle düzelt · Bu notta dokunma); ayar `SpellModePicker` (sheet + Ayarlar). Sonra perf S57 "denetim açıkken 5 tuş", kasma-kontrol, belgeler.
- Karar: `runHeavy` yerine dilimli ana iş parçacığı taraması (web'de izole yok + `SpellMemory` kopyası) — sabah bakılacak.

**Ölçüm:** `flutter test test/spell_corpus_test.dart` (YANLIŞ DÜZELTME / YAKALAMA / ALTI ÇİZİLİ / DÜZYAZI satırları).
**Not:** Flutter `C:/src` altında YOK; 3.47.9 scratchpad'de. main (1d750105) dala birleştirildi (0fb13fe2).
