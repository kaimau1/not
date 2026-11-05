"""Klavye aç/kapa birikim ölçümü (F38.7): aynı notta N tur; turdan tura artıyor mu?

  python -u klavye.py <etiket> [paket] [tur=15] [not=kisa metin]

Tur başına SF kare aralıkları (açılış ve kapanış ayrı) + uygulama belleği. Yorum:
`open_max`/`open_over25` turlarla büyüyorsa birikim, hep aynıysa sabit maliyet.
Ekranı yalnız ölçüm boyunca açar, sonunda uyutur (telefon ısınmasın).
"""
import re
import sys
import perf
from perf import *
from taban import intervals, layer_of, reveal, temp


def kb_shown():
    return "mInputShown=true" in sh("dumpsys input_method | grep mInputShown")


def pss(pkg):
    m = re.search(r"TOTAL PSS:\s*(\d+)", sh(f"dumpsys meminfo {pkg} | grep 'TOTAL PSS'"))
    return int(m.group(1)) // 1024 if m else None


def cycle(lay, xy):
    with SF(lay) as s1:
        tap(*xy)
        time.sleep(1.5)
    shown = kb_shown()
    with SF(lay) as s2:
        key("KEYCODE_BACK")
        time.sleep(1.5)
    a, b = intervals(s1.frames), intervals(s2.frames)
    return {
        # İmleç yanıp sönmesi (~500 ms) kare sayılmaz: animasyon dizisi.
        "open_iv": [round(v) for v in a if v < 400][:45],
        "close_iv": [round(v) for v in b if v < 400][:45],
        "shown": shown,
        "open_frames": len(a), "open_max": max(a, default=0),
        "open_over25": sum(1 for v in a if v > 25),
        "close_frames": len(b), "close_max": max(b, default=0),
        "close_over25": sum(1 for v in b if v > 25),
    }


if __name__ == "__main__":
    tag = sys.argv[1]
    pkg = sys.argv[2] if len(sys.argv) > 2 else "dev.kaimau.notlar"
    turns = int(sys.argv[3]) if len(sys.argv) > 3 else 15
    label = sys.argv[4] if len(sys.argv) > 4 else "kisa metin"
    perf.PKG = pkg
    wake()
    try:
        front(pkg)
        time.sleep(2)
        x, y = reveal(label)
        time.sleep(1)
        tap(x, y)
        time.sleep(2.6)
        lay = layer_of(pkg)
        out = {"pkg": pkg, "note": label, "temp_start": temp(), "turns": []}
        for i in range(turns):
            r = cycle(lay, (540, 900))
            r["pss_mb"] = pss(pkg)
            out["turns"].append(r)
            print(i + 1, json.dumps(r), flush=True)
        out["temp_end"] = temp()
        save("klavye_" + tag, out)
        key("KEYCODE_BACK")
    finally:
        sh("input keyevent KEYCODE_SLEEP")
