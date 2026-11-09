"""A/B: ana ekran kaydırması (2026-11-10 "genel yavaşlık").

  python -u ab_liste.py <etiket>

Uygulama önde, ana ekranda. 8 fırlatma (4 aşağı, 4 yukarı) tek pencerede;
UI kare sayısı, toplam/en uzun kare, 16 ms'yi aşan ve LAYOUT/BUILD toplamı.
"""
import sys
from perf import *
from vmsvc import *

label = sys.argv[1]
vm = VM(open(os.path.join(OUT, 'vm.url')).read())
wake()
w, h = (int(v) for v in re.search(r'(\d+)x(\d+)', sh('wm size').splitlines()[-1]).groups())
x = w // 2
vm.start(widgets=False)
for d in (1, 1, 1, 1, -1, -1, -1, -1):
    y0, y1 = (int(h * 0.75), int(h * 0.3)) if d > 0 else (int(h * 0.3), int(h * 0.75))
    swipe(x, y0, x, y1, 90)
    time.sleep(1.1)
tl, _ = vm.stop()
evs = events(tl)
ui = [e[3] / 1000 for e in evs if e[0] == 'Animator::BeginFrame']
lay = sum(e[3] / 1000 for e in evs if e[0] == 'LAYOUT')
bld = sum(e[3] / 1000 for e in evs if e[0] == 'BUILD')
srt = sorted(ui)
print(f'{label}: kare {len(ui)} toplam {sum(ui):.0f} ms p50 {srt[len(srt) // 2]:.1f} '
      f'p90 {srt[int(len(srt) * .9)]:.1f} max {max(ui):.1f} >16 {sum(v > 16 for v in ui)} '
      f'BUILD {bld:.0f} LAYOUT {lay:.0f}')
