"""Uygulama simgesinin SVG kaynaklarini uretir (i3, 2026-10-17: "simge daha
elit kaliteli olsun").

Tasarim: koyu murekkep radyal zemin + altin gradyanli katlanmis sayfa; satirlar
ve son satirin yanindaki 4 koseli YILDIZ (yapay zeka) zemin tonuyla oyulur.
Eski ortak simge dili (beyaz zemin, tek renk) bu uygulamada BIRAKILDI.

Kullanim:
  python3 tool/gen_icon.py assets/icon/src
  # her SVG'yi 1024 px PNG'ye cevir (Chromium headless; pencereyi 1324 px
  # yuksek ac ve ust 1024x1024'u kirp — headless alt kenari kesiyor):
  #   icon.svg → assets/icon/icon.png, icon_foreground.svg →
  #   assets/icon/icon_foreground.png, icon_background.svg →
  #   assets/icon/icon_background.png, icon_monochrome.svg → 432 px
  #   android/.../drawable-xxxhdpi/ic_launcher_monochrome.png
  dart run flutter_launcher_icons
  # sonra mipmap-anydpi-v26/ic_launcher.xml'e <monochrome> blogunu geri ekle.
"""
import sys
OUT=sys.argv[1]
PAGE='M13 7h33.5L63 23.5V69a5 5 0 0 1-5 5H18a5 5 0 0 1-5-5V12a5 5 0 0 1 5-5z'
FOLD='M46.5 7L63 23.5H50.5a4 4 0 0 1-4-4V7z'
LINES='M25 35h26M25 47h26M25 59h13'
# 4 köşeli parıltı, merkez (51,59), yarıçap 6.2
def star(cx,cy,r,w):
    return (f'M{cx} {cy-r}C{cx+w*0.25} {cy-w*0.25} {cx+w*0.25} {cy-w*0.25} {cx+r} {cy}'
            f'C{cx+w*0.25} {cy+w*0.25} {cx+w*0.25} {cy+w*0.25} {cx} {cy+r}'
            f'C{cx-w*0.25} {cy+w*0.25} {cx-w*0.25} {cy+w*0.25} {cx-r} {cy}'
            f'C{cx-w*0.25} {cy-w*0.25} {cx-w*0.25} {cy-w*0.25} {cx} {cy-r}z')
STAR=star(50.5,59,6.6,6.6)
INK='#17120C'
DEFS='''<linearGradient id="gold" x1="13" y1="7" x2="63" y2="74" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FBEBC2"/><stop offset=".45" stop-color="#E6BF6E"/><stop offset="1" stop-color="#A9761F"/></linearGradient>
<linearGradient id="fold" x1="46.5" y1="7" x2="58" y2="20" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#FFF7E0"/><stop offset="1" stop-color="#E9C77C"/></linearGradient>
<radialGradient id="bg" cx="512" cy="430" r="720" gradientUnits="userSpaceOnUse">
<stop offset="0" stop-color="#3A2C1B"/><stop offset=".55" stop-color="#211912"/><stop offset="1" stop-color="#0E0B08"/></radialGradient>'''
def mark(scale, carve=INK):
    return f'''<g transform="translate(512,512) scale({scale}) translate(-38,-40.5)">
<path d="M14.6 9.2h33.5L64.6 25.7V71.2a5 5 0 0 1-5 5H19.6a5 5 0 0 1-5-5V14.2a5 5 0 0 1 5-5z" fill="#000" opacity=".35"/>
<path d="{PAGE}" fill="url(#gold)"/>
<path d="{FOLD}" fill="url(#fold)"/>
<path d="M46.5 7v12.5a4 4 0 0 0 4 4H63" fill="none" stroke="#8A5F17" stroke-width=".8" opacity=".55"/>
<path d="{LINES}" stroke="{carve}" stroke-width="4.6" stroke-linecap="round"/>
<path d="{STAR}" fill="{carve}"/>
</g>'''
bgrect='<rect width="1024" height="1024" fill="url(#bg)"/>'
ring='<rect x="24" y="24" width="976" height="976" rx="160" fill="none" stroke="#C99A45" stroke-opacity=".22" stroke-width="3"/>'
full=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<title>Notlar — tam ikon (i3, elit: koyu murekkep + altin sayfa)</title>
<defs>{DEFS}<clipPath id="kose"><rect width="1024" height="1024" rx="180"/></clipPath></defs>
<g clip-path="url(#kose)">{bgrect}{ring}{mark(11.9)}</g></svg>'''
fg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<title>Notlar — adaptive on plan (i3). ic_launcher.xml bunu %16 inset ile sarar; olcek 13.0 bunu telafi eder.</title>
<defs>{DEFS}</defs>{mark(13.0)}</svg>'''
bg=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<title>Notlar — adaptive zemin (i3)</title><defs>{DEFS}</defs>{bgrect}</svg>'''
mono=f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
<title>Notlar — Android 13+ temali simge (i3). Yalniz alfa kullanilir; ayrintilar oyulur.</title>
<defs><mask id="oyuk" maskUnits="userSpaceOnUse" x="0" y="0" width="1024" height="1024">
<g transform="translate(512,512) scale(13.0) translate(-38,-40.5)">
<path d="{PAGE}" fill="#FFF"/><path d="{FOLD}" fill="#000"/>
<path d="{LINES}" stroke="#000" stroke-width="4.6" stroke-linecap="round"/><path d="{STAR}" fill="#000"/>
</g></mask></defs><rect width="1024" height="1024" fill="#1F1B16" mask="url(#oyuk)"/></svg>'''
for n,c in [('icon',full),('icon_foreground',fg),('icon_background',bg),('icon_monochrome',mono)]:
    open(f'{OUT}/{n}.svg','w').write(c)
