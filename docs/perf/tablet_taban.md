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

## A/B 2026-11-19 (ÖLÇÜM KAPISI, `[apk]` öncesi: A = `a77b1cc4` v1.2.91, B = main `75493691` P72–P78)
Aynı tablet/koşul (MatePad 11, dikey, 26–27 °C, `--altin`); iki profil APK'sı `--build-name=1.2.999 --build-number=9001` ile derlendi (yoksa ana ekranda "Yeni sürüm var: v1.2.91" bandı çıkıp tablet piksel tablosunu kaydırıyordu, `home_locate` ⋮ levhasını bulamadı). Tur 1: `--kosu 3 --teyit 2` (5A+5B); tur 2 (teyit): `--kosu 2 --teyit 0` (2A+2B). İlk deneme "gövde alanı bulunamadı" ile düştü, aynı komut yeniden koşunca sorunsuz (anlık semantik boşluğu).

**KARAR: KALDI (araç; iki turda da).** Gerekçe tek madde, ölçüm yolu farkı: `menu` evresi altına karşı B LAYOUT 31,3 / 25,1 ms (altın 19,2; +%63 / +%31; mutlak +6…12 ms) — B önceki `[apk]` A'dan çok daha iyi (UI 123 vs 291–299 ms, LAYOUT 25–31 vs 122–130). Tur 2'deki `not_ac KÖTÜLEŞTİ` yalnız 2 A koşusunun ortalaması: koşu 2A `not_ac` = 8,5 ms (dokunuş boşa gitti, 38 kare) → ölçüm artefaktı; tur 1'de 5+5 koşuyla aynı evre A 101,1 → B 104,9 (+%4).
**Neden `menu` kıyas dışı:** A koşuları "tablet ilk kart" (boş semantik → `GEO_1600` piksel tablosu, ⋮ geometri), B koşuları "Kitap bilet. 12 madde. Sabitle" (dolu semantik → ⋮ semantik düğümü) yolundan geçti; yani B ana ekranı boşta uygulamada semantik ağacı gönderiyor, A göndermiyor (A↔A de altın tabanla [T16: aynı geometri yolu] 109/19 vs şimdi 291–299/122–130 farklı → evre yolu/sıra duyarlı). Altın tabanı değiştirmedim.

| evre | A UI ms | B UI ms | A LAYOUT | B LAYOUT | karar (tur 1, 5A+5B) |
|---|---|---|---|---|---|
| acilis | 134,7 | 126,0 | 120,7 | 111,2 | aynı/iyi |
| liste | 2448,9 | 2496,8 | 1319,6 | 1352,5 | aynı/iyi (+%2) |
| menu | 291,5 | 122,7 | 122,3 | 31,3 | aynı/iyi; altın +%63 (LAYOUT) — yukarı |
| arama | 159,5 | 157,0 | 95,6 | 95,1 | aynı/iyi |
| klasor | 246,8 | 227,4 | 98,5 | 81,0 | aynı/iyi |
| yeni_not | 296,3 | 285,4 | 44,2 | 45,8 | aynı/iyi |
| not_ac | 101,1 | 104,9 | 45,3 | 48,2 | aynı/iyi |
| kb | 300,1 | 303,6 | 121,9 | 122,2 | aynı/iyi |
| yaz | 1128,2 | 696,2 | 190,8 | 98,4 | aynı/iyi (A tek koşu 1183 ms sıçraması; tur 2: 658,9 → 683,8, +%3,8) |
| not_kapa | 230,4 | 224,1 | 68,8 | 72,0 | aynı/iyi |
| sabit_ac | 449,0 | 468,7 | 130,3 | 129,7 | aynı/iyi |
| sabit_kay | 490,2 | 487,2 | 106,1 | 104,7 | aynı/iyi |
| sabit_kb | 1166,7 | 1184,6 | 260,9 | 276,0 | aynı/iyi |
| sablon | 262,4 | 261,4 | 54,7 | 55,0 | aynı/iyi |
| bicim | 1651,5 | 1582,2 | 86,9 | 84,3 | aynı/iyi |
| kalem, duzen | — | 1325,4 / 297,8 (tur 1 son koşu) | — | 232,6 / 58,7 | A'da ölçülemedi: A koşularının hepsinde "'Kalemle yaz' düğmesi yok" + uygulama launcher'a düştü (araç, A'nın ana ekran yolu); yalnız B var → tablet altınına göre kalem UI 1247,5 → ~1325 (+%6), LAYOUT 236,1 → 232,6; duzen 308,2 → 297,8 (−%3): altın içinde |

İlk kare: A 27 / B 26 ms (tur 2: 39,5 / 23,5). Evre UI/LAYOUT'ta önceki `[apk]`'ya göre > %20 kötüleşen yok (B ≤ +%5 hepsinde; yalnız `menu` ölçüm-yolu farklı ve B lehine); tablet altınına göre > %15: yalnız `menu` LAYOUT (+6…12 ms mutlak). Şüpheli değişiklik: ⋮ kart levhası (P72 ✨ levha satırı / P74 jest hedefleri) LAYOUT'u ~+6…12 ms büyütmüş olabilir; yol farkı yüzünden KANITLANMADI. Düzeltme önerisi: `home_locate` B'nin dolu semantiğini kullansın ya da altın tabanı bu yol için yeniden yazılsın (`--altin-yaz`, kullanıcı kararı).

### U5 (P75 süre çizgisi) bildirimli yazma — elle, tablet dikey
Senaryo: açık not (Kitap bilet), ⋮ → "Notu çoğalt" (bildirim "Not çoğaltıldı · Geri al", 4 sn), alana dokun, 6 × `input text " deneme yazisi"` 0,55 sn aralıkla (≈3,3 sn, bildirim açıkken); kontrol: aynı yazma bildirimsiz. 2 tekrar toplamı, VM zaman çizelgesi (Flutter'da `gfxinfo` kare saymaz; kare = `Animator::BeginFrame`, janky = UI > 16 ms):

| | bildirimsiz yazma (kare / UI ms / LAYOUT ms / janky) | bildirimli yazma (kare / UI ms / LAYOUT ms / en uzun kare / janky) |
|---|---|---|
| A (v1.2.91, Timer 8 adım/sn) | 258 / 1091,9 / 395,2 / 0 | 339 / 823,9 / 278,6 / 17,7 ms / 1 (%0,3) |
| B (P75 AnimationController) | 264 / 1112,5 / 402,7 / 0 | 811 / 1112,6 / 263,5 / 8,8 ms / 0 (%0) |

Okuma: B bildirim açıkken ≈2,4× kare çiziyor (her vsync; ödünleşim beklendiği gibi) ama kare başı maliyet küçük (ortalama 1,4 ms); bildirimli yazmada janky % A'dan kötü DEĞİL (0 vs 1), en uzun kare 17,7 → 8,8 ms. UI ms toplamı +%35 (kare sayısı yüzünden) — pil/ısı etkisi için kullanıcı turu ("bildirim varken kasma" 11-16 kapandı sayılır; ısınma ölçülmedi). Önceki iki deneme (alana yeniden dokunmadan) yazı girmediği için geçersiz sayıldı. Ölçüm uygulamasında "Notu çoğalt" kopyaları (11) geri alınmadığından birikti; temizlendi (10+1 not çöp kutusunda; liste 209 / Sabit 3 eski hâlinde).

## Faz 5 Doğrulaması — `9005` (2026-11-27, dikey + yatay + RAM + K-20/K-21)
- **Derlemeler (`dev.kaimau.notlar.olcum` `1.2.999+9005`, ARM64 profil):** Dikey `64.059.187` bayt; yatay (`NOTLAR_OLCUM_YON=landscape`) `64.068.856` bayt. Dikey APK ile `--yon yatay` red kontrolü (`KT-17(c)`) temiz durdu (`çıkış 1`).
- **`K-21` yenileme hızı & Ayarlar satırı:** MatePad 11 ana ekranda ve sanal klavye (`SwiftKey`) açıkken `NotlarEkran: etkin 120.00001 Hz (mod 2, 1600x2560) · istenen 120.00001 Hz (mod 2)` ve `mActiveModeId=2` ile `120 Hz` korunuyor; `l15_ayarlar.png` Uygulama sürümü satırı `1.2.999 (9005) · 120 Hz` gösteriyor.
- **`K-20` `panel_kayit.py`:** MatePad 11 HarmonyOS'ta `/system/bin/screenrecord` ikilisi yok (`inaccessible or not found`, çıkış `1`); açık/kapalı ekran görüntülerinde alt panel SwiftKey üzerinde temiz, `kb` evresinde `0 >16 ms` UI karesi var (`K-20` video kaydı Android telefon gerektirir).
- **Dikey `ab_hepsi.py --kosu 3 --teyit 0 --altin` (`26,0 → 27,2 °C`, 6 koşu A=B `opt9005_dikey`):** İlk kare ortancası **A `26` / B `27` ms** (`altın ~40 ms`); öne çıkan medyanlar (A / B UI, LAYOUT): `acilis 142.7/149.8`, `liste 2511.8/2471.2`, `menu 111.7/111.6 (LAYOUT 21.2/33.4 — A=B gürültü, altın 19.2)`, `kb 508.8/501.8 (169.0/162.7, max 15.7 ms, 0 >16)`, `yaz 677.1/656.6 (LAYOUT 79.4/77.8, 0 >16)`, `not_kapa 190.3/178.0 (LAYOUT 48.6/43.7 vs altın 72.7)`, `bicim 1534.7/1487.1 (LAYOUT 39.9/37.3 vs altın 90.3, 0 >16)`, `sabit_kay 506.0/470.5 (0 >16)`, `sabit_kb 1280.4/1235.8 (0 >16)`, `kalem 1363.7/1268.4 (0 >16)`.
- **5 durum RAM (`ram_taban.py --etiket optimizasyon_9005_20261127 --youtube "OLCUM yt video"`, `26,9 °C`, çıkış `0`):**
  - `ana ekran`: PSS `363` / RSS `468` MB (`Java 19`, `Native 46`, `Graphics 111`, `Code 92`)
  - `editör`: PSS `373` / RSS `478` MB (`Java 20`, `Native 45`, `Graphics 111`, `Code 98`)
  - `PDF`: PSS `409` / RSS `514` MB (`Java 21`, `Native 76`, `Graphics 111`, `Code 101`)
  - `kalem`: PSS `369` / RSS `475` MB (`Java 21`, `Native 47`, `Graphics 111`, `Code 93`)
  - `YouTube` *(YouTube kartlı/ekli not açılışı; geçici not Çöp dahil kalıcı silindi, `209 | Tümü`)*: PSS `375` / RSS `480` MB (`Java 20`, `Native 46`, `Graphics 111`, `Code 98`)
- **Yatay `tur_gez.py yatay`, `32 İki not yan yana` ve `ab_hepsi.py --yon yatay` (`2560x1600`, `27,2 / 27,1 °C`):**
  - `tur_gez.py yatay` (`TUR_YATAY_EXIT=0`): `l30_editor_liste`/`yanda_ac` içinde yüzen kalem düğmesi `Ara başlık` ve `İşaretliler · Sil`'i örtmüyor (`P78(a)`); `l33_pdf` ve `kt17b_9005` sol listede `"Başa dön"` (`540, 1450`) `"Yeni not"` (`690, 1450`) düğmesinin solunda aynı satırda (`KT-17(b)`); `32 İki not yan yana` (`yanda_ac_9005.png`) sol listeyi gizleyip iki notu yan yana açtı, `☰` listeyi açtı-kapattı (`3` kart) ve `✕` ikincil notu kapattı.
  - `ab_hepsi.py --yon yatay --kosu 1 --teyit 0` (`AB_YATAY_EXIT=0`): `17/17` evre koştu (ilk kare `A 27 / B 23 ms`, `kb` `0 >16`, `yaz` `0 >16`, `sabit_kay` `0 >16`, `sabit_kb` `0 >16`, `bicim` `0 >16`, `duzen` `0 >16`; `phase_kalem` sol liste yüzünden `kalem hapı yok` atladı, `menu` LAYOUT A=B gürültüsü `20.5/26.3`).
- **Kapanış:** `9005` dikey APK geri yüklendi, `adb logcat -d -s flutter AndroidRuntime` `0` `flutter`/istisna satırı, ortak kilit bırakıldı (`BIRAKILDI` → `BOS`).

## Faz 5 Doğrulaması — `9006` / `9007` (2026-11-28, `v1.2.150+` Görünüm Stüdyosu + Ekler + Arapça RTL)
- **Derlemeler (`dev.kaimau.notlar.olcum` `1.2.999`, ARM64 profil):** `9006` (`9da8bd5d`) ve `9007` (`theme_picker.dart` 360 dp tek satır düzeltmeli, `53.349.287` bayt).
- **4 durum RAM (`ram_taban.py --etiket v1_2_150_9006`, `25,4 °C`):** Tüm durumlarda `9005`'e göre net düşüş:
  - `ana ekran`: PSS `331` / RSS `437` MB (`9005`: `363 / 468` MB → **-32 MB PSS**)
  - `editör`: PSS `359` / RSS `465` MB (`9005`: `373 / 478` MB → **-14 MB PSS**)
  - `PDF`: PSS `371` / RSS `478` MB (`9005`: `409 / 514` MB → **-38 MB PSS**)
  - `kalem`: PSS `360` / RSS `467` MB (`9005`: `369 / 475` MB → **-9 MB PSS**)
- **Eşli `9005` vs `9006` (`ab_hepsi.py --kosu 2 --teyit 0 --altin`, `25,8–26,7 °C`):** `16/17` evre `aynı/iyi` (`liste 2495.5 → 2395.3`, `arama 173.4 → 160.9`, `sabit_ac 500.7 → 475.2`, `sabit_kay 498.9 → 466.7`, `bicim 1501.8 → 1472.7`, `duzen 308.8 → 299.6`); `yaz` yalnız `1B` tekil sıçramasıyla (`1116.6`, `2B: 662.7`) işaretlendi.
- **4 koşulu `9007` kararlılık ve `--altin` doğrulaması (`B_9007` vs `B_9007`, `--kosu 2 --teyit 0 --altin`, `25,0 → 26,6 °C`, açık kip):**
  - İlk kare ortancası: **A `33.5` / B `27.0` ms**. `17/17` evre `aynı/iyi`; `16/17` evre `altın içinde` (yalnız `kb` `layout_ms` `168.3` ms — `9005` tabanıyla aynı seviye, `max 15.2 ms`, `0 >16`).
  - `yaz` koşuları: `1A: 1181.9` *(ilk ısınma sıçraması)*, `1B: 677.7`, `2A: 644.5`, `2B: 685.9` → `B` ortancası `681.8` ms (`LAYOUT 83.6`, `max 8.1 ms`, **`0 >16`**, `altın içinde`).
  - Öne çıkan `B` medyanları (`UI ms / LAYOUT ms`): `acilis 140.2/124.8`, `liste 2451.4/1293.6`, `menu 103.3/21.9 (altın içinde)`, `arama 154.0/91.4`, `klasor 242.6/91.3`, `yeni_not 292.6/51.5`, `not_ac 114.6/52.5`, `kb 514.4/168.3 (0 >16)`, `not_kapa 189.4/47.4`, `sabit_ac 480.5/122.3`, `sabit_kay 493.1/99.8 (0 >16)`, `sabit_kb 1262.2/272.2 (0 >16)`, `sablon 254.8/55.0`, `bicim 1492.1/37.4 (0 >16)`, `kalem 1290.6/225.1 (0 >16)`, `duzen 309.3/60.5`.
- **Arayüz & Arapça RTL turları (`tur_gez.py dikey`, `verify_9006_tablet.py`, `verify_arabic_and_light.py`):** Görünüm Stüdyosu (`Tema` Açık/Koyu/Otomatik + `Zemin` + `Düzen`), `Arayüz düzeni`, `Görünüm ve süz`, `Sesli dinle` (Antalia yok), `Notlar ve klasörler`, `Şablonlar v2`, `Akıllı Liste v2`, Sabit PDF klavye kontrolleri (`Küçült` / `Klavyeyi gizle`), Arapça RTL (`v09_arabic_rtl` Ayarlar + `v09b_arabic_home` Ana ekran — sağdan sola taşmasız dizilim) doğrulandı; `Türkçe` + `Açık` kip geri yüklendi; `adb logcat -d -s flutter AndroidRuntime` `0` hata; ortak kilit bırakıldı (`BIRAKILDI` → `BOS`).
