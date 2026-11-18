"""RAM TABANI (PLAN PL11, 16K §2.5): beş durumda `dumpsys meminfo` — ana ekran, editör, PDF, kalem, YouTube.

  python -u ram_taban.py [--etiket ADI] [--youtube "arama metni"]

Ölçüm uygulaması (`dev.kaimau.notlar.olcum`, profil). Her durum: uygulama sıfırdan başlar (force-stop), duruma
gidilir, 5 sn beklenir, `dumpsys meminfo` okunur (TOTAL PSS / RSS, Java/Native/Graphics/Code kalemleri, MB).
Tablet ana ekran koordinatları `ab_hepsi.home_locate` (GEO_1600). YouTube durumu için veri setinde YouTube'lu not
yoksa `--youtube` verilmedikçe "denenmedi" yazılır. Çıktı: markdown tablo (stdout) + `docs/perf/ram_tablet.md`'ye elle.
Telefon kuralları (ekran/ısı) ab_hepsi ile aynı; bitince ekran kapatılır.
"""
import argparse, re, sys
from ab_hepsi import *


def meminfo():
    out = sh(f"dumpsys meminfo {OPKG}", timeout=60)

    def grab(pat):
        m = re.search(pat, out)
        return int(m.group(1)) / 1024 if m else None

    return {
        "pss": grab(r"TOTAL PSS:\s+(\d+)") or grab(r"TOTAL\s+(\d+)"),
        "rss": grab(r"TOTAL RSS:\s+(\d+)"),
        "java": grab(r"Java Heap:\s+(\d+)"),
        "native": grab(r"Native Heap:\s+(\d+)"),
        "graphics": grab(r"Graphics:\s+(\d+)"),
        "code": grab(r"Code:\s+(\d+)"),
    }


def fresh():
    sh(f"am force-stop {OPKG}"); time.sleep(1.5)
    wake()
    sh(f"am start -n {ACT}"); time.sleep(7.0)
    ready()
    W, H = screen_size()
    return W, H, home_locate(W, H)


def state_ana():
    fresh(); time.sleep(5.0)


def state_editor():
    W, H, h = fresh()
    m = h["card_menu"]
    tap(m[1] - 170, m[2] + 150); time.sleep(5.0)


def state_pdf():
    W, H, h = fresh()
    hit = find_note("OLCUM kalem pdf", "^OLCUM kalem pdf", W, H, h)
    tap(*hit); time.sleep(6.0)


def state_kalem():
    W, H, h = fresh()
    m = h["card_menu"]
    tap(m[1] - 170, m[2] + 150); time.sleep(2.5)
    pen = nodes(dump(), "^Kalemle yaz")
    if not pen:
        raise RuntimeError("'Kalemle yaz' yok")
    tap(pen[0][1], pen[0][2]); time.sleep(1.5)
    x0, x1 = int(W * .2), int(W * .8)
    for i in range(10):
        swipe(x0, int(H * .3) + i * 40, x1, int(H * .32) + i * 40, 200); time.sleep(0.4)
    time.sleep(5.0)


def cleanup_kalem():
    """Çizgileri geri al (not büyümesin): hap → kapsül → Geri al ×10 → geri tuşlarıyla çık."""
    peek = nodes(dump(), "^Kalem tepsisini aç")
    if peek:
        tap(peek[0][1], peek[0][2]); time.sleep(1.2)
        undo = sorted(nodes(dump(), "^Geri al$"), key=lambda n: n[2])
        if undo and undo[-1][2] > screen_size()[1] * .7:
            for _ in range(10):
                tap(undo[-1][1], undo[-1][2]); time.sleep(0.3)
    for _ in range(4):
        if not nodes(dump(), "^(Notta ara|Kalem tepsisini aç|Kalemle yaz)"):
            break
        key("KEYCODE_BACK"); time.sleep(0.9)


def state_youtube(q):
    W, H, h = fresh()
    tap(*h["search"]); time.sleep(1.0)
    text(q.replace(" ", "%s")); time.sleep(1.6)
    tap(*h["hit"]); time.sleep(8.0)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--etiket", default="tablet")
    ap.add_argument("--youtube", default=None, help="YouTube'lu notu bulacak arama metni")
    o = ap.parse_args()
    rows = []
    steps = [("ana ekran", state_ana), ("editör", state_editor), ("PDF", state_pdf), ("kalem", state_kalem)]
    if o.youtube:
        steps.append(("YouTube", lambda: state_youtube(o.youtube)))
    t = temperature()
    try:
        for name, fn in steps:
            try:
                fn()
                rows.append((name, meminfo()))
                if name == "kalem":
                    cleanup_kalem()
            except (RuntimeError, IndexError) as e:
                rows.append((name, str(e)))
        if not o.youtube:
            rows.append(("YouTube", "denenmedi (veri setinde YouTube'lu not yok)"))
    finally:
        sh(f"am force-stop {OPKG}")
        sh("input keyevent KEYCODE_SLEEP")
    print(f"| durum | PSS MB | RSS MB | Java | Native | Graphics | Code |  ({o.etiket}, başlangıç {t} °C)")
    print("|---|---|---|---|---|---|---|")
    for name, v in rows:
        if isinstance(v, str):
            print(f"| {name} | {v} | | | | | |")
        else:
            f = lambda k: "-" if v[k] is None else f"{v[k]:.0f}"
            print(f"| {name} | {f('pss')} | {f('rss')} | {f('java')} | {f('native')} | {f('graphics')} | {f('code')} |")


if __name__ == "__main__":
    main()
