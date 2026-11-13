# DEVIR — P43 (oto/P43-hiz-olcum)

## Yapılanlar
- F82.1–F82.3 main'de (580e40b1). F81.1/3/5 `tool/perf/ab_hepsi.py` (980cd82c, 3e085383), ilk A/B 260effc7.
- 1. tur kabul KALDI (fd406d24): %10 eşik + 37 °C'de başlama → A=A yanlış alarm.
- 2. tur (sabah): 0b741b8c eşik %20, < 34 °C başlangıç, `--altin-yaz` ≥ 5 koşu (A=B'de 6);
  dbfa1233 ready() null odakta bekler; altın taban 6 koşu A=A ile yeniden (bu commit'ten önceki).
- Kabul A=A: 1. koşu A/B GEÇTİ; 2. koşu `--altin` A/B GEÇTİ, altına karşı `yaz` LAYOUT +%16 → KALDI.

## Şu an / sıradaki (sabah bakılacak)
- %15 altın eşiği HIZ SÖZLEŞMESİ'nde: gevşetilmedi. Karar kullanıcıda: `yaz` LAYOUT (302–377
  oturumlar arası) için gürültü payı ya da altın dışı. Sonra 3. A=A + yavaşlatılmış B (ItemsEditor +5 ms).
- F68.4 → P46 (liste > 16 ms %2,3–3,3).

## Tuzaklar
- `liste` evresi bazı koşularda 1 kare yakalıyor (ortanca etkilenmez).
- AC şarj kesilemiyor; < 34 °C'de koşu ~5 dk + soğuma ~3 dk, 6 koşu ~45 dk.
- Ekran ~30 sn'de kilitleniyor: her dokunuştan önce `ready()`. Git Bash'te `adb push` için `MSYS_NO_PATHCONV=1`.

## Komut
`cd tool/perf && PYTHONIOENCODING=utf-8 python -u ab_hepsi.py <A.apk> <B.apk> --etiket-a .. --etiket-b .. --commit .. --altin`
(aynı APK: `C:/Users/sena/Desktop/ab_A_9c837495.apk`)
