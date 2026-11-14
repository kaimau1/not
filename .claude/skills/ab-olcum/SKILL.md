---
name: ab-olcum
description: Cihazda A/B hız ölçümü (ÖLÇÜM KAPISI / HIZ SÖZLEŞMESİ) — taban profil APK'sı, ab_hepsi.py --altin, telefon kuralları, karar eşikleri. [apk] öncesi ya da Cihaz=A/B paketinde çağır.
---

# Cihaz A/B ölçümü

CLAUDE.md "ÖLÇÜM KAPISI" + "HIZ SÖZLEŞMESİ" ve OTOMASYON.md "Telefon kuralları" + 6./8. adım
buraya taşındı (2026-11-14), AYNEN. Gerekçe (kullanıcı 2026-11-10): "son güncellemelerden sonra
kasma yeniden başladı… bunları çözmek için baya zaman ve token harcadık, zamanında kontrol et."

## Ne zaman (bağlayıcı)

- **ÖLÇÜM KAPISI (2026-11-10):** editör, klavye, alt/üst çubuk, ana ekran listesi ya da geçişe
  dokunan iş `[apk]`'ya girmeden önce cihazda A/B ölçülür.
- **HIZ SÖZLEŞMESİ (2026-11-12, tedbirler `docs/hafiza/akicilik.md` "Hız sözleşmesi"; eski plan `docs/arsiv/planlar/HIZ_PLANI.md`):**
  1. Yeni özellik/güncelleme hangi yüzeye dokunursa (editör, liste, geçiş, levha, arama, açılış,
     ekler) o yüzeyin cihazsız bütçe senaryosu `test/perf_budget_test.dart`'ta olmalı — yoksa
     işin parçası olarak YAZILIR (OTURTMA Ek A'ya S satırı).
  2. Her `[apk]` öncesi cihazda tam ölçüm (`tool/perf/ab_hepsi.py --altin`) — önceki `[apk]`'ya
     karşı %20, altın tabana karşı %15 kayma = birleştirme yok. APK noktasında paket A/B
     istemese bile ZORUNLU (F83.1); telefon yoksa `[apk]` ertelenir, birleştirme `[apk]`'sız.
  3. Hız/akıcılık işlerinde kötüleşme SIFIR; madde başı ayrı commit, kötüleştiren tek commit
     geri alınır, iyiler birleşir.
  4. Mandallar (`budgets.json`, tasarım bütçesi, altın taban) yalnız düşer.
  Ölçmeden "akıcı/hızlı" denmez.
- **Yürütücü ölçümü KENDİ yapmaz:** derlemeler bitince `Agent` `model: "sonnet"` alt ajana
  ("iki APK, `ab_hepsi.py <A> <B> --altin`, tabloyu ve son satırı getir").

## Taban ve aday derleme

- Taban (A) = önceki `[apk]` commit'i: `git worktree add ../not_ab <commit>` → orada
  `flutter pub get` → profil derlemesi. Aday (B) = dal başı, aynı bayraklarla.
- `"C:/src/flutter/bin/flutter.bat" build apk --profile --target-platform android-arm64 --dart-define-from-file=env.json --build-number=<N>`
  — ölçüm uygulaması kimliği `dev.kaimau.notlar.olcum` ("Notlar Ölçüm"); derleme yapılandırması
  profil APK'sını bu kimlikle üretir, doğrula (`aapt dump badging` ya da kurulum sonrası
  `adb shell pm list packages | grep olcum`). `env.json` yoksa Google girişi çöker.
- Ölçüm bitince taban ağacı silinir: `git worktree remove --force ../not_ab` (kullanıcı kararı
  2026-11-12: 34 kopya ~onlarca GB birikmişti; silinemiyorsa tutan Gradle sürecini durdur).

## Koşu

`python -u tool/perf/ab_hepsi.py <A.apk> <B.apk> --altin` (bayraklar: `--kosu 3` varsayılan,
`--altin`, `--altin-yaz`, `--etiket-a X`, `--etiket-b Y`, `--commit SHA`; betiğin başındaki
belge dizesi esastır). 13 evre: açılış, liste, ⋮, arama, klasör, yeni not, not aç, klavye,
yazma, kapanış, sabit PDF aç/kaydır/klavye; A,B ×3 sırayla (A,B,A,B,A,B), ortanca, son satır
`KARAR: GEÇTİ|KALDI`, sonuç `docs/perf/gecmis.csv`'ye. Bekleme `timeout` ile (arka planda).
Eğilim: `python tool/perf/gecmis.py [--son 10] [--esik 10]` (kayma > eşik → çıkış 1).
Hazırlık (bir kez): veri seti + sabit PDF'li not ("OLCUM kalem pdf") — betik belge dizesi.

## Karar eşikleri

- Karar `KARAR:` satırıdır. F81.2: bir evrede B ortancası (UI ms ya da LAYOUT ms) A'nın en kötü
  koşusundan da kötü VE fark > %20 VE > 3 ms → KÖTÜLEŞTİ (%10, aynı APK A=A'da yanlış alarm
  verdi, 2026-11-13). Bir evrede UI ms ya da LAYOUT ms %20'den fazla artarsa birleştirme yok —
  önce kök neden; satır `takıldı: ölçüm` + sayılar, sıradaki pakete geç.
- `--altin`: B ayrıca `docs/perf/altin_taban.json`'a karşı, evrede %15'ten fazla kötü → KALDI
  (kümülatif kayma). İstisna: `yaz` LAYOUT ms payı %25 (`ALTIN_PAY`; kullanıcı 2026-11-13,
  gürültü payı).
- **Hız hissi / açılış / yükleme / akıcılık paketlerinde (P39 vb.; kullanıcı 2026-11-12: "hız
  hissinde kötüleşme kabul edilmemeli, mutlaka iyileşmeli") eşik %20 DEĞİL:** hiçbir evre
  kötüleşmez, hedef evre ölçülebilir iyileşir; iyileşme kanıtlanamayan değişiklik yapılmaz.
  Kötüleşirse paket çöpe gitmez: maddeler ayrı commit; kötüleştiren `git revert` + maddeye
  "iyileşme kanıtlanamadı", iyiler yeniden ölçülüp birleşir.
- **En çok 2 tur** (kullanıcı 2026-11-13: "gece boyu ufacık işler yapıp durmuş"; P43 kabulü
  saatler yedi): cihaz kabul ölçümü (A=A, altın taban) 2 turda da kırmızıysa satıra
  `kullanıcı kararı` yaz, aracı/işi birleştir, sıradakine geç — saatlerce ölçüm döngüsü yok.
- Ölçüm ham sayıları DEVIR'e/plana yazılır, sohbette kalmaz.
- Telefon yoksa/ısınmışsa satır `cihaz bekliyor`, birleştirme `[apk]`'sız, ilk APK noktası
  ertelenir. Telefon gerektiren ölçüm yapılamazsa: "yazıldı, cihazda doğrulanmadı" +
  `KONTROL_LISTEM.md` "Telefonda bak"a madde.

## Telefon kuralları (Mi Note 10 Lite, USB)

Kullanıcı 2026-11-06: ekran arızalı, sürekli açık kalınca ısınıyor ("sadece ihtiyaç halinde
ekranı aç"); kilit yok, yukarı kaydırarak açılır. Telefon tek seferde BİR ölçüme.
- `adb devices` boşsa cihaz işi atlanır (`cihaz bekliyor`).
- Ekran yalnız ölçüm/tur sırasında: `adb shell input keyevent KEYCODE_WAKEUP` → yukarı kaydır
  (`adb shell input swipe 540 1800 540 600`); iş bitince `KEYCODE_SLEEP`. Derleme beklerken
  ekran KAPALI. Ekran ~30 sn'de kararır: uyandırma ile dokunuşları aynı komutta gönder.
  `svc power stayon` gibi kalıcı ayar değiştirme. Okuma için ekran görüntüsü yerine
  `uiautomator dump` (ölçüm penceresinde değil — semantiği açar).
- Ölçümden önce `adb shell dumpsys battery | grep temperature` < 370 (37 °C); değilse bekle.
  (`ab_hepsi.py` kendisi her koşuyu < 34 °C'de başlatır, en çok 30 dk bekler, hâlâ sıcaksa
  koşu GEÇERSİZ.)
- **Varsayılan kimlikli uygulamaya ASLA dokunma** (`flutter run/drive` varsayılan kimlikle
  yasak — veri gider); yalnız `dev.kaimau.notlar.olcum`.
- Telefonda misafir hesap: Google/Drive/Gmail akışları "denenmedi".
- Kalem/tablet yok: kalem ölçümü telefonda parmakla (`ab_kalem.py`); tablet isteyen ölçüt
  "tablette doğrulanmadı".
- Koordinatla basmadan önce ekran yönüne ve klavyeye bak (HAFIZA "Cihaz turu tuzakları").
- Telefon yoksa tablette telefon düzeni: `adb shell wm size 1080x2400; adb shell wm density 420`
  (sonra `wm size reset; wm density reset`); fiziksel klavye takılıysa ⌨ ile sanal klavye.
