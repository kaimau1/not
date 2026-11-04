"""Profil uygulamasının Dart VM servisi (HTTP GET) — zaman çizelgesi + CPU örnekleri."""
import json, re, time, urllib.parse, urllib.request
from collections import Counter, defaultdict
from perf import sh, adb, wake, save

OPKG = "dev.kaimau.notlar.olcum"


class VM:
    def __init__(self, base):
        self.base = base.rstrip("/") + "/"
        self.iso = [i["id"] for i in self.call("getVM")["isolates"] if i["name"] == "main"][0]

    def call(self, method, **params):
        q = urllib.parse.urlencode({k: (v if isinstance(v, str) else json.dumps(v)) for k, v in params.items()})
        with urllib.request.urlopen(self.base + method + ("?" + q if q else ""), timeout=180) as r:
            d = json.loads(r.read())
        if "error" in d:
            raise RuntimeError(d["error"])
        return d.get("result", d)

    def now(self):
        return self.call("getVMTimelineMicros")["timestamp"]

    def start(self, widgets=False):
        try:
            self.call("setFlag", name="profiler", value="true")
            self.call("setFlag", name="profile_period", value="250")
        except RuntimeError as e:
            print("profiler bayrağı:", e)
        self.call("setVMTimelineFlags", recordedStreams="[Dart,Embedder,GC]")
        self.call("clearVMTimeline")
        if widgets is not None:
            self.call("ext.flutter.profileWidgetBuilds", isolateId=self.iso, enabled=str(widgets).lower())
        self.t0 = self.now()

    def channels(self, reset=False, top=12):
        """F27.1: platform kanalı sayacı (`ext.notlar.channels`) — kanal başına
        giden/gelen ileti + bayt. reset=True okuduktan sonra sıfırlar."""
        r = self.call("ext.notlar.channels", isolateId=self.iso, reset=str(reset).lower())
        rows = sorted(((k, v) for k, v in r.items() if isinstance(v, dict)),
                      key=lambda kv: -(kv[1]["outBytes"] + kv[1]["inBytes"]))
        for k, v in rows[:top]:
            print(f"{k:60s} {v['outCount']:5d}↑ {v['inCount']:5d}↓ "
                  f"{(v['outBytes'] + v['inBytes']) / 1024:8.1f} KB")
        return dict(rows)

    def stop(self):
        t1 = self.now()
        tl = self.call("getVMTimeline", timeOriginMicros=self.t0, timeExtentMicros=t1 - self.t0)
        try:
            cpu = self.call("getCpuSamples", isolateId=self.iso, timeOriginMicros=self.t0, timeExtentMicros=t1 - self.t0)
        except RuntimeError as e:
            print("cpu örnekleri yok:", str(e)[:120])
            cpu = {}
        return tl, cpu


def launch_profile(extra=""):
    sh(f"am force-stop {OPKG}")
    time.sleep(1)
    sh("logcat -c")
    sh(f"am start -n {OPKG}/dev.kaimau.notlar.MainActivity{extra}")
    url = None
    for _ in range(40):
        time.sleep(0.5)
        m = re.search(r"listening on (http://127\.0\.0\.1:(\d+)/\S+)", sh("logcat -d -s flutter:I"))
        if m:
            url, port = m.group(1), m.group(2)
            break
    adb("forward", f"tcp:{port}", f"tcp:{port}")
    time.sleep(5)
    from perf import OUT
    import os
    open(os.path.join(OUT, "vm.url"), "w").write(url)
    return VM(url)


# ---------------------------------------------------------------- çözümleme
def events(tl):
    """Tamamlanmış olaylar: (ad, tid, başlangıç_us, süre_us, args). B/E eşlenir."""
    out = []
    stacks = defaultdict(list)
    for e in tl.get("traceEvents", []):
        ph = e.get("ph")
        if ph == "X":
            out.append((e["name"], e.get("tid"), e["ts"], e.get("dur", 0), e.get("args", {})))
        elif ph == "B":
            stacks[e.get("tid")].append(e)
        elif ph == "E" and stacks[e.get("tid")]:
            b = stacks[e.get("tid")].pop()
            out.append((b["name"], b.get("tid"), b["ts"], e["ts"] - b["ts"], b.get("args", {})))
    return sorted(out, key=lambda x: x[2])


def frame_report(evs, budget_us=16700, top=12):
    """Uzun UI karelerinin (Animator::BeginFrame) evre dökümü."""
    frames = [e for e in evs if e[0] in ("Animator::BeginFrame",)]
    phases = ("Animate", "BUILD", "LAYOUT", "UPDATING COMPOSITING BITS", "PAINT", "COMPOSITING", "FINALIZE TREE", "SEMANTICS")
    rep = []
    for name, tid, ts, dur, _ in frames:
        if dur < budget_us:
            continue
        inner = defaultdict(int)
        for n2, t2, ts2, d2, _ in evs:
            if t2 == tid and ts2 >= ts and ts2 + d2 <= ts + dur and n2 in phases:
                inner[n2] += d2
        rep.append((round(dur / 1000, 1), ts, {k: round(v / 1000, 1) for k, v in inner.items()}))
    rep.sort(reverse=True)
    allf = [e[3] / 1000 for e in frames]
    return {
        "frames": len(allf),
        "over_budget": sum(1 for d in allf if d > budget_us / 1000),
        "p50": round(sorted(allf)[len(allf) // 2], 1) if allf else 0,
        "max": round(max(allf), 1) if allf else 0,
        "worst": rep[:top],
    }


def gc_report(evs):
    g = [e for e in evs if "Collect" in e[0] or "Scavenge" in e[0] or "Mark" in e[0] or "Sweep" in e[0] or "Compact" in e[0]]
    c = defaultdict(lambda: [0, 0, 0])
    for n, tid, ts, d, _ in g:
        c[n][0] += 1
        c[n][1] += d
        c[n][2] = max(c[n][2], d)
    return {k: {"n": v[0], "total_ms": round(v[1] / 1000, 1), "max_ms": round(v[2] / 1000, 1)} for k, v in c.items()}


def widget_builds(evs, window=None, top=25):
    """profileWidgetBuilds açıkken: widget türü başına kapsayıcı süre (ms)."""
    skip = {"Animator::BeginFrame", "Animate", "BUILD", "LAYOUT", "PAINT", "COMPOSITING", "FINALIZE TREE",
            "UPDATING COMPOSITING BITS", "SEMANTICS", "Frame", "VSYNC"}
    c = Counter()
    n = Counter()
    for name, tid, ts, d, _ in evs:
        if name in skip or "::" in name or name.startswith("Collect"):
            continue
        if window and not (window[0] <= ts <= window[1]):
            continue
        c[name] += d
        n[name] += 1
    return [(k, round(v / 1000, 1), n[k]) for k, v in c.most_common(top)]


def cpu_report(cpu, window=None, top=30, only_app=False):
    funcs = cpu.get("functions", [])

    def fname(i):
        f = funcs[i].get("function", {})
        owner = f.get("owner", {})
        url = funcs[i].get("resolvedUrl", "")
        on = owner.get("name", "") if isinstance(owner, dict) else ""
        nm = f.get("name", "?")
        short = url.split("/lib/")[-1] if "package:notlar" in url or "/lib/" in url else url.split("/")[-1]
        return f"{on + '.' if on and on != nm else ''}{nm}  [{short}]"

    samples = cpu.get("samples", [])
    if window:
        samples = [s for s in samples if window[0] <= s["timestamp"] <= window[1]]
    incl = Counter()
    excl = Counter()
    for s in samples:
        st = s.get("stack", [])
        if not st:
            continue
        excl[fname(st[0])] += 1
        seen = set()
        for i in st:
            nm = fname(i)
            if nm in seen:
                continue
            seen.add(nm)
            if only_app and "notlar" not in nm and "features/" not in nm and "core/" not in nm and "app/" not in nm:
                continue
            incl[nm] += 1
    total = len(samples) or 1
    period = cpu.get("samplePeriod", 1000)
    return {
        "samples": len(samples),
        "period_us": period,
        "inclusive": [(k, v, round(100 * v / total, 1)) for k, v in incl.most_common(top)],
        "exclusive": [(k, v, round(100 * v / total, 1)) for k, v in excl.most_common(15)],
    }
