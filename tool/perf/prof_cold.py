"""Soğuk açılış profili (profil derlemesi): start-paused → profiler → resume.

  python -u prof_cold.py [etiket]   → karelerin evre dökümü, CPU, platform kanalları
"""
import sys, pickle
from perf import *
from vmsvc import *

label = sys.argv[1] if len(sys.argv) > 1 else "cold"
sh(f"am force-stop {OPKG}")
time.sleep(1.2)
sh("logcat -c")
sh(f"am start -n {OPKG}/dev.kaimau.notlar.MainActivity --ez start-paused true")
url = None
for _ in range(40):
    time.sleep(0.3)
    m = re.search(r"listening on (http://127\.0\.0\.1:(\d+)/\S+)", sh("logcat -d -s flutter:I"))
    if m:
        url, port = m.group(1), m.group(2)
        break
adb("forward", f"tcp:{port}", f"tcp:{port}")
open(os.path.join(OUT, "vm.url"), "w").write(url)
time.sleep(0.5)
vm = VM(url)
vm.start(widgets=None)
vm.call("resume", isolateId=vm.iso)
time.sleep(7)
tl, cpu = vm.stop()
pickle.dump((tl, cpu), open(os.path.join(OUT, f"prof_{label}.pkl"), "wb"))
evs = events(tl)
fr = frame_report(evs, top=10)
print("kare", fr["frames"], "aşan", fr["over_budget"], "p50", fr["p50"], "en çok", fr["max"])
t0 = vm.t0
for w in fr["worst"]:
    print("  ", w[0], "ms @", round((w[1] - t0) / 1000), "ms", w[2])
frames = [e for e in evs if e[0] == "Animator::BeginFrame"]
if frames:
    print("ilk kare @", round((frames[0][2] - t0) / 1000), "ms; 10. kare @", round((frames[min(9, len(frames) - 1)][2] - t0) / 1000), "ms")
print("--- platform kanalları")
vm.channels(top=10)
r = cpu_report(cpu, top=40, only_app=True)
print(f"--- CPU tüm pencere ({r['samples']} örnek) kapsayıcı, uygulama:")
for k, v, p in r["inclusive"][:24]:
    print(f"   {p:5.1f}%  {k[:100]}")
r2 = cpu_report(cpu, top=14)
print("   özel:")
for k, v, p in r2["exclusive"][:12]:
    print(f"   {p:5.1f}%  {k[:100]}")
