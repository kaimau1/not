# Tablet tabanı — HUAWEI MatePad 11 (T1 / PL11, 2026-11-19)

Telefon tabanıyla (`altin_taban.json`) KARŞILAŞTIRILMAZ (PLAN §1.0): ayrı dosyalar `altin_taban_tablet.json`, `gecmis_tablet.csv`.

## Koşul
- Cihaz: MatePad 11 (DBY-W09), 1600x2560 @ 400 dpi = 640x1024 dp, DİKEY (`wm user-rotation lock 0`), sistem karanlık tema, uygulama açık tema, fiziksel klavye (HUAWEI MatePad Keyboard) takılı, misafir hesap (Google/Drive/Gmail "denenmedi").
- Derleme: profil APK, ölçüm kimliği `dev.kaimau.notlar.olcum`, dal `oto/T16-tablet-turu` (main dd55fb09 birleşimi: KW-1, U1, U4, obfuscate CI; profil manifesti ölçüm için YÖN SERBEST — kilit `wm user-rotation` ile; kod/manifest commit'te DEĞİL).
- Komut: `python -u tool/perf/ab_hepsi.py <APK> <APK> --kosu 3 --teyit 0 --altin-yaz` (A = B aynı APK; 6 koşu A,B,A,B,A,B; ortanca; sıcaklık 27,0–27,4 °C, hepsi < 34 °C).
- Veri: ana ölçüm uygulaması verisi (209 not + "OLCUM kalem pdf/bos/cizgi"; geri yükleme `olcum_kalem.notyedek`); ölçüm uygulamasında **"Listeyi tepeden aşağı çekince" = Hiçbiri** (U1 jesti `list_top` fırlatmalarında klasör menüsünü açıp dokunuşları yutuyordu); ilk kart sabit "Kitap bilet" (`yaz` her koşuda ek yazar, `trim_typed` siler).
- **Ekran yenileme hızı:** panel modları 60 ve 120 Hz; SurfaceFlinger `refresh-rate: 60.00fps` (DisplayManager `primaryRefreshRateRange=[0 60]`, etkin mod 60), uygulama Ayarlar → Hakkında "120 Hz" gösteriyor (desteklenen). Kare sayıları bu 60 Hz paneli yansıtır; 120 Hz kipi için ayrı koşu gerekir (sistem ekran ayarına dokunulmadı → kullanıcıdan istenecek: PLAN T1 "60 Hz ayrımı" açık kalır).
- Isınma: koşular 27 °C civarında başlayıp kaldı, pil %100 şarjda; ısınma kaynaklı eleme olmadı. Telefondaki 49 °C sorunu tablette görülmedi.

## Altın taban (ortanca; 6 koşu)
| evre | kare | UI ms | LAYOUT ms | not |
|---|---|---|---|---|
| acilis | 19,5 | 154,9 | 130,3 | ilk kare ~40 ms (A/B ortancaları 52 / 37); **ilk koşu bazen 2 kare** (yeniden kurulumdan sonra ilk başlangıç: VM zaman çizelgesi 145 ms'de kesiliyor, `ReactorGLES::LinkProgram` ×16 = ilk Impeller program derlemesi; 5/6 koşu 18–20 kare) |
| liste | 1236 | 2469,9 | 1294,4 | 8 fırlatma |
| menu | 99,5 | 109,3 | 19,2 | kart ⋮ levhası |
| arama | 18 | 161,9 | 88,5 | 5 harf |
| klasor | 126 | 267,2 | 87,8 | Gelen'e kaydır + Tümü çipi (tablet: sağa kaydırma Gelen'de kalabiliyordu) |
| yeni_not | 196,5 | 290,8 | 51,3 | "+" → Metin notu |
| not_ac | 70 | 111,4 | 51,6 | |
| kb | 174 | 306,4 | 124,6 | ⌨ AÇ/KAPA + alana dokunuş ×3 |
| yaz | 384 | 682,9 | 101,5 | 4 × " deneme yazisi" |
| not_kapa | 88,5 | 238,6 | 72,7 | |
| sabit_ac | 332 | 498,7 | 133,0 | "OLCUM kalem pdf" |
| sabit_kay | 451 | 495,1 | 104,7 | 3 sayfa kaydırma |
| sabit_kb | 787,5 | 1233,2 | 285,6 | |
| sablon | 209,5 | 257,0 | 57,0 | "+" → Hazır şablonlar → Planlama |
| bicim | 847 | 1679,4 | 90,3 | çizgi tepsisi aç/kapa ×3 + tür seç ×3 |
| kalem | 1002 | 1247,5 | 236,1 | kalem kipi + 10 çizgi + kapsül ×3 |
| duzen | 194 | 308,2 | 64,2 | düzen modu 6 dokunuş + Bitti |

A = B (aynı APK) karşılaştırması: 17 evrenin hepsi `aynı/iyi` (en büyük A↔B fark `sabit_kay` UI +%4,4); yani tablet gürültüsü telefondakinden belirgin düşük (±%5).

## RAM tabanı (PL11; `python -u tool/perf/ram_taban.py`, dikey, her durum sıfırdan başlatma + 5 sn)
| durum | PSS MB | RSS MB | Java | Native | Graphics | Code |
|---|---|---|---|---|---|---|
| ana ekran | 296 | 369 | 19 | 40 | 79 | 76 |
| editör (liste notu) | 356 | 470 | 19 | 43 | 111 | 96 |
| PDF (sabit, "OLCUM kalem pdf") | 375 | 488 | 19 | 58 | 111 | 99 |
| kalem kipi (10 çizgi) | 357 | 471 | 18 | 46 | 111 | 91 |
| YouTube | denenmedi | | | | | | veri setinde YouTube'lu not yok; ağ + WebView gerekir → kullanıcı turuna (KONTROL) |

## Kalan / dürüstlük
- Yatay (sol ray genişletilmiş + bölünmüş görünüm, K32) ölçülmedi: profil APK'sının yön kilidi + yatay ölçüm betik desteği (yalnız yön zorlama var) → öneri T16 raporu.
- 120 Hz paneli ve 1000/3000 not veri setleri (T1) yapılmadı.
- Güncelleme sonrası `[apk]` A/B'sinde taban `--altin` ile bu dosyaya karşı karşılaştırılır (`ab_hepsi.py` tablette otomatik `altin_taban_tablet.json` seçer).
