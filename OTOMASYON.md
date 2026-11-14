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
| P60 | Kalan kasmalar fazı: ölçümde hâlâ kötü / yeterince iyileşmemiş her yüzey | opus (gerekirse plan evresi fable) | kullanıcı 2026-11-14 | A/B | evet | bekliyor — sıra: P22 [apk]'dan sonra, K32/K34 ile telefon çakışmaz biçimde (telefon tek seferde BİR iş). Adımlar: (1) ÖLÇÜM VERİSİNİ ONAR: `gecmis.py --son 8` 2026-11-14'te not_ac/kb/yaz/not_kapa ~3 kat sıçradı (226→659, 415→1792, 1034→2080, 216→648 ms) — sıçrama ölçüm uygulaması verisinin sıfırlanıp yeniden kurulduğu tura denk (240→170 not, 'OLCUM kalem pdf' notu elle sabitlendi, 6 sabit not, 'deneme yazisi' metinleri): ölçüm uygulamasının verisini sil, `keep_olcum.zip`'i temiz içe aktar, ab_hepsi'nin açtığı notun beklenen not olduğunu doğrula, aynı APK'yı iki kez ölçüp sıçramanın veri mi kod mu olduğunu KANITLA; veri ise altın tabanı yeniden al (KONTROL_LISTEM 40). (2) GERÇEK KAYMALAR: temiz veriyle `gecmis.py` KAYMA evreleri (şu an liste +%11, klasör +%15 süzülerek) + `acilis` ilk kare (P22 A/B'de B 65–90 ms yavaş; denetimli deney sürüyor) + `test/perf_budget/budgets.json`'da hedefe inmemiş mandallar (S9 gövde boy karesi 2, Seç kipi/tablette madde satırı 23, S18 874, S24 927, ve hedef≠mandal olan her satır) + `docs/hafiza/akicilik.md`/`editor.md`'de 'kaldı/sabah bakılacak' kasma maddeleri (M6 `_sameVisual`). (3) Her biri için kanıt→kök neden→düzeltme→cihaz A/B (`ab-olcum`); düzelmeyen için en az 2 farklı yaklaşım dene, sonuçları sayıyla yaz. Kötüleşme SIFIR; mandallar yalnız düşer. Bitince her evre için önce/sonra tablosu. |
| K32 | İki not yan yana (tablet) | opus | docs/plan_K32_K34.md §K32 | tablet | evet | cihaz bekliyor — kod bitti (CI yeşil), tablet doğrulaması kullanıcıda; telefon A/B [apk] öncesi. Dal oto/K32-yan-yana: A0–A6 (kart ⋮ "Yanda aç", SplitShell 3. sütun, `_closeEditor` hunisi, S27 0/0/0/0 — editör kökü liste akışını izlemiyor artık, telefonda da kayıt yankısı kök kurmaz). Sabah bakılacak: plan §Sabah bakılacaklar K32 (1)–(6) |
| K34 | Parmağa ayrı araç (tahmin kullanıcı kararıyla çıkarıldı) | opus | docs/plan_K32_K34.md §K34 | tablet | evet | cihaz bekliyor — kod bitti (CI yeşil), tablet doğrulaması kullanıcıda; telefon A/B [apk] öncesi. Dal oto/K34-parmak-araci: parmak Kaydırır/Çizer/Siler (Siler = geçici silgi yolu, avuç/iki parmak/iptal geri getirir, 22 dp yarıçap süzgeci, kement içinde taşır), üçlü seçim kalem ayarları + Ayarlar → Kalem, tepsi/çizim menüsü/hap Siler metni; tahmin kullanıcı kararıyla yok. Sabah bakılacak: editördeki "kalem kipi açıldı" ipucu Siler'i söylemiyor (K32 dosyası); Siler'de tek parmak kaydırmaz; 22 dp eşik tahminî |

**SIRA (2026-11-14):** Kuyruk'ta yalnız P22 (cihaz bekliyor: A/B → [apk]). Sonra boş; yeni iş `PLAN.md`'den kullanıcı isteğiyle (dondurma K-O1, `ISTEK_KUTUSU.md`).

Paket ayrıntısı: Kuyruk satırı + `PLAN.md`; eski paket protokolleri (P22, P53, P33–P42) `docs/arsiv/planlar/KUYRUK_AYRINTI.md`; kalıcı kurallar `docs/hafiza/arayuz.md` sonu.
