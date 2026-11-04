"""Sürüm öncesi duman testi / taban çizelgesi (F20.4, F27.4): Ek B'nin bütün sütunları.

  python -u taban.py <etiket> [paket]     → PERF_OUT/taban_<etiket>.json + özet

Paket varsayılan release (`dev.kaimau.notlar`). Veri: `OLCUM …` stres notları
(make_dataset.py). Koşudan önce sıcaklığa bakar: > 38 °C sayılar geçersiz.
"""
import sys
import perf
from perf import *

LABELS = ("kisa metin", "gorselli", "uzun liste", "uzun metin")


def temp():
    m = re.search(r"temperature: (\d+)", sh("dumpsys battery"))
    return int(m.group(1)) / 10 if m else 0


def layer_of(pkg):
    return f"SurfaceView[{pkg}/dev.kaimau.notlar.MainActivity](BLAST)#0"


def intervals(frames):
    ts = sorted(frames)
    return [round((b - a) / 1e6, 1) for a, b in zip(ts, ts[1:])]


def cold(pkg, reps=3):
    out = []
    for _ in range(reps):
        wake()
        sh(f"am force-stop {pkg}")
        time.sleep(1.5)
        with SF(layer_of(pkg)) as sf:
            r = sh(f"am start -W -n {pkg}/dev.kaimau.notlar.MainActivity")
            time.sleep(5)
        m = re.search(r"TotalTime: (\d+)", r)
        iv = intervals(sf.frames)
        # İlk 2 sn'deki en uzun aralık (boşta bekleme eşiği yok: açılışta değişen kare).
        out.append({"total_ms": int(m.group(1)) if m else None, "frames": len(iv) + 1,
                    "max_ms": max(iv) if iv else 0, "over50": [x for x in iv if x > 50][:8]})
        print("açılış", out[-1], flush=True)
    return out


def scroll(pkg):
    wake()
    with SF(layer_of(pkg)) as sf:
        for _ in range(6):
            swipe(540, 1850, 540, 650, 90)
            time.sleep(1.3)
        for _ in range(6):
            swipe(540, 650, 540, 1850, 90)
            time.sleep(1.3)
    a = analyze(sf.frames, sf.period)
    print("kaydırma", {k: a.get(k) for k in ("frames", "jank_pct", "dropped_vsyncs", "max_ms", "p99_ms", "hitches_ms")}, flush=True)
    return a


def reveal(label, tries=45):
    """Kartı ekranın orta bölgesine getirir → (x, y). Liste en üstten taranır."""
    for _ in range(5):
        swipe(540, 700, 540, 2000, 80)
        time.sleep(0.5)
    time.sleep(0.8)
    for _ in range(tries):
        for n in find("^OLCUM " + label):
            if 650 < n[2] < 2000:
                return n[1], n[2]
        swipe(540, 1500, 540, 900, 400)
        time.sleep(1.0)
    raise RuntimeError("kart yok: " + label)


def open_close(pkg, label, reps=3):
    x, y = reveal(label)
    time.sleep(3)  # uiautomator'ın açtığı semantik kapansın
    res = []
    lay = layer_of(pkg)
    for _ in range(reps):
        wake()
        with SF(lay) as s1:
            tap(x, y)
            time.sleep(2.4)
        with SF(lay) as s2:
            key("KEYCODE_BACK")
            time.sleep(1.8)
        i1, i2 = intervals(s1.frames), intervals(s2.frames)
        res.append({"open_max": max(i1, default=0), "open_over17": sum(1 for v in i1 if v > 25),
                    "close_anim_max": max(i2[:-1], default=0), "close_last": i2[-1] if i2 else 0,
                    "close_over33": sum(1 for v in i2[:-1] if v > 34)})
    print("aç/kapa", label, json.dumps(res, ensure_ascii=False), flush=True)
    return {"xy": (x, y), "reps": res}


def typing(pkg, label, tap_xy, chars="kontroledildi", bursts=4, pause=3.0):
    """Tuş patlamaları; kayıt zamanlayıcısı (2 sn) patlama aralarına düşer."""
    from scen import app_tids
    x, y = reveal(label)
    time.sleep(1)
    tap(x, y)
    time.sleep(2.6)
    tap(*tap_xy)
    time.sleep(2.0)
    perf.PKG = pkg
    pid, tids = app_tids()
    atrace_start()
    with SF(layer_of(pkg)) as sf:
        for _ in range(bursts):
            text(chars)
            time.sleep(pause)
    path = atrace_stop("type_" + label.replace(" ", "_"))
    runs, marks = parse_sched(path, tids)
    os.remove(path)
    a = analyze(sf.frames, sf.period)
    main = burst_stats(runs.get("main", []))
    # Boştaki kayıt bloğu: uzun koşular.
    long_bursts = sorted((round(1000 * (e - s), 1) for s, e, _ in bursts_of(runs.get("main", [])) if (e - s) > 0.012), reverse=True)[:12]
    key("KEYCODE_BACK")
    time.sleep(0.8)
    key("KEYCODE_BACK")
    time.sleep(1.5)
    if "MainActivity" not in sh("dumpsys window | grep mCurrentFocus"):
        front(pkg)
    out = {"sf": {k: a.get(k) for k in ("frames", "jank_frames", "max_ms", "p90_ms", "p99_ms", "eff_fps", "hitches_ms")}, "main": main, "main_long": long_bursts}
    print("yazma", label, json.dumps(out, ensure_ascii=False), flush=True)
    return out


def bursts_of(iv):
    return perf.bursts(iv)


if __name__ == "__main__":
    tag = sys.argv[1]
    pkg = sys.argv[2] if len(sys.argv) > 2 else "dev.kaimau.notlar"
    perf.PKG = pkg
    print("sıcaklık", temp(), flush=True)
    res = {"pkg": pkg, "temp_start": temp()}
    res["cold"] = cold(pkg)
    time.sleep(3)
    res["scroll"] = scroll(pkg)
    res["oc"] = {l: open_close(pkg, l) for l in LABELS}
    res["type_kisa"] = typing(pkg, "kisa metin", (540, 900))
    res["type_uzun"] = typing(pkg, "uzun metin", (700, 900))
    res["temp_end"] = temp()
    save("taban_" + tag, res)
    print("sıcaklık sonu", res["temp_end"], "→", os.path.join(OUT, f"taban_{tag}.json"), flush=True)
