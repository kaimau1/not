# DEVIR — oto/skill-otomasyon (2026-11-14)

Otomasyon/token kuralları proje skill'lerine taşındı (yalnız belge; Dart yok). CLAUDE.md 11239 → 8322 B, OTOMASYON.md 20443 → 10609 B (Kuyruk tablosu + SIRA satırı dokunulmadı).

## Kayıp denetimi — eski kural → yeni yeri

| Eski yer | Kural | Yeni yer |
|---|---|---|
| CLAUDE Gece kuralı (2026-11-03/09) | zincir OTOMASYON'da, KARAR verilmiş → en güvenli + sabah bakılacak, [apk] akışı, CI kırmızı birleştirme yok, revert -m 1, cihaz yoksa KALANLAR §2, veri göçü yedek | CLAUDE özet (aynen) + `oto-tur` (7–8. adım) + `isci` |
| CLAUDE Kasma listesi 1–8 (2026-11-09) | 8 madde + gerekçe | `kasma-kontrol` (aynen); CLAUDE 1 satır |
| CLAUDE ÖLÇÜM KAPISI (2026-11-10) | kapsam, komut, 13 evre, taban, %20, tablette wm size/density | `ab-olcum`; CLAUDE 1 satır |
| CLAUDE HIZ SÖZLEŞMESİ (2026-11-12) | (1)–(4) | `ab-olcum` "Ne zaman"; CLAUDE 1 satır |
| OTO adım 0 Kilit | 60 dk, date >, döngü yasak, sil | `oto-tur` 0 |
| OTO adım 1–2 Depo, main sağlığı | stash, pull, gh run list, [apk] sürerken push yok | `oto-tur` 1–2 |
| OTO adım 3–4 Paket seç, yaptır | bulutta: atla, sürüyor/bekliyor, Agent+worktree, model | `oto-tur` 3–4 |
| OTO adım 5 Doğrula | gh run watch, en çok 2 tur | `oto-tur` 5 |
| OTO adım 6 Cihaz kapısı | Sonnet ölçer, KARAR, hız paketinde kötüleşme sıfır, revert | `oto-tur` 6 + `ab-olcum` |
| OTO adım 7 Birleştir, temizlik, yarım iş devri (2026-11-12) | merge --no-ff, durum commit'i yok, worktree/dal sil, DEVIR satırı | `oto-tur` 7, 9, 10 |
| OTO adım 8–9 APK noktası, APK izlenmez, regresyon turu | --altin zorunlu F83.1, sürüm notu | `oto-tur` 8 |
| OTO adım 10 Limit freni, limiti boş bırakma (2026-11-13), diriltme yasağı (2026-11-13), haftalık Fable | %90/%80, 2 paralel, 2 tur ölçüm | `oto-tur` 4, 11 + `ab-olcum` |
| OTO adım 11 Takılma önleme | timeout 2700, 90 dk, TaskStop, telefon uyut | `oto-tur` 12–13 |
| OTO İşçi kuralları (tümü) | dal, pub get, push, DEVIR, doğrulama, hız işi, KARAR, dokunma, kanıt, timeout, rapor | `isci` |
| OTO Telefon kuralları | adb devices, uyandır/uyut, 370, misafir, kalem, koordinat | `ab-olcum` (OTOMASYON'da işaret başlığı kaldı: ab_hepsi.py "OTOMASYON §Telefon" atfı) |
| Zamanlanmış istem 4–6 + FABLE KURALI (Kuyruk satırı) | token tasarrufu, takılma, 2 paralel, Fable yalnız karar | `oto-tur` (FABLE KURALI OTOMASYON'da da kalır) |

Not: zamanlanmış istem Fable eşiği %65, OTOMASYON/hafıza %55 → `oto-tur` sıkı olanı (%55) yazar, sabah bakılacak.
Test: CLAUDE/OTOMASYON içeriğini okuyan test yok (`jank_patterns_guard_test.dart`, `tool/perf/*` yalnız yorum atfı; adlar korundu).
Sıradaki: kullanıcı onayıyla zamanlanmış istemi kısalt; birleştirmeden önce bu dosyayı sil.
