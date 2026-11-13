# OTOMASYON — gözetimsiz iş zinciri

**Kullanıcı izni (2026-11-09):** işleri otomasyonla başlat, istediğin modelde alt ajan aç,
limite göre çalış; test telefonu USB'de (şifresiz, ekranı bozuk: yalnız gerekince aç); işi
bitir, main'e gönder; token israf etme ama bitmiş iş ver.

Plan: `OTURTMA_PLANI.md`. Bu dosya yalnız YÜRÜTME düzenidir. Her tur bu dosyayı baştan okur.

## Nasıl çalışır

- Zamanlanmış görev `not-oturtma-zinciri` her saat :55'te oturum başlatır; limit dolunca
  oturum ölür, sonraki tetik **kaldığı yerden** sürer. Durum: aşağıdaki Kuyruk.
- Zamanlanmış oturum YENİ OTURUM AÇAMAZ. Başka model gereken paket
  `Agent` aracıyla ALT AJANA verilir: `model: "fable" | "opus" | "sonnet"`,
  `isolation: "worktree"`, istem = "`isci` skill'ini uygula" + paketin satırı. `Agent`
  reddedilirse ya da o model yoksa paket BU oturumda yapılır; Kuyruk'a gerçek model yazılır.
- **Yürütücü ince kalır (kullanıcı kararı 2026-11-12: "alt ajanlar daha çok işi yapabilir"):**
  CI izleme, kırmızı CI düzeltme, DEVIR, plan `[x]`, Kuyruk satırı güncellemesi ve sürüm notu
  taslağı ALT AJANIN işidir; yürütücü yalnız raporu, `git log`/diff özetini ve `gh run`
  sonucunu kontrol eder, birleştirir. Paketleri büyük tut (alt ajan başına daha çok madde;
  her alt ajan sıfırdan başlar). Alt ajan beklerken yoklama yok, bildirimi bekle.
- Aynı anda TEK yürütücü. Kilit: `.git/oto.lock` (içinde ISO zaman).

## Bir turun adımları → `oto-tur` skill'i

Yürütücü: **`oto-tur` skill'i** (`.claude/skills/oto-tur/SKILL.md`; kilit, main sağlığı, paket
seçimi, alt ajan, doğrulama, birleştirme/[apk], temizlik, yarım iş devri, limit freni, FABLE
KURALI, diriltme yasağı, takılma önleme, bitiriş — kullanıcı kararları tarihleriyle orada).
Taşındı 2026-11-14 (her oturuma yüklenen bağlam küçülsün).

## İşçi kuralları → `isci` skill'i

Alt ajan istemi: "`isci` skill'ini uygula" + paketin Kuyruk satırı + `KUYRUK_AYRINTI.md` bölümü.

## Telefon kuralları → `ab-olcum` skill'i

Mi Note 10 Lite, USB: uyandır/kaydır/uyut, sıcaklık < 370, varsayılan kimlikli uygulamaya
dokunma, misafir hesap, tablette telefon düzeni — `.claude/skills/ab-olcum/SKILL.md`.

## Kuyruk

Durum: `bekliyor` · `sürüyor` · `bitti` · `takıldı: <neden>` · `cihaz bekliyor`.

Biten paketler: P01–P19, P23–P37, P39, P40, P42, P47 (39; P39 cihaz A/B 2026-11-12: soğuk açılış −5…−11 %, beyaz kare −11…−20 %, liste −46 % kare, klavye gürültü sınırında; ayrıntı sürüm geçmişinde: `-S '| P01 |'`).

| No | Paket | Model | Plan maddeleri | Cihaz | APK | Durum / sonuç |
|---|---|---|---|---|---|---|
| P54b | .md başlık düzeltmesi | opus | P54 devamı | | evet | bitti — main'e birleştirildi 2026-11-13 |
| P43 | Hız: tek komutla tam ölçüm + karar + altın taban + cihazsız bekçiler (P44 katıldı) | opus | HIZ_PLANI F81–F82 + F68.4 | cihaz |  | araç main'e birleştirildi 2026-11-13 (kabul: kullanıcı 2026-11-13 `yaz` LAYOUT'a gürültü payı verdi (ab_hepsi ALTIN_PAY %25) → kapandı) — F82 main'de; F81 araç+altın taban bitti, KABUL KALDI (2. tur: A/B %20 eşikle A=A 2/2 GEÇTİ; altına karşı `yaz` LAYOUT +%16 yanlış alarm — sabah bakılacak); F68.4 ölçüldü (%2,3–3,3) → P46; ayrıntı: KUYRUK_AYRINTI.md §P43 |
| P55 | KASMA KÖKTEN: not aç/kapa, klavye aç/kapa, alt panel titremesi, alt çizgili madde + P46'nın cihaz maddeleri (F84.1–3, F60.S2, F60.5, F68.3) | opus | kullanıcı 2026-11-13 | A/B | evet | bitti — main'e [apk] 2026-11-14 entegrasyonla (P55+P56+P38+P50 tek dal): cihaz A/B 13 evrede A↔B aynı/iyi; KARAR KALDI yalnız altın tabana karşı `acilis` ilk kare +%19 ve `klasor` LAYOUT +%19 — A'da (main) da aynı, değişiklikten değil → kullanıcı kararı (altın taban tazelenmeli mi, sabah bakılacak); log Desktop/ab_entegre.log |
| P56 | Not sürükle-sırala: iki sütun arasında zıplama | opus | kullanıcı 2026-11-13 | A/B | evet | bitti — main'e [apk] 2026-11-14 entegrasyonla (P55+P56+P38+P50 tek dal): cihaz A/B 13 evrede A↔B aynı/iyi; KARAR KALDI yalnız altın tabana karşı `acilis` ilk kare +%19 ve `klasor` LAYOUT +%19 — A'da (main) da aynı, değişiklikten değil → kullanıcı kararı (altın taban tazelenmeli mi, sabah bakılacak); log Desktop/ab_entegre.log |
| P57 | Alt çubuk: her düğme eklenip çıkarılabilir, sıralanabilir (Ayarlar) | opus | kullanıcı 2026-11-13 |  | evet | bitti — bulut 2026-11-13, main'e [apk]: `UiPrefs.barOrder/aiOrder` + 8 eklenebilir düğme (geri al, yinele, hatırlatıcı, fotoğraf, kamera, tara, renk, paylaş); Ayarlar → Kişiselleştir → alt çubuk sürükle-sırala + anahtar; varsayılan görünüş aynı; cihazda doğrulanmadı (KALANLAR L5); kalan: düğmeyi iki kapsül arasında taşıma yok — P50'ye; ayrıntı: KUYRUK_AYRINTI.md §P57 |
| P58 | Klasörde/süzgeçte de basılı tut → çöpe sürükle | opus | kullanıcı 2026-11-13 |  | evet | bitti — bulut 2026-11-13, main'e [apk]: elle sıra kapalı görünümlerde (klasör, süzgeç, arama, etiket) sürükleme yalnız çöp hedefine (`inSection` false → sıra önizlemesi yok, sıra yazılmaz); oynamadan bırakma eskisi gibi seçer; başkasının paylaşılan klasöründe kapalı; kanıt `drag_trash_target_test` (önce kırmızı); cihazda doğrulanmadı (KALANLAR L6) |
| P45 | Hız: her [apk]'da ölçüm + geçmiş | sonnet | HIZ_PLANI F83.1–F83.3 | cihaz |  | bitti — main'e birleştirildi 2026-11-14: F83.1 (8. adım `--altin` zorunlu) + F83.2 (`tool/perf/gecmis.py`); F83.3 (CI kare ölçümü) kullanıcı kararı → P22 kapanış listesi |
| P46 | Hız: ölçümün bulduğu yavaşlıkları düzelt | opus | HIZ_PLANI F84 + F60.S2/F60.5/F68.3 | A/B | evet | bitti — main'e birleştirildi [apk] 2026-11-13 KULLANICI KARARIYLA (cihaz A/B sonucu bu oturumda görülmedi; `Desktop/ab_P46.log` bakılacak, kötüleşme varsa madde başı commit `git revert`); S9/S18/S21/S22/S23/S25 bütçeleri düştü; cihaz maddeleri → P55 |
| P48 | Web yazı seçimi + takvim senkronu + web ek | opus | kullanıcı 2026-11-12 | cihaz (b) | evet | bitti — main'e birleştirildi [apk] 2026-11-13: web fare/klavye seçimi genişletilmiyor; yeni etkinlik varsayılanı Firestore "Tüm cihazlar" (K2 sapması kullanıcıca onaylandı 2026-11-13: etkinlik her yerde); (c) web ek üretilemedi; cihazda doğrulanmadı; ayrıntı: KUYRUK_AYRINTI.md §P48 |
| P49 | Sabit ek baştan: tasarım, tuşlar, özellikler | opus (kullanıcı 2026-11-13: tasarım bitti, kalanı Opus sürdürür) | kullanıcı 2026-11-12 | A/B | evet | bitti — bulut 2026-11-13, main'e [apk]: (a) tek ⋮ levhası (görünüm anahtarı, balonlar, PDF işleri, ek işleri, Kaldır); (b) ✏ hep görünür, yüzen kalemle senkron (`onPenOff`); (c) bölme kalemi açıkken çubukta silgi/geri al/yinele/ayar; (d) ipuçları kalem tepsisinin üstünde (`SnackBarObstacle`), oturumda durum başına bir kez; (e) klavye kasması S17 düştü; (f) F65.1 K-O6 dar çubuk + F65.2 K-O7 (kullanıcı kararı: geniş yatay pencerede seçilmemişse ek solda), F65.3 K-O8 en güvenli = tek sabit ek, sabah bakılacak; (g) 360/393 dp × 1,3 yazı taşmaz (bekçi `pinned_bar_redesign_test`); cihaz A/B YAPILMADI (bulut, telefon yok) — cihaz bekliyor, KALANLAR L7–L9 |
| P50 | Düzenleme modu baştan + hızlı menü | fable (limit %55 üstü → opus) | kullanıcı 2026-11-12 |  | evet | bitti — main'e [apk] 2026-11-14 entegrasyonla (P55+P56+P38+P50 tek dal): cihaz A/B 13 evrede A↔B aynı/iyi; KARAR KALDI yalnız altın tabana karşı `acilis` ilk kare +%19 ve `klasor` LAYOUT +%19 — A'da (main) da aynı, değişiklikten değil → kullanıcı kararı (altın taban tazelenmeli mi, sabah bakılacak); log Desktop/ab_entegre.log; kalan → P20 |
| P38 | Hareket ve dokunsal dil | opus | DENEYIM F77.1–F77.4 | A/B | evet | bitti — main'e [apk] 2026-11-14 entegrasyonla (P55+P56+P38+P50 tek dal): cihaz A/B 13 evrede A↔B aynı/iyi; KARAR KALDI yalnız altın tabana karşı `acilis` ilk kare +%19 ve `klasor` LAYOUT +%19 — A'da (main) da aynı, değişiklikten değil → kullanıcı kararı (altın taban tazelenmeli mi, sabah bakılacak); log Desktop/ab_entegre.log; kalan göç → P41, editör pop → P20 |
| P20 | Editör çekirdeği + editör artıkları (P50/P38 kalanı katıldı) | fable (yalnız karar evresi) → opus (uygulama) | Faz 64 + P50 kalan (üst çubuk sırası, ana ekran `Customizable` sarmaları) + P38 editör pop'u | A/B | evet | bekliyor — 1. evre FABLE: mimari kararlar + adım adım uygulama planı (`KUYRUK_AYRINTI.md` §P20 altına, kanıtlı, kendi başına okunur; kod yazmaz ya da yalnız iskelet), 2. evre OPUS alt ajanları planı adım adım uygular; başlama: entegrasyon (P55+P56+P38+P50) main'e girince; P49/P50 editör bloklarını AYNEN taşır; P41 ile paralel olabilir; ayrıntı: KUYRUK_AYRINTI.md §P20 |
| P41 | Mekanik göç: belirteçler + haptik (P38 kalanı katıldı) | sonnet | DENEYIM F72.6 + P38 kalan 35 `HapticFeedback` → `AppHaptics` |  |  | bekliyor — entegrasyon main'e girince; P20 ile PARALEL (dosya çiti: `lib/features/editor/**`, `note_editor_screen.dart`, P20'nin dosyaları hariç); ayrıntı: KUYRUK_AYRINTI.md §P41 |
| P22 | KAPANIŞ: açık maddeler + büyük toparlama (P53 katıldı) | opus | kalan `[ ]` maddeler + P53 protokolü (F69.4/5, F58.1/4) | gerekirse | gerekirse | bekliyor — EN SON (P20 ve P41'den sonra); 1. evre açık maddeler, 2. evre tek plan/tek kontrol listesi; ayrıntı: KUYRUK_AYRINTI.md §P22 + §P53 |

**SIRA (kullanıcı 2026-11-14, yeniden düzen — kalan 3 paket):** entegrasyon (P55+P56+P38+P50, tek A/B) → [apk] · P59 → **P20 ∥ P41** (aynı anda, dosya çitiyle) → **P22** (EN SON; P53 içinde). Eski sıra satırları geçersiz. **FABLE KURALI (kullanıcı 2026-11-14):** limit yenilenince (02:20) ilk Fable başlar ama BÜTÜN işi Fable yapmaz — yalnız önemli karar/plan kısımlarını; uygulama, test, CI, belge Opus'a. Fable paketi yalnız 5 saatlik limit %55 altındayken başlar; üstündeyse sıradaki Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince EN BAŞTA alınır. P20 yalnız P33 bitmişse. P41 yalnız Kuyruk'ta `sürüyor`/`bulutta:` satırı yokken.

Paket protokolleri (P22, P53, P33–P42 = `DENEYIM_PLANI.md` kuralları: K-D kararları verildi, kapsam çiti Ek D, `istek_tara.py`, "Atlananlar") ve satırların tam metni: **`KUYRUK_AYRINTI.md`**; alt ajana paketin ayrıntı bölümünü de ver.
