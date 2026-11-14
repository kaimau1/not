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
| P22 | KAPANIŞ: açık maddeler + büyük toparlama (P53 katıldı) | opus | kalan `[ ]` maddeler + P53 protokolü (F69.4/5, F58.1/4) | gerekirse | gerekirse | bitti — dal oto/P22-kapanis (2026-11-14): 1. evre F60.6 düzeltme (zemin görseli ek sayılmıyor), F69.3 alarm izni satırı (cihazda doğrulanmadı), F66.5 rapor, açık maddeler değerlendirildi; P53: PLAN.md + KONTROL_LISTEM.md (40 madde), 15 plan + KALANLAR*/KUYRUK_AYRINTI `docs/arsiv/planlar/`'a, kalıcı kurallar docs/hafiza'ya, Kuyruk sıkıştırıldı, CLAUDE.md yol haritası + F58.1/F58.4, F69.5 [x]. Sabah bakılacak: dondurma (K-O1) kalksın mı; SIRA satırı bayat (dokunulmadı); APK = evet (2 görünür değişiklik, sürüm notu yazıldı) |

**SIRA (kullanıcı 2026-11-14, yeniden düzen — kalan 3 paket):** entegrasyon (P55+P56+P38+P50, tek A/B) → [apk] · P59 → **P20 ∥ P41** (aynı anda, dosya çitiyle) → **P22** (EN SON; P53 içinde). Eski sıra satırları geçersiz. **FABLE KURALI (kullanıcı 2026-11-14):** limit yenilenince (02:20) ilk Fable başlar ama BÜTÜN işi Fable yapmaz — yalnız önemli karar/plan kısımlarını; uygulama, test, CI, belge Opus'a. Fable paketi yalnız 5 saatlik limit %55 altındayken başlar; üstündeyse sıradaki Opus/Sonnet paketi yapılır, Fable paketi `bekliyor` kalır ve limit yenilenince EN BAŞTA alınır. P20 yalnız P33 bitmişse. P41 yalnız Kuyruk'ta `sürüyor`/`bulutta:` satırı yokken.

Paket ayrıntısı: Kuyruk satırı + `PLAN.md`; eski paket protokolleri (P22, P53, P33–P42) `docs/arsiv/planlar/KUYRUK_AYRINTI.md`; kalıcı kurallar `docs/hafiza/arayuz.md` sonu.
