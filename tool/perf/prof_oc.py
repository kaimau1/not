import sys, pickle
from perf import *
from vmsvc import *
label, x, y = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
widgets = len(sys.argv) > 4 and sys.argv[4] == 'w'
open_wait = float(sys.argv[5]) if len(sys.argv) > 5 else 2.4
vm = VM(open(os.path.join(OUT, 'vm.url')).read())
wake()
vm.start(widgets=widgets)
tap(x, y); time.sleep(open_wait)
tmid = vm.now()
key('KEYCODE_BACK'); time.sleep(1.8)
tl, cpu = vm.stop()
if widgets:
    vm.call("ext.flutter.profileWidgetBuilds", isolateId=vm.iso, enabled="false")
pickle.dump((tl, cpu, tmid), open(os.path.join(OUT, f'prof_{label}.pkl'), 'wb'))
evs = events(tl)
fr = frame_report(evs)
print('frames', fr['frames'], 'over', fr['over_budget'], 'p50', fr['p50'], 'max', fr['max'])
for w in fr['worst']:
    print('  ', w[0], 'ms', 'KAPANIŞ' if w[1] > tmid else 'AÇILIŞ', w[2])
print('GC', gc_report(evs))
ui = [e for e in evs if e[0] == 'Animator::BeginFrame']
uitid = ui[0][1] if ui else None
for e in sorted([e for e in evs if e[1] == uitid and e[3] > 8000 and e[0] not in ('Animator::BeginFrame',)], key=lambda e: -e[3])[:14]:
    print('  L', e[0][:70], round(e[3] / 1000, 1), 'KAPANIŞ' if e[2] > tmid else 'AÇILIŞ')
if cpu:
    for phase, win in (('AÇILIŞ', (vm.t0, tmid)), ('KAPANIŞ', (tmid, 10**15))):
        worst = [w for w in fr['worst'] if (w[1] > tmid) == (phase == 'KAPANIŞ')]
        if not worst:
            continue
        w0 = max(worst, key=lambda w: w[0])
        r = cpu_report(cpu, window=(w0[1], w0[1] + int(w0[0] * 1000)), top=40, only_app=True)
        print(f'--- CPU en kötü {phase} karesi ({w0[0]} ms, {r["samples"]} örnek) kapsayıcı (uygulama):')
        for k, v, p in r['inclusive'][:28]:
            print(f'   {p:5.1f}%  {k[:110]}')
        r2 = cpu_report(cpu, window=(w0[1], w0[1] + int(w0[0] * 1000)), top=15)
        print('   özel (en üst çerçeve):')
        for k, v, p in r2['exclusive'][:10]:
            print(f'   {p:5.1f}%  {k[:110]}')
