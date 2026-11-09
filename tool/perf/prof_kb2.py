"""Klavye kapa/aç döngüsü + not kapanışı; klavye AÇIK, not açıkken başlar.

  python -u prof_kb2.py <etiket> <alan_x> <alan_y> [w]

UI karelerini (VM zaman çizelgesi) ve sunulan kareleri (SurfaceFlinger)
evre evre yazar. Ölçüm penceresinde uiautomator dökümü YAPILMAZ.
"""
import sys, pickle
from perf import *
from vmsvc import *
from taban import layer_of, intervals

label = sys.argv[1]
fx, fy = int(sys.argv[2]), int(sys.argv[3])
widgets = len(sys.argv) > 4 and sys.argv[4] == 'w'
pkg = 'dev.kaimau.notlar.olcum'
vm = VM(open(os.path.join(OUT, 'vm.url')).read())
marks = []
with SF(layer_of(pkg)) as sf:
    vm.start(widgets=widgets)
    marks.append(('başla', vm.now(), time.time()))
    for i in range(3):
        key('KEYCODE_BACK'); time.sleep(1.5)
        marks.append((f'kapa{i}', vm.now(), time.time()))
        tap(fx, fy); time.sleep(1.8)
        marks.append((f'aç{i}', vm.now(), time.time()))
    key('KEYCODE_BACK'); time.sleep(1.2)
    marks.append(('kapa-son', vm.now(), time.time()))
    key('KEYCODE_BACK'); time.sleep(1.8)
    marks.append(('not-kapa', vm.now(), time.time()))
    tl, cpu = vm.stop()
if widgets:
    vm.call("ext.flutter.profileWidgetBuilds", isolateId=vm.iso, enabled="false")
pickle.dump((tl, cpu, marks, sf.frames), open(os.path.join(OUT, f'prof_{label}.pkl'), 'wb'))
evs = events(tl)


def phase(ts):
    for (_, t0, _), (name, t1, _) in zip(marks, marks[1:]):
        if t0 <= ts < t1:
            return name
    return '?'


ui = [e for e in evs if e[0] == 'Animator::BeginFrame']
ras = [e for e in evs if e[0] == 'GPURasterizer::Draw']
print('UI kareleri', len(ui), 'raster', len(ras))
for (_, t0, _), (name, t1, _) in zip(marks, marks[1:]):
    u = [e[3] / 1000 for e in ui if t0 <= e[2] < t1]
    r = [e[3] / 1000 for e in ras if t0 <= e[2] < t1]
    print(f'{name:10s} UI n={len(u):3d} max={max(u, default=0):6.1f} >16={sum(x > 16 for x in u):2d}'
          f' | raster n={len(r):3d} max={max(r, default=0):6.1f} >16={sum(x > 16 for x in r):2d}')
fr = frame_report(evs, top=12)
for w in fr['worst']:
    print('  ', w[0], 'ms', phase(w[1]), w[2])
# SurfaceFlinger: duvar saati → evre
iv = sorted(sf.frames)
print('SF kare', len(iv), 'periyot ms', round(sf.period / 1e6, 2))
if widgets:
    for (_, t0, _), (name, t1, _) in zip(marks, marks[1:]):
        rows = widget_builds(evs, window=(t0, t1), top=14)
        if rows:
            print(f'--- build ({name}):')
            for k, ms, n in rows:
                print(f'   {ms:7.1f} ms  {n:5d}x  {k[:80]}')
