# OTOMASYON — gözetimsiz iş zinciri

**Kullanıcı izni (2026-11-09):** işleri otomasyonla başlat, istediğin modelde alt ajan aç,
limite göre çalış; test telefonu USB'de (şifresiz, ekranı bozuk: yalnız gerekince aç); işi
bitir, main'e gönder; token israf etme ama bitmiş iş ver.

Plan: `PLAN.md` (açık işler; eski planlar `docs/arsiv/planlar/`). Bu dosya yalnız YÜRÜTME düzenidir. Her tur bu dosyayı baştan okur.

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

Alt ajan istemi: "`isci` skill'ini uygula" + paketin Kuyruk satırı + `PLAN.md` ilgili maddesi.

## Telefon kuralları → `ab-olcum` skill'i

Mi Note 10 Lite, USB: uyandır/kaydır/uyut, sıcaklık < 370, varsayılan kimlikli uygulamaya
dokunma, misafir hesap, tablette telefon düzeni — `.claude/skills/ab-olcum/SKILL.md`.

## Kuyruk

Durum: `bekliyor` · `sürüyor` · `bitti` · `takıldı: <neden>` · `cihaz bekliyor`.

Biten paketler: P01–P20, P23–P59 (P21/P53 → P22'ye katıldı; P44 → P43). Ayrıntı git geçmişinde (`git log -S '| P43 |' -- OTOMASYON.md`) ve `docs/arsiv/planlar/KUYRUK_AYRINTI.md`. Son satırların "sabah bakılacak"ları `KONTROL_LISTEM.md` 8/40 ve `PLAN.md` (C)'ye taşındı (P53, 2026-11-14).

| No | Paket | Model | Plan maddeleri | Cihaz | APK | Durum / sonuç |
|---|---|---|---|---|---|---|
| P22 | KAPANIŞ: açık maddeler + büyük toparlama (P53 katıldı) | opus | kalan `[ ]` maddeler + P53 protokolü (F69.4/5, F58.1/4) | gerekirse | gerekirse | bitti — [apk] 2026-11-14. KARAR (3 tur A/B, P22'nin kodu açılış/⋮/yeni not yoluna dokunmuyor): her turda FARKLI tek evre eşiği az aştı — 1. tur menu LAYOUT +%24, 2. tur menu geçti ama ilk kare +65–90 ms, 3. tur (aynı env/bayraklarla denetimli A2=e4d960d3, B2=main) açılış eşit (ilk kare 136/161), yalnız yeni_not LAYOUT +%21 (114→139); 1. turda yeni_not B daha iyiydi (133→123) → tutarlı kötüleşme yok, ölçüm gürültüsü; gürültüyü azaltma (daha çok tekrar, birleşik ortanca) P60'ta. Önceki: 1. evre açık maddeler + P53 arşive taşıma, PLAN.md/KONTROL_LISTEM.md |
| P60 | Kalan kasmalar fazı: ölçümde hâlâ kötü / yeterince iyileşmemiş her yüzey | opus (gerekirse plan evresi fable) | kullanıcı 2026-11-14 | A/B | evet | sürüyor — dal oto/P60-kalan-kasmalar (77bcb7f5 + durak commit): bitti veri onarımı (sıçrama VERİYDİ: ilk kart PDF'li nottu; ab_hepsi OLCUM'u atlar + ek temizler + --teyit), altın taban temiz veriyle yeniden (A=A 8 koşu GEÇTİ), liste/klasör kayması temiz veride YOK (9c83 vs 0fe2), S21 arama 56→24 kart (cihazda ölçülmedi); kalan: yaz LAYOUT 164↔225 oturum farkı (trim_typed liste maddesi şüphesi), B_P60_1 A/B, en uzun kareler (not_ac 78, arama 61 ms) kökü; DEVIR.md'den sür. Önceki: bekliyor — sıra: P22 [apk]'dan sonra, K32/K34 ile telefon ça…
| P61 | Keşif turu (TestSprite benzeri) + bulguların düzeltilmesi | opus (düzeltme) · sonnet (telefon turu) | kullanıcı 2026-11-14: uygulamayı açıp her yere tıklayıp hata bul, düzelt; web/tablet/telefon görsel tasarım + bug önerileri, çoğuna sen karar ver | A/B | evet | sürüyor — 1. aşama bitti: dal oto/P61-kesif-turu (b14cc135) `docs/kesif_turu_2026-11-14.md` 12 bulgu (0 yüksek, 6 orta, 6 düşük; KT-1…KT-12, ekran görüntüleriyle; web headless'ta erişilebilirlik ağacı boş → her düğme denenemedi). KALAN: (2) telefonda adb/uiautomator ile CANLI tur (her ekran, ⋮, ayar, levha, düğme; bulguları aynı belgeye KT-13…), (3) Opus: bütün bulguları düzelt (zevk kararlarını en güvenli + kullanıcının eski isteklerine uygun ver, `istek_tara.py`), (4) K32+K34+P60+P61 tek A/B → [apk] + sürüm notları. |
| K32 | İki not yan yana (tablet) | opus | docs/plan_K32_K34.md §K32 | tablet | evet | cihaz bekliyor — kod bitti (CI yeşil), tablet doğrulaması kullanıcıda; telefon A/B [apk] öncesi. Dal oto/K32-yan-yana: A0–A6 (kart ⋮ "Yanda aç", SplitShell 3. sütun, `_closeEditor` hunisi, S27 0/0/0/0 — editör kökü liste akışını izlemiyor artık, telefonda da kayıt yankısı kök kurmaz). Sabah bakılacak: plan §Sabah bakılacaklar K32 (1)–(6) |
| K34 | Parmağa ayrı araç (tahmin kullanıcı kararıyla çıkarıldı) | opus | docs/plan_K32_K34.md §K34 | tablet | evet | cihaz bekliyor — kod bitti (CI yeşil), tablet doğrulaması kullanıcıda; telefon A/B [apk] öncesi. Dal oto/K34-parmak-araci: parmak Kaydırır/Çizer/Siler (Siler = geçici silgi yolu, avuç/iki parmak/iptal geri getirir, 22 dp yarıçap süzgeci, kement içinde taşır), üçlü seçim kalem ayarları + Ayarlar → Kalem, tepsi/çizim menüsü/hap Siler metni; tahmin kullanıcı kararıyla yok. Sabah bakılacak: editördeki "kalem kipi açıldı" ipucu Siler'i söylemiyor (K32 dosyası); Siler'de tek parmak kaydırmaz; 22 dp eşik tahminî |
| P62 | Görsel tasarım A — PLAN + iskelet (Fable beyin): ayarlar ekranları, ana ekran hesap sekmesi, Ayarlar → hesap ayarları, ipucu/uyarı görünümü ve yeri (üste binme), sağa-sola kaydırma hissi/animasyonu | fable (plan+iskelet) → uygulama: görsel paket fable, altyapı/ölçüm opus, CI/test/mekanik sonnet (kullanıcı 2026-11-14) | kullanıcı 2026-11-14: son kullanıcıya hazır, tertemiz, premium, animasyonlu; kasma yok; ara commit | A/B | evet | plan + iskelet main'de (2026-11-14); uygulama PA0–PA9 `docs/plan_tasarim_A.md` §8 sırasıyla — PA0 (opus) sürüyor — bu oturumda alt ajan, dal oto/PA0-butce (ajan bitene dek dokunma); KALAN PAKETLERİN HEPSİ opus (kullanıcı 2026-11-14 gece; plan tablosundaki fable yazısı geçersiz); kullanıcı KONTROL_LISTEM 40 eşiğini bu iş için aştı (2026-11-14); açık: PA5 modeli |
| P63 | Görsel tasarım B — PLAN + iskelet (Fable beyin): düzenleme modu (eksik düzenlenemeyenler + görünüm), şablonlar baştan, kalem seti görünümü, sesle yazma etkin menüsü (hareketli ses alanı + tüm menü), madde altı çizgiler ve menüsü | fable (plan) → uygulama: görsel paket fable, altyapı/ölçüm opus, CI/mekanik sonnet (kullanıcı 2026-11-14) | kullanıcı 2026-11-14 (P62 ile aynı) | A/B | evet | plan main'de (2026-11-14); uygulama PB0, PBT, PB1–PB7 `docs/plan_tasarim_B.md` §7 sırasıyla — PB0 (fable) sürüyor — bu oturumda alt ajan, dal oto/PB0-iskelet (ajan bitene dek dokunma); sonra PBT; KALAN PAKETLERİN HEPSİ opus (kullanıcı 2026-11-14 gece; plan tablosundaki fable yazısı geçersiz) |

**ÖNCELİK (kullanıcı 2026-11-14 gece — "planları birleştir, hızlı bitsin, çok parça çok token"):** P62/P63 uygulaması 5 BÜYÜK ÖBEKTE (plan paketleri tek alt ajanda, sırayla, her alt paket ayrı commit+push; plan dosyalarında her alt paket `[x]`). **Model: hepsi opus** (Fable açılmaz; cihaz A/B ölçümü sonnet). Şu an bu oturumda PA0 (oto/PA0-butce) ve PB0 (oto/PB0-iskelet) alt ajanları sürüyor — bitip birleşene dek dokunma.
| Öbek | Alt paketler | Ön koşul | Dal | Cihaz | APK |
|---|---|---|---|---|---|
| G1 ayarlar | PA1+PA2+PA3+PA4 (`plan_tasarim_A.md` §8) | PA0 main'de | oto/G1-ayarlar | A/B | evet |
| G2 şablon+çizgi | PBT+PB4+PB6 (`plan_tasarim_B.md` §7) | PB0 main'de | oto/G2-sablon-cizgi | A/B | evet |
| G3 bildirim+kaydırma | PA5+PA6+PA7+PA8 | G1 main'de | oto/G3-bildirim-kaydirma | A/B | evet |
| G4 kalem+ses | PB3+PB5 | G2 main'de | oto/G4-kalem-ses | A/B | evet |
| G5 düzen modu + kapanış | PB1+PB2+PB7+PA9 | G3 ve G4 main'de | oto/G5-duzen | A/B | evet |
Aynı anda en çok 2 öbek (G1∥G2, sonra G3∥G4, sonra G5). APK başına 5 görünür değişiklik kuralı bu öbekler için kullanıcı kararıyla gevşetildi (öbek başına bir `[apk]`, cihaz A/B öbek sonunda bir kez); KONTROL_LISTEM 40 eşiği de aşıldı. Bitince aşağıdaki SIRA.

**SIRA (2026-11-14, kullanıcı duraklattı — kaldığı yerden sür):** 1) P60'ı `oto/P60-kalan-kasmalar` DEVIR.md'den sür (ilk iş: telefonda 'Kitap bilet' notunun ilk maddesi; S21 arama aday APK `../ab_apk/B_P60_1.apk` A/B) → 2) P61 telefon canlı turu (telefon P60'tan sonra) ∥ P61 düzeltmeleri (Opus, telefonsuz) → 3) K32+K34+P60+P61 tek A/B (`ab_hepsi.py --teyit 2`, temiz veri) → [apk] + sürüm notları → 4) KONTROL_LISTEM'de telefonda denetlenebilir maddeleri ajanla denetle → 5) kullanıcıya ayrıntılı rapor (bu oturumda yapılanlar + kalan yalnız kullanıcıya özgü işler). Ayrı oturum: 'Fix silent note loss on first Keep import' (içe aktarma ilk denemede 67/240 notu sessiz atlıyor).

Paket ayrıntısı: Kuyruk satırı + `PLAN.md`; eski paket protokolleri (P22, P53, P33–P42) `docs/arsiv/planlar/KUYRUK_AYRINTI.md`; kalıcı kurallar `docs/hafiza/arayuz.md` sonu.
