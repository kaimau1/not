"""A/B: klavye aç/kapa + yazma + not kapanışı (2026-11-10 regresyonu).

  python -u ab_klavye.py <etiket> <kart_x> <kart_y> <alan_x> <alan_y> [kb_x kb_y]

Uygulama önde, ana ekran listesi en üstte olmalı (profil uygulaması +
`vm.url`). [kb_x kb_y]: fiziksel klavye takılıyken sanal klavyeyi açan ⌨
düğmesi (2026-11-07 sonrası sürümler). Evre başına UI kare sayısı, toplam/
en uzun kare, 16 ms'yi aşan kare ve TOPLAM LAYOUT süresi (yeniden dizilme
regresyonunun doğrudan ölçüsü) yazılır. Ölçüm penceresinde uiautomator
dökümü yok (semantiği açar).
"""
import sys, pickle
from perf import *
from vmsvc import *

label = sys.argv[1]
cx, cy, fx, fy = (int(v) for v in sys.argv[2:6])
kb = (int(sys.argv[6]), int(sys.argv[7])) if len(sys.argv) > 7 else None
vm = VM(open(os.path.join(OUT, 'vm.url')).read())
wake()
tap(cx, cy); time.sleep(2.8)
if kb:
    tap(*kb); time.sleep(1.2)
tap(fx, fy); time.sleep(2.0)
shown = 'mInputShown=true' in sh('dumpsys input_method | grep mInputShown')
print('klavye açık:', shown)
# Halka tamponu ~10 sn tutuyor: her evre grubu AYRI pencerede toplanır.
evs, marks = [], []


def window(steps):
    vm.start(widgets=False)
    marks.append(('başla', vm.now()))
    for name, act, wait in steps:
        act(); time.sleep(wait); marks.append((name, vm.now()))
    tl, _ = vm.stop()
    evs.extend(events(tl))


window([(f'kb-kapa{i // 2}' if i % 2 == 0 else f'kb-ac{i // 2}',
         (lambda: key('KEYCODE_BACK')) if i % 2 == 0 else (lambda: tap(fx, fy)),
         1.4 if i % 2 == 0 else 1.6) for i in range(6)])
key('KEYCODE_MOVE_END')
window([(f'yaz{i}', lambda: text(' deneme yazisi'), 1.4) for i in range(4)])
window([('kb-son', lambda: key('KEYCODE_BACK'), 1.3),
        ('not-kapa', lambda: key('KEYCODE_BACK'), 1.8)])
pickle.dump((evs, marks), open(os.path.join(OUT, f'ab_{label}.pkl'), 'wb'))
ui = [e for e in evs if e[0] == 'Animator::BeginFrame']
lay = [e for e in evs if e[0] == 'LAYOUT']
tot = {}
print(f'{"evre":10s} {"kare":>5s} {"top_ms":>7s} {"max":>6s} {">16":>4s} {"layout_ms":>9s}')
for (_, t0), (name, t1) in zip(marks, marks[1:]):
    if name == 'başla':
        continue
    u = [e[3] / 1000 for e in ui if t0 <= e[2] < t1]
    l = sum(e[3] / 1000 for e in lay if t0 <= e[2] < t1)
    grp = name.rstrip('0123456789')
    g = tot.setdefault(grp, [0, 0.0, 0.0, 0, 0.0])
    g[0] += len(u); g[1] += sum(u); g[2] = max(g[2], max(u, default=0)); g[3] += sum(x > 16 for x in u); g[4] += l
    print(f'{name:10s} {len(u):5d} {sum(u):7.1f} {max(u, default=0):6.1f} {sum(x > 16 for x in u):4d} {l:9.1f}')
print('--- toplam (grup)')
for k, (n, s, m, j, l) in tot.items():
    print(f'{k:10s} {n:5d} {s:7.1f} {m:6.1f} {j:4d} {l:9.1f}')
