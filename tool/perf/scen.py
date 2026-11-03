"""Release uygulamasında senaryolar (SurfaceFlinger + atrace).

Komut satırı: python -u scen.py scroll <etiket> [impeller|skia]
Diğerleri modül olarak: open_close(), typing(), measure_sections().
"""
import sys
from perf import *

APP_THREADS = ("1.ui", "1.raster", "1.io")


def launch(renderer="impeller", wait=6):
    sh(f"am force-stop {PKG}")
    time.sleep(1.2)
    extra = " --ez enable-impeller false" if renderer == "skia" else ""
    sh(f"am start -n {PKG}/.MainActivity{extra}")
    time.sleep(wait)


def app_tids():
    pid = sh(f"pidof {PKG}").strip().split()[0]
    names = thread_names(pid)
    main = int(pid)
    tids = {}
    for tid, n in names.items():
        if tid == main:
            tids[tid] = "main"
        elif n in APP_THREADS:
            tids[tid] = n
        elif n.startswith("DartWorker"):
            tids[tid] = "DartWorker"
        elif "RenderThread" in n or n.startswith("hwui"):
            tids[tid] = "hwui"
    return pid, tids


def measure(name, action, trace=True):
    wake()
    layer = flutter_layer()
    pid, tids = app_tids()
    if trace:
        atrace_start()
    with SF(layer) as sf:
        t0 = time.time()
        action()
        time.sleep(1.5)
    res = {"sf": analyze(sf.frames, sf.period)}
    if trace:
        path = atrace_stop(name)
        runs, marks = parse_sched(path, tids)
        res["threads"] = {k: burst_stats(v) for k, v in runs.items()}
        os.remove(path)
    save(name, res)
    return res


def scroll():
    for _ in range(6):
        swipe(540, 1850, 540, 650, 90)
        time.sleep(1.3)
    for _ in range(6):
        swipe(540, 650, 540, 1850, 90)
        time.sleep(1.3)


def marks_latency(marks, runs):
    """deliverInputEvent (main) → sonraki ilk queueBuffer (ms) listesi."""
    inputs = [t for t, th, m in marks if th == "main" and "deliverInputEvent" in m and m.startswith("B|")]
    qb = sorted(t for t, th, m in marks if "queueBuffer" in m and m.startswith("B|"))
    out = []
    for t in inputs:
        nxt = [q for q in qb if q > t]
        if nxt:
            out.append(round(1000 * (nxt[0] - t), 1))
    return out


def open_close(label, x, y, reps=3, open_wait=2.4, close_wait=1.8, trace=True):
    layer = flutter_layer()
    pid, tids = app_tids()
    res = []
    for r in range(reps):
        wake()
        if trace:
            atrace_start()
        with SF(layer) as sf:
            tap(x, y)
            time.sleep(open_wait)
        op = analyze(sf.frames, sf.period)
        with SF(layer) as sf2:
            key("KEYCODE_BACK")
            time.sleep(close_wait)
        cl = analyze(sf2.frames, sf2.period)
        item = {"open": op, "close": cl}
        if trace:
            path = atrace_stop(f"oc_{label}_{r}")
            runs, marks = parse_sched(path, tids)
            item["main"] = burst_stats(runs.get("main", []))
            item["raster"] = burst_stats(runs.get("1.raster", []))
            item["input_to_frame_ms"] = marks_latency(marks, runs)
            os.remove(path)
        res.append(item)
        print(label, r, json.dumps({k: (v if k == "input_to_frame_ms" else {kk: v.get(kk) for kk in ("frames", "jank_frames", "dropped_vsyncs", "max_ms", "p99_ms", "over16", "hitches_ms") if kk in v}) for k, v in item.items()}, ensure_ascii=False), flush=True)
    save(f"oc_{label}", res)
    return res


def typing(label, bursts=4, chars="kontrol edildi", pause=1.8, trace=True):
    """Odaklı metin alanına ardışık yazma; her patlamadan sonra otomatik kayıt beklenir."""
    def act():
        for i in range(bursts):
            text(chars)
            time.sleep(pause)
    return measure(f"type_{label}", act, trace=trace)


def measure_sections(name, action):
    wake()
    layer = flutter_layer()
    pid, tids = app_tids()
    atrace_start()
    with SF(layer) as sf:
        action()
        time.sleep(1.5)
    res = {"sf": analyze(sf.frames, sf.period)}
    path = atrace_stop(name)
    runs, marks = parse_sched(path, tids)
    res["threads"] = {k: burst_stats(v) for k, v in runs.items()}
    res["main_sections"] = top_sections(marks, "main")
    res["raster_sections"] = top_sections(marks, "1.raster", min_ms=6)
    os.remove(path)
    save(name, res)
    return res


if __name__ == "__main__":
    scen, label = sys.argv[1], sys.argv[2]
    renderer = sys.argv[3] if len(sys.argv) > 3 else "impeller"
    wake()
    if scen == "scroll":
        launch(renderer)
        r = measure(f"scroll_{label}", scroll)
    print(json.dumps(r, ensure_ascii=False, indent=1))
