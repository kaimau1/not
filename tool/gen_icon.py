"""Uygulama simgesinin PNG'lerini kullanicinin tasarim gorselinden uretir.

i6 (2026-10-19, kullanici gorseli: "simgemizi degistirecegiz, attigim gibi
olsun"): lacivert gradyan zemin, uzerinde gumus, egik kesimli (bevel) serif
"N" ve sag ust bacagin yaninda alt alta "o t e". Kaynak: assets/icon/src/
source.jpg (kullanicinin gonderdigi gorsel, acik gri zemin uzerinde yuvarlak
kare simge).

Gorsel bir FOTOGRAF gibi tek parca oldugundan uyarlanabilir simgenin
katmanlari ondan AYRISTIRILIR:
* zemin: simgenin icindeki lacivert piksellere (harflerin uzagindakiler)
  x, y'de ikinci derece yuzey uydurulur -> kenardan kenara 108 birimlik
  tuvale uzatilir (yuvarlak kose ve dis golge gorselden ALINMAZ — maskeyi
  baslatici, kose/golgeyi Play kendisi ekler);
* on plan: gumus harfler. Lacivertte mavi kanal kirmiziyi ~55 asiyor,
  gumuste ~0: alfa = 1 - (b - r) / (b - r)_zemin. Renk zeminden ayristirilir
  (on = (p - (1 - a) * zemin) / a). Harflerin yumusak golgesi yeniden
  cizilir (gorseldeki golge zeminle karisik, ayrisamaz);
* monokrom (Android 13+ temali simge): on planin alfasi.

Olcek: isaretin kutusunun kosegeni 66 birimlik GUVENLI DAIREYE sigar (yuvarlak
maskede de kirpilmaz); baslaticinin gosterdigi ortadaki 72 birimde harfler
gorseldeki oranda (~%66) durur.

Kullanim (depo kokunden):
  python3 tool/gen_icon.py && dart run flutter_launcher_icons
Uretilenler: assets/icon/*.png (1024 px), assets/icon/play_store_512.png
(Play Console'a yuklenecek: tam kare, opak), web/icons/*, web/favicon.png.
"""
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICON = os.path.join(ROOT, 'assets', 'icon')
SOURCE = os.path.join(ICON, 'src', 'source.jpg')

# Kaynak gorselde (2400x1792) simgenin ici ve harflerin kutusu — olculdu.
INNER = (760, 430, 1640, 1380)   # zemin ornegi alinan, koselerden uzak bolge
GLYPH = (870, 540, 1592, 1232)   # harfler (+ ~10 px pay)
S = 1024                         # cikti tuvali (108 birim)
SAFE = 66                        # guvenli daire capi (birim)


def fit_background(im):
    """Lacivert piksellere r, g, b icin ikinci derece yuzey uydurur; kaynak
    koordinatinda (x, y) -> renk donduren fonksiyon verir."""
    import numpy as np
    a = np.asarray(im, dtype=np.float64)
    x0, y0, x1, y1 = INNER
    ys, xs = np.mgrid[y0:y1:4, x0:x1:4]
    px = a[ys, xs]
    navy = (px[..., 2] - px[..., 0]) > 40
    gx0, gy0, gx1, gy1 = GLYPH
    far = ~((xs > gx0 - 40) & (xs < gx1 + 40) & (ys > gy0 - 40) & (ys < gy1 + 40))
    keep = navy & far
    X, Y = xs[keep].astype(float), ys[keep].astype(float)
    M = np.stack([np.ones_like(X), X, Y, X * X, X * Y, Y * Y], axis=1)
    coef = [np.linalg.lstsq(M, px[..., c][keep], rcond=None)[0] for c in range(3)]

    def color(X, Y):
        M = np.stack([np.ones_like(X), X, Y, X * X, X * Y, Y * Y], axis=-1)
        return np.stack([M @ k for k in coef], axis=-1)
    return color


def extract_glyph(im, bg):
    """Harfleri saydam zemine ayristirir (RGBA, GLYPH kutusu boyutunda)."""
    import numpy as np
    x0, y0, x1, y1 = GLYPH
    p = np.asarray(im.crop(GLYPH), dtype=np.float64)
    ys, xs = np.mgrid[y0:y1, x0:x1]
    b = bg(xs.astype(float), ys.astype(float))
    blue = np.clip(b[..., 2] - b[..., 0], 1, None)
    alpha = np.clip(1 - (p[..., 2] - p[..., 0]) / blue, 0, 1)
    # Lacivertteki JPEG gurultusu ve harf golgesi: dusuk alfayi sil, kalani
    # yeniden ol ekle.
    alpha = np.clip((alpha - 0.12) / 0.8, 0, 1)
    a3 = alpha[..., None]
    fg = np.where(a3 > 0.02, (p - (1 - a3) * b) / np.maximum(a3, 0.02), 0)
    fg = np.clip(fg, 0, 255)
    rgba = np.concatenate([fg, alpha[..., None] * 255], axis=-1).astype(np.uint8)
    return Image.fromarray(rgba, 'RGBA')


def background_layer(bg, size, units):
    """Zemin yuzeyini [units] birimlik kareye (merkezi simgenin merkezi)
    uzatir. 108 birim = kaynaktaki harf kutusu olcegine gore hesaplanir."""
    import numpy as np
    cx = (GLYPH[0] + GLYPH[2]) / 2 - 16   # harfler gorselde hafif sagda
    cy = (GLYPH[1] + GLYPH[3]) / 2
    src_per_unit = glyph_diag() / SAFE
    half = units / 2 * src_per_unit
    t = np.linspace(-half, half, size)
    X, Y = np.meshgrid(cx + t, cy + t)
    # Yuzey kare terimli: simgenin disina cok uzaninca sapar; kaynak
    # simgenin icine kenetle.
    X = np.clip(X, 655, 1744)
    Y = np.clip(Y, 329, 1456)
    c = np.clip(bg(X, Y), 0, 255).astype(np.uint8)
    return Image.fromarray(c, 'RGB')


def glyph_diag():
    w, h = GLYPH[2] - GLYPH[0], GLYPH[3] - GLYPH[1]
    return (w * w + h * h) ** 0.5


def foreground_layer(glyph, size, units=108):
    """Harfleri [units] birimlik tuvalin ortasina, kosegeni guvenli daireye
    sigacak olcekte koyar; alta yumusak golge."""
    scale = size / units * SAFE / glyph_diag()
    g = glyph.resize((round(glyph.width * scale), round(glyph.height * scale)), Image.LANCZOS)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ox = (size - g.width) // 2 + round(16 * scale)
    oy = (size - g.height) // 2
    shadow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    a = g.getchannel('A').point(lambda v: v * 0.45)
    blk = Image.new('RGBA', g.size, (0, 0, 8, 255))
    blk.putalpha(a)
    shadow.paste(blk, (ox + round(size * 0.006), oy + round(size * 0.012)), blk)
    shadow = shadow.filter(ImageFilter.GaussianBlur(size * 0.008))
    out = Image.alpha_composite(out, shadow)
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    layer.paste(g, (ox, oy), g)
    # Harf kutusu merkeze gore saga kaydirildi; kosegen yine daire icinde mi?
    bx0, by0 = ox - size / 2, oy - size / 2
    bx1, by1 = bx0 + g.width, by0 + g.height
    r = max((x * x + y * y) ** 0.5 for x in (bx0, bx1) for y in (by0, by1))
    assert r <= size / units * SAFE / 2 * 1.06, f'isaret guvenli daireyi asiyor: {r:.0f}'
    return Image.alpha_composite(out, layer)


def rounded(im, radius_frac):
    s = im.size[0]
    mask = Image.new('L', (s * 4, s * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, s * 4 - 1, s * 4 - 1),
                                           radius=int(s * 4 * radius_frac), fill=255)
    mask = mask.resize((s, s), Image.LANCZOS)
    out = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    out.paste(im, (0, 0), mask)
    return out


def full_icon(bg, glyph, size, units):
    """Ortadaki [units] birimi gosteren opak tam simge."""
    back = background_layer(bg, size, units).convert('RGBA')
    fore = foreground_layer(glyph, size, units)
    return Image.alpha_composite(back, fore)


def main():
    im = Image.open(SOURCE).convert('RGB')
    bg = fit_background(im)
    glyph = extract_glyph(im, bg)

    background_layer(bg, S, 108).save(os.path.join(ICON, 'icon_background.png'))
    fore = foreground_layer(glyph, S)
    fore.save(os.path.join(ICON, 'icon_foreground.png'))
    mono = Image.new('RGBA', (S, S), (255, 255, 255, 0))
    white = Image.new('RGBA', (S, S), (255, 255, 255, 255))
    alpha = foreground_layer(glyph, S).getchannel('A')
    # Golgeyi monokroma katma: yalniz harflerin kendi alfasi.
    letters = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    scale = S / 108 * SAFE / glyph_diag()
    g = glyph.resize((round(glyph.width * scale), round(glyph.height * scale)), Image.LANCZOS)
    letters.paste(g, ((S - g.width) // 2 + round(16 * scale), (S - g.height) // 2), g)
    mono = Image.composite(white, mono, letters.getchannel('A'))
    mono.save(os.path.join(ICON, 'icon_monochrome.png'))
    del alpha

    # Eski (API<26) Android: yuvarlak kare, ortadaki 80 birim.
    legacy = rounded(full_icon(bg, glyph, S, 80), 0.22)
    legacy.save(os.path.join(ICON, 'icon.png'))
    # Play magaza simgesi: TAM KARE, OPAK (kose/golgeyi Play ekler).
    play = full_icon(bg, glyph, 512, 78).convert('RGB')
    play.save(os.path.join(ICON, 'play_store_512.png'), optimize=True)
    # Web: "any" (yuvarlak kare) ve "maskable" (kenardan kenara, guvenli
    # daire %80 — W3C maskable kurali).
    web = os.path.join(ROOT, 'web', 'icons')
    for s in (192, 512):
        legacy.resize((s, s), Image.LANCZOS).save(os.path.join(web, f'Icon-{s}.png'), optimize=True)
        full_icon(bg, glyph, s, 82).convert('RGB').save(
            os.path.join(web, f'Icon-maskable-{s}.png'), optimize=True)
    legacy.resize((32, 32), Image.LANCZOS).save(os.path.join(ROOT, 'web', 'favicon.png'), optimize=True)
    print('tamam: assets/icon/*.png, play_store_512.png, web/icons/*')


if __name__ == '__main__':
    main()
