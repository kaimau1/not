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
  sablon     (P63) "+" → Şablonlar levhası aç → "Planlama" çipi → kapat
  bicim      (P63) "OLCUM cizgi" notunda madde → Biçim → çizgi tepsisi aç/kapa
             ×3 → tür seç ×3 (düz/kesikli/aynı tür = kaldır)
  kalem      (P63 G4) ilk OLCUM olmayan notta "Kalemle yaz" → 10 parmak çizgisi
             → kapsül aç (hap) / geri ×3 → kalem kipinden çık (çizgiler geri al)
  duzen      (P63 G5) ilk OLCUM olmayan notta ⋮ → "Ekranı düzenle" → alt
             çubukta 3 öğe gizle + geri göster (6 dokunuş, net değişiklik
             yok) → Bitti
P63 evreleri eskilerin SONUNDA (eski evrelerin sayıları kaymasın); hazırlık
yoksa (şablon düğmesi / "OLCUM cizgi" notu bulunamazsa) evre atlanır, koşu
düşmez.

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
"OLCUM cizgi" yoksa betik koşulardan önce bu yedeği KENDİSİ yükler
(`ensure_cizgi`; geri yükleme birleştirir, var olan notlar atlanır).

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
          "kb", "yaz", "not_kapa", "sabit_ac", "sabit_kay", "sabit_kb",
          "sablon", "bicim", "kalem", "duzen"]
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
        # 2026-11-15: açılış penceresi P60'tan beri yalnız 2 boş kare (~0,4 ms, LAYOUT 0)
        # yakalıyordu; 11-04 prof_cold.pkl aynı yöntemle 18 kare + 88 BUILD vermişti.
        # Erken olaylar kalıp sonrakiler düşüyor = VM'in sabit boy zaman çizelgesi
        # tamponu açılış seli ile doluyor (varsayım, cihazda doğrulanmadı). Sonsuz
        # tampon (motor bayrağı, FlutterShellArgs) olay düşürmez; pencereler
        # clearVMTimeline ile temizlendiğinden bellek büyümez.
        sh(f"am start -n {ACT} --ez start-paused true --ez endless-trace-buffer true")
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
        if len(frames) < 5:  # tanı: kayıt mı durdu, uygulama mı boşta?
            names = {}
            for e in self.evs:
                names[e[0]] = names.get(e[0], 0) + 1
            last = max((e[2] + e[3] for e in self.evs), default=t_res)
            top = sorted(names.items(), key=lambda kv: -kv[1])[:6]
            print(f"açılış tanı: {len(frames)} kare, {len(self.evs)} olay, son olay "
                  f"+{(last - t_res) / 1000:.0f} ms, en sık {top}", flush=True)
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
    W, H = screen_size()
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
    list_top(W, H)  # sonraki koşu aynı yerden başlasın

    for phase in (phase_sablon, phase_bicim, phase_kalem, phase_duzen):
        try:
            phase(s, W, H, plus)
        except (RuntimeError, IndexError) as e:
            if isinstance(e, NotReady):
                raise
            print(f"evre atlandı ({phase.__name__}): {e}", flush=True)
            # 2026-11-15: evre kendi BACK'lerini bastı; fazladan BACK uygulamadan
            # çıkarıp koşuyu düşürüyordu. Hazır değilse kalan evreler atlanır.
            try:
                ready()
            except NotReady:
                break
            # run_g3 (2026-11-15): bicim "OLCUM cizgi"yi ararken listeyi 12 kez
            # aşağı kaydırıp düştü; kalem dipteki OLCUM stres kartlarını görüp
            # "OLCUM olmayan kart yok" verdi. Düşen evre listeyi başa alır.
            list_top(W, H)

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
    yoksa ölçülen not her koşuda 56 karakter büyür (P60, kayma kaynağı).
    Liste notunda madde metni EditText'te değil, üstündeki View'in content-desc'inde
    gelir ve sarılan maddede MOVE_END yalnız ilk satır sonuna gider (ek ortaya
    girer): maddenin SON satırına basılır, 'deneme'den sonrası silinir; rapor
    edilen metin kısa (kesik) gelirse tur tekrarlanır. Madde boş kalırsa 'Kitap'."""
    deleted = False
    for _ in range(6):
        best = None
        for m in re.finditer(r'<node [^>]*>', ui_dump()):
            nd = m.group(0)
            b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', nd)
            if not b:
                continue
            x0, y0, x1, y1 = map(int, b.groups())
            if not (x0 <= fx <= x1 and y0 <= fy <= y1):
                continue
            for attr in ("text", "content-desc"):
                t = re.search(attr + r'="([^"]*)"', nd)
                if t and (best is None or len(t.group(1)) > len(best[0])):
                    best = (t.group(1), (x0, y0, x1, y1))
        junk = re.search(r"deneme|yazisi", best[0], re.I) if best else None
        if not junk:
            break
        t, (x0, y0, x1, y1) = best
        keep = t[:junk.start()].rstrip()
        n = len(t) - len(keep)
        tap(x1 - 20, y1 - 20); time.sleep(0.6)
        key("KEYCODE_MOVE_END")
        for i in range(0, n, 50):
            sh("input keyevent " + " ".join(["67"] * min(50, n - i)))
        deleted = True
        time.sleep(1.0)
    if deleted and (not best or not best[0].strip()):
        tap(fx, fy); time.sleep(0.6)
        key("KEYCODE_MOVE_END"); text("Kitap"); time.sleep(0.6)
    if deleted:
        tap(fx, fy)
        time.sleep(3.5)  # kEditorSaveDelay 2 sn: kayıt kb penceresine taşmasın


def list_top(W, H):
    """Ana ekran listesini başa al."""
    for _ in range(6):
        swipe(W // 2, int(H * .3), W // 2, int(H * .85), 120); time.sleep(0.3)


TPL = "^(Şablondan|From template)"  # l10n fromTemplate (add_catalog.dart)


def phase_sablon(s, W, H, plus):
    """P63: "+" → Şablonlar → levha → Planlama çipi → kapat (koordinatlar
    pencere dışında bulunur)."""
    # Kök neden (run_g2/g3/g4 "'+' menüsünde Şablondan yok"): panel
    # `SingleChildScrollView(reverse: true)` (quick_add_fab.dart) ve gruplar
    # TERSTEN dizili → Şablon grubu panelin en ÜSTÜNDE, telefonda ekranın üstünde
    # kalıyor; uiautomator görünmeyeni dökmüyor. Eski kaydırma "Metin notu"na
    # doğru ~90 px çekiyordu (yetmez). Başa çıkmak için parmak panelin üst
    # kısmından AŞAĞI uzun çekilir (taşan panel ekranı doldurur → H*0,2 içinde);
    # tavanda durur, iki kez çekmek zararsız. Ölçüm penceresi aynı yolu izler.
    tap(plus[0][1], plus[0][2]); time.sleep(1.2)
    xml = dump()
    tpl = nodes(xml, TPL)
    roll = None
    if not tpl:
        top = nodes(xml, "^Metin notu")
        if top:
            px = top[0][1]
            roll = (px, int(H * .2), px, max(int(H * .2) + 200, top[0][2] - 150), 400)
            for _ in range(2):
                swipe(*roll); time.sleep(0.8)
            tpl = nodes(dump(), TPL)
    if not tpl:
        key("KEYCODE_BACK"); time.sleep(1.0)
        raise RuntimeError("'+' menüsünde Şablondan yok (kaydırınca da)")
    tap(tpl[0][1], tpl[0][2]); time.sleep(1.8)
    chip = nodes(dump(), "^Planlama")
    key("KEYCODE_BACK"); time.sleep(1.0)
    key("KEYCODE_BACK"); time.sleep(1.0)
    if not chip:
        raise RuntimeError("şablon levhasında 'Planlama' çipi yok")
    ready()
    s.window([("sablon", lambda: tap(plus[0][1], plus[0][2]), 1.0)]
             + ([("sablon", lambda: swipe(*roll), 0.8)] * 2 if roll else [])
             + [("sablon", lambda: tap(tpl[0][1], tpl[0][2]), 1.8),
              ("sablon", lambda: tap(chip[0][1], chip[0][2]), 1.2),
              ("sablon", lambda: key("KEYCODE_BACK"), 1.2)])
    time.sleep(0.6)
    ready()


def phase_bicim(s, W, H, plus):
    """P63: çizgili listede madde → Biçim → çizgi tepsisi aç/kapa ×3 → tür
    seç ×3. Tepsi düğmelerinin erişilebilirlik adları çeviriden gelir."""
    hit = find_in_list("^OLCUM cizgi", W, H)
    if not hit:
        raise RuntimeError("'OLCUM cizgi' bulunamadı (hazırlık başarısız? koşu başındaki 'hazırlık:' satırı)")
    tap(hit[0][1], hit[0][2]); time.sleep(2.5)
    boxes = edit_boxes(dump())
    if len(boxes) < 3:
        raise RuntimeError("çizgili listede madde alanı yok")
    it = boxes[2]
    tap((it[0] + it[2]) // 2, (it[1] + it[3]) // 2); time.sleep(1.6)
    fmt = nodes(dump(), "^Biçim$")
    if not fmt:
        raise RuntimeError("Biçim düğmesi yok")
    tap(fmt[0][1], fmt[0][2]); time.sleep(1.2)
    menu = nodes(dump(), "^Alt çizgi$")
    if not menu:
        raise RuntimeError("çizgi tepsisi düğmesi yok")
    mx, my = menu[-1][1], menu[-1][2]
    tap(mx, my); time.sleep(1.0)
    xml = dump()
    solid = nodes(xml, "^(Düz|Alta çizgi çek)$")
    dashed = nodes(xml, "^(Kesikli|Alta kesikli çizgi)$")
    tap(mx, my); time.sleep(1.0)
    if not solid or not dashed:
        raise RuntimeError("tepside tür hücreleri yok")
    ready()
    s.window([("bicim", lambda: tap(mx, my), 1.0) for _ in range(6)]
             + [("bicim", lambda: tap(mx, my), 1.0),
                ("bicim", lambda: tap(solid[0][1], solid[0][2]), 1.0),
                ("bicim", lambda: tap(dashed[0][1], dashed[0][2]), 1.0),
                ("bicim", lambda: tap(dashed[0][1], dashed[0][2]), 1.0),
                ("bicim", lambda: tap(mx, my), 1.0)])
    for _ in range(3):
        key("KEYCODE_BACK"); time.sleep(0.8)
    time.sleep(1.0)
    ready()
    list_top(W, H)


def phase_kalem(s, W, H, plus):
    """P63 G4: kalem kipi aç → 10 çizgi → kapsül aç/kapa ×3 (geri tuşu kapsülü
    hapa indirir). Çizgiler sonra geri alınır (not büyümesin); "Kalemle yaz"
    alt çubukta, hap düğmesi ("Kalem tepsisini aç") çizimden sonra bulunur."""
    xml = dump()
    menus = [n for n in nodes(xml, "^Not menüsü$") if n[2] > 600]
    m, _ = pick_card(xml, menus)
    tap(m[1] - 170, m[2] + 150); time.sleep(2.5)
    pen = nodes(dump(), "^Kalemle yaz")
    if not pen:
        key("KEYCODE_BACK"); time.sleep(1.0)
        raise RuntimeError("'Kalemle yaz' düğmesi yok")
    x0, x1 = int(W * .2), int(W * .8)
    ready()
    s.window([("kalem", lambda: tap(pen[0][1], pen[0][2]), 1.5)]
             + [("kalem", lambda i=i: swipe(x0, int(H * .3) + i * 40, x1, int(H * .32) + i * 40, 200), 0.6)
                for i in range(10)])
    time.sleep(7.0)  # çekmece 6 sn sonra hapa iner
    peek = nodes(dump(), "^Kalem tepsisini aç")
    if not peek:
        for _ in range(3):
            key("KEYCODE_BACK"); time.sleep(0.8)
        raise RuntimeError("kalem hapı yok")
    ready()
    s.window([w for _ in range(3) for w in (
        ("kalem", lambda: tap(peek[0][1], peek[0][2]), 1.2),
        ("kalem", lambda: key("KEYCODE_BACK"), 1.2))])
    # Çizgileri kapsülün geri al'ı ile sil (en alttaki "Geri al" = kapsül).
    tap(peek[0][1], peek[0][2]); time.sleep(1.2)
    undo = sorted(nodes(dump(), "^Geri al$"), key=lambda n: n[2])
    if undo and undo[-1][2] > H * .7:
        for _ in range(10):
            tap(undo[-1][1], undo[-1][2]); time.sleep(0.3)
    key("KEYCODE_BACK"); time.sleep(1.0)   # kapsül
    key("KEYCODE_BACK"); time.sleep(1.0)   # kalem kipi
    key("KEYCODE_BACK"); time.sleep(1.8)   # not
    ready()


def find_in_list(pat, W, H, tries=12):
    """Ana ekran listesinde kaydırarak kart ara (listeyi baştan tarar)."""
    for _ in range(tries):
        hit = nodes(dump(), pat)
        if hit and 500 < hit[0][2] < H - 400:
            return hit
        swipe(W // 2, int(H * .75), W // 2, int(H * .35), 300); time.sleep(1.0)
    return None


def ensure_cizgi(apk):
    """HAZIRLIK otomatik (2026-11-15, run_g3 "'OLCUM cizgi' bulunamadı"): telefon
    verisi "OLCUM cizgi" notu (PBT 6, `make_dataset.py --ink`) eklenmeden ÖNCEKİ
    yedekten kurulmuştu. Not yoksa yedek üretilir, Download'a itilir ve
    Ayarlar → Senkronizasyon → "Yedekten geri yükle" ile yüklenir. Geri yükleme
    BİRLEŞTİRİR (backup_service.restore: aynı kimlik / `restoredFrom` / özet
    atlanır) → yalnız eksik OLCUM notları eklenir, var olan veri değişmez.
    Koşulardan ÖNCE bir kez; başarısızsa bicim evresi eskisi gibi atlanır."""
    import make_dataset
    install(apk)
    sh(f"am force-stop {OPKG}"); time.sleep(1.0)
    wake()
    sh(f"am start -n {ACT}"); time.sleep(5.0)
    W, H = screen_size()
    try:
        ready()
        if find_in_list("^OLCUM cizgi", W, H):
            return True
        name = "olcum_kalem.notyedek"
        make_dataset.main_ink(40)
        adb("push", os.path.join(os.path.dirname(make_dataset.OUT), name), "/sdcard/Download/" + name)
        sh(f"am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/{name}")
        list_top(W, H)
        open_import(name, button="^Yedekten geri yükle$")
        for _ in range(30):  # "Geri yükleniyor" iletişim kutusu → "N not geri yüklendi"
            time.sleep(3)
            if not find("Geri yükleniyor"):
                break
        for _ in range(4):  # ayarlardan ana ekrana (uygulamadan çıkmadan)
            if nodes(dump(), "^Not menüsü$"):
                break
            key("KEYCODE_BACK"); time.sleep(1.2)
        ok = bool(find_in_list("^OLCUM cizgi", W, H))
        print(f"hazırlık: 'OLCUM cizgi' {'eklendi' if ok else 'EKLENEMEDİ (bicim atlanacak)'}", flush=True)
        return ok
    except (RuntimeError, IndexError) as e:
        print(f"hazırlık atlandı: {e}", flush=True)
        return False
    finally:
        sh(f"am force-stop {OPKG}")


def phase_duzen(s, W, H, plus):
    """P63 G5: not ⋮ ("Not menüsü", üstte) → "Ekranı düzenle" → alt çubuktaki
    ilk 3 çerçeveye (anlam adı "Gizle") ikişer kez dokun → "Bitti". Kayıt
    değişmez (gizle + göster)."""
    xml = dump()
    menus = [n for n in nodes(xml, "^Not menüsü$") if n[2] > 600]
    m, _ = pick_card(xml, menus)
    tap(m[1] - 170, m[2] + 150); time.sleep(2.5)
    more = [n for n in nodes(dump(), "^Not menüsü$") if n[2] < H * .2]
    if not more:
        key("KEYCODE_BACK"); time.sleep(1.0)
        raise RuntimeError("not ⋮ yok")
    tap(more[0][1], more[0][2]); time.sleep(1.2)
    item = nodes(dump(), "^Ekranı düzenle")
    if not item:
        swipe(W // 2, int(H * .85), W // 2, int(H * .45), 300); time.sleep(0.8)
        item = nodes(dump(), "^Ekranı düzenle")
    if not item:
        key("KEYCODE_BACK"); time.sleep(0.8)
        key("KEYCODE_BACK"); time.sleep(1.0)
        raise RuntimeError("'Ekranı düzenle' yok")
    tap(item[0][1], item[0][2]); time.sleep(1.5)
    xml = dump()
    frames = sorted([n for n in nodes(xml, "^Gizle") if n[2] > H * .8],
                    key=lambda n: n[1])[:3]
    done = nodes(xml, "^Bitti$")
    if len(frames) < 3 or not done:
        if done:
            tap(done[0][1], done[0][2]); time.sleep(1.0)
        key("KEYCODE_BACK"); time.sleep(1.5)
        raise RuntimeError("düzen modu çerçeveleri yok")
    # Mod açılışı pencere dışında (menü levhası kapanışıyla karışmasın);
    # ölçülen: 6 dokunuş + Bitti (şeridin çıkışı).
    ready()
    s.window([("duzen", lambda f=f: tap(f[1], f[2]), 0.8)
              for f in frames for _ in range(2)]
             + [("duzen", lambda: tap(done[0][1], done[0][2]), 1.5)])
    key("KEYCODE_BACK"); time.sleep(1.8)   # not
    ready()


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
        if cool_enough():
            ensure_cizgi(o.a)
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
