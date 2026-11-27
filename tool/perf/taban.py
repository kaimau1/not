"""Sürüm öncesi duman testi / taban çizelgesi (F20.4, F27.4): Ek B'nin bütün sütunları.

  python -u taban.py <etiket> [paket]     → PERF_OUT/taban_<etiket>.json + özet

Paket varsayılan release (`dev.kaimau.notlar`). Veri: `OLCUM …` stres notları
(make_dataset.py). Koşudan önce sıcaklığa bakar: > 38 °C sayılar geçersiz.
"""
import argparse
import re
import ab_hepsi
import perf
from perf import *

LABELS = ("kisa metin", "gorselli", "uzun liste", "uzun metin")
TABLET_FALLBACK_LABELS = ("kalem pdf", "kalem bos", "cizgi")
_TR_FOLD = str.maketrans("İIıĞğÜüŞşÖöÇç", "iiigguussoocc")


def _fold(s):
    return (s or "").translate(_TR_FOLD).lower()


def temp():
    m = re.search(r"temperature: (\d+)", sh("dumpsys battery"))
    return int(m.group(1)) / 10 if m else 0


def layer_of(pkg):
    return f"SurfaceView[{pkg}/dev.kaimau.notlar.MainActivity](BLAST)#0"


def intervals(frames):
    ts = sorted(frames)
    return [round((b - a) / 1e6, 1) for a, b in zip(ts, ts[1:])]


def cold(pkg, reps=3):
    out = []
    for _ in range(reps):
        wake()
        sh(f"am force-stop {pkg}")
        time.sleep(1.5)
        with SF(layer_of(pkg)) as sf:
            r = sh(f"am start -W -n {pkg}/dev.kaimau.notlar.MainActivity")
            time.sleep(5)
        m = re.search(r"TotalTime: (\d+)", r)
        iv = intervals(sf.frames)
        # İlk 2 sn'deki en uzun aralık (boşta bekleme eşiği yok: açılışta değişen kare).
        out.append({"total_ms": int(m.group(1)) if m else None, "frames": len(iv) + 1,
                    "max_ms": max(iv) if iv else 0, "over50": [x for x in iv if x > 50][:8]})
        print("açılış", out[-1], flush=True)
    return out


def scroll(pkg, W, H):
    wake()
    x = W // 2
    y_bot, y_top = int(H * 0.77), int(H * 0.27)
    with SF(layer_of(pkg)) as sf:
        for _ in range(6):
            swipe(x, y_bot, x, y_top, 90)
            time.sleep(1.3)
        for _ in range(6):
            swipe(x, y_top, x, y_bot, 90)
            time.sleep(1.3)
    a = analyze(sf.frames, sf.period)
    print("kaydırma", {k: a.get(k) for k in ("frames", "jank_pct", "dropped_vsyncs", "max_ms", "p99_ms", "hitches_ms")}, flush=True)
    return a


def reveal(label, W, H, tries=None):
    """Telefonda semantik listeden kartı orta bölgeye getirir → (x, y) | None."""
    if tries is None:
        tries = 12 if ab_hepsi.is_tablet() else 45
    x = W // 2
    for _ in range(12):
        swipe(x, int(H * 0.29), x, int(H * 0.83), 80)
        time.sleep(0.5)
    time.sleep(0.8)
    lo, hi = 300, H - 150
    for _ in range(tries):
        for n in find("^OLCUM " + re.escape(label)):
            if lo < n[2] < hi:
                return n[1], n[2]
        swipe(x, int(H * 0.62), x, int(H * 0.37), 400)
        time.sleep(1.0)
    return None


def _open_verified(pkg, label, h, W, H):
    """Kartı açar ve açılan notun gerçekten [label] olduğunu doğrular.
    Dönüş: (tap_xy, used_search) | None. [label is None] → tablet ilk kartı."""
    if label is None:
        if not h.get("card_menu"):
            return None
        m = h["card_menu"]
        xy = (m[1] - 170, m[2] + 150)
        tap(*xy); time.sleep(2.5)
        xml = ab_hepsi.dump(allow_empty=True)
        if ab_hepsi._in_editor(xml):
            return xy, False
        return None

    query = f"OLCUM {label}"
    if not h["geo"]:
        xy = reveal(label, W, H)
        if not xy:
            return None
        tap(*xy); time.sleep(2.5)
        xml = ab_hepsi.dump(allow_empty=True)
        if ab_hepsi._in_editor(xml):
            return xy, False
        return None

    hit = ab_hepsi.find_note(query, "^" + re.escape(query), W, H, h)
    if not hit:
        return None
    tap(*hit); time.sleep(2.5)
    ab_hepsi.close_note_search(H)
    xml = ab_hepsi.dump(allow_empty=True)
    texts = [n[0] for n in nodes(xml) if n[0]] + re.findall(r'text="([^"]*)"', xml)
    matched = ab_hepsi._in_editor(xml) and (_fold(label) in _fold(" ".join(texts)))
    if not matched:
        if ab_hepsi._in_editor(ab_hepsi.dump(allow_empty=True)):
            ab_hepsi.back_note(); time.sleep(0.8)
        ab_hepsi.clear_search(h)
        return None
    return hit, True


def open_close(pkg, label, h, W, H, reps=3):
    opened = _open_verified(pkg, label, h, W, H)
    if not opened:
        tag = label or "ilk kart"
        print("atlandı (aç/kapa): kart yok:", tag, flush=True)
        return {"skipped": f"kart yok: {tag}"}
    (x, y), used_search = opened
    # Önce doğrulama için açtığımız notu kapat; arama süzgeci varsa hit sabit kalır.
    ab_hepsi.back_note(); time.sleep(1.5)
    time.sleep(2.0)  # uiautomator semantiği sakinleşsin
    res = []
    lay = layer_of(pkg)
    try:
        for _ in range(reps):
            wake()
            with SF(lay) as s1:
                tap(x, y)
                time.sleep(2.4)
            ab_hepsi.close_note_search(H)
            with SF(lay) as s2:
                key("KEYCODE_BACK")
                time.sleep(1.8)
            if ab_hepsi._in_editor(ab_hepsi.dump(allow_empty=True)) or ab_hepsi.ime_shown():
                ab_hepsi.back_note()
            i1, i2 = intervals(s1.frames), intervals(s2.frames)
            res.append({"open_max": max(i1, default=0), "open_over17": sum(1 for v in i1 if v > 25),
                        "close_anim_max": max(i2[:-1], default=0), "close_last": i2[-1] if i2 else 0,
                        "close_over33": sum(1 for v in i2[:-1] if v > 34)})
    finally:
        if used_search:
            ab_hepsi.clear_search(h)
        ab_hepsi.list_top(W, H)
    tag = label or "ilk kart"
    print("aç/kapa", tag, json.dumps(res, ensure_ascii=False), flush=True)
    return {"xy": (x, y), "reps": res}


def typing(pkg, candidates, h, W, H, chars="kontroledildi", bursts=4, pause=3.0):
    """Tuş patlamaları; kayıt zamanlayıcısı (2 sn) patlama aralarına düşer."""
    import scen
    scen.PKG = pkg
    from scen import app_tids
    opened = None
    chosen = None
    for cand in candidates:
        opened = _open_verified(pkg, cand, h, W, H)
        if opened:
            chosen = cand or "ilk kart"
            break
    if not opened:
        label_desc = "/".join(c or "ilk kart" for c in candidates)
        print("atlandı (yazma): uygun kart yok:", label_desc, flush=True)
        return {"skipped": f"yazma kartı yok: {label_desc}"}

    _, used_search = opened
    try:
        xml = ab_hepsi.dump(allow_empty=True)
        boxes = ab_hepsi.edit_boxes(xml)
        body = boxes[1] if len(boxes) > 1 else (boxes[0] if boxes else None)
        tap_xy = ((body[0] + body[2]) // 2, min(body[1] + 60, (body[1] + body[3]) // 2)) if body else (W // 2, int(H * 0.4))
        tap(*tap_xy)
        time.sleep(1.5)
        kb_xy = ab_hepsi.kb_button(xml) or ab_hepsi.kb_button(ab_hepsi.dump(allow_empty=True))
        if kb_xy:
            ab_hepsi.ensure_ime(kb_xy, tap_xy)
        perf.PKG = pkg
        pid, tids = app_tids()
        atrace_start()
        with SF(layer_of(pkg)) as sf:
            for _ in range(bursts):
                text(chars)
                time.sleep(pause)
        path = atrace_stop("type_" + chosen.replace(" ", "_"))
        runs, marks = parse_sched(path, tids)
        os.remove(path)
        a = analyze(sf.frames, sf.period)
        main_stats = burst_stats(runs.get("main", []))
        # Boştaki kayıt bloğu: uzun koşular.
        long_bursts = sorted((round(1000 * (e - s), 1) for s, e, _ in bursts_of(runs.get("main", [])) if (e - s) > 0.012), reverse=True)[:12]
        out = {"note_used": chosen,
               "sf": {k: a.get(k) for k in ("frames", "jank_frames", "max_ms", "p90_ms", "p99_ms", "eff_fps", "hitches_ms")},
               "main": main_stats, "main_long": long_bursts}
        print("yazma", chosen, json.dumps(out, ensure_ascii=False), flush=True)
        return out
    finally:
        if ab_hepsi._in_editor(ab_hepsi.dump(allow_empty=True)) or ab_hepsi.ime_shown():
            ab_hepsi.back_note()
        if ab_hepsi._in_editor(ab_hepsi.dump(allow_empty=True)):
            key("KEYCODE_BACK"); time.sleep(0.8)
        if used_search:
            ab_hepsi.clear_search(h)
        ab_hepsi.list_top(W, H)
        if "MainActivity" not in sh("dumpsys window | grep mCurrentFocus"):
            front(pkg)


def bursts_of(iv):
    return perf.bursts(iv)


def main():
    ap = argparse.ArgumentParser(
        description="Sürüm öncesi duman testi / taban çizelgesi (Ek B).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="Örnek: python -u taban.py opt9003 dev.kaimau.notlar.olcum",
    )
    ap.add_argument("etiket", help="Çıktı dosya etiketi (PERF_OUT/taban_<etiket>.json)")
    ap.add_argument("paket", nargs="?", default="dev.kaimau.notlar",
                    help="Hedef paket kimliği (varsayılan: dev.kaimau.notlar)")
    args = ap.parse_args()

    tag, pkg = args.etiket, args.paket
    perf.PKG = pkg
    ab_hepsi.OPKG = pkg
    ab_hepsi.ACT = f"{pkg}/dev.kaimau.notlar.MainActivity"

    print("sıcaklık", temp(), flush=True)
    res = {"pkg": pkg, "temp_start": temp()}
    res["cold"] = cold(pkg)
    time.sleep(3)
    W, H = screen_size()
    res["scroll"] = scroll(pkg, W, H)
    ab_hepsi.list_top(W, H)
    h = ab_hepsi.home_locate(W, H)
    res["oc"] = {l: open_close(pkg, l, h, W, H) for l in LABELS}
    if ab_hepsi.is_tablet() and all("skipped" in v for v in res["oc"].values()):
        for fl in (*TABLET_FALLBACK_LABELS, None):
            k = fl or "ilk kart"
            res["oc"][k] = open_close(pkg, fl, h, W, H)
    res["type_kisa"] = typing(pkg, ("kisa metin", "kalem bos", None), h, W, H)
    res["type_uzun"] = typing(pkg, ("uzun metin", "cizgi", "kalem pdf"), h, W, H)
    res["temp_end"] = temp()
    save("taban_" + tag, res)
    print("sıcaklık sonu", res["temp_end"], "→", os.path.join(OUT, f"taban_{tag}.json"), flush=True)


if __name__ == "__main__":
    main()
