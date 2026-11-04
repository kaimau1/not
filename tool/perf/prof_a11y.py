"""F27.2: erişilebilirlik istemcisi açıkken semantik ağacın kare maliyeti (profil).

`uiautomator events` uzun ömürlü UiAutomation bağlantısı açar: Flutter semantiği
açılır (şifre yöneticisi / ekran okuyucu gibi), sistem ayarı değişmez.
"""
import subprocess
import perf
perf.PKG = "dev.kaimau.notlar.olcum"
from taban import temp
from perf import *
from vmsvc import *

vm = VM(open(os.path.join(OUT, "vm.url")).read())


def run(label):
    wake()
    time.sleep(1.5)
    vm.start(widgets=None)
    for _ in range(5):
        swipe(540, 1850, 540, 650, 90); time.sleep(1.3)
    for _ in range(5):
        swipe(540, 650, 540, 1850, 90); time.sleep(1.3)
    tl, _ = vm.stop()
    evs = events(tl)
    fr = sorted(e[3] / 1000 for e in evs if e[0] == "Animator::BeginFrame")
    sem = sorted(e[3] / 1000 for e in evs if e[0] == "SEMANTICS")
    q = lambda v, p: v[min(len(v) - 1, int(len(v) * p))] if v else 0
    print(f"{label:10s} kare {len(fr)} aşan {sum(1 for f in fr if f > 16.7)} p90 {q(fr, .9):.1f} en çok {fr[-1]:.1f}"
          f" | SEMANTICS {len(sem)} kare p50 {q(sem, .5):.1f} p90 {q(sem, .9):.1f} en çok {q(sem, 1):.1f} toplam {sum(sem):.0f} ms | {temp()}", flush=True)


run("kapalı")
p = subprocess.Popen([ADB, "shell", "uiautomator", "events"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
time.sleep(3)
run("açık")
p.terminate()
sh("pkill -f uiautomator")
time.sleep(2)
