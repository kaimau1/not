"""F24.1: metin boyutuna göre tuş başına maliyet (profil derlemesi, VM servisi).

  python -u prof_sizes.py [boyutlar...]   — make_dataset.py boyut + içe aktarma ister
LAYOUT/BeginFrame süreleri + flutter/textinput kanalında ileti başına bayt.
"""
import statistics, sys
import perf
perf.PKG = "dev.kaimau.notlar.olcum"
from taban import reveal, temp
from perf import *
from vmsvc import *

sizes = [int(a) for a in sys.argv[1:]] or [1, 2, 3, 4, 5, 8, 20, 35]
vm = VM(open(os.path.join(OUT, "vm.url")).read())
print("KB  kare  LAYOUT p50/p90/en çok  kare p90/en çok  >16.7  IME bayt/ileti  sıcaklık")
for k in sizes:
    x, y = reveal(f"boyut {k}" + r"\b")
    time.sleep(1)
    tap(x, y); time.sleep(2.6)
    tap(700, 900); time.sleep(2.0)
    text("a"); time.sleep(1.0)  # pencereli kip ilk tuşta girer; ölçüme karışmasın
    vm.start(widgets=None)
    vm.channels(reset=True, top=0)
    for _ in range(4):
        text("kontroledildi"); time.sleep(1.4)
    tl, _ = vm.stop()
    ch = vm.channels(reset=True, top=0)
    ti = ch.get("flutter/textinput", {})
    msgs = ti.get("outCount", 0) + ti.get("inCount", 0)
    bytes_ = ti.get("outBytes", 0) + ti.get("inBytes", 0)
    key("KEYCODE_BACK"); time.sleep(0.8); key("KEYCODE_BACK"); time.sleep(1.8)
    evs = events(tl)
    lay = sorted(e[3] / 1000 for e in evs if e[0] == "LAYOUT")
    fr = sorted(e[3] / 1000 for e in evs if e[0] == "Animator::BeginFrame")
    if not lay:
        print(k, "kare yok"); continue
    q = lambda v, p: v[min(len(v) - 1, int(len(v) * p))]
    print(f"{k:3d} {len(fr):4d}  {q(lay,.5):5.1f}/{q(lay,.9):5.1f}/{lay[-1]:5.1f}   {q(fr,.9):5.1f}/{fr[-1]:5.1f}  {sum(1 for f in fr if f>16.7):3d}   {bytes_//max(msgs,1):6d}  {temp()}", flush=True)
