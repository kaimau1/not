# DEVIR — P60 kalan kasmalar (dal oto/P60-kalan-kasmalar, main 0fe290ec'den)

## Yapılanlar
- KÖK NEDEN (3 kat sıçrama = VERİ): ab_hepsi `not_ac/kb/yaz/not_kapa`'yı ilk kartta ölçüyor; veri yeniden kurulunca
  sabitlenmiş "OLCUM kalem pdf" ilk kart oldu (uiautomator dökümü 2026-11-14: ilk ⋮ = OLCUM kalem pdf) → PDF'li not ölçüldü.
- ab_hepsi: `pick_card` OLCUM kartlarını atlar + koşu satırına açılan notu yazar; `trim_typed` önceki koşuların
  " deneme yazisi" ekini pencere dışında siler (not koşu başına 56 karakter büyüyordu); `--teyit 2` (KALDI ise 2 çift daha, karar tüm koşularla).
- Telefon: `pm clear dev.kaimau.notlar.olcum` → keep_olcum.zip içe aktarma (240).

## Şu an
- İçe aktarma sürüyor; sonra olcum_ozel.zip + olcum_kalem.notyedek (Yedekten geri yükle), A=A (A_0fe290ec.apk) ölçümü.

## Sıradaki
- Temiz veride A=A `--altin-yaz` (eski altin_taban silinip yeniden; KONTROL 40), gecmis.py ile gerçek kaymalar.
- S9 gövde boy karesi 2 = tek adım (kasma md.6 ideali); 0 için panel yüzmeli = tasarım değişikliği.

## Komut
- `ADB=C:/Users/sena/Desktop/ab_apk/adbd.bat python -u tool/perf/ab_hepsi.py ../../../../ab_apk/A_0fe290ec.apk <aynı> --altin`
