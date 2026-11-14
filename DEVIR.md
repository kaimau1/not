# DEVIR — P60 kalan kasmalar (dal oto/P60-kalan-kasmalar, main 0fe290ec'den) — DURAKLATILDI 2026-11-14

## Bitti
- (1) VERİ ONARILDI: 3 kat sıçramanın kökü veri — sabitlenmiş "OLCUM kalem pdf" ilk kart olmuştu, not_ac/kb/yaz/not_kapa PDF'li notu ölçüyordu.
  Telefon: `pm clear dev.kaimau.notlar.olcum` → keep_olcum.zip (İKİ KEZ: ilk içe aktarma 67 notu sessizce attı, ayrı görev açıldı) + olcum_ozel.zip + olcum_kalem.notyedek. Tümü 215, sabit 5; ölçülen not "Kitap bilet" (12 madde).
- ab_hepsi (32a65369 + bu commit): `pick_card` OLCUM kartını atlar ve koşu satırına notu yazar; `trim_typed` önceki " deneme yazisi" ekini siler; `--teyit 2` (KALDI ise 2 çift daha, karar tüm koşularla); teyit satırı ilk kararın nedenini yazar.
- ALTIN TABAN yeniden (123b627a): 0fe290ec A=A 8 koşu, GEÇTİ. not_ac/kb/yaz/not_kapa 659/1792/2080/648 → 205/426/961/238 ms (altın). Eski taban git geçmişinde. KONTROL 40 [x].
- S21 (77bcb7f5): aramaya girişte ekran dışı kartlar kurulmadan atılır — not sliver anahtarına arama durumu; harf başına kart 56 → 24 (bütçe düştü), S23 mandalı 2361 → 2282 (main'de de 2282). Cihazda ÖLÇÜLMEDİ: aday APK hazır `C:/Users/sena/Desktop/ab_apk/B_P60_1.apk`.

## Ölçüm: 9c837495 (eski altın commit'i) vs 0fe290ec, temiz veri — YARIDA (A 4 / B 3 koşu, teyit sürerken durduruldu)
- Ortanca UI ms A/B: liste 1325/1316 · menu 235/200 · arama 359/316 · klasor 251/254 · yeni_not 492/444 · not_ac 208/237 · kb 423/420 · yaz 1034/982 · not_kapa 238/235 · sabit_ac 1111/754 · sabit_kay 916/618 · sabit_kb 2335/1758 · ilk kare 209/235.
- SONUÇ: eski "liste +%11 / klasör +%15" kayması temiz veride YOK (veri farkıydı). İlk 3 çiftte F81.2 kötüleşme yok; teyidi tetikleyen yalnız altın: not_ac UI +%16, yaz LAYOUT +%35.
- AÇIK SORU: yaz LAYOUT bu oturumda İKİ APK'da da ~225 (altın oturumunda 164). Şüphe: `trim_typed` liste maddesinde eki silemiyor → madde koşu başına büyüyor. Önce telefonda "Kitap bilet" ilk maddesine bak (ek birikmiş mi), gerekirse sil + trim'i düzelt.

## Sıradaki
1. "Kitap bilet" ilk madde metnini doğrula/temizle; trim gerekirse düzelt.
2. `ab_hepsi.py A_0fe290ec.apk B_P60_1.apk --altin` (S21 aramada iyileşme bekleniyor; arama B en uzun kare 60,9 ms, 6/16 kare > 16 ms).
3. En uzun kareler (A=A): not_ac 77,7 · arama 60,9 · sabit_ac 50,6 · yeni_not 41,9 · not_kapa 41,5 · klasor 40 ms → `scratchpad`taki `prof_evre.py` gibi tek evre profili (vmsvc frame_report + widget_builds) ile kök aranacak.
4. Bitiş: Kuyruk satırı + önce/sonra tablosu, akicilik.md, regresyon listesi, sürüm notu (S21 cihazda doğrulanırsa).

## Düzeltilmeyen (gerekçeli)
- S9 gövde boy karesi 2 = açılış 1 + kapanış 1 (kasma md. 6'nın "tek adım" ideali); hedef "0 (Faz 64)" tuval içindi (0). 0 için panel içeriğin üstünde yüzmeli = tasarım değişikliği.
- Tablet/Seç kipi satır 23: Flutter `SliverReorderableList` her satırı DİZİNLİ GlobalKey ile sarıyor (çerçeve sınırı); çözüm kendi sıralama listesi (çatallama) — denenmedi.
- M6 `_sameVisual` tam silme: kullanıcı kararı (editor.md), ölçülen kasma değil.

## Komut
- `cd tool/perf && PYTHONIOENCODING=utf-8 python -u ab_hepsi.py C:/Users/sena/Desktop/ab_apk/A_0fe290ec.apk C:/Users/sena/Desktop/ab_apk/B_P60_1.apk --altin`
