"""F26.1: titreme için ekran videosu (ffmpeg gerekir).

  python -u video.py <etiket> [paket]

Açılış, arka plandan dönüş, klasör çipi geçişi, not aç/kapa, kaydırma kaydedilir;
kare kare (30 fps, gri) fark hesaplanır. Çıktı: evre başına parlaklık sıçraması
(flaş) + büyük tek kare değişimleri (zıplama) + kuşkulu anların kare yaprağı
PERF_OUT/video_<etiket>_*.png.
"""
import subprocess, sys, tempfile
import perf
from perf import *
from PIL import Image

W, H = 108, 234


def record(tag, pkg):
    marks = []
    t0 = None
    p = subprocess.Popen([ADB, "shell", "screenrecord", "--bit-rate", "20000000", "--time-limit", "32", "/sdcard/v.mp4"])
    t0 = time.time()

    def mark(name):
        marks.append((name, time.time() - t0))

    act = f"{pkg}/dev.kaimau.notlar.MainActivity"
    time.sleep(1)
    mark("soğuk açılış")
    sh(f"am start -n {act}")
    time.sleep(5)
    mark("arka plan→dönüş")
    key("KEYCODE_HOME"); time.sleep(2)
    sh(f"am start -n {act}")
    time.sleep(3)
    mark("klasör çipi")
    tap(330, 472); time.sleep(1.5)
    tap(133, 472); time.sleep(2)
    mark("not aç")
    tap(281, 875); time.sleep(2.4)
    mark("not kapa")
    key("KEYCODE_BACK"); time.sleep(2)
    mark("kaydırma")
    swipe(540, 1850, 540, 650, 90); time.sleep(1.4)
    swipe(540, 650, 540, 1850, 90); time.sleep(1.4)
    mark("son")
    p.wait(timeout=60)
    time.sleep(1.5)
    local = os.path.join(OUT, f"video_{tag}.mp4")
    adb("pull", "/sdcard/v.mp4", local, timeout=120)
    sh("rm /sdcard/v.mp4")
    return local, marks


def analyse(local, marks, tag):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", local, "-vf", f"fps=30,scale={W}:{H},format=gray",
                          "-f", "rawvideo", "-"], capture_output=True).stdout
    n = len(raw) // (W * H)
    frames = [raw[i * W * H:(i + 1) * W * H] for i in range(n)]
    means = [sum(f) / (W * H) for f in frames]
    diffs = [0.0] + [sum(abs(a - b) for a, b in zip(frames[i - 1], frames[i])) / (W * H) for i in range(1, n)]
    print(f"{n} kare, {n / 30:.1f} sn")

    def phase(t):
        cur = "?"
        for name, at in marks:
            if t >= at:
                cur = name
        return cur

    flash, jumps = [], []
    for i in range(2, n - 2):
        # Flaş: parlaklık gidip dönüyor (kalıcı değişim değil).
        if abs(means[i] - means[i - 2]) > 6 and abs(means[i + 2] - means[i - 2]) < 3:
            flash.append(i)
        # Zıplama: komşularından çok büyük tek kare farkı.
        if diffs[i] > 12 and diffs[i] > 3 * max(diffs[i - 1], diffs[i + 1], 1):
            jumps.append(i)
    for name, lst in (("FLAŞ", flash), ("ZIPLAMA", jumps)):
        print(name, [(round(i / 30, 2), phase(i / 30), round(diffs[i], 1)) for i in lst][:24])
    for name, at in marks:
        print(f"  {name:18s} @{at:5.1f} sn")
    picks = (flash + jumps)[:12]
    if picks:
        sheet = Image.new("L", (W * 5 + 16, (H + 4) * len(picks)), 255)
        for row, i in enumerate(picks):
            for col, j in enumerate(range(i - 2, i + 3)):
                sheet.paste(Image.frombytes("L", (W, H), frames[max(0, min(n - 1, j))]), (col * (W + 4), row * (H + 4)))
        out = os.path.join(OUT, f"video_{tag}_supheli.png")
        sheet.save(out)
        print("kare yaprağı:", out)
    return frames, marks


if __name__ == "__main__":
    tag = sys.argv[1]
    pkg = sys.argv[2] if len(sys.argv) > 2 else "dev.kaimau.notlar"
    perf.PKG = pkg
    wake()
    sh(f"am force-stop {pkg}")
    time.sleep(1)
    local, marks = record(tag, pkg)
    analyse(local, marks, tag)
