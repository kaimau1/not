""""Yeni not" süresi (DENEYIM F78.2): "+" → "Metin notu" dokunuşundan klavye
görünür olana dek (`dumpsys input_method` `mInputShown=true`).

  python -u prof_new.py [etiket] [paket] [xArti yArti xMetin yMetin]

Uygulama önde, ana ekranda, klavye kapalı. Koordinat verilmezse düğmeler
uiautomator ile BİR KEZ bulunur (ölçüm penceresinin dışında). 5 koşu, ortanca.
Hedef ≤ 450 ms.

Nasıl ölçer: dokunuş ve bekleme TEK `adb shell` içinde, saat telefonun saati —
adb gidiş-dönüşü ölçüme girmez. Başlangıç = `input tap` dönünce (dokunuş
uygulamaya teslim edildi); bitiş = `mInputShown=true` görülen ilk yoklama.
Çözünürlük bir yoklama (~30–60 ms; çıktıda `yoklama` sütunu); sayı o kadar
YUKARI yuvarlanmış olabilir. Klavye, editörün ilk karesinden sonra istenir —
"ilk kare + klavye görünür"ün geç olanı budur.

Her koşu boş bir not açar; geri ile kapanınca boş not kendiliğinden atılır.
"""
import sys
from perf import *

label = sys.argv[1] if len(sys.argv) > 1 else "yeni"
pkg = sys.argv[2] if len(sys.argv) > 2 else PKG
xy = [int(v) for v in sys.argv[3:7]]

RUNS = 5
# Telefonda koşan ölçüm: dokun → klavye görünene dek yokla (en çok ~5 sn).
TIMED = (
    "input tap {x} {y}; t0=$(date +%s%N); i=0; "
    "while [ $i -lt 120 ]; do i=$((i+1)); "
    "if dumpsys input_method | grep -q 'mInputShown=true'; then break; fi; done; "
    "t1=$(date +%s%N); echo $(( (t1-t0)/1000000 )) $i"
)


def shown():
    return "mInputShown=true" in sh("dumpsys input_method | grep mInputShown")


def home():
    """Klavyeyi ve açık notu kapatır; uygulama önde kalır."""
    for _ in range(3):
        if not shown():
            break
        key("KEYCODE_BACK")
        time.sleep(0.6)
    key("KEYCODE_BACK")  # notu kapat
    time.sleep(1.2)
    front(pkg)


front(pkg)
if len(xy) == 4:
    plus, metin = xy[:2], xy[2:]
else:
    _, px, py, _ = tap_label("Yeni not")  # "+" (ipucu: "Yeni not — tip seç")
    _, mx, my, _ = find("Metin notu")[0]
    plus, metin = (px, py), (mx, my)
    key("KEYCODE_BACK")  # paneli kapat
    time.sleep(0.8)
    print(f"koordinatlar: {plus[0]} {plus[1]} {metin[0]} {metin[1]}", flush=True)

out = []
for n in range(RUNS):
    tap(*plus)
    time.sleep(1.0)  # panel yerine otursun
    r = sh(TIMED.format(x=metin[0], y=metin[1])).split()
    ms, polls = int(r[0]), int(r[1])
    ok = polls < 120
    print(f"koşu {n + 1}: {ms} ms, yoklama {polls} (~{ms // max(polls, 1)} ms/yoklama)"
          + ("" if ok else "  KLAVYE GELMEDİ"), flush=True)
    if ok:
        out.append(ms)
    time.sleep(0.8)
    home()

if out:
    med = statistics.median(out)
    print(f"{label}: ortanca {med:.0f} ms (en az {min(out)}, en çok {max(out)}; "
          f"{len(out)}/{RUNS} koşu) — hedef ≤ 450 ms: {'TAMAM' if med <= 450 else 'ÜSTÜNDE'}")
    save(f"yeni_not_{label}", {"ms": out, "ortanca": med})
else:
    print("ölçülemedi: klavye hiç görünmedi (koordinatları ver ya da paneli kontrol et)")
