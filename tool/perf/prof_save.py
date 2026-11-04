"""F22.1: kısa notta otomatik kayıt başına Firestore olayı ve Dart'taki blok (profil)."""
import perf
perf.PKG = "dev.kaimau.notlar.olcum"
from taban import reveal, temp
from perf import *
from vmsvc import *

vm = VM(open(os.path.join(OUT, "vm.url")).read())
print("not sayısı", [n[0][:12] for n in find("Tümü")], "sıcaklık", temp())
x, y = reveal("kisa metin")
time.sleep(1)
tap(x, y); time.sleep(2.6)
tap(540, 1000); time.sleep(2.0)
vm.start(widgets=None)
vm.channels(reset=True, top=0)
N = 3
for _ in range(N):
    text("kontroledildi")
    time.sleep(4.0)  # 2 sn sonra kayıt + onay
tl, _ = vm.stop()
ch = vm.channels(reset=True, top=0)
key("KEYCODE_BACK"); time.sleep(0.8); key("KEYCODE_BACK"); time.sleep(1.5)
for k, v in ch.items():
    if "firestore" in k or "firebase_firestore" in k:
        print(f"  {k[:70]:70s} ↑{v['outCount']} ↓{v['inCount']} {(v['inBytes'] + v['outBytes']) / 1024:.0f} KB")
evs = events(tl)
ui = [e for e in evs if e[0] == "Animator::BeginFrame"][0][1]
rows = sorted((e for e in evs if e[1] == ui and e[0] not in ("Animator::BeginFrame", "VsyncProcessCallback")), key=lambda e: -e[3])[:8]
for e in rows:
    print(f"  {e[0][:50]:50s} {e[3] / 1000:6.1f} ms")
fr = sorted(e[3] / 1000 for e in evs if e[0] == "Animator::BeginFrame")
print(f"kare {len(fr)} en çok {fr[-1]:.1f} >16.7: {sum(1 for f in fr if f > 16.7)}; {N} kayıt")
