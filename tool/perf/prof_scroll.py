import sys, pickle
from perf import *
from vmsvc import *
label = sys.argv[1]
widgets = len(sys.argv) > 2 and sys.argv[2] == 'w'
vm = VM(open(os.path.join(OUT, 'vm.url')).read())
wake()
vm.start(widgets=widgets)
for _ in range(5):
    swipe(540, 1850, 540, 650, 90); time.sleep(1.3)
for _ in range(5):
    swipe(540, 650, 540, 1850, 90); time.sleep(1.3)
tl, cpu = vm.stop()
if widgets:
    vm.call("ext.flutter.profileWidgetBuilds", isolateId=vm.iso, enabled="false")
pickle.dump((tl, cpu), open(os.path.join(OUT, f'prof_{label}.pkl'), 'wb'))
evs = events(tl)
fr = frame_report(evs, top=8)
print('frames', fr['frames'], 'over', fr['over_budget'], 'p50', fr['p50'], 'max', fr['max'])
for w in fr['worst']:
    print('  ', w[0], 'ms', w[2])
print('GC', gc_report(evs))
if widgets:
    wins = [(w[1], w[1] + int(w[0] * 1000)) for w in frame_report(evs, top=200)['worst']]
    agg = Counter(); cnt = Counter()
    for a, b in wins:
        for k, ms, n in widget_builds(evs, window=(a, b), top=400):
            agg[k] += ms; cnt[k] += n
    print('--- widget build (aşan karelerde, kapsayıcı ms, adet)')
    for k, v in agg.most_common(30):
        print(f'   {v:7.1f} ms  x{cnt[k]:4d}  {k}')
if cpu:
    over = [(w[1], w[1] + int(w[0] * 1000)) for w in frame_report(evs, top=500)['worst']]
    samples = cpu.get('samples', [])
    sel = {'samples': [s for s in samples if any(a <= s['timestamp'] <= b for a, b in over)], 'functions': cpu['functions'], 'samplePeriod': cpu.get('samplePeriod')}
    r = cpu_report(sel, top=45, only_app=True)
    print(f'--- CPU (bütçeyi aşan {len(over)} karede {r["samples"]} örnek) kapsayıcı, uygulama:')
    for k, v, p in r['inclusive'][:40]:
        print(f'   {p:5.1f}%  {k[:120]}')
    r2 = cpu_report(sel, top=20)
    print('   özel:')
    for k, v, p in r2['exclusive'][:15]:
        print(f'   {p:5.1f}%  {k[:120]}')
