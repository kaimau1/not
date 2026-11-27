"""S47 cihaz kanıtı: klavye açılıp kapanırken alt panelin kare kare yeri.

  python -u panel_kayit.py <etiket> <alan_x> <alan_y> --panel-y <px> [--panel-boy <px>]
                           [--tekrar 10] [--bant 24] [--video dosya.mp4]

Önkoşul: ölçüm uygulaması ("Notlar Ölçüm", dev.kaimau.notlar.olcum) önde, bir
METİN notu açık, klavye KAPALI. <alan_x> <alan_y>: gövdede dokunulunca klavyeyi
açan nokta (tam çözünürlük px). --panel-y: klavye kapalıyken alt panelin ÜST
kenarı (ayraç çizgisi) — `adb exec-out screencap -p > s.png` ile bir kez
bakılır. --panel-boy: panelin İÇERİK boyu (ayraçtan düğmelerin altına, gezinme
çubuğu HARİÇ); verilmezse ekranın dibinden gezinme çubuğu (`dumpsys window`
navigationBar) düşülerek bulunur.

Yöntem (P55 `bar_track` kalıbı): `screenrecord` (20 Mbit, ekranın kendi kare
hızı) → ffmpeg ile her kare gri, 1/4 ölçek → ilk karedeki panel bandı
(--panel-y'den --bant satır) ŞABLON; her karede şablonun en iyi oturduğu satır
(SAD) = panelin üstü. Klavyenin üstü: ilk açılıştan 1 sn sonraki (oturmuş)
karede panelin hemen altındaki bant klavye şablonu olur, her karede aynı
yöntemle aranır. Ölçülen her karede sapma = panel altı − klavye üstü (> 0:
klavye paneli örtüyor, < 0: arada boşluk).

Çıktı (çevrim başına ve toplam):
  geri_sicrama : panelin klavyeye TERS yönde > 2 px (tam çözünürlük) oynadığı kare
  takilma      : klavye > 3 px ilerlerken panelin < 1 px kıpırdadığı kare
  ort/maks sapma (px): yalnız klavyenin görünür olduğu hareket karelerinde
  gizli        : panel şablonunun bulunamadığı kare — panel klavyenin ALTINDA
                 kalmış (geride izliyor) ya da solmuş (kip c'de beklenir)
Ham kare dizisi PERF_OUT/panel_<etiket>.csv (zaman, panel_y, klavye_y).

Üç kip (S47; derlemede `--dart-define=ALT_PANEL_KIP=a|b|c`) için üç profil
APK'sı: bkz. tool/perf/README.md "Alt panel kipleri".

TELEFON KURALI: ekranı yalnız ölçüm sırasında aç; bitince `input keyevent
KEYCODE_SLEEP` (ab-olcum skill'i).
"""
import argparse
import csv
import os
import subprocess
import time

import numpy as np

from perf import ADB, OUT, adb, key, sh, tap, wake

SCALE = 4  # 1/4 ölçek: 1080 → 270 sütun


def nav_height():
    """Gezinme çubuğu boyu (px); bulunamazsa 0."""
    out = sh("dumpsys window | grep -i -A3 'navigationbar'")
    import re
    m = re.search(r"frame=\[\d+,(\d+)\]\[\d+,(\d+)\]", out)
    return int(m.group(2)) - int(m.group(1)) if m else 0


def record(label, fx, fy, repeat, kb_x=None, kb_y=None):
    use_kb_btn = kb_x is not None and kb_y is not None
    secs = min(180, int(repeat * 2.6 + (5.5 if use_kb_btn else 4)))
    remote = "/sdcard/panel_kayit.mp4"
    proc = subprocess.Popen([ADB, "shell", "screenrecord", "--bit-rate", "20000000",
                             "--time-limit", str(secs), remote])
    t0 = time.time()
    marks = []
    time.sleep(0.8)
    if use_kb_btn:
        tap(fx, fy)
        time.sleep(0.8)
    else:
        time.sleep(0.7)
    for _ in range(repeat):
        marks.append(("ac", time.time() - t0))
        tap(kb_x, kb_y) if use_kb_btn else tap(fx, fy)
        time.sleep(1.3)
        marks.append(("kapa", time.time() - t0))
        key("KEYCODE_BACK")
        time.sleep(1.3)
    proc.wait(timeout=secs + 30)
    time.sleep(1.5)
    local = os.path.join(OUT, f"panel_{label}.mp4")
    adb("pull", remote, local, timeout=180)
    sh(f"rm {remote}")
    return local, marks


def frames_of(video):
    """(zamanlar, kareler[n, h, w] uint8): ekranın kendi kare hızında."""
    probe = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                            "stream=width,height", "-of", "csv=p=0", video],
                           capture_output=True, text=True).stdout.strip().split(",")
    w, h = int(probe[0]) // SCALE, int(probe[1]) // SCALE
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", video, "-vsync", "0",
                          "-vf", f"scale={w}:{h},format=gray", "-f", "rawvideo", "-"],
                         capture_output=True).stdout
    n = len(raw) // (w * h)
    arr = np.frombuffer(raw[:n * w * h], np.uint8).reshape(n, h, w).astype(np.int16)
    ts = subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                         "frame=pts_time", "-of", "csv=p=0", video],
                        capture_output=True, text=True).stdout.split()
    times = [float(t) for t in ts[:n]] or [i / 60 for i in range(n)]
    return np.array(times), arr


def match(frame, tmpl, lo, hi):
    """Şablonun [lo, hi) aralığında en iyi oturduğu satır ve ortalama farkı."""
    b = tmpl.shape[0]
    best, best_y = 1e9, -1
    for y in range(max(0, lo), min(frame.shape[0] - b, hi)):
        d = np.abs(frame[y:y + b] - tmpl).mean()
        if d < best:
            best, best_y = d, y
    return best_y, best


def analyse(label, times, frames, marks, panel_y, panel_h, band):
    py0 = panel_y // SCALE
    ph = max(1, panel_h // SCALE)
    tmpl_p = frames[0, py0:py0 + band].copy()
    # Oturmuş açık kare: ilk açılıştan 1 sn sonra.
    t_open = marks[0][1] + 1.0
    i_open = min(len(frames) - 1, int(np.searchsorted(times, t_open)))
    yo, _ = match(frames[i_open], tmpl_p, 0, frames.shape[1])
    kb0 = yo + ph
    tmpl_k = frames[i_open, kb0:kb0 + band].copy()
    h = frames.shape[1]
    rows = []
    for i, f in enumerate(frames):
        y_p, d_p = match(f, tmpl_p, 0, h)
        y_k, d_k = match(f, tmpl_k, y_p + ph - 40 // SCALE if y_p >= 0 else 0, h)
        rows.append((times[i], y_p if d_p < 18 else None, y_k if d_k < 18 else None))
    with open(os.path.join(OUT, f"panel_{label}.csv"), "w", newline="") as fh:
        csv.writer(fh).writerows([("t", "panel_y", "klavye_y")] + [
            (round(t, 4), None if p is None else p * SCALE, None if k is None else k * SCALE)
            for t, p, k in rows])

    total = dict(geri_sicrama=0, takilma=0, gizli=0, kare=0, sapma=[])
    cycles = []
    for (kind, t0), (_, t1) in zip(marks, marks[1:] + [("son", times[-1])]):
        c = dict(evre=kind, geri_sicrama=0, takilma=0, gizli=0, kare=0, sapma=[])
        prev = None
        for t, p, k in rows:
            if not (t0 <= t < t1):
                continue
            if p is None:
                c["gizli"] += 1
                continue
            if prev is not None and prev[1] is not None:
                step = (p - prev[1]) * SCALE  # + = aşağı
                rising = kind == "ac"
                if (step > 2 if rising else step < -2):
                    c["geri_sicrama"] += 1
                if k is not None and prev[2] is not None:
                    kstep = (k - prev[2]) * SCALE
                    if abs(kstep) > 3 and abs(step) < 1:
                        c["takilma"] += 1
            # Klavye gezinme çubuğunun ardındayken (kapalı panelin altından
            # aşağıda) panel yerinde durur: sapma sayılmaz.
            if k is not None and k < py0 + ph:
                c["sapma"].append((p + ph - k) * SCALE)
                c["kare"] += 1
            prev = (t, p, k)
        cycles.append(c)
        for key_ in ("geri_sicrama", "takilma", "gizli", "kare"):
            total[key_] += c[key_]
        total["sapma"] += c["sapma"]

    def fmt(c):
        s = [abs(x) for x in c["sapma"]] or [0]
        return (f"geri_sicrama={c['geri_sicrama']} takilma={c['takilma']} gizli={c['gizli']} "
                f"ort_sapma={sum(s) / len(s):.1f}px maks_sapma={max(s):.0f}px (kare {c['kare']})")

    for i, c in enumerate(cycles):
        print(f"{i // 2 + 1:2d} {c['evre']:4s} {fmt(c)}")
    print(f"TOPLAM {label}: {fmt(total)}")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("label")
    ap.add_argument("fx", type=int)
    ap.add_argument("fy", type=int)
    ap.add_argument("--panel-y", type=int, required=True)
    ap.add_argument("--panel-boy", type=int)
    ap.add_argument("--tekrar", type=int, default=10)
    ap.add_argument("--kb-x", type=int, default=None, help="fiziksel klavyeli tablette ⌨ düğmesi x")
    ap.add_argument("--kb-y", type=int, default=None, help="fiziksel klavyeli tablette ⌨ düğmesi y")
    ap.add_argument("--bant", type=int, default=8, help="şablon bandı (1/4 ölçekte satır)")
    ap.add_argument("--video", help="kayıt yerine var olan video (yeniden çözümleme)")
    a = ap.parse_args()
    if a.video:
        video = a.video
        marks = []
        t = 1.5
        for _ in range(a.tekrar):
            marks += [("ac", t), ("kapa", t + 1.3)]
            t += 2.6
    else:
        wake()
        video, marks = record(a.label, a.fx, a.fy, a.tekrar, kb_x=a.kb_x, kb_y=a.kb_y)
        sh("input keyevent KEYCODE_SLEEP")
    panel_h = a.panel_boy
    if panel_h is None:
        size = sh("wm size").split()[-1]
        panel_h = int(size.split("x")[1]) - nav_height() - a.panel_y
    times, frames = frames_of(video)
    print(f"{len(frames)} kare, {times[-1]:.1f} sn ({len(frames) / max(times[-1], 1e-3):.0f} fps)")
    analyse(a.label, times, frames, marks, a.panel_y, panel_h, a.bant)


if __name__ == "__main__":
    main()
