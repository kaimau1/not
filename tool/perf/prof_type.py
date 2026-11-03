import sys, pickle
from perf import *
from vmsvc import *
label, x, y = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
TXT = sys.argv[6] if len(sys.argv) > 6 else "kontrol edildi"
tapx, tapy = int(sys.argv[4]), int(sys.argv[5])
vm = VM(open(os.path.join(OUT, 'vm.url')).read())
wake()
tap(x, y); time.sleep(2.5)
tap(tapx, tapy); time.sleep(1.8)
vm.start(widgets=False)
marks = []
for i in range(4):
    marks.append(vm.now())
    text(TXT)
    time.sleep(1.8)
tl, cpu = vm.stop()
key('KEYCODE_BACK'); time.sleep(0.8); key('KEYCODE_BACK'); time.sleep(1.5)
pickle.dump((tl, cpu, marks), open(os.path.join(OUT, f'prof_{label}.pkl'), 'wb'))
evs = events(tl)
fr = frame_report(evs, top=10)
print('frames', fr['frames'], 'over', fr['over_budget'], 'p50', fr['p50'], 'max', fr['max'])
for w in fr['worst']:
    print('  ', w[0], 'ms', round((w[1] - marks[0]) / 1000), w[2])
print('GC', {k: v for k, v in gc_report(evs).items() if k in ('Scavenge', 'CollectNewGeneration', 'CollectOldGeneration', 'StartConcurrentMarking')})
ui = [e for e in evs if e[0] == 'Animator::BeginFrame'][0][1]
for e in sorted([e for e in evs if e[1] == ui and e[3] > 6000 and e[0] not in ('Animator::BeginFrame', 'VsyncProcessCallback')], key=lambda e: -e[3])[:16]:
    print('  L', e[0][:70], round(e[3] / 1000, 1), round((e[2] - marks[0]) / 1000))
if cpu:
    over = [(w[1], w[1] + int(w[0] * 1000)) for w in frame_report(evs, top=500)['worst']]
    samples = cpu.get('samples', [])
    sel = {'samples': [s for s in samples if any(a <= s['timestamp'] <= b for a, b in over)], 'functions': cpu['functions']}
    r = cpu_report(sel, top=45, only_app=True)
    print(f'--- CPU (aşan {len(over)} karede {r["samples"]} örnek) kapsayıcı, uygulama:')
    for k, v, p in r['inclusive'][:34]:
        print(f'   {p:5.1f}%  {k[:120]}')
    r2 = cpu_report(sel, top=20)
    print('   özel:')
    for k, v, p in r2['exclusive'][:14]:
        print(f'   {p:5.1f}%  {k[:120]}')
    # tüm yazma süresi (kare dışı dahil) — ana iş parçacığında ne var
    rall = cpu_report(cpu, top=40, only_app=True)
    print(f'--- CPU tüm pencere ({rall["samples"]} örnek) kapsayıcı, uygulama:')
    for k, v, p in rall['inclusive'][:25]:
        print(f'   {p:5.1f}%  {k[:120]}')
