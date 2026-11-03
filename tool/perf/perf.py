"""Telefonda akıcılık ölçümü: SurfaceFlinger kare zamanları + atrace iş parçacığı yükü.

Kullanım (modül olarak): from perf import *
"""
import os, re, subprocess, threading, time, statistics, json

ADB = os.environ.get("ADB", "adb")
PKG = "dev.kaimau.notlar"
# Çıktılar (png/json/atrace) depoya düşmesin: varsayılan geçici klasör.
OUT = os.environ.get("PERF_OUT") or os.path.join(__import__("tempfile").gettempdir(), "notlar_perf")
os.makedirs(OUT, exist_ok=True)


def sh(cmd, timeout=90):
    r = subprocess.run([ADB, "shell", cmd], capture_output=True, text=True,
                       timeout=timeout, encoding="utf-8", errors="replace")
    return r.stdout


def adb(*args, timeout=180):
    r = subprocess.run([ADB, *args], capture_output=True, timeout=timeout)
    return r.stdout


# ---------------------------------------------------------------- giriş
def wake():
    sh("input keyevent KEYCODE_WAKEUP")
    time.sleep(0.4)
    if "isKeyguardShowing=true" in sh("dumpsys window | grep isKeyguardShowing"):
        sh("input swipe 540 2000 540 700 200")
        time.sleep(0.8)


def tap(x, y):
    sh(f"input tap {x} {y}")


def swipe(x1, y1, x2, y2, ms=120):
    sh(f"input swipe {x1} {y1} {x2} {y2} {ms}")


def key(k):
    sh(f"input keyevent {k}")


def text(s):
    sh("input text '" + s.replace(" ", "%s").replace("'", "") + "'")


def shot(name, scale=0.4):
    png = adb("exec-out", "screencap", "-p")
    path = os.path.join(OUT, name + ".png")
    from PIL import Image
    import io
    im = Image.open(io.BytesIO(png))
    im = im.resize((int(im.width * scale), int(im.height * scale)))
    im.save(path)
    return path


def ui_dump():
    sh("uiautomator dump /sdcard/ui.xml", timeout=60)
    return sh("cat /sdcard/ui.xml")


def nodes(xml, pat=None):
    """uiautomator düğümleri: (metin/açıklama, merkez x, y, sınırlar)."""
    out = []
    for m in re.finditer(r'<node [^>]*?(?:text="([^"]*)")[^>]*?(?:content-desc="([^"]*)")[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml):
        t, d, x1, y1, x2, y2 = m.groups()
        label = (t or d or "").replace("&#10;", " | ")
        x1, y1, x2, y2 = map(int, (x1, y1, x2, y2))
        if pat and not re.search(pat, label, re.I):
            continue
        out.append((label, (x1 + x2) // 2, (y1 + y2) // 2, (x1, y1, x2, y2)))
    return out


# ---------------------------------------------------------------- SurfaceFlinger
def flutter_layer():
    out = sh("dumpsys SurfaceFlinger --list")
    c = [l.strip() for l in out.splitlines() if PKG in l and "SurfaceView" in l and "BLAST" in l and "Background" not in l]
    return c[-1] if c else None


class SF:
    """Katmanın sunulan karelerini 0,7 sn'de bir toplar (tampon 128 kare)."""

    def __init__(self, layer):
        self.layer = layer
        self.frames = {}
        self.period = 16666666
        self._stop = False

    def poll(self):
        out = sh(f"dumpsys SurfaceFlinger --latency '{self.layer}'")
        lines = out.strip().splitlines()
        if not lines:
            return
        try:
            self.period = int(lines[0])
        except ValueError:
            return
        for l in lines[1:]:
            p = l.split()
            if len(p) != 3:
                continue
            d, a, r = map(int, p)
            if a == 0 or a >= 2 ** 62:
                continue
            self.frames[a] = (d, r)

    def _run(self):
        while not self._stop:
            self.poll()
            time.sleep(0.7)

    def __enter__(self):
        sh("dumpsys SurfaceFlinger --latency-clear")
        self.t0 = time.time()
        self._t = threading.Thread(target=self._run, daemon=True)
        self._t.start()
        return self

    def __exit__(self, *a):
        self._stop = True
        self._t.join()
        self.poll()


def analyze(frames, period=16666666, idle_ms=250):
    ts = sorted(frames)
    per = period / 1e6
    iv = [(b - a) / 1e6 for a, b in zip(ts, ts[1:])]
    active = [x for x in iv if x <= idle_ms]
    if not active:
        return {"frames": len(ts)}
    jank = [x for x in active if x > per * 1.5]
    dropped = sum(max(0, round(x / per) - 1) for x in active)
    q = statistics.quantiles(active, n=100) if len(active) > 2 else active * 100
    big = sorted([round(x, 1) for x in active if x > per * 2.5], reverse=True)[:12]
    return {
        "frames": len(ts),
        "active_intervals": len(active),
        "jank_frames": len(jank),
        "jank_pct": round(100 * len(jank) / len(active), 1),
        "dropped_vsyncs": dropped,
        "p50_ms": round(q[49], 1),
        "p90_ms": round(q[89], 1),
        "p99_ms": round(q[98], 1),
        "max_ms": round(max(active), 1),
        "eff_fps": round(len(active) / (sum(active) / 1000), 1),
        "hitches_ms": big,
    }


# ---------------------------------------------------------------- atrace
def atrace_start(cats="sched freq gfx input view am dalvik binder_driver"):
    sh("atrace --async_stop > /dev/null 2>&1")
    sh(f"atrace --async_start -b 24000 {cats}")


def atrace_stop(name):
    dev = f"/data/local/tmp/{name}.txt"
    sh(f"atrace --async_stop -o {dev}", timeout=180)
    local = os.path.join(OUT, name + ".txt")
    adb("pull", dev, local, timeout=300)
    sh(f"rm {dev}")
    return local


SW = re.compile(r"^\s*(?P<task>.+?)-(?P<pid>\d+)\s+(?:\(\s*[\d-]+\)\s+)?\[(?P<cpu>\d+)\]\s+\S+\s+(?P<ts>\d+\.\d+): sched_switch: prev_comm=(?P<pc>.*?) prev_pid=(?P<pp>\d+) prev_prio=\d+ prev_state=(?P<ps>\S+) ==> next_comm=(?P<nc>.*?) next_pid=(?P<np>\d+)")
MARK = re.compile(r"^\s*(?P<task>.+?)-(?P<pid>\d+)\s+(?:\(\s*(?P<tgid>[\d-]+)\)\s+)?\[(?P<cpu>\d+)\]\s+\S+\s+(?P<ts>\d+\.\d+): tracing_mark_write: (?P<m>.*)$")


def thread_names(pid):
    names = {}
    for l in sh(f"ps -T -p {pid}").splitlines()[1:]:
        p = l.split()
        if len(p) >= 10:
            names[int(p[2])] = " ".join(p[9:])
    return names


def parse_sched(path, tids):
    """tids: {tid: ad}. Dönüş: {ad: [(başlangıç, bitiş)]} (sn)."""
    cur = {}
    runs = {}
    marks = []
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            if "sched_switch" in line:
                m = SW.match(line)
                if not m:
                    continue
                cpu = int(m["cpu"]); ts = float(m["ts"])
                pp = int(m["pp"]); np_ = int(m["np"])
                if cpu in cur:
                    tid, st = cur[cpu]
                    if tid == pp and tid in tids:
                        runs.setdefault(tids[tid], []).append((st, ts))
                cur[cpu] = (np_, ts)
            elif "tracing_mark_write" in line:
                m = MARK.match(line)
                if m and int(m["pid"]) in tids:
                    marks.append((float(m["ts"]), tids[int(m["pid"])], m["m"]))
    return runs, marks


def bursts(intervals, gap=0.002):
    """Aralarındaki boşluk < gap olan koşuları birleştirir: (başlangıç, bitiş, cpu_süresi)."""
    out = []
    for s, e in sorted(intervals):
        if out and s - out[-1][1] < gap:
            ps, pe, cpu = out[-1]
            out[-1] = (ps, max(pe, e), cpu + (e - s))
        else:
            out.append((s, e, e - s))
    return out


def burst_stats(intervals, window=None):
    b = bursts(intervals)
    if window:
        b = [x for x in b if window[0] <= x[0] <= window[1]]
    if not b:
        return {}
    walls = [1000 * (e - s) for s, e, _ in b]
    cpu_total = sum(c for *_, c in b)
    span = (b[-1][1] - b[0][0]) or 1
    q = statistics.quantiles(walls, n=100) if len(walls) > 2 else walls * 100
    return {
        "bursts": len(b),
        "busy_pct": round(100 * cpu_total / span, 1),
        "p50_ms": round(q[49], 2),
        "p90_ms": round(q[89], 2),
        "p99_ms": round(q[98], 2),
        "max_ms": round(max(walls), 1),
        "over16": sum(1 for w in walls if w > 16.7),
        "over8": sum(1 for w in walls if w > 8),
    }


def save(name, obj):
    with open(os.path.join(OUT, name + ".json"), "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=1)


def find(pat, xml=None):
    if xml is None:
        # Ekran zaman aşımı (60 sn) uzun döngülerde kilitliyordu.
        key('KEYCODE_SHIFT_LEFT')
        if 'NotificationShade' in sh('dumpsys window | grep mCurrentFocus'):
            wake()
    xml = xml or ui_dump()
    return nodes(xml, pat)


def tap_label(pat, idx=0, wait=1.2):
    hits = find(pat)
    if not hits:
        raise RuntimeError("bulunamadı: " + pat)
    _, x, y, _ = hits[idx]
    tap(x, y)
    time.sleep(wait)
    return hits[idx]


def open_import(zip_name):
    """Ayarlar → Senkronizasyon → Başka uygulamadan içe aktar → dosyayı seç."""
    wake()
    focus = sh('dumpsys window | grep mCurrentFocus')
    if 'dev.kaimau.notlar' not in focus:
        raise RuntimeError('uygulama önde değil: ' + focus.strip())
    if not find('^Yapay zekâyla ara$'):
        tap_label('^Diğer$')
        tap_label('^Ayarlar$', wait=2)
    for i in range(6):
        if find('Başka uygulamadan'):
            break
        hits = find('^Senkronizasyon$')
        if hits:
            tap(hits[0][1], hits[0][2]); time.sleep(1.5)
            continue
        swipe(540, 1800, 540, 900, 300); time.sleep(0.8)
    for i in range(4):
        if find('Başka uygulamadan'):
            break
        swipe(540, 1800, 540, 900, 300); time.sleep(0.8)
    tap_label('Başka uygulamadan', wait=3)
    if 'dosyaokuyucu' in sh('dumpsys window | grep mCurrentFocus'):
        tap_label('^Diğer$', wait=2)
    time.sleep(1)
    if not find(re.escape(zip_name) + '$'):
        tap_label('Kök dizinleri göster', wait=1.5)
        tap_label('^İndirilenler$', wait=2)
    tap_label(re.escape(zip_name) + '$', wait=2)


def wait_import(limit=900):
    t0 = time.time()
    while time.time() - t0 < limit:
        key('KEYCODE_SHIFT_LEFT')
        time.sleep(8)
        h = [n[0] for n in find(r'aktar|/ \d+ not') if n[0]]
        print(round(time.time() - t0), h[:2], flush=True)
        if not any('aktarılıyor' in x for x in h):
            return h


def sections(marks, thread="main"):
    """tracing_mark_write B/E çiftlerinden bölümler: (ad, başlangıç, süre_ms)."""
    stack, out = [], []
    for ts, th, m in marks:
        if th != thread:
            continue
        if m.startswith("B|"):
            parts = m.split("|", 2)
            stack.append((parts[2] if len(parts) > 2 else "?", ts))
        elif m.startswith("E") and stack:
            name, st = stack.pop()
            out.append((name, st, round(1000 * (ts - st), 2)))
    return out


def top_sections(marks, thread="main", min_ms=4.0, top=25):
    from collections import defaultdict
    agg = defaultdict(lambda: [0, 0.0, 0.0])
    for name, st, d in sections(marks, thread):
        key = re.sub(r"\d+", "#", name)[:70]
        a = agg[key]
        a[0] += 1; a[1] += d; a[2] = max(a[2], d)
    rows = sorted(agg.items(), key=lambda kv: -kv[1][1])
    return [(k, v[0], round(v[1], 1), round(v[2], 1)) for k, v in rows if v[2] >= min_ms][:top]


def front(pkg=PKG):
    """Uygulamayı öne getirir ve doğrular."""
    wake()
    act = f"{pkg}/dev.kaimau.notlar.MainActivity"
    sh(f"am start -n {act}")
    time.sleep(2.0)
    f = sh("dumpsys window | grep mCurrentFocus")
    if f"{pkg}/" not in f:
        raise RuntimeError("öne gelmedi: " + f.strip())
    return f.strip()
