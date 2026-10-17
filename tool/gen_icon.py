"""Uygulama simgesinin kaynaklarini ve PNG'lerini uretir.

i5 (2026-10-17, kullanici secimi: "1 nolu tasarim guzel, onu simgemiz
olarak yapalim" — DOGAL & KARALAMA / Playful Doodle): krem zemin, altta
dalgali nane seridi, el cizimi koyu konturlu SARI yapiskan not (sol alt
kosesi kivrik, dalgali yazi satirlari), capraz duran YESIL kalem (pembe
silgi), kenarlarda karalama parıltilar. Susleme yalniz ZEMIN katmaninda
(maskeyle kirpilabilir); not + kalem guvenli dairede.

Onceki (i4, 2026-10-17:
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
    cream='#FFF5DF', mint='#BFE5D1', mint2='#A9DBC2',
    paper0='#FFE58A', paper1='#FFD45C', curl='#F2C14E',
    ink='#2F2A24', text='#6B5A3A',
    pencil='#86CFA9', pencil2='#5FB58B', wood='#F6D7A7', lead='#2F2A24',
    band='#C9CED6', eraser='#F49CA6',
)
INK_W = 2.2
# Not: 108 birimlik tuvalde, merkez (54,54), guvenli daire r=33. Hafif
# egik (-7 derece) el cizimi yapiskan not; sol alt kosesi kivrik.
NX0, NY0, NX1, NY1 = 32, 35, 64, 76
NCX, NCY, ROT = (NX0 + NX1) / 2, (NY0 + NY1) / 2, -7
CURL = 9
# Kalem: ucu (57,73), silgisi (75,35) yonunde; 42 birim boy, 9 birim en.
TIP = (57.0, 73.0)
ANGLE = math.degrees(math.atan2(35 - 73, 75 - 57))
PL, PW = 42, 9


def wobble(points, amp=0.45):
    """Noktalar arasinda hafif dalgali (el cizimi) yol: her kenarin ortasi
    sirayla ice/disa itilir."""
    d = f'M{points[0][0]:.2f} {points[0][1]:.2f}'
    for i in range(1, len(points)):
        (x0, y0), (x1, y1) = points[i - 1], points[i]
        mx, my = (x0 + x1) / 2, (y0 + y1) / 2
        nx, ny = -(y1 - y0), x1 - x0
        n = math.hypot(nx, ny) or 1
        k = amp * (1 if i % 2 else -1)
        d += f'Q{mx + nx / n * k:.2f} {my + ny / n * k:.2f} {x1:.2f} {y1:.2f}'
    return d


def note_path():
    """Kivrik sol alt koseli yapiskan not (el cizimi kenarlar)."""
    return wobble([(NX0 + 1, NY0), (NX1, NY0 + 0.6), (NX1 - 0.4, NY1),
                   (NX0 + CURL, NY1 - 0.3), (NX0, NY1 - CURL), (NX0 + 1, NY0)]) + 'Z'


def curl_path():
    """Kivrilan kose: kagidin arka yuzu."""
    x, y = NX0, NY1
    return (f'M{x + CURL:.2f} {y - 0.3:.2f}Q{x + CURL - 1.5:.2f} {y - CURL + 2:.2f} '
            f'{x:.2f} {y - CURL:.2f}Q{x + 4:.2f} {y - 2:.2f} {x + CURL:.2f} {y - 0.3:.2f}Z')


def text_lines():
    """Notun ustundeki dalgali "yazi" satirlari."""
    out = []
    for i, (x0, y, x1) in enumerate([(37, 45, 58), (37, 52, 60), (37, 59, 55), (41, 66, 57)]):
        segs = int((x1 - x0) / 3)
        d = f'M{x0} {y}'
        for j in range(segs):
            xa = x0 + (j + 0.5) * (x1 - x0) / segs
            xb = x0 + (j + 1) * (x1 - x0) / segs
            d += f'Q{xa:.2f} {y + (1.1 if (j + i) % 2 else -1.1):.2f} {xb:.2f} {y}'
        out.append(f'<path d="{d}"/>')
    return ''.join(out)


def star(cx, cy, r, k=0.26):
    """4 koseli parilti: uclar sivri, bel ice kavisli."""
    w = r * k
    return (f'M{cx:.2f} {cy - r:.2f}'
            f'C{cx + w:.2f} {cy - w:.2f} {cx + w:.2f} {cy - w:.2f} {cx + r:.2f} {cy:.2f}'
            f'C{cx + w:.2f} {cy + w:.2f} {cx + w:.2f} {cy + w:.2f} {cx:.2f} {cy + r:.2f}'
            f'C{cx - w:.2f} {cy + w:.2f} {cx - w:.2f} {cy + w:.2f} {cx - r:.2f} {cy:.2f}'
            f'C{cx - w:.2f} {cy - w:.2f} {cx - w:.2f} {cy - w:.2f} {cx:.2f} {cy - r:.2f}Z')


def pencil(fill=True):
    """Yerel eksende (uc 0, silgi PL) cizilen kalem; donusumle yerine konur."""
    p = PALETTE
    h = PW / 2
    t = f'translate({TIP[0]} {TIP[1]}) rotate({ANGLE:.2f})'
    if not fill:
        return (f'<g transform="{t}"><path d="M0 0L9 {-h}H{PL - 2}a2 2 0 0 1 2 2'
                f'V{h - 2}a2 2 0 0 1-2 2H9Z" fill="#fff"/></g>')
    ink = p['ink']
    return (
        f'<g transform="{t}" stroke="{ink}" stroke-width="{INK_W}" '
        f'stroke-linejoin="round" stroke-linecap="round">'
        f'<path d="M9 {-h}H{PL - 7}V{h}H9Z" fill="{p["pencil"]}"/>'
        f'<path d="M9 {-h / 3:.2f}H{PL - 7}" stroke="{p["pencil2"]}" stroke-width="1.6" fill="none"/>'
        f'<path d="M9 {h / 3:.2f}H{PL - 7}" stroke="{p["pencil2"]}" stroke-width="1.6" fill="none"/>'
        f'<path d="M{PL - 7} {-h}H{PL - 4}V{h}H{PL - 7}Z" fill="{p["band"]}"/>'
        f'<path d="M{PL - 4} {-h}H{PL - 2}a2 2 0 0 1 2 2V{h - 2}a2 2 0 0 1-2 2H{PL - 4}Z" '
        f'fill="{p["eraser"]}"/>'
        f'<path d="M9 {-h}L0 0L9 {h}Z" fill="{p["wood"]}"/>'
        f'<path d="M3.2 {-h * 3.2 / 9:.2f}L0 0L3.2 {h * 3.2 / 9:.2f}Z" fill="{p["lead"]}" '
        f'stroke-width="1"/>'
        f'</g>'
    )


def defs():
    p = PALETTE
    return (
        '<defs>'
        f'<linearGradient id="paper" x1="{NX0}" y1="{NY0}" x2="{NX1}" y2="{NY1}" '
        'gradientUnits="userSpaceOnUse">'
        f'<stop offset="0" stop-color="{p["paper0"]}"/>'
        f'<stop offset="1" stop-color="{p["paper1"]}"/></linearGradient>'
        '<filter id="soft" x="-30%" y="-30%" width="160%" height="160%">'
        '<feGaussianBlur stdDeviation="1.6"/></filter>'
        '</defs>'
    )


def background():
    """Krem zemin, altta dalgali NANE seridi, kenarlarda karalama
    parıltilar (zemin maskeyle kirpilabilir — susleme burada)."""
    p = PALETTE
    ink = p['ink']
    return (
        f'<rect width="108" height="108" fill="{p["cream"]}"/>'
        f'<path d="M0 70Q18 62 36 70T72 70T108 68V108H0Z" fill="{p["mint"]}"/>'
        f'<path d="M0 82Q20 76 40 83T80 82T108 80V108H0Z" fill="{p["mint2"]}" opacity=".55"/>'
        f'<g fill="none" stroke="{ink}" stroke-width="1.6" stroke-linecap="round" opacity=".8">'
        '<path d="M26 31l2.5 2.5M24 37.5h3.4M29.5 26.5v3.4"/>'
        '<path d="M78 80q4 3 1.5 6t-4 -0.5q-1-3 3-2.5"/>'
        '</g>'
        f'<path d="{star(84, 30, 4.2)}" fill="none" stroke="{ink}" stroke-width="1.4" '
        'stroke-linejoin="round"/>'
        f'<path d="{star(77, 22, 2.3)}" fill="{ink}"/>'
        f'<path d="{star(24, 74, 2.6)}" fill="{ink}" opacity=".85"/>'
    )


def mark():
    p = PALETTE
    note = note_path()
    rot = f'rotate({ROT} {NCX} {NCY})'
    return (
        f'<g transform="{rot}">'
        f'<path d="{note}" transform="translate(1.2 2.4)" fill="#5A4A2A" opacity=".28" '
        'filter="url(#soft)"/>'
        f'<path d="{note}" fill="url(#paper)" stroke="{p["ink"]}" stroke-width="{INK_W}" '
        'stroke-linejoin="round"/>'
        f'<path d="{curl_path()}" fill="{p["curl"]}" stroke="{p["ink"]}" '
        f'stroke-width="{INK_W - 0.4}" stroke-linejoin="round"/>'
        f'<g stroke="{p["text"]}" stroke-width="1.7" stroke-linecap="round" fill="none">'
        f'{text_lines()}</g>'
        '</g>'
        f'{pencil()}'
        f'<g fill="none" stroke="{p["ink"]}" stroke-width="1.5" stroke-linecap="round">'
        '<path d="M79 44l3.5-1.2M80 49.5h3.6M77.5 39.5l2.6-2.4"/></g>'
    )


def mono():
    """Temali simge: not silueti (satirlar oyuk) + kalem silueti; aradaki
    bosluk oyuk (sistem rengi tek tondur, ayrintiyi yalniz alfa tasir)."""
    rot = f'rotate({ROT} {NCX} {NCY})'
    h = PW / 2 + 2.4
    return (
        '<mask id="cut" maskUnits="userSpaceOnUse" x="0" y="0" width="108" height="108">'
        f'<g transform="{rot}"><path d="{note_path()}" fill="#fff"/>'
        '<g stroke="#000" stroke-width="2" stroke-linecap="round" fill="none">'
        f'{text_lines()}</g></g>'
        f'<g transform="translate({TIP[0]} {TIP[1]}) rotate({ANGLE:.2f})">'
        f'<path d="M-1 0L8 {-h}H{PL + 2}V{h}H8Z" fill="#000"/></g>'
        '</mask>'
        '<rect width="108" height="108" fill="#fff" mask="url(#cut)"/>'
        f'{pencil(fill=False)}'
    )


def svg(title, body, bg):
    back = background() if bg else ''
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 108 108" '
            f'width="108" height="108"><title>{title}</title>{defs()}{back}{body}</svg>')


SOURCES = {
    'icon_full': ('Notlar i5 — tam kompozisyon (zemin + isaret), 108 birim',
                  mark, True),
    'icon_foreground': ('Notlar i5 — uyarlanabilir ON PLAN, inset YOK; isaret '
                        'ortadaki 66 birimlik dairede', mark, False),
    'icon_background': ('Notlar i5 — uyarlanabilir ZEMIN', lambda: '', True),
    'icon_monochrome': ('Notlar i5 — Android 13+ temali simge (yalniz alfa)',
                        mono, False),
}


def chromium():
    for c in [os.environ.get('CHROME'), '/opt/pw-browsers/chromium-1194/chrome-linux/chrome', '/opt/pw-browsers/chromium',
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
    """Isaretin (egik not + kalem) 66 birimlik guvenli dairede kaldigini
    dogrular."""
    c, safe = 54, 33
    worst = 0
    t = math.radians(ROT)
    for x, y in [(NX0, NY0), (NX1, NY0), (NX1, NY1), (NX0, NY1)]:
        dx, dy = x - NCX, y - NCY
        rx = NCX + dx * math.cos(t) - dy * math.sin(t)
        ry = NCY + dx * math.sin(t) + dy * math.cos(t)
        worst = max(worst, math.hypot(rx - c, ry - c))
    a = math.radians(ANGLE)
    for lx, ly in [(0, 0), (PL, PW / 2), (PL, -PW / 2)]:
        gx = TIP[0] + lx * math.cos(a) - ly * math.sin(a)
        gy = TIP[1] + lx * math.sin(a) + ly * math.cos(a)
        worst = max(worst, math.hypot(gx - c, gy - c))
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
