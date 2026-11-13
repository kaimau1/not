# DEVIR — P45 (oto/P45-olcum-gecmis)
Yapıldı: F83.1 (OTOMASYON 8. adım zorunluluğu), F83.2 (tool/perf/gecmis.py + docs/perf/README.md,
--self-check geçti, gerçek csv'de çalıştı: yalnız menu +%11,5 KAYMA), HIZ_PLANI/Kuyruk/KALANLAR/akicilik güncel.
Kalan: F83.3 — CI "Kare ölçümü" işi dokunulmadı; 3 aynı-commit koşu ~1 sa + kota, bu turda yapılmadı.
Sabah bakılacak: üç `[perf]` boş commit'i (koşu bitince sıradaki), perf-summary p90 sapması < %10 ise
`marker` `perf` çıktısını `[apk]` için de true yap; değilse işi kaldır, nedenini plana yaz.
Cihaza dokunulmadı. Komut: python tool/perf/gecmis.py [--self-check]
