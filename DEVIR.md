# DEVIR — P83 yazım denetimi v3 (dal oto/P83-yazim-v3)

**Yapılanlar:**
- Y-0 ölçüm seti: `test/spell_corpus/dogru.txt` (500), `yanlis.tsv` (300, tür sütunlu), `test/spell_corpus_test.dart` (mandal).

**Taban (Y-0, davranış değişmedi, boş bellek):**
- Yanlış düzeltme 17/500 (%3,40): listemde→liste de, yazdım→yazım, çalışmıyor→çalışıyor, gelmiyor→geliyor, yapmıyor→yapıyor, almaz→al az, yapmaz→yap az, alıp→alış, gelerek→gelecek, bekliyor→geliyor, koşu→kolu, gerekecek→gelecek, bunda→bu da, buraya→burada, nereye→nerede, başkası→başladı, yanı→yani.
- Yakalama 124/300 (%41,3): harfsiz 18/65, komsu 37/45, eksik 15/35, fazla 2/35, yer 14/30, bitisik 14/35, kural 11/30, agiz 13/25.

**Şu anki adım:** Y-1 ek çözücü.

**Sıradaki:** Y-1 → Y-2 → Y-3 → Y-4 (her biri ayrı commit + push).

**Ölçüm komutu:** `flutter test test/spell_corpus_test.dart` (çıktıda YANLIŞ DÜZELTME / YAKALAMA satırları).

**Not:** Flutter bu makinede `C:/src` altında YOK; 3.47.9 scratchpad'e indirildi (CLAUDE.md bulut yolu).
