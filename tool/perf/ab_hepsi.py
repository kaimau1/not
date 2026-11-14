"""TAM HIZ ÖLÇÜMÜ + OTOMATİK KARAR (HIZ_PLANI F81.1–F81.4).

  python -u ab_hepsi.py <A.apk> <B.apk> [--kosu 3] [--teyit 2] [--altin] [--altin-yaz]
                        [--etiket-a X] [--etiket-b Y] [--commit SHA]

İki PROFİL APK'sı (kimlik `dev.kaimau.notlar.olcum`, "Notlar Ölçüm") sırayla
A,B,A,B,A,B kurulur (`adb install -r`: veri kalır; ısınma dengesi). Her
koşuda uygulama start-paused açılır ve evreler tek oturumda ölçülür:

  acilis     soğuk açılış (resume → 7 sn): ilk kare ms + kareler
  liste      ana ekran 8 fırlatma (ab_liste)
  menu       ilk kartın ⋮ levhası aç → kapat
  arama      arama kutusuna 5 harf, harf başına 0,5 sn
  klasor     ızgarada yana çekiş (Tümü → sonraki durak) ve geri
  yeni_not   "+" → "Metin notu" → editör (sonra boş not geri ile atılır)
  not_ac     ilk karttan not aç (genişleyen geçiş)
  kb         klavye aç/kapa ×3 (ab_klavye)
  yaz        4 × " deneme yazisi"
  not_kapa   klavye kapa + notu kapat
  sabit_ac   sabit PDF'li not ("OLCUM kalem pdf") aç
  sabit_kay  sabit bölmede 3 sayfa kaydırma
  sabit_kb   sabit PDF'li notta klavye aç/kapa ×2 (kullanıcı 2026-11-12)

Evre başına: UI kare sayısı, UI ms toplamı, LAYOUT ms, en uzun kare,
> 16 ms kare. A ve B için ORTANCA (3 koşu).

KARAR (F81.2): bir evrede B ortancası (UI ms ya da LAYOUT ms) A'nın EN KÖTÜ
koşusundan da kötü VE fark > %20 VE > 3 ms → KÖTÜLEŞTİ (%10 aynı APK
A=A'da yanlış alarm verdi, 2026-11-13). Tek KÖTÜLEŞTİ =
`KARAR: KALDI`. TEYİT (P60): ilk karar KALDI ise `--teyit` (2) A,B çifti daha
koşulur, karar tüm koşularla yeniden verilir (tek seferlik gürültü elenir;
`--teyit 0` eski davranış). `--altin`: B ayrıca `docs/perf/altin_taban.json`'a karşı;
bir evrede %15'ten fazla kötü → KALDI (kümülatif kayma, A3). `--altin-yaz`:
ortancalar altın tabana yazılır (A=B aynı APK ise iki tarafın TÜM koşuları;
en az 5 koşu) — dosya yoksa tümü, varsa yalnız İYİLEŞEN evreler (mandal).

Kayıt (F81.3): her koşunun evre ortancaları `docs/perf/gecmis.csv`'ye
(tarih, commit, etiket, evre, UI ms, LAYOUT ms, kare, sıcaklık).

HAZIRLIK (bir kez): veri seti (`make_dataset.py`, README) + sabit PDF'li not:
`python make_dataset.py --ink 40` → `olcum_kalem.notyedek`'i
`/sdcard/Download/`'a it (Git Bash'te `MSYS_NO_PATHCONV=1`) → Ayarlar →
Senkronizasyon → Yedekten geri yükle → Diğer → İndirilenler.

TELEFON KURALLARI (OTOMASYON §Telefon): her koşu < 34 °C'de başlar (37'nin
altı yetmedi: koşu içinde 40'a ısınıp gürültüyü büyütüyordu) → bekler
(ekran kapalı, en çok 30 dk), hâlâ sıcaksa GEÇERSİZ sayılır.
VERİ (P60): not_ac/kb/yaz ilk OLCUM OLMAYAN kartta ölçülür (adı koşu satırında
`[...]`); önceki koşuların eklediği " deneme yazisi" pencere dışında silinir. Varsayılan kimlikli uygulamaya
dokunulmaz. Her dokunuş grubundan önce `ready()`: ekran açık, kilit yok,
ÖNDEKİ PENCERE ölçüm uygulaması — değilse koşu durur (yanlış uygulamaya
basmamak için). Ölçüm penceresinde uiautomator dökümü yok (semantiği açar);
koordinatlar pencereden ÖNCE bulunur. Bitince ekran kapatılır.
"""
import argparse, csv, datetime, json, statistics, subprocess, sys
from perf import *
from vmsvc import OPKG, VM, events

ACT = f"{OPKG}/dev.kaimau.notlar.MainActivity"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DOCS = os.path.join(ROOT, "docs", "perf")
PHASES = ["acilis", "liste", "menu", "arama", "klasor", "yeni_not", "not_ac",
          "kb", "yaz", "not_kapa", "sabit_ac", "sabit_kay", "sabit_kb"]
METRICS = ["kare", "ui_ms", "layout_ms", "max_ms", "j16"]


class NotReady(RuntimeError):
    pass


def focus():
    return sh("dumpsys window | grep mCurrentFocus")


def ready():
    """Ekran açık + kilit yok + önde ÖLÇÜM uygulaması; değilse durur."""
    wake()
    f = focus()
    if "NotificationShade" in f or "Keyguard" in f:
        wake(); time.sleep(0.6); f = focus()
    for _ in range(3):  # geçiş anında odak kısa süre null olur (2026-11-13, koşu 1B)
        if "mCurrentFocus=null" not in f:
            break
        time.sleep(1.0); f = focus()
    if f"{OPKG}/" not in f:
        raise NotReady("önde ölçüm uygulaması yok: " + f.strip())


def temperature():
    m = re.search(r"temperature: (\d+)", sh("dumpsys battery"))
    return int(m.group(1)) / 10 if m else 0.0


def cool_enough(limit=34.0, wait_s=1800):
    t0 = time.time()
    while temperature() >= limit:
        if time.time() - t0 > wait_s:
            return False
        sh("input keyevent KEYCODE_SLEEP")
        time.sleep(30)
    return True


def install(apk):
    r = subprocess.run([ADB, "install", "-r", apk], capture_output=True,
                       text=True, timeout=300)
    out = (r.stdout + r.stderr).strip()
    if "Success" not in out:
        raise RuntimeError("kurulamadı: " + out[-300:])


def edit_boxes(xml):
    return [tuple(map(int, m.groups())) for m in re.finditer(
        r'class="android\.widget\.EditText"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml)]


def dump():
    """Koordinat bulmak için (ÖLÇÜM PENCERESİ DIŞINDA). Semantik ağacı ilk
    dökümde boş gelebiliyor: dolana dek tekrar."""
    for _ in range(4):
        ready()
        x = ui_dump()
        if len(x) > 3000:
            return x
        time.sleep(1.0)
    return x


class Session:
    def __init__(self):
        self.evs, self.marks = [], []
        self.vm = None

    def cold_start(self):
        sh(f"am force-stop {OPKG}"); time.sleep(1.2)
        wake()
        sh("logcat -c")
        sh(f"am start -n {ACT} --ez start-paused true")
        url = None
        for _ in range(60):
            time.sleep(0.3)
            m = re.search(r"listening on (http://127\.0\.0\.1:(\d+)/\S+)", sh("logcat -d -s flutter:I"))
            if m:
                url, port = m.group(1), m.group(2)
                break
        if not url:
            raise RuntimeError("VM servisi bulunamadı")
        adb("forward", f"tcp:{port}", f"tcp:{port}")
        time.sleep(0.5)
        self.vm = VM(url)
        # Duraklatılmışken uzantılar yok: widgets=None.
        self.window([("acilis", lambda: self.vm.call("resume", isolateId=self.vm.iso), 7.0)], widgets=None)
        t_res = self.marks[-2][1]
        frames = [e for e in self.evs if e[0] == "Animator::BeginFrame" and e[2] >= t_res]
        self.first_frame_ms = round((frames[0][2] - t_res) / 1000) if frames else None
        time.sleep(2.0)

    def window(self, steps, widgets=False):
        """Tek VM zaman çizelgesi penceresi; adım = (evre, eylem, bekleme)."""
        self.vm.start(widgets=widgets)
        self.marks.append(("başla", self.vm.now()))
        for name, act, wait in steps:
            act(); time.sleep(wait)
            self.marks.append((name, self.vm.now()))
        tl, _ = self.vm.stop()
        self.evs.extend(events(tl))

    def stats(self):
        ui = [e for e in self.evs if e[0] == "Animator::BeginFrame"]
        lay = [e for e in self.evs if e[0] == "LAYOUT"]
        out = {}
        for (_, t0), (name, t1) in zip(self.marks, self.marks[1:]):
            if name == "başla":
                continue
            u = [e[3] / 1000 for e in ui if t0 <= e[2] < t1]
            l = sum(e[3] / 1000 for e in lay if t0 <= e[2] < t1)
            g = out.setdefault(name, {k: 0.0 for k in METRICS})
            g["kare"] += len(u); g["ui_ms"] += sum(u); g["layout_ms"] += l
            g["max_ms"] = max(g["max_ms"], max(u, default=0))
            g["j16"] += sum(x > 16 for x in u)
        return {k: {m: round(v, 1) for m, v in d.items()} for k, d in out.items()}


def run_once(label):
    s = Session()
    s.cold_start()
    W, H = (int(v) for v in re.search(r"(\d+)x(\d+)", sh("wm size").splitlines()[-1]).groups())
    x = W // 2

    # Ana ekran koordinatları (pencere DIŞINDA).
    xml = dump()
    search = edit_boxes(xml)[0]
    menus = [n for n in nodes(xml, "^Not menüsü$") if n[2] > 600]
    plus = nodes(xml, "^Yeni not")
    # P60 (2026-11-14): veri yeniden kurulunca ilk kart sabitlenmiş "OLCUM kalem pdf"
    # oldu → not_ac/kb/yaz/not_kapa PDF'li notu ölçtü (~3 kat sıçrama). OLCUM
    # stres notları atlanır; açılan not her koşuda yazılır (veri doğrulaması).
    card_menu, card_title = pick_card(xml, menus)
    card = (card_menu[1] - 170, card_menu[2] + 150)  # ⋮ kartın sağ üstünde; gövdesi sol altta

    ready()
    s.window([(f"liste", lambda d=d: swipe(x, *((int(H * .75), x, int(H * .3)) if d > 0 else (int(H * .3), x, int(H * .75))), 90), 1.1)
              for d in (1, 1, 1, 1, -1, -1, -1, -1)])
    time.sleep(1.0)

    ready()
    s.window([("menu", lambda: tap(card_menu[1], card_menu[2]), 1.4),
              ("menu", lambda: key("KEYCODE_BACK"), 1.0)])

    ready()
    sx, sy = (search[0] + search[2]) // 2, (search[1] + search[3]) // 2
    tap(sx, sy); time.sleep(1.2)
    s.window([("arama", lambda c=c: text(c), 0.5) for c in "olcum"])
    key("KEYCODE_BACK"); time.sleep(0.6)   # klavye
    key("KEYCODE_BACK"); time.sleep(1.2)   # aramayı temizle
    ready()

    s.window([("klasor", lambda: swipe(int(W * .85), int(H * .6), int(W * .15), int(H * .6), 160), 1.6),
              ("klasor", lambda: swipe(int(W * .15), int(H * .6), int(W * .85), int(H * .6), 160), 1.6)])
    time.sleep(0.6)
    # Geri çekiş takvimi açtıysa (Tümü'de sağa çekiş, 2026-11-06) dön.
    if "Takvim" in "".join(n[0] for n in nodes(dump())[:6]):
        key("KEYCODE_BACK"); time.sleep(1.2)
    ready()

    # Yeni not: "Metin notu" düğmesini panel açıkken bul (pencere dışında).
    tap(plus[0][1], plus[0][2]); time.sleep(1.2)
    metin = nodes(dump(), "^Metin notu")
    key("KEYCODE_BACK"); time.sleep(1.0)
    ready()
    s.window([("yeni_not", lambda: tap(plus[0][1], plus[0][2]), 1.0),
              ("yeni_not", lambda: tap(metin[0][1], metin[0][2]), 2.2)])
    for _ in range(2):
        key("KEYCODE_BACK"); time.sleep(0.8)
    time.sleep(1.0)
    ready()

    # Not aç + klavye + yazma + kapanış (ab_klavye).
    s.window([("not_ac", lambda: tap(*card), 2.8)])
    boxes = edit_boxes(dump())
    if len(boxes) < 2:
        raise RuntimeError("gövde alanı bulunamadı")
    body = boxes[1]
    fx, fy = (body[0] + body[2]) // 2, min(body[1] + 60, (body[1] + body[3]) // 2)
    ready()
    tap(fx, fy); time.sleep(2.0)
    trim_typed(fx, fy)
    s.window([("kb", (lambda: key("KEYCODE_BACK")) if i % 2 == 0 else (lambda: tap(fx, fy)),
               1.4 if i % 2 == 0 else 1.6) for i in range(6)])
    key("KEYCODE_MOVE_END")
    s.window([("yaz", lambda: text(" deneme yazisi"), 1.4) for _ in range(4)])
    s.window([("not_kapa", lambda: key("KEYCODE_BACK"), 1.3),
              ("not_kapa", lambda: key("KEYCODE_BACK"), 1.8)])
    time.sleep(0.8)
    ready()

    # Sabit PDF'li not: listede kaydırarak bul (pencere dışında).
    hit = None
    for _ in range(10):
        hit = nodes(dump(), "^OLCUM kalem pdf")
        if hit and 500 < hit[0][2] < H - 400:
            break
        swipe(x, int(H * .75), x, int(H * .35), 300); time.sleep(1.0)
    if not hit:
        raise RuntimeError("'OLCUM kalem pdf' bulunamadı (HAZIRLIK)")
    ready()
    s.window([("sabit_ac", lambda: tap(hit[0][1], hit[0][2]), 2.8)])
    xml = dump()
    # Bölme: başlık alanının altından ek çubuğunun ("Tam ekran") üstüne
    # ("Sayfa 1 / 1" etiketi her zaman gelmiyor).
    bar = nodes(xml, "^Tam ekran$")
    boxes = edit_boxes(xml)
    body = boxes[1] if len(boxes) > 1 else None
    if not bar or not body:
        raise RuntimeError("sabit bölme / gövde bulunamadı")
    top, bot, px = boxes[0][3], bar[0][3][1], W // 2
    ready()
    s.window([("sabit_kay", lambda: swipe(px, int(bot - (bot - top) * .2), px, int(top + (bot - top) * .2), 200), 0.9)
              for _ in range(3)])
    bx, by = (body[0] + body[2]) // 2, min(body[1] + 60, (body[1] + body[3]) // 2)
    tap(bx, by); time.sleep(2.0)
    s.window([("sabit_kb", (lambda: key("KEYCODE_BACK")) if i % 2 == 0 else (lambda: tap(bx, by)),
               1.4 if i % 2 == 0 else 1.6) for i in range(4)])
    key("KEYCODE_BACK"); time.sleep(0.8)
    key("KEYCODE_BACK"); time.sleep(1.5)
    ready()
    # Listeyi başa al (sonraki koşu aynı yerden başlasın).
    for _ in range(6):
        swipe(x, int(H * .3), x, int(H * .85), 120); time.sleep(0.3)

    st = s.stats()
    st["acilis"]["ilk_kare_ms"] = s.first_frame_ms or 0
    st["_not"] = card_title
    return st


def pick_card(xml, menus):
    """İlk OLCUM olmayan kartın ⋮ düğmesi + kart başlığı."""
    labels = [n for n in nodes(xml) if n[0] and n[0] != "Not menüsü"]
    for m in menus:
        own = [n for n in labels if n[3][0] <= m[1] <= n[3][2] and n[3][1] <= m[2] <= n[3][3]]
        title = own[0][0] if own else ""
        if not title.startswith("OLCUM"):
            return m, title[:40]
    raise RuntimeError("OLCUM olmayan kart yok (veri seti?)")


YAZI = " deneme yazisi"


def trim_typed(fx, fy):
    """Önceki koşuların `yaz` evresinde eklenen metni (pencere DIŞINDA) siler:
    yoksa ölçülen not her koşuda 56 karakter büyür (P60, kayma kaynağı)."""
    boxes = [m for m in re.finditer(r'text="([^"]*)"[^>]*?class="android\.widget\.EditText"', ui_dump())]
    if len(boxes) < 2:
        return
    body, n = boxes[1].group(1), 0
    while body.endswith(YAZI) and n < 40:
        body, n = body[:-len(YAZI)], n + 1
    if n:
        key("KEYCODE_MOVE_END")
        for i in range(0, n * len(YAZI), 50):
            sh("input keyevent " + " ".join(["67"] * min(50, n * len(YAZI) - i)))
        time.sleep(3.5)  # kEditorSaveDelay 2 sn: kayıt kb penceresine taşmasın


def median_of(runs):
    out = {}
    for ph in PHASES:
        vals = [r[ph] for r in runs if ph in r]
        if vals:
            out[ph] = {m: round(statistics.median(v[m] for v in vals), 1) for m in vals[0]}
    return out


def worst_of(runs):
    out = {}
    for ph in PHASES:
        vals = [r[ph] for r in runs if ph in r]
        if vals:
            out[ph] = {m: max(v[m] for v in vals) for m in vals[0]}
    return out


# Kullanıcı kararı 2026-11-13: `yaz` LAYOUT oturumlar arası 302–377 ms oynuyor (aynı APK
# A=A'da altına karşı +%16) → gürültü payı. Diğer evreler %15.
ALTIN_PAY = {("yaz", "layout_ms"): 0.25}


def decide(a_runs, b_runs, golden=None):
    """F81.2 kuralı (+ --altin). Dönüş: (tablo satırları, kaldı mı)."""
    am, bm, aw = median_of(a_runs), median_of(b_runs), worst_of(a_runs)
    rows, failed = [], False
    for ph in PHASES:
        if ph not in am or ph not in bm:
            continue
        verdict = "aynı/iyi"
        # ponytail: açılışta UI ms anlamsız (duraklatılmış başlangıç 2 kare yakalıyor) → ilk kare ms.
        ms = ("ilk_kare_ms",) if ph == "acilis" else ("ui_ms", "layout_ms")
        for m in ms:
            a, b, w = am[ph][m], bm[ph][m], aw[ph][m]
            if b > w and b - a > 3 and b > a * 1.20:
                verdict = f"KÖTÜLEŞTİ ({m})"
                failed = True
        g = ""
        if golden and ph in golden:
            for m in ms:
                gv = golden[ph].get(m, 0)
                if gv > 3 and bm[ph][m] > gv * (1 + ALTIN_PAY.get((ph, m), 0.15)):
                    g = f"altın +{(bm[ph][m] / gv - 1) * 100:.0f}% ({m})"
                    failed = True
            g = g or "altın içinde"
        rows.append((ph, am[ph], bm[ph], verdict, g))
    return rows, failed


def record(path, commit, label, med, temp):
    new = not os.path.exists(path)
    with open(path, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        if new:
            w.writerow(["tarih", "commit", "etiket", "evre", "ui_ms", "layout_ms", "kare", "sicaklik"])
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        for ph, v in med.items():
            w.writerow([now, commit, label, ph, v["ui_ms"], v["layout_ms"], int(v["kare"]), temp])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("a"); ap.add_argument("b")
    ap.add_argument("--kosu", type=int, default=3)
    ap.add_argument("--teyit", type=int, default=2)
    ap.add_argument("--altin", action="store_true")
    ap.add_argument("--altin-yaz", action="store_true")
    ap.add_argument("--etiket-a", default=None); ap.add_argument("--etiket-b", default=None)
    ap.add_argument("--commit", default="?")
    o = ap.parse_args()
    la = o.etiket_a or os.path.splitext(os.path.basename(o.a))[0]
    lb = o.etiket_b or os.path.splitext(os.path.basename(o.b))[0]
    os.makedirs(DOCS, exist_ok=True)
    runs = {"A": [], "B": []}
    temps = []
    golden_path = os.path.join(DOCS, "altin_taban.json")
    golden = json.load(open(golden_path, encoding="utf-8"))["evreler"] if os.path.exists(golden_path) else None

    def pairs(first, count):
        for i in range(first, first + count):
            for side, apk in (("A", o.a), ("B", o.b)):
                if not cool_enough():
                    print(f"koşu {i + 1}{side}: SICAK ({temperature()} °C) — GEÇERSİZ", flush=True)
                    continue
                temps.append(temperature())
                install(apk)
                try:
                    st = run_once(side)
                except NotReady as e:
                    print(f"koşu {i + 1}{side}: DURDU — {e}", flush=True)
                    raise
                note = st.pop("_not", "")
                runs[side].append(st)
                print(f"koşu {i + 1}{side} ({temps[-1]} °C) [{note}]: " + json.dumps(
                    {k: v["ui_ms"] for k, v in st.items()}, ensure_ascii=False), flush=True)
                json.dump(runs, open(os.path.join(OUT, "ab_hepsi_ham.json"), "w"), ensure_ascii=False)

    try:
        pairs(0, o.kosu)
        rows, failed = (decide(runs["A"], runs["B"], golden if o.altin else None)
                        if runs["A"] and runs["B"] else ([], True))
        # P60 TEYİT (2026-11-14): son 3 turda her seferinde FARKLI tek evre %20'yi az aştı
        # (menu, ilk kare, yeni_not) = gürültü. KALDI ise O.TEYIT çift daha koşulur ve
        # karar TÜM koşularla yeniden verilir; kalıcı kötüleşme yine yakalanır.
        if failed and o.teyit and runs["A"] and runs["B"]:
            bad = [f"{ph}: {v} {g}".strip() for ph, _, _, v, g in rows if v != "aynı/iyi" or "+" in g]
            print(f"teyit: {o.teyit} çift daha (karar tüm koşularla yeniden) — ilk karar: {'; '.join(bad)}", flush=True)
            pairs(o.kosu, o.teyit)
            rows, failed = decide(runs["A"], runs["B"], golden if o.altin else None)
    finally:
        sh("input keyevent KEYCODE_SLEEP")
    if not runs["A"] or not runs["B"]:
        print("KARAR: KALDI (ölçülemedi)")
        sys.exit(2)
    print(f"\n| evre | A UI ms | B UI ms | A LAYOUT | B LAYOUT | A kare | B kare | B en uzun | B >16 | karar | altın |")
    print("|---|---|---|---|---|---|---|---|---|---|---|")
    for ph, a, b, v, g in rows:
        print(f"| {ph} | {a['ui_ms']} | {b['ui_ms']} | {a['layout_ms']} | {b['layout_ms']} | "
              f"{a['kare']:.0f} | {b['kare']:.0f} | {b['max_ms']} | {b['j16']:.0f} | {v} | {g} |")
    am = median_of(runs["A"])
    print(f"\nilk kare (ms, ortanca): A {am['acilis'].get('ilk_kare_ms')} / B {median_of(runs['B'])['acilis'].get('ilk_kare_ms')}")
    t = round(statistics.median(temps), 1) if temps else ""
    record(os.path.join(DOCS, "gecmis.csv"), o.commit, la, am, t)
    record(os.path.join(DOCS, "gecmis.csv"), o.commit, lb, median_of(runs["B"]), t)
    src = runs["A"] + (runs["B"] if o.a == o.b else [])
    if o.altin_yaz and len(src) < 5:
        print(f"altın taban YAZILMADI: {len(src)} koşu < 5")
    elif o.altin_yaz:
        g = golden or {}
        for ph, v in median_of(src).items():
            if ph not in g or (v["ui_ms"] <= g[ph]["ui_ms"] and v["layout_ms"] <= g[ph]["layout_ms"]):
                g[ph] = v
        json.dump({"_kural": "Altın taban (HIZ_PLANI F81.4): yalnız İYİLEŞEN evre güncellenir. "
                   "B bir evrede %15'ten fazla kötüyse KALDI.",
                   "etiket": la, "tarih": datetime.date.today().isoformat(), "evreler": g},
                  open(golden_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("altın taban yazıldı:", golden_path)
    print("KARAR: " + ("KALDI" if failed else "GEÇTİ"))


if __name__ == "__main__":
    main()
