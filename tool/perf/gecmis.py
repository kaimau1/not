"""gecmis.csv + altin_taban.json -> evre basina son N kosunun egilimi (HIZ_PLANI F83.2).

Kullanim: python tool/perf/gecmis.py [--son 10] [--esik 10]
Kosu = ayni etiket. Her evre icin ui_ms, altin tabana gore %; kayma > esik ise "KAYMA" ve
cikis kodu 1 (haftalik tur bunu Kuyruk'a "hiz: <evre>" satiri yapar).
Cihaz gerekmez: `python tool/perf/gecmis.py --self-check`.
"""
import argparse, csv, io, json, os, sys

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "docs", "perf")


def load(csv_text):
    kosular, sira = {}, []
    for r in csv.DictReader(io.StringIO(csv_text)):
        e = r["etiket"]
        if e not in kosular:
            kosular[e] = {}
            sira.append(e)
        kosular[e][r["evre"]] = float(r["ui_ms"])
    return kosular, sira


def rapor(kosular, sira, altin, son=10, esik=10.0):
    # A etiketleri (taban kopyalari) egilime girmez; yalnizca B/altin/tekil kosular.
    sira = [e for e in sira if "_A_" not in e and "_A2_" not in e][-son:]
    out, kayan = [], []
    for ev, g in altin.items():
        g = g["ui_ms"]
        vals = [kosular[e][ev] for e in sira if ev in kosular[e]]
        if not vals:
            continue
        pct = (vals[-1] / g - 1) * 100 if g > 3 else 0.0
        bayrak = ""
        if g > 3 and pct > esik:
            bayrak = "  KAYMA"
            kayan.append(ev)
        out.append("%-10s taban %7.1f  son %7.1f (%+5.1f%%)  egilim: %s%s" % (
            ev, g, vals[-1], pct, " ".join("%.0f" % v for v in vals), bayrak))
    return out, kayan


def self_check():
    t = ("tarih,commit,etiket,evre,ui_ms,layout_ms,kare,sicaklik\n"
         "d,c,altin_x,yaz,100,1,1,1\nd,c,k_A_x,yaz,500,1,1,1\n"
         "d,c,k_B_x,yaz,125,1,1,1\nd,c,k_B_x,acilis,0.5,0,1,1\n")
    k, s = load(t)
    out, kayan = rapor(k, s, {"yaz": {"ui_ms": 100}, "acilis": {"ui_ms": 0.5}})
    assert kayan == ["yaz"], out
    out, kayan = rapor(k, s, {"yaz": {"ui_ms": 120}}, esik=10)
    assert kayan == [] and "yaz" in out[0], out
    print("self-check tamam")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--son", type=int, default=10)
    p.add_argument("--esik", type=float, default=10.0)
    p.add_argument("--self-check", action="store_true")
    o = p.parse_args()
    if o.self_check:
        self_check()
        sys.exit(0)
    with open(os.path.join(D, "gecmis.csv"), encoding="utf-8") as f:
        k, s = load(f.read())
    with open(os.path.join(D, "altin_taban.json"), encoding="utf-8") as f:
        altin = json.load(f)["evreler"]
    out, kayan = rapor(k, s, altin, o.son, o.esik)
    print("\n".join(out))
    if kayan:
        print("KAYAN EVRELER:", ", ".join(kayan))
    sys.exit(1 if kayan else 0)
