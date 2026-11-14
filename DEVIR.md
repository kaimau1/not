# DEVIR — P63 Görsel tasarım B (PLAN TAMAM; iskelet kodu ve uygulama YOK)
Dal: `oto/P63-tasarim-B`. Tek dosya: `docs/plan_tasarim_B.md` (§0–§7). Kod yazılmadı, main'e dokunulmadı.

## Yapılanlar
- §0–§2 (S40, S41) 39eaff22 · §3 kalem (S42) d2b82c34 · §4 sesle yazma (S43) 65787bad
- §5 madde çizgileri (hedef, durumlar, kabul, kasma + S44) — ad45534b
- §6 iskelet sözleşmesi: altı bileşen (imza, yer, kod gerçekleri), P62 uyum tablosu, çeviri — 4ae13fb1
- §7 paketler (kanıt, önce üretilecek test/tur, kabul, tuzak, model, bağımlılık) — 0ca7c848
- Durum satırı + tutarsızlıklar (§0 P62 atfı, S29–S39, PB2, karar öneki SB) — 96670a30

## Paketler (ayrıntı plan §7)
PB0 iskelet (fable) ∥ PBT taban ölçüm + altyapı (opus) → PB4 şablon ∥ PB6 çizgi (fable; P62 beklemez)
→ [P62 iskeleti main'de] → PB1 düzen şeridi ∥ PB3 kalem ∥ PB5 ses (fable) → PB2 düzen merkezi (fable)
→ PB7 sarmalar + sıralar (opus high). CI/birleştirme/sürüm notu: sonnet. Model kuralı kullanıcı kararı
(2026-11-14): görünüş = fable, altyapı/ölçüm = opus, mekanik = sonnet.

## Kanıt / hipotezler / tuzaklar
- Kanıt planda (x.1 bölümleri, dosya:satır). Açık hipotezler: §3.1 alt şeridin Column'u (PB3 ilk iş) ·
  §5.1 bulgu 13 tepsi `AnimatedSize`'ı gövdeyi diziyor mu + §5.5 md. 3 kök kurulumu (PBT ölçer) ·
  §6.3 `fountainRadii` hız kaynağı (PB0 okur).
- `ab_hepsi.py`'de kalem/biçim/düzen/şablon evresi YOK (`run_once :180-287`); tur sahneleri tek
  dokunuşlu (`screen_tour_test.dart:703-725`) — ikisini de PBT ekler.
- §1.4 "var olan testler değişmeden yeşil" ancak `bar-switch/bar-move/personalize-bar-*` anahtar
  uyumuyla tutar (plan §6.1, §7.4).
- Worktree'de heredoc içinde kesme işareti ve `python - <<EOF` reddediliyor: içeriği Write ile yaz.

## Sıradaki
PB0 (fable) ∥ PBT (opus). Yürütücü Kuyruk'a PB0, PBT, PB1–PB7 satırlarını açar; `OTOMASYON.md` P63
satırı bu dalda GÜNCELLENMEDİ (main ile çakışmasın). Açık kararlar plan §7.11 (SB1–SB11).
