"""Tablet keşif turu yardımcısı (T16): her komut ekranı uyandırır, işi yapar, ekranı bırakır.

  python tur.py snap AD [ölçek]     ekran görüntüsü (varsayılan 0,4) → $TUR_OUT/AD.png (varsayılan: PERF_OUT/tur)
  python tur.py dump [regex]        uiautomator düğümleri (etiket, merkez, sınırlar); regex süzer
  python tur.py tap "regex" [i]     etikete uyan i. düğmeye dokun (yoksa çıkış 1)
  python tur.py xy X Y              koordinata dokun
  python tur.py swipe X1 Y1 X2 Y2 [ms]
  python tur.py key BACK|HOME|...   KEYCODE_<ad>
  python tur.py text "metin"        yaz
  python tur.py rot 0|1|3|free      ekran yönü (wm user-rotation; free = serbest/eski hâl)
  python tur.py sleep               ekranı uyut
  python tur.py fg [paket]          uygulamayı öne getir (varsayılan dev.kaimau.notlar)
  python tur.py crash               logcat'te FATAL/E-flutter/Exception özeti

Ortam: ADB (adb yolu), ANDROID_SERIAL (tek cihaz yoksa). Dokunma/uyandırma `perf.py`'den.
"""
import os, re, subprocess, sys, time
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from perf import sh, adb, tap, swipe, key, wake, nodes, ui_dump, OUT

sys.stdout.reconfigure(encoding="utf-8")
TUR_OUT = os.environ.get("TUR_OUT") or os.path.join(OUT, "tur")


def snap(name, scale=0.4):
    import io
    from PIL import Image
    png = adb("exec-out", "screencap", "-p")
    im = Image.open(io.BytesIO(png))
    w, h = im.size
    if scale != 1:
        im = im.resize((int(w * scale), int(h * scale)))
    os.makedirs(TUR_OUT, exist_ok=True)
    p = os.path.join(TUR_OUT, name + ".png")
    im.save(p, optimize=True)
    return p, (w, h)


def dump_nodes(pat=None):
    for _ in range(3):
        x = ui_dump()
        if len(x) > 800:
            break
        time.sleep(0.8)
    return nodes(x, pat)


def main():
    a = sys.argv[1:]
    if not a:
        print(__doc__); return 2
    cmd = a[0]
    if cmd == "sleep":
        sh("input keyevent KEYCODE_SLEEP"); return 0
    if cmd == "rot":
        v = a[1]
        if v == "free":
            sh("wm user-rotation free")
        else:
            sh(f"wm user-rotation lock {v}")
        return 0
    wake()
    if cmd == "snap":
        p, size = snap(a[1], float(a[2]) if len(a) > 2 else 0.4)
        print(p, size)
    elif cmd == "dump":
        for lbl, x, y, b in dump_nodes(a[1] if len(a) > 1 else None):
            if lbl:
                print(f"{lbl[:70]!r} ({x},{y}) {b}")
    elif cmd == "tap":
        hits = dump_nodes(a[1])
        i = int(a[2]) if len(a) > 2 else 0
        if len(hits) <= i:
            print("YOK:", a[1]); return 1
        tap(hits[i][1], hits[i][2]); print("dokunuldu:", hits[i][0][:60], hits[i][1], hits[i][2])
    elif cmd == "xy":
        tap(int(a[1]), int(a[2]))
    elif cmd == "swipe":
        swipe(*[int(v) for v in a[1:5]], int(a[5]) if len(a) > 5 else 300)
    elif cmd == "key":
        key("KEYCODE_" + a[1].upper())
    elif cmd == "text":
        sh("input text '" + a[1].replace(" ", "%s").replace("'", "") + "'")
    elif cmd == "fg":
        pkg = a[1] if len(a) > 1 else "dev.kaimau.notlar"
        sh(f"am start -n {pkg}/dev.kaimau.notlar.MainActivity")
    elif cmd == "crash":
        out = subprocess.run([os.environ.get("ADB", "adb"), "logcat", "-d", "-t", "4000"], capture_output=True,
                             text=True, encoding="utf-8", errors="replace").stdout
        hits = [l for l in out.splitlines() if re.search(r"FATAL EXCEPTION|E/flutter|AndroidRuntime: |RenderFlex|ANR in", l)]
        print(len(hits), "satır")
        for l in hits[:40]:
            print(l[:220])
    else:
        print(__doc__); return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
