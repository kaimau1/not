# DEVIR — oto/G2-sablon-cizgi (A/B düzeltme turu, 2026-11-15)

Yapılanlar:
- İlk cihaz A/B (C:/Users/sena/Desktop/ab_apk/run_g2.log): tek kırmızı `not_kapa` LAYOUT altın +%15.
  Ham (ab_hepsi_ham.json) not_kapa layout ms: A 84.9/80.3/75.8/90.7/105.4, B 112.1/85.2/100.9/91.3/105.2.
  Altın 87.4 ×1.15 = 100.5; B ortanca 100.9 (0.4 ms aşım). A/B kuralı "aynı" (B < A en kötü 105.4).
- Kanıt: S45 bütçesi (test/perf_budget_test.dart; liste notu, her 3. madde çizgili, klavye kapa + geri,
  debugPrintLayouts sayımı). G2 başı: dizilme 173 (klavye) / 153 (kapa), kurulum 404 / 1049.
  Birleşme tabanı 05078e55 `lib` ile: 173 / 153, 403 / 1049. `_DividerReveal`'i düz CustomPaint'e
  çevirmek de birebir aynı sayı. → G2'de kapanışı ağırlaştıran kod yok; fark cihaz gürültüsü.
- PB6 4 GERİ ALINMADI (geri almak sayıyı değiştirmez); yine kırmızıysa SB11 → geri al (sabah bakılacak).
- ab_hepsi `phase_sablon`: "+" paneli kaydırılabilir, Şablon grubu katalogun sonunda → bulunamazsa
  panel bir kez yukarı kaydırılır (ölçüm penceresi aynı yolu izler). Cihazda denenmedi.

Sıradaki: yürütücü A/B'yi yeniden koşar (`--altin --teyit 2`).
Test: `flutter test test/perf_budget_test.dart --plain-name S45`
