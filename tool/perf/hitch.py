"""SF kareleri (monotonik) + atrace (boot saati) hizalı takılma dökümü."""
import re
from perf import *

def clock_offset(marks):
    offs = []
    for ts, th, m in marks:
        if th == "main" and m.startswith("B|") and "deliverInputEvent" in m:
            mm = re.search(r"eventTimeNano=(\d+)", m)
            if mm:
                offs.append(ts - int(mm.group(1)) / 1e9)
    return min(offs) if offs else None

def aligned_hitches(frames, runs, marks, gap_ms=25, idle_ms=250):
    off = clock_offset(marks)
    if off is None:
        return None, []
    pres = sorted(frames)
    main = sorted(runs.get("main", []))
    rast = sorted(runs.get("1.raster", []))
    secs = sections(marks, "main")
    inputs = [ts for ts, th, m in marks if th == "main" and m.startswith("B|") and "deliverInputEvent" in m]
    rows = []
    for a, b in zip(pres, pres[1:]):
        iv = (b - a) / 1e6
        if not (gap_ms < iv <= idle_ms):
            continue
        A = a / 1e9 + off - 0.016
        B = b / 1e9 + off - 0.016
        mb = sum(min(e, B) - max(s, A) for s, e in main if e > A and s < B) * 1000
        rb = sum(min(e, B) - max(s, A) for s, e in rast if e > A and s < B) * 1000
        longest = 0
        for s, e in main:
            if e > A and s < B:
                longest = max(longest, (min(e, B) - max(s, A)) * 1000)
        n_in = sum(1 for t in inputs if A <= t <= B)
        ss = [(n[:40], round(d, 1)) for n, st, d in secs if A <= st <= B and d >= 1.5]
        rows.append({"t": round(A, 3), "iv": round(iv, 1), "main_busy": round(mb, 1), "raster_busy": round(rb, 1), "inputs": n_in, "secs": ss[:4]})
    return off, rows
