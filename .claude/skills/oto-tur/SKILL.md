---
name: oto-tur
description: Gözetimsiz zincirin yürütücü turu — kilit, main sağlığı, Kuyruk'tan paket seçip alt ajana verme, doğrulama, cihaz kapısı, birleştirme/[apk], temizlik, limit freni, bitiriş. Zamanlanmış görev ya da "otomasyonu sür" denince uygula.
---

# Yürütücü turu

OTOMASYON.md "Bir turun adımları" + CLAUDE.md "Gece / zamanlanmış görev kuralı" + zamanlanmış
görev istemi buraya taşındı (2026-11-14), AYNEN. **Kuyruk VERİSİ ve SIRA `OTOMASYON.md`'de**
(paket ayrıntısı Kuyruk satırında + `PLAN.md`; P53 2026-11-14 öncesi paketler `docs/arsiv/planlar/KUYRUK_AYRINTI.md`); bu skill yalnız yöntemdir.

**Kullanıcı izni (2026-11-09):** işleri otomasyonla başlat, istediğin modelde alt ajan aç, limite
göre çalış; test telefonu USB'de (şifresiz, ekranı bozuk: yalnız gerekince aç); işi bitir,
main'e gönder; token israf etme ama bitmiş iş ver. Gözetimsiz çalış, soru sorma. Plan
dosyalarındaki KARAR maddeleri verilmiştir (KARAR (kullanıcı, 2026-11-03)): SORMADAN uygula;
yeni karar → en güvenli + "sabah bakılacak".

**Yürütücü ince kalır (kullanıcı kararı 2026-11-12: "alt ajanlar daha çok işi yapabilir"):** kod,
CI izleme, kırmızı CI düzeltme, DEVIR, plan `[x]`, Kuyruk satırı, sürüm notu taslağı ALT AJANIN
işidir; yürütücü raporu, `git log`/diff özetini ve `gh run` sonucunu kontrol eder, birleştirir.
Paketleri büyük tut (her alt ajan sıfırdan başlar). Aynı anda TEK yürütücü.

## Token tasarrufu (kullanıcı kararı 2026-11-12: "notları okumak %20 limit yedi")

Her araç çağrısı bütün bağlamı yeniden gönderir — az ve toplu çağrı. `OTOMASYON.md`'yi BİR kez
oku (tek parça); aynı dosyayı/tabloyu ikinci kez dökme. Paket ayrıntısı için yalnız
`PLAN.md`'nin ilgili satırı. Büyük çıktıyı `| tail -n 40` / `cut -c1-300` ile kes.
HAFIZA/plan dosyalarını baştan okuma, Grep ile ara. Graphify'ı açma. Alt ajan beklerken yoklama
yok, bildirimi bekle.

## Adımlar

0. **Kilit** `.git/oto.lock` (içinde ISO zaman). Son değişimi 60 dakikadan yeniyse: hiçbir şey
   yapmadan "başka yürütücü çalışıyor" de ve BİTİR. Değilse şimdi yaz. Her adımın başında ve her
   alt ajan bildiriminde tek `date -u +%FT%TZ > .git/oto.lock` ile tazele; arka plan döngüsüyle
   ASLA (oturum ölünce döngü yaşar, kilit sonsuza dek taze kalır). Eşik tek: 60 dk. Tur nasıl
   biterse bitsin kilidi sil.
1. **Depo.** `git status` temiz olmalı (değilse `git stash push -u -m oto-<tarih>` + Kuyruk
   notuna yaz), `git checkout main && git pull --ff-only`. Uzaktaki `oto/*` dallarına bak;
   satırı olmayan dalı DEVIR'iyle satıra bağla.
2. **main sağlığı.** `gh run list -b main -L 3` (yoksa GitHub MCP `actions_list`). Son BİTEN
   koşu kırmızıysa bu turun işi onu düzeltmektir (yalnız kırmızı işin kayıt kuyruğu). `[apk]`
   koşusu SÜRÜYORSA bitene dek main'e push YOK (iptal eder) — bu sırada dalda çalışılır.
   main iki kez üst üste kırmızı → dur.
3. **Paketi seç** (Kuyruk + SIRA satırı `OTOMASYON.md`'de). `bulutta:` ile başlayan satır başka
   oturumundur: ATLA, dalına dokunma; yalnız Cihaz = `A/B` ve "cihaz bekliyor" olunca ölçümü sen
   yaptırırsın. İlk `sürüyor` (yarım: uzakta `oto/<no>-*` varsa oradan, DEVIR.md'den) yoksa ilk
   `bekliyor`. Satırı `sürüyor` yap (yalnız yerelde; ayrıca push yok).
4. **Yaptır.** `Agent`, `isolation: "worktree"`, `model` Kuyruk satırından (`fable|opus|sonnet`),
   **fork tipi AÇMA**. İstem = "`isci` skill'ini uygula" + paketin Kuyruk satırı + `PLAN.md` ilgili
   bölümü (+ dal yarımsa "dalın DEVIR.md'sinden sür"). `Agent` reddedilirse ya da model yoksa
   paket bu oturumda yapılır; Kuyruk'a gerçek model yazılır.
   **Paralellik (kullanıcı kararı 2026-11-13: "gece boyu ufacık işler yapıp durmuş"):** aynı anda
   EN ÇOK 2 paket alt ajanı (dosyaları çakışmayan); telefon/A-B ölçümü tek seferde BİR. Biri
   bitince doğrula-birleştir, HEMEN sıradakini başlat.
   **FABLE KURALI (kullanıcı 2026-11-14: "limit yetmiyor ve iş bitmiyor yoksa"):** Fable yalnız
   önemli karar/plan evresini yapar (mimari, adım planı); uygulama, test, CI, belge Opus alt
   ajanlarına. Limit yenilenince ilk Fable başlar. Fable paketi yalnız 5 saatlik limit %55
   altındayken başlar (OTOMASYON FABLE KURALI; zamanlanmış istem %65 der — sıkı olan %55
   uygulanır, 2026-11-11 gecesi tek Fable paketi limiti freni geçip doldurdu); üstündeyse
   sıradaki Opus/Sonnet paketi, Fable `bekliyor` kalır ve limit yenilenince EN BAŞTA alınır.
   Haftalık Fable kotası SONUNA KADAR kullanılır (kullanıcı 2026-11-13); bitince Opus.
5. **Doğrula.** Raporu oku ama güvenme: `git log oto/<no>`, diff özeti, test çıktısı. Dal push'lu
   olmalı. CI: `gh run list -b oto/<no> -L 1` → sürüyorsa arka planda
   `timeout 2700 gh run watch <id> --exit-status` (yoklama döngüsü yok). Kırmızıysa YENİ alt
   ajana yalnız kırmızı işin kayıt kuyruğuyla ver (en çok 2 tur; sonra `takıldı`).
6. **Cihaz kapısı** (Cihaz = `A/B`) → `ab-olcum` skill'i. Ölçümü yürütücü KENDİ yapmaz:
   derlemeler bitince `Agent` `model: "sonnet"` alt ajan. Karar `KARAR:` satırı; kırmızıysa
   birleştirme yok, satır `takıldı: ölçüm` + sayılar. En çok 2 tur → `kullanıcı kararı`, birleştir,
   sıradakine geç. Telefon yok/ısınmış → `cihaz bekliyor`, `[apk]`'sız.
7. **Birleştir.** Dalda hazır olmalı: Kuyruk satırı `bitti` + sonuç, plan `[x]`,
   `docs/regresyon_listesi.md`, HAFIZA. CI yeşil değilse ASLA birleştirme. `DEVIR.md`'yi daldan
   sil, `git checkout main && git merge --no-ff oto/<no>` (başlık `Birleştir: <paket adı>`),
   sonra `git grep -E "^(<<<<<<<|>>>>>>>)"` BOŞ olmalı, push. **Durum için ayrı commit/push
   atma** — her main push'u CI'ı baştan koşturur ve süren APK'yı iptal eder. main CI kırmızıysa
   düzelt ya da `git revert -m 1`.
8. **APK noktası** (APK = `evet`): birleştirmeden ÖNCE `ab_hepsi.py <A> <B> --altin` ZORUNLU
   (paket A/B istemese bile; F83.1) — telefon yoksa `[apk]` ertelenir, birleştirme `[apk]`'sız.
   Başlığa `[apk]` (kişisel APK; CI'da `NOTLAR_KISISEL=1`); aynı commit'te
   `assets/guide/release_notes_tr.md` + `_en.md`'ye günün bölümü (kullanıcı diliyle, o APK'ya
   giren bütün paketler). Önce regresyon turu: `docs/regresyon_listesi.md` baştan (protokol
   madde 8). **APK izlenmez (kullanıcı kararı 2026-11-12):** dal CI'ı yeşilse birleştir, push,
   sıradakine geç; yalnız sonraki main push'undan ÖNCE `gh run list -b main -L 1` — APK işi
   sürüyorsa push'u bekletip dalda çalış.
9. **Temizlik (kullanıcı kararı 2026-11-12: 34 kopya ~onlarca GB birikmişti):** birleştirince
   `git worktree remove --force <ağaç>`, `git push origin --delete oto/<no>-*`, yerel dal silinir;
   `../not_ab` ölçüm bitince silinir. Silinemeyen klasörü tutan Gradle sürecini durdur.
   "Filename too long" → PowerShell `Remove-Item -LiteralPath '\\?\C:\...\<ağaç>' -Recurse -Force`
   + `git worktree prune`.
10. **Yarım iş devri (kullanıcı kararı 2026-11-12):** paket yarıda kalırsa (limit/durdurma)
    Kuyruk satırı HEMEN `sürüyor — dal <ad> (<commit>): bitti <x>, kalan <y>; DEVIR.md'den sür`
    olur ve main'e push edilir ("bekliyor" kalırsa sonraki tur sıfırdan başlar). Önce
    `git log origin/<dal>..HEAD` boş olmalı.
11. **Limit freni.** Her alt ajan başlatmadan ÖNCE, her bildirimde ve birleştirmeden önce
    `mcp__ccd_session_mgmt__get_usage` (ToolSearch ile yükle), "5-hour limit" `percentUsed`:
    ≥ 90 → yeni paket/alt ajan YOK; çalışana "commit + push yap ve dur"; satır `sürüyor`; kilidi
    sil; `resetsAt`'ı özete yaz, bitir (tur başında ≥ 90 ise hiçbir şey yapmadan bitir). ≥ 80 →
    yeni paket başlatma, elindekini bitir. < 80 ve Kuyruk'ta iş varken tur BİTMEZ. Araç
    `unavailable` ise frensiz devam (özete yaz). Limit elverdikçe 3. adıma dön.
    **Uzun alt ajanı DİRİLTME (2026-11-13: limit açılınca iki Fable ajanı SendMessage ile
    sürdürüldü, 1 dakikada 0 → %43):** limit yenilenince ya da 5 dk'dan uzun aradan sonra eski
    ajana mesaj atma; YENİ alt ajan, istem "dalın DEVIR.md'sinden sür".
12. **Takılma önleme (kullanıcı 2026-11-12).** Her arka plan bekleme `timeout` ile (45 dk; tek
    koşu, döngü yok); dolunca `gh run view <id> --json status,conclusion`. Alt ajandan 90 dk
    bildirim yoksa `SendMessage` "commit + push + dur"; dönmezse `TaskStop`, satır `sürüyor`.
13. **Bitiriş.** Dur: art arda 3 `takıldı`; main iki kez üst üste kırmızı; Kuyruk boş; limit.
    Kendi arka plan görevlerini `TaskStop`, telefonu uyut (`adb shell input keyevent
    KEYCODE_SLEEP`), kilidi sil — kilidi silmeden özet yazma — sonra 5 satır özet.
