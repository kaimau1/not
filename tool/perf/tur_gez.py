"""T16 tablet turu: ekranları/levhaları/ayarları otomatik gezer, her durumda ekran görüntüsü alır.

  python -u tur_gez.py dikey|yatay|koyu [--cikti KLASOR]

Ölçüm uygulaması (`dev.kaimau.notlar.olcum`, misafir veri) üstünde, dokunma etiketten (semantik) yapılır;
ana ekranda semantik boşsa `home_locate` koordinatı kullanılır. Her adım bağımsız (hata → "YOK" satırı, tur sürer).
Görüntüler 0,3 ölçekli PNG (`snap`); inceleme: `python tur_gez.py sayfa a.png b.png c.png d.png -> sayfa.png`.
Yön: `wm user-rotation lock 0|1` (iş bitince `free`). Kod/veri değiştirmez (yeni not açıp boş geri alır, ayar açıp kapatır).
"""
import os, re, sys, time
from ab_hepsi import *
import tur

OUT_DIR = None


def snap(name, scale=0.3):
    p, size = tur.snap(name, scale)
    print(f"  görüntü {name} {size}", flush=True)


def step(name, fn):
    try:
        fn()
    except NotReady as e:
        print(f"DURDU {name}: {e} → yeniden açılıyor", flush=True)
        cold()
    except Exception as e:  # noqa
        print(f"YOK {name}: {e}", flush=True)
        try:
            ready()
        except NotReady:
            sh(f"am start -n {ACT}"); time.sleep(5)


def tap_label(pat, idx=0, wait=1.8, region=None):
    x = dump(allow_empty=True)
    hits = [n for n in nodes(x, pat) if n[0]]
    if region:
        hits = [n for n in hits if region(n)]
    if len(hits) <= idx:
        raise RuntimeError("etiket yok: " + pat)
    tap(hits[idx][1], hits[idx][2]); time.sleep(wait)
    return hits[idx]


def back(n=1, wait=1.0):
    for _ in range(n):
        key("KEYCODE_BACK"); time.sleep(wait)
        if f"{OPKG}/" not in focus():     # ana ekranda fazla BACK uygulamadan çıkar → yeniden aç
            print("  (uygulamadan çıkıldı, yeniden açılıyor)", flush=True)
            cold()
            break


def cold():
    sh(f"am force-stop {OPKG}"); time.sleep(1.2)
    wake(); sh(f"am start -n {ACT}"); time.sleep(8)
    ready()


def rail(label, name, wait=2.5):
    tap_label(r"^" + label + r" \| Sekme", wait=wait)
    snap(name)


def main():
    global OUT_DIR
    mode = sys.argv[1]
    if len(sys.argv) > 3 and sys.argv[2] == "--cikti":
        os.environ["TUR_OUT"] = sys.argv[3]
        tur.TUR_OUT = sys.argv[3]
    rot = "1" if mode == "yatay" else "0"
    sh("wm user-rotation lock " + rot); time.sleep(2)
    p = {"dikey": "p", "yatay": "l", "koyu": "d"}[mode]
    try:
        cold()
        W, H = screen_size(); print("ekran", W, H, flush=True)
        snap(f"{p}01_ana")
        step("arti", lambda: (tap_label(r"^Yeni not . tip seç"), snap(f"{p}02_arti_paneli"), back()))
        step("suz", lambda: (tap_label(r"^Süz$"), snap(f"{p}03_suz"), back()))
        step("diger", lambda: (tap_label(r"^Diğer$"), snap(f"{p}04_diger"), back()))
        step("hesap", lambda: (tap_label(r"^(Yerel hesap|Hesap)$"), snap(f"{p}06_hesap"), back()))
        step("kart_menu", lambda: (tap_label(r"^Not menüsü$", region=lambda n: n[2] > int(H * 0.22)), snap(f"{p}07_kart_menu"), back()))
        # (mikrofon izni isteyen "Hızlı ekle"/"Dikte" adımları kaldırıldı: izin pencereleri kullanıcı işi)
        step("takvim_serit", lambda: (tap_label(r"^Takvim şeridini (daralt|genişlet)"), snap(f"{p}09_serit"), tap_label(r"^Takvim şeridini (daralt|genişlet)"), time.sleep(0.8)))
        for lab, nm in [("Klasörler", "10_klasorler"), ("Takvim", "12_takvim"),
                        ("Arşiv", "13_arsiv"), ("Çöp kutusu", "14_cop"), ("Ayarlar", "15_ayarlar")]:
            step(nm, lambda lab=lab, nm=nm: rail(lab, p + nm))
        # ayar alt sayfaları
        for sub, nm in [("Görünüm", "16_gorunum"), ("Güvenlik", "17_guvenlik"), ("Kalem, yazım", "18_kalem"),
                        ("Notlar ve klasörler", "19_notlar_klasorler"), ("(Arayüz düzeni|Kişiselleştir)", "20_kisisel"),
                        ("Sesli dinle", "22_ses")]:
            def f(sub=sub, nm=nm):
                tap_label(r"^" + sub, wait=2.2)
                snap(p + nm)
                back()
            step(nm, f)
        back()
        cold()
        # not editörü: ilk kart (liste notu), menüsü, sabit PDF
        def editor():
            hh = home_locate(W, H)
            m = hh["card_menu"]
            tap(m[1] - 170, m[2] + 150); time.sleep(2.8)
            snap(f"{p}30_editor_liste")
            tap_label(r"^Not menüsü$", region=lambda n: n[2] < 400, wait=1.6)
            snap(f"{p}31_not_menu")
            back()
            tap_label(r"^Sanal klavyeyi aç", wait=1.5)
            snap(f"{p}32_klavye")
            back(2)
        step("editor", editor)
        def pdf():
            cold()
            hh = home_locate(W, H)
            hit = find_note("OLCUM kalem pdf", "^OLCUM kalem pdf", W, H, hh)
            tap(*hit); time.sleep(3.5)
            snap(f"{p}33_pdf")
            back(2)
        step("pdf", pdf)
        def sablon():
            cold()
            tap_label(r"^Yeni not . tip seç", wait=1.6)
            tap_label(r"^Hazır şablonlar", wait=2.2)
            snap(f"{p}34_sablon")
            back(2)
        step("sablon", sablon)
        def kalem():
            cold()
            hh = home_locate(W, H)
            m = hh["card_menu"]
            tap(m[1] - 170, m[2] + 150); time.sleep(2.5)
            tap_label(r"^Kalemle yaz", wait=1.8)
            snap(f"{p}35_kalem_kipi")
            back(3)
        step("kalem", kalem)
    finally:
        sh("wm user-rotation free")
        sh("input keyevent KEYCODE_SLEEP")


def is_semantic_home():
    x = dump(allow_empty=True)
    return bool(edit_boxes(x))


def sayfa(out, files):
    from PIL import Image
    ims = [Image.open(f) for f in files]
    w = sum(i.width for i in ims) + 10 * (len(ims) - 1)
    h = max(i.height for i in ims)
    c = Image.new("RGB", (w, h), "white")
    x = 0
    for i in ims:
        c.paste(i, (x, 0)); x += i.width + 10
    c.save(out)
    print(out, c.size)


if __name__ == "__main__":
    if sys.argv[1] == "sayfa":
        sayfa(sys.argv[2], sys.argv[3:])
    else:
        main()
