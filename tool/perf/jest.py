"""İki parmak zoom + yana kaydırma kare ölçümü (TUTARLILIK F39.2/F39.3).
  python -u jest.py <etiket>   (tool/perf içinden)
Önce Pinch.java: javac (android.jar) + d8 → /data/local/tmp/pinch.dex (adb push).
"""
import sys
from perf import *
tag=sys.argv[1]
L=f"SurfaceView[{PKG}/dev.kaimau.notlar.MainActivity](BLAST)#0"
wake(); print('sürüm',sh(f'dumpsys package {PKG} | grep versionName').strip(), sh('dumpsys battery | grep temperature').strip())
front(); time.sleep(2.5)
def iv(sf):
    ts=sorted(sf.frames); return [round((b-a)/1e6,1) for a,b in zip(ts,ts[1:])]
def rep(name,fn,n=4):
    all=[]
    for i in range(n):
        key('KEYCODE_SHIFT_LEFT'); time.sleep(.5)
        with SF(L) as sf:
            fn(i); time.sleep(1.4)
        v=iv(sf); all.append(v)
        print(name,i,'kare',len(v)+1,'en kötü',max(v) if v else 0,'>17:',sum(x>17 for x in v),'>33:',sum(x>34 for x in v),flush=True)
    return all
def pinch(i):
    h=(330,180) if i%2==0 else (180,330)
    sh(f'CLASSPATH=/data/local/tmp/pinch.dex app_process / Pinch 540 1300 {h[0]} {h[1]} 420')
def hsw(i):
    if i%2==0: swipe(950,1400,150,1400,160)
    else: swipe(150,1400,950,1400,160)
out={'pinch':rep('pinch',pinch),'yana':rep('yana',hsw)}
save(f'jest_{tag}',out)
key('KEYCODE_SLEEP'); print('sıcaklık',sh('dumpsys battery | grep temperature').strip())
