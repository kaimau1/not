"""A/B: kalemle çizim + kayıt + not kapanışı (OTURTMA F59.5).

  python -u ab_kalem.py <etiket> <kart_x> <kart_y> <kalem_x> <kalem_y> [seçenekler]
  python -u ab_kalem.py hazirla <N> <kart_x> <kart_y> <kalem_x> <kalem_y> [seçenekler]

<kart_x kart_y>  : ana ekranda açılacak notun kartı (perf.find('OLCUM kalem')).
<kalem_x kalem_y>: not açıkken kalem kipini açan düğme (alt çubuk / hızlı
                   satırdaki kalem; koordinatı ölçümden ÖNCE perf.find ile bul).
                   Telefonda kalem yok: kalem kipi açıkken parmak çizer.
Seçenekler:
  --alan x0 y0 x1 y1  çizim alanı (varsayılan 140 700 940 1700 — 1080×2400)
  --cizgi N           ölçülen çizgi sayısı (varsayılan 30, 10'arlı pencereler)

Uygulama önde, ana ekran listesi en üstte olmalı (profil uygulaması
`dev.kaimau.notlar.olcum` + `vm.url`: `launch_profile()`), telefon düzeni.
İki veri hâli AYRI koşulur (ikisi de A ve B'de, arka arkaya, ikişer koşu;
ikinci koşu alınır):
  boş sayfa  : "OLCUM kalem bos" notu (make_dataset.py --ink N ile gelir ya da
               elle açılmış boş not).
  dolu sayfa : aynı düzende 1500 çizgili not. Sayfa el yazısı yedekle
               TAŞINMIYOR (not paketi `pageInk` yazmıyor), o yüzden bir kez
               cihazda üretilir:  ab_kalem.py hazirla 1500 <kart> <kalem>
               (~1500 × 0,6 sn ≈ 15 dk, ekran açık — sıcaklığa bak; uygulama
               verisi A/B kurulumları arasında `install -r` ile kalır).
               PDF üstüne çizim için: make_dataset.py --ink 1500 →
               olcum_kalem.notyedek (Ayarlar → Yedekten geri yükle).

Çıktı, evre başına: UI kare / toplam ms / en uzun / >16,7 ms kare; raster
kare / toplam ms / en uzun / >16,7; `kayit` evresinde (son çizgiden sonraki
3,5 sn: 2 sn gecikmeli otomatik kayıt) UI iş parçacığındaki EN UZUN blok.
KAPI (CLAUDE.md ÖLÇÜM KAPISI ile aynı): bir evrede UI ms ya da raster ms
tabana göre %20'den fazla artarsa birleştirme yok.

TUZAK: her koşu sayfaya <cizgi> çizgi EKLER — A ile B'yi aynı sayıda koşuyla
karşılaştır. Ölçüm penceresinde uiautomator dökümü yok (semantiği açar).
"""
import sys, pickle
import perf
perf.PKG = "dev.kaimau.notlar.olcum"
from perf import *
from vmsvc import *

args = sys.argv[1:]


def opt(name, n, default):
    if name not in args:
        return default
    i = args.index(name)
    vals = [int(v) for v in args[i + 1:i + 1 + n]]
    del args[i:i + 1 + n]
    return vals


x0, y0, x1, y1 = opt('--alan', 4, [140, 700, 940, 1700])
count = opt('--cizgi', 1, [30])[0]
prepare = args[0] == 'hazirla'
if prepare:
    total = int(args[1])
    args = args[1:]
label = args[0]
cx, cy, px, py = (int(v) for v in args[1:5])


def stroke_cmd(i):
    """i. çizgi: satırlara dizilmiş kısa, hafif eğik el yazısı benzeri çizik."""
    cols, rows = 8, 20
    w, h = (x1 - x0) // cols, (y1 - y0) // rows
    c, r = i % cols, (i // cols) % rows
    # Aynı hücreye düşen sonraki turlar birkaç piksel kayar (üst üste binmesin).
    shift = (i // (cols * rows)) * 7 % (h // 2)
    ax, ay = x0 + c * w + 6, y0 + r * h + h // 2 + shift
    return f"input swipe {ax} {ay} {ax + w - 14} {ay + (h // 3 if i % 2 else -h // 3)} 90"


def temp():
    return sh('dumpsys battery | grep temperature').strip()


wake()
print('sıcaklık', temp())
tap(cx, cy); time.sleep(2.8)
tap(px, py); time.sleep(1.5)

if prepare:
    # Ölçüm yok: sayfayı doldur. 20'şerli tek adb çağrısı (çağrı başına
    # ~0,5 sn `input` açılışı kalır).
    for a in range(0, total, 20):
        sh('; '.join(stroke_cmd(i) for i in range(a, min(a + 20, total))), timeout=300)
        print(f'{min(a + 20, total)}/{total}', temp(), flush=True)
    time.sleep(4)  # son kayıt
    key('KEYCODE_BACK'); time.sleep(1.2); key('KEYCODE_BACK'); time.sleep(1.5)
    key('KEYCODE_SLEEP')
    sys.exit()

vm = VM(open(os.path.join(OUT, 'vm.url')).read())
# Halka tamponu ~10 sn tutuyor: her 10 çizgi AYRI pencerede toplanır.
evs, marks = [], []


def window(steps):
    vm.start(widgets=False)
    marks.append(('başla', vm.now()))
    for name, act, wait in steps:
        act(); time.sleep(wait); marks.append((name, vm.now()))
    tl, _ = vm.stop()
    evs.extend(events(tl))


for a in range(0, count, 10):
    window([(f'ciz{i}', (lambda i=i: sh(stroke_cmd(i))), 0.35)
            for i in range(a, min(a + 10, count))])
# Kayıt: son çizgiden 2 sn sonra otomatik kayıt + onay.
window([('kayit', lambda: None, 3.5)])
window([('kalem-kapa', lambda: key('KEYCODE_BACK'), 1.3),
        ('not-kapa', lambda: key('KEYCODE_BACK'), 1.8)])
pickle.dump((evs, marks), open(os.path.join(OUT, f'abk_{label}.pkl'), 'wb'))

ui = [e for e in evs if e[0] == 'Animator::BeginFrame']
ras = [e for e in evs if e[0] in ('GPURasterizer::Draw', 'Rasterizer::DoDraw')]
if ras and len({e[0] for e in ras}) > 1:  # iç içe iki ad: dıştakini say
    ras = [e for e in ras if e[0] == 'GPURasterizer::Draw']
ui_tid = ui[0][1] if ui else None
frame_names = ('Animator::BeginFrame', 'VsyncProcessCallback', 'Frame', 'PipelineProduce')


def row(vals):
    return f'{len(vals):5d} {sum(vals):7.1f} {max(vals, default=0):6.1f} {sum(x > 16.7 for x in vals):4d}'


tot = {}
print(f'{"evre":10s} | {"UIkare":>5s} {"ms":>7s} {"max":>6s} {">16":>4s} | {"RSkare":>5s} {"ms":>7s} {"max":>6s} {">16":>4s}')
for (_, t0), (name, t1) in zip(marks, marks[1:]):
    if name == 'başla':
        continue
    u = [e[3] / 1000 for e in ui if t0 <= e[2] < t1]
    r = [e[3] / 1000 for e in ras if t0 <= e[2] < t1]
    grp = name.rstrip('0123456789')
    g = tot.setdefault(grp, ([], []))
    g[0].extend(u); g[1].extend(r)
    if grp != 'ciz':
        print(f'{name:10s} | {row(u)} | {row(r)}')
    if name == 'kayit':
        blocks = sorted(((e[3] / 1000, e[0]) for e in evs
                         if e[1] == ui_tid and t0 <= e[2] < t1 and e[0] not in frame_names),
                        reverse=True)[:3]
        print('  kayıt anı en uzun UI blokları:',
              ', '.join(f'{n[:40]} {d:.1f} ms' for d, n in blocks) or 'yok')
print('--- toplam (grup)')
for k, (u, r) in tot.items():
    print(f'{k:10s} | {row(u)} | {row(r)}')
key('KEYCODE_SLEEP')
print('sıcaklık', temp())
