"""Uygulama simgesinin kaynaklarini ve PNG'lerini uretir (i4, 2026-10-17:
"simgemiz olmamis, arastir, gercekten Play'de cikmaya hazir bir simge yap").

ARASTIRMA (bkz. HAFIZA.md 2026-10-17):
* Google Play magaza simgesi: 512x512, 32 bit PNG, sRGB, <=1024 KB, TAM KARE
  ve OPAK; koseleri Play kendisi yuvarlar (%30) ve golgeyi kendisi ekler —
  varlikta yuvarlak kose, dis golge, rozet/yazi OLMAZ. Logo/serbest cizim
  "keyline" icinde durur, zemin kenardan kenara.
* Android uyarlanabilir simge: 108 dp katmanlar; baslatici maskesi (daire,
  squircle, yuvarlak kare, damla) ortadaki 72 dp'yi gosterir, onemli icerik
  ortadaki 66 dp CAPLI DAIREDE kalmali. Android 13+ temali simge icin ayri
  monokrom katman (yalniz alfa kullanilir).

i3'un sorunlari: (1) on plan %16 inset + 13x olcekle 66 dp daireyi asiyordu —
dairesel maskede sayfanin koseleri ve yildiz kirpiliyordu; (2) tam simgede
yuvarlak kose, ic cerceve cizgisi ve sert dis golge GOMULUYDU (Play kendisi
yuvarlayip golge ekliyor — cift kose/cift golge); (3) altin sayfa + koyu zemin
kucuk boyda okunmuyordu, "dosya yoneticisi" simgesine benziyordu.

i4: mavi-mor gradyan zemin, beyaz YAPISKAN NOT (sag alt kosesi kivrik), not
renginde uc satir ve notun kosesine binen ALTIN yapay zeka parlamasi.
Her sey 108 birimlik tuvalde tasarlanir; on plan inset'SIZ kullanilir.

Kullanim (depo kokunden):
  python3 tool/gen_icon.py
  dart run flutter_launcher_icons   # Android (mipmap/drawable) + Windows .ico
Uretilenler: assets/icon/src/*.svg, assets/icon/*.png (1024 px kaynaklar),
assets/icon/play_store_512.png (Play Console'a yuklenecek), web/icons/*,
web/favicon.png. Render: headless Chromium (Playwright'in ya da sistemin).
"""
import math
import os
import shutil
import subprocess
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'assets', 'icon', 'src')
ICON = os.path.join(ROOT, 'assets', 'icon')

PALETTE = dict(
    bg0='#5B5BF7', bg1='#3A2FC9', bg2='#7A3CF0',
    paper0='#FFFFFF', paper1='#EEF0FF',
    ink='#4338CA',
    gold0='#FFE38A', gold1='#FFB020', gold2='#F08A00',
)
# Geometri: 108 birimlik tuval, merkez (54,54), guvenli daire r=33.
X0, Y0, X1, Y1, R, FOLD = 31, 31.5, 71, 80.5, 7.5, 12.5
LINES = [(39.5, 48.5, 57), (39.5, 57.5, 63), (39.5, 66.5, 54.5)]
SX, SY, SR = 68, 35, 9.6
STROKE = 4.4


def star(cx, cy, r, k=0.22):
    """4 koseli parilti: uclar sivri, bel ice kavisli."""
    w = r * k
    return (f'M{cx:.2f} {cy - r:.2f}'
            f'C{cx + w:.2f} {cy - w:.2f} {cx + w:.2f} {cy - w:.2f} {cx + r:.2f} {cy:.2f}'
            f'C{cx + w:.2f} {cy + w:.2f} {cx + w:.2f} {cy + w:.2f} {cx:.2f} {cy + r:.2f}'
            f'C{cx - w:.2f} {cy + w:.2f} {cx - w:.2f} {cy + w:.2f} {cx - r:.2f} {cy:.2f}'
            f'C{cx - w:.2f} {cy - w:.2f} {cx - w:.2f} {cy - w:.2f} {cx:.2f} {cy - r:.2f}Z')


def note_path():
    """Sag alt kosesi katlanmis yuvarlak dikdortgen (yapiskan not)."""
    r = R
    return (f'M{X0 + r} {Y0}H{X1 - r}A{r} {r} 0 0 1 {X1} {Y0 + r}V{Y1 - FOLD}'
            f'L{X1 - FOLD} {Y1}H{X0 + r}A{r} {r} 0 0 1 {X0} {Y1 - r}'
            f'V{Y0 + r}A{r} {r} 0 0 1 {X0 + r} {Y0}Z')


FOLD_PATH = f'M{X1 - FOLD} {Y1}V{Y1 - FOLD + 3}a3 3 0 0 1 3-3H{X1}Z'


def defs():
    p = PALETTE
    return f'''<defs>
<linearGradient id="bg" x1="0" y1="0" x2="108" y2="108" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="{p['bg0']}"/><stop offset=".55" stop-color="{p['bg1']}"/><stop offset="1" stop-color="{p['bg2']}"/></linearGradient>
<radialGradient id="glow" cx="40" cy="30" r="70" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FFFFFF" stop-opacity=".22"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient>
<linearGradient id="paper" x1="{X0}" y1="{Y0}" x2="{X1}" y2="{Y1}" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="{p['paper0']}"/><stop offset="1" stop-color="{p['paper1']}"/></linearGradient>
<linearGradient id="fold" x1="{X1 - FOLD}" y1="{Y1 - FOLD}" x2="{X1}" y2="{Y1}" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#C9CCF7"/><stop offset="1" stop-color="#F4F5FF"/></linearGradient>
<linearGradient id="gold" x1="{SX - SR}" y1="{SY - SR}" x2="{SX + SR}" y2="{SY + SR}" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="{p['gold0']}"/><stop offset=".5" stop-color="{p['gold1']}"/><stop offset="1" stop-color="{p['gold2']}"/></linearGradient>
<filter id="soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="2.2"/></filter>
</defs>'''


def lines_svg():
    return ''.join(f'<path d="M{a} {y}H{b}"/>' for a, y, b in LINES)


def mark():
    p = PALETTE
    note = note_path()
    return f'''<path d="{note}" transform="translate(0 2.2)" fill="#140B5C" opacity=".38" filter="url(#soft)"/>
<path d="{note}" fill="url(#paper)"/>
<path d="{FOLD_PATH}" fill="url(#fold)"/>
<g stroke="{p['ink']}" stroke-width="{STROKE}" stroke-linecap="round" fill="none">{lines_svg()}</g>
<clipPath id="onnote"><path d="{note}"/></clipPath>
<path d="{star(SX, SY, SR + 2.4)}" fill="{p['bg1']}" clip-path="url(#onnote)"/>
<path d="{star(SX, SY, SR)}" fill="url(#gold)"/>
<path d="{star(SX - 2.2, SY - 2.6, 3.2)}" fill="#FFF8DC" opacity=".85"/>'''


def mono():
    """Temali simge: not silueti, satirlar ve kat OYUK; yildiz ayri, aradaki
    bosluk oyuk (sistem rengi tek tondur, ayrintiyi yalniz alfa tasir)."""
    return f'''<mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="108" height="108">
<path d="{note_path()}" fill="#fff"/>
<g stroke="#000" stroke-width="{STROKE}" stroke-linecap="round">{lines_svg()}</g>
<path d="M{X1 - FOLD} {Y1}V{Y1 - FOLD + 3}a3 3 0 0 1 3-3H{X1}" fill="none" stroke="#000" stroke-width="2.2"/>
<path d="{star(SX, SY, SR + 2.6)}" fill="#000"/>
</mask>
<rect width="108" height="108" fill="#fff" mask="url(#cut)"/>
<path d="{star(SX, SY, SR)}" fill="#fff"/>'''


def svg(title, body, bg):
    back = ('<rect width="108" height="108" fill="url(#bg)"/>'
            '<rect width="108" height="108" fill="url(#glow)"/>') if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" '
            f'width="108" height="108"><title>{title}</title>{defs()}{back}{body}</svg>')


SOURCES = {
    'icon_full': ('Notlar i4 — tam kompozisyon (zemin + isaret), 108 birim',
                  mark, True),
    'icon_foreground': ('Notlar i4 — uyarlanabilir ON PLAN, inset YOK; isaret '
                        'ortadaki 66 birimlik dairede', mark, False),
    'icon_background': ('Notlar i4 — uyarlanabilir ZEMIN', lambda: '', True),
    'icon_monochrome': ('Notlar i4 — Android 13+ temali simge (yalniz alfa)',
                        mono, False),
}


def chromium():
    for c in [os.environ.get('CHROME'), '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
              shutil.which('chromium'), shutil.which('google-chrome'), shutil.which('chrome')]:
        if c and os.path.exists(c):
            return c
    sys.exit('Chromium bulunamadi (CHROME ortam degiskeniyle ver).')


def render(svg_text, size, out):
    """SVG'yi size x size PNG'ye cevirir. TUZAK: headless pencere alt kenari
    kesiyor — pencere yuksek acilir, ust kare kirpilir."""
    tmp = out + '.svg'
    with open(tmp, 'w') as f:
        f.write(svg_text.replace('width="108" height="108"', f'width="{size}" height="{size}"', 1))
    subprocess.run([chromium(), '--headless=new', '--no-sandbox', '--disable-gpu',
                    '--hide-scrollbars', '--force-device-scale-factor=1',
                    '--default-background-color=00000000', f'--window-size={size},{size + 300}',
                    f'--screenshot={out}', f'file://{tmp}'],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    os.remove(tmp)
    im = Image.open(out).convert('RGBA').crop((0, 0, size, size))
    im.save(out)
    return im


def crop_units(im, units):
    """Tuvalin ortasindaki [units] birimlik kareyi kirpar."""
    s = im.size[0]
    m = (108 - units) / 2 * s / 108
    return im.crop((round(m), round(m), round(s - m), round(s - m)))


def rounded(im, radius_frac):
    from PIL import ImageDraw
    s = im.size[0]
    mask = Image.new('L', (s * 4, s * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, s * 4 - 1, s * 4 - 1),
                                           radius=int(s * 4 * radius_frac), fill=255)
    mask = mask.resize((s, s), Image.LANCZOS)
    out = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def check_geometry():
    """Isaretin 66 birimlik guvenli dairede kaldigini dogrular."""
    c, safe = 54, 33
    worst = 0
    for ax, ay in [(X0 + R, Y0 + R), (X1 - R, Y0 + R), (X0 + R, Y1 - R)]:
        worst = max(worst, math.hypot(ax - c, ay - c) + R)
    for px, py in [(X1, Y1 - FOLD), (X1 - FOLD, Y1)]:
        worst = max(worst, math.hypot(px - c, py - c))
    # Yildizin not disindaki halkasi notla kirpilir (bkz. mark) — yalniz
    # altin yildizin kendisi sayilir.
    for px, py in [(SX, SY - SR), (SX + SR, SY)]:
        worst = max(worst, math.hypot(px - c, py - c))
    assert worst <= safe + 0.01, f'isaret guvenli daireyi asiyor: {worst:.2f} > {safe}'
    return worst


def main():
    print(f'en uzak nokta merkezden {check_geometry():.2f} birim (sinir 33)')
    os.makedirs(SRC, exist_ok=True)
    for old in os.listdir(SRC):
        os.remove(os.path.join(SRC, old))
    texts = {}
    for name, (title, body, bg) in SOURCES.items():
        texts[name] = svg(title, body(), bg)
        with open(os.path.join(SRC, f'{name}.svg'), 'w') as f:
            f.write(texts[name])

    full = render(texts['icon_full'], 1024, os.path.join(ICON, '_full.png'))
    render(texts['icon_foreground'], 1024, os.path.join(ICON, 'icon_foreground.png'))
    render(texts['icon_background'], 1024, os.path.join(ICON, 'icon_background.png'))
    render(texts['icon_monochrome'], 1024, os.path.join(ICON, 'icon_monochrome.png'))
    os.remove(os.path.join(ICON, '_full.png'))

    # Eski (API<26) Android, Windows: yuvarlak kare, ortadaki 80 birim.
    legacy = rounded(crop_units(full, 80).resize((1024, 1024), Image.LANCZOS), 0.22)
    legacy.save(os.path.join(ICON, 'icon.png'))
    # Play magaza simgesi: TAM KARE, OPAK, ortadaki 78 birim — isaret Play'in
    # %30 kose yuvarlamasinin (154 px yay) icinde, keyline'a yakin buyuklukte.
    play = crop_units(full, 78).resize((512, 512), Image.LANCZOS).convert('RGB')
    play.save(os.path.join(ICON, 'play_store_512.png'), optimize=True)
    # Web: "any" (yuvarlak kare) ve "maskable" (kenardan kenara, guvenli
    # daire %80 — W3C maskable kurali).
    web = os.path.join(ROOT, 'web', 'icons')
    for s in (192, 512):
        legacy.resize((s, s), Image.LANCZOS).save(os.path.join(web, f'Icon-{s}.png'), optimize=True)
        crop_units(full, 82).resize((s, s), Image.LANCZOS).convert('RGB').save(
            os.path.join(web, f'Icon-maskable-{s}.png'), optimize=True)
    legacy.resize((32, 32), Image.LANCZOS).save(os.path.join(ROOT, 'web', 'favicon.png'), optimize=True)
    print('tamam: assets/icon/*.png, play_store_512.png, web/icons/*')


if __name__ == '__main__':
    main()
