"""TAM HIZ ÖLÇÜMÜ + OTOMATİK KARAR (HIZ_PLANI F81.1–F81.4).

  python -u ab_hepsi.py <A.apk> <B.apk> [--kosu 3] [--teyit 2] [--altin] [--altin-yaz]
                        [--etiket-a X] [--etiket-b Y] [--commit SHA] [--yon yatay|dikey|mevcut]

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

TABLET (T13/T1, 2026-11-18; PLAN §1.0: tablet tabanı telefonla karşılaştırılmaz): cihazın kısa kenarı
>= 1400 px ise tablet sayılır → kayıt `gecmis_tablet.csv`, altın taban `altin_taban_tablet.json`.
Tablet kendi düzeninde ölçülür: profil APK'sı manifestte DİKEY kilitli → 640x1024 dp, sol ray + 2 sütun
liste; yatay/bölünmüş için APK'yı `NOTLAR_OLCUM_YON=landscape` ile derle (TP-F; `--yon yatay`
dikey kilitli APK'yı görünce durur). `--yon` ekranı ölçüm süresince döndürür
(`wm user-rotation lock`, bitince `free`); varsayılan tablette `dikey`, telefonda `mevcut`. Ekran boyutu DÖNDÜRÜLMÜŞ ekrandan okunur (`perf.screen_size`).

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


def is_tablet():
    """Fiziksel kısa kenar >= 1400 px (MatePad 11 1600; Mi Note 10 Lite 1080)."""
    w, h = (int(v) for v in re.search(r"(\d+)x(\d+)", sh("wm size").splitlines()[-1]).groups())
    return min(w, h) >= 1400


def cool_enough(limit=34.0, wait_s=1800):
    t0 = time.time()
    while temperature() >= limit:
        if time.time() - t0 > wait_s:
            return False
        sh("input keyevent KEYCODE_SLEEP")
        time.sleep(30)
    return True


def _confirm_installer(stop, marker="Ölçüm"):
    """HUAWEI/Honor (HarmonyOS) `adb install` iki onay penceresi çıkarır ("DEVAM ET" uyarısı,
    sonra "YÜKLE"; T13, MatePad 11, 2026-11-18). Onay YALNIZ ölçüm uygulamasının kendi kurulumu
    için ("Notlar Ölçüm" yazan pencere) ve yalnız paket yükleyici önde iken verilir; başka bir
    pencereye dokunulmaz. Telefonda (Xiaomi, USB yükleme izni açık) pencere hiç çıkmaz."""
    last = 0.0
    while not stop.is_set():
        time.sleep(1.2)
        if "packageinstaller" not in focus():
            continue
        wake()
        xml = ui_dump()
        if marker not in xml and not nodes(xml, "^DEVAM ET$"):
            continue
        for pat in ("^DEVAM ET$", "^YÜKLE$"):
            hit = nodes(xml, pat)
            if hit and time.time() - last > 1.5:
                tap(hit[0][1], hit[0][2]); last = time.time()
                break


def install(apk, marker="Ölçüm"):
    import threading
    wake()   # ekran kapalıyken kurulum pencereleri görünmez → adb install 300 sn asılıyordu (2026-11-18)
    stop = threading.Event()
    th = threading.Thread(target=_confirm_installer, args=(stop, marker), daemon=True)
    th.start()
    try:
        r = subprocess.run([ADB, "install", "-r", apk], capture_output=True,
                           text=True, timeout=300)
    finally:
        stop.set(); th.join(timeout=5)
    for _ in range(6):   # "Yükleme başarılı" ekranı (BİTTİ/AÇ) uygulamanın önünde kalır → kapat
        if "packageinstaller" not in focus():
            break
        hit = nodes(ui_dump(), "^BİTTİ$")
        if hit:
            tap(hit[0][1], hit[0][2]); time.sleep(0.8)
            break
        time.sleep(1.0)
    out = (r.stdout + r.stderr).strip()
    if "Success" not in out:
        raise RuntimeError("kurulamadı: " + out[-300:])


def edit_boxes(xml):
    return [tuple(map(int, m.groups())) for m in re.finditer(
        r'class="android\.widget\.EditText"[^>]*?bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', xml)]


def labels_in(x):
    return len(re.findall(r'(?:text|content-desc)="[^"]+"', x))


def dump(allow_empty=False):
    """Koordinat bulmak için (ÖLÇÜM PENCERESİ DIŞINDA). Semantik ağacı ilk
    dökümde boş gelebiliyor: dolana dek tekrar. 2026-11-18 (tablet): boş ağaç da 3,4 KB tuttuğundan
    boyut değil ETİKETLİ düğüm sayısına bakılır; tablet ana ekranı doğası gereği boş
    ([allow_empty]: beklemeden döner)."""
    for _ in range(4):
        ready()
        x = ui_dump()
        if labels_in(x) >= 3 or (allow_empty and len(x) > 3000):
            return x
        time.sleep(1.0)
    return x


def ime_shown():
    return "mInputShown=true" in sh("dumpsys input_method | grep mInputShown")


def _in_editor(xml):
    """Editör içi mi (ana ekranda yalnız 1 EditText = arama kutusu var)."""
    return len(edit_boxes(xml)) >= 2 or bool(nodes(xml, r"^(Notta ara|Search in note)$"))


def kb_show_button(xml):
    """Fiziksel klavye algılanan cihazda (tablet) sanal klavyeyi açan ⌨ düğmesi."""
    n = nodes(xml, r"^(Sanal klavyeyi aç|Show on-screen keyboard)")
    return (n[0][1], n[0][2]) if n else None


def kb_hide_button(xml):
    """Sanal klavye açık/istenir iken görünen kapatma ⌨ düğmesi."""
    n = nodes(xml, r"^(Sanal klavyeyi kapat|Hide on-screen keyboard)")
    return (n[0][1], n[0][2]) if n else None


def kb_button(xml):
    """Fiziksel klavye algılanan cihazda (tablet) sanal klavye ⌨ düğmesi (aç ya da kapat);
    telefonda yok → None (alana dokunmak yeter)."""
    return kb_show_button(xml) or kb_hide_button(xml)


def _wait_ime(checks=5):
    for _ in range(checks):
        time.sleep(0.5)
        if ime_shown():
            time.sleep(0.8)
            return True
    return False


def ensure_ime(kb_xy, field=None):
    """Klavyeyi AÇIK getir (ölçüm penceresi dışında). Bayat `kb_xy` hiçbir zaman
    tıklanmaz; düğme adı (`aç` / `kapat`) taze dökümden okunur. Editör kapalıysa
    hemen açık hata verir. Telefonda (`kb_xy` yok) çağrı etkisiz."""
    if not kb_xy:
        return
    for attempt in range(4):
        if ime_shown():
            return
        xml = dump(allow_empty=True)
        in_ed = _in_editor(xml)
        show_xy = kb_show_button(xml)
        hide_xy = kb_hide_button(xml)
        print(f"  ensure_ime[{attempt}]: ime={ime_shown()} in_ed={in_ed} show={show_xy} hide={hide_xy}", flush=True)
        if not in_ed:
            top = [(n[0][:24], n[1], n[2]) for n in nodes(xml) if n[0]][:8]
            print(f"  ensure_ime düğümler: {top}", flush=True)
            shot("ime_acilmadi", 0.3)
            raise RuntimeError(
                "sanal klavye açılmadı: editör kapalı / ana ekrana dönülmüş "
                "(ekran: PERF_OUT/ime_acilmadi.png)")
        if show_xy:
            tap(*show_xy)
            if _wait_ime(5):
                return
            if field:
                tap(*field)
                if _wait_ime(4):
                    return
        elif hide_xy:
            if field:
                tap(*field)
                if _wait_ime(4):
                    return
            tap(*hide_xy); time.sleep(0.6)
            show_xy = kb_show_button(dump(allow_empty=True))
            if show_xy:
                tap(*show_xy); time.sleep(0.6)
                if _wait_ime(4):
                    return
            if field:
                tap(*field)
                if _wait_ime(4):
                    return
        elif field:
            tap(*field)
            if _wait_ime(4):
                return
    if not ime_shown():
        shot("ime_acilmadi", 0.3)
        raise RuntimeError("sanal klavye açılmadı (⌨ + alan dokunuşu ×4; ekran: PERF_OUT/ime_acilmadi.png)")


def back_note():
    """Notu kapat. Klavye açıksa ilk BACK onu kapatır; tablet fiziksel klavye algılayıp sanal
    klavyeyi açmadığından 2. BACK koşulsuz basılırsa uygulamadan çıkar (T13)."""
    if ime_shown():
        key("KEYCODE_BACK"); time.sleep(0.8)
    key("KEYCODE_BACK"); time.sleep(0.8)


# TABLET ANA EKRANI (T13, 2026-11-18). UiAutomation geçici bağlanır (~1 sn); Flutter, boşta bir uygulamada
# ana ekranın semantik ağacını o pencerede göndermiyor: tablet ana ekranı (ray + liste) dökümde BOŞ
# (3,4 KB, yalnız kök View'ler); levhalar, editör, ayarlar DOLU. Telefon düzeninde (wm size 1080x2400) ağaç
# dolu. Bu yüzden tablet ANA EKRAN tıklamaları 1600 px genişlikteki (MatePad 11 dikey, 400 dpi) piksel
# tablosundan gelir; arayüz değişince yeniden ölçülür. Her tablo noktası ARDINDAN dolu semantiğe sahip bir
# ekranla (levha/editör) doğrulanır; tutmazsa evre/koşu açık hata verir. Varsayım: "Notların
# yedeklenmiyor" bandı küçültülmüş ("Sonra", kalıcı) ve ilk kart sabit not.
GEO_1600 = {"search": (360, 132), "clear": (1063, 132), "plus": (84, 600), "menu": (814, 658),
            "hit": (533, 750)}


def home_locate(W, H):
    """Ana ekran koordinatları: semantik (telefon) ya da tablet tablosu. Dönüş sözlüğü:
    search (x,y), clear (x,y)|None, plus [node], card_menu node, title, geo bool, hit (x,y)|None."""
    xml = dump(allow_empty=True)
    boxes = edit_boxes(xml)
    if boxes:
        menus = [n for n in nodes(xml, "^Not menüsü$") if n[2] > int(H * 0.22)]
        plus = nodes(xml, "^Yeni not . tip seç") or nodes(xml, "^Yeni not")
        m, title = pick_card(xml, menus)
        b = boxes[0]
        tumu = [n for n in nodes(xml, r"(^|\| )T[üu]m[üu]$") if n[2] < int(H * 0.40)]
        return {"search": ((b[0] + b[2]) // 2, (b[1] + b[3]) // 2), "clear": None, "plus": plus,
                "card_menu": m, "title": title, "geo": False, "hit": None,
                "tumu": (tumu[0][1], tumu[0][2]) if tumu else None}
    if not is_tablet():
        raise RuntimeError("ana ekran semantiği boş (telefon)")
    k = W / 1600

    def pt(key_):
        return (int(GEO_1600[key_][0] * k), int(GEO_1600[key_][1] * k))

    pl, mn = pt("plus"), pt("menu")
    # doğrulama: ⋮ levhası dolu semantikle açılmalı (editör değil)
    tap(*mn); time.sleep(1.5)
    xml_m = dump()
    n = [x for x in nodes(xml_m) if x[0]]
    is_editor = bool(edit_boxes(xml_m))
    key("KEYCODE_BACK"); time.sleep(1.0)
    if len(n) < 4 or is_editor:
        raise RuntimeError(
            "tablet geometrisi tutmadı: kart ⋮ levhası yerine editör açıldı "
            "(menü düğmesi koordinatı kaymış olabilir)"
            if is_editor else
            "tablet geometrisi tutmadı: kart ⋮ levhası açılmadı "
            "(yedek bandı büyük mü? 'Sonra'ya dokun; ilk kart sabit not mu?)")
    return {"search": pt("search"), "clear": pt("clear"), "plus": [("+", pl[0], pl[1], (*pl, *pl))],
            "card_menu": ("geo", mn[0], mn[1], (*mn, *mn)), "title": "tablet ilk kart", "geo": True,
            "hit": pt("hit"), "tumu": None}


def find_note(q, pat, W, H, h):
    """Kartı bul → dokunma noktası. Telefon: listede kaydırarak semantik ara. Tablet (ana ekran
    semantiği boş): arama kutusuna yaz, tek sonuç sol üst yuvada; arama kalır → [clear_search]."""
    if not h["geo"]:
        hit = find_in_list(pat, W, H)
        return (hit[0][1], hit[0][2]) if hit else None
    tap(*h["search"]); time.sleep(1.0)
    text(q); time.sleep(1.6)
    return h["hit"]


def close_add_panel():
    """"+" paneli hâlâ açıksa kapat (kapalıyken BACK uygulamadan çıkar → durum dökümden okunur)."""
    if nodes(dump(allow_empty=True), "^Metin notu"):
        key("KEYCODE_BACK"); time.sleep(1.0)


def close_note_search(H):
    """Ana ekran aramasından açılan notta başlık eşleşirse not-içi arama çubuğu da açılır ("1/1", ✕ "Kapat")
    ve alt araç çubuğunu ("Biçim"…) gizler; çubuk varsa kapatılır."""
    cl = [n for n in nodes(dump()) if n[0] == "Kapat" and n[2] < H * .2]
    if cl:
        tap(cl[0][1], cl[0][2]); time.sleep(1.0)


def clear_search(h):
    if h["geo"]:
        tap(*h["clear"]); time.sleep(0.8)      # ✕: arama metni silinir
        if ime_shown():
            key("KEYCODE_BACK"); time.sleep(0.6)
        # (fazladan BACK YOK: ana ekranda boşken BACK klasör geçiş menüsünü açıp sonraki dokunuşu yutuyordu)


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
        print("  evre:", ",".join(dict.fromkeys(n for n, _, _ in steps)), flush=True)
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
    h = home_locate(W, H)
    plus = h["plus"]
    # P60 (2026-11-14): veri yeniden kurulunca ilk kart sabitlenmiş "OLCUM kalem pdf"
    # oldu → not_ac/kb/yaz/not_kapa PDF'li notu ölçtü (~3 kat sıçrama). OLCUM
    # stres notları atlanır; açılan not her koşuda yazılır (veri doğrulaması).
    card_menu, card_title = h["card_menu"], h["title"]
    card = (card_menu[1] - 170, card_menu[2] + 150)  # ⋮ kartın sağ üstünde; gövdesi sol altta

    ready()
    s.window([(f"liste", lambda d=d: swipe(x, *((int(H * .75), x, int(H * .3)) if d > 0 else (int(H * .3), x, int(H * .75))), 90), 1.1)
              for d in (1, 1, 1, 1, -1, -1, -1, -1)])
    time.sleep(1.0)

    ready()
    s.window([("menu", lambda: tap(card_menu[1], card_menu[2]), 1.4),
              ("menu", lambda: key("KEYCODE_BACK"), 1.0)])

    ready()
    tap(*h["search"]); time.sleep(1.2)
    s.window([("arama", lambda c=c: text(c), 0.5) for c in "olcum"])
    if ime_shown():
        key("KEYCODE_BACK"); time.sleep(0.6)   # klavye (tablet: sanal klavye açılmıyor)
    key("KEYCODE_BACK"); time.sleep(1.2)       # aramayı temizle
    ready()

    # Geri dönüş: "Tümü" çipi VARSA ona dokun (tablet: sağa kaydırma Gelen'de kalabiliyor → not_ac boş listeye
    # basıyordu, 2026-11-19); yoksa eski gibi sağa kaydır.
    back_step = (lambda: tap(*h["tumu"])) if h.get("tumu") else (
        lambda: swipe(int(W * .15), int(H * .6), int(W * .85), int(H * .6), 160))
    s.window([("klasor", lambda: swipe(int(W * .85), int(H * .6), int(W * .15), int(H * .6), 160), 1.6),
              ("klasor", back_step, 1.6)])
    time.sleep(0.6)
    # Geri çekiş takvimi açtıysa (Tümü'de sağa çekiş, 2026-11-06) dön.
    if "Takvim" in "".join(n[0] for n in nodes(dump(allow_empty=True))[:6]):
        key("KEYCODE_BACK"); time.sleep(1.2)
    ready()

    # Yeni not: "Metin notu" düğmesini panel açıkken bul (pencere dışında).
    tap(plus[0][1], plus[0][2]); time.sleep(1.2)
    metin = nodes(dump(), "^Metin notu")
    key("KEYCODE_BACK"); time.sleep(1.0)
    ready()
    s.window([("yeni_not", lambda: tap(plus[0][1], plus[0][2]), 1.0),
              ("yeni_not", lambda: tap(metin[0][1], metin[0][2]), 2.2)])
    back_note()
    time.sleep(1.0)
    ready()

    # Not aç + klavye + yazma + kapanış (ab_klavye).
    s.window([("not_ac", lambda: tap(*card), 2.8)])
    boxes = edit_boxes(dump())
    if len(boxes) < 2:
        raise RuntimeError("gövde alanı bulunamadı")
    body = boxes[1]
    fx, fy = (body[0] + body[2]) // 2, min(body[1] + 60, (body[1] + body[3]) // 2)
    kb_xy = kb_button(dump())
    ready()
    tap(fx, fy); time.sleep(2.0)
    print(f"  after tap(fx,fy): in_ed={_in_editor(dump(allow_empty=True))}", flush=True)
    trim_typed(fx, fy)
    xml_after = dump(allow_empty=True)
    kb_closed = kb_button(xml_after) or kb_xy
    print(f"  not_ac/trim: boxes={len(boxes)} in_ed={_in_editor(xml_after)} kb={kb_xy} kb_closed={kb_closed} field=({fx},{fy})", flush=True)
    ensure_ime(kb_closed or kb_xy, (fx, fy))
    open_kb = (lambda: tap(*kb_closed)) if kb_closed else (lambda: tap(fx, fy))
    s.window([("kb", (lambda: key("KEYCODE_BACK")) if i % 2 == 0 else open_kb,
               1.4 if i % 2 == 0 else 1.6) for i in range(6)])
    key("KEYCODE_MOVE_END")
    s.window([("yaz", lambda: text(" deneme yazisi"), 1.4) for _ in range(4)])
    s.window([("not_kapa", lambda: key("KEYCODE_BACK"), 1.3),
              ("not_kapa", lambda: key("KEYCODE_BACK"), 1.8)])
    if _in_editor(dump(allow_empty=True)):
        key("KEYCODE_BACK")
    time.sleep(0.8)
    ready()

    # Sabit PDF'li not: listede kaydırarak bul (pencere dışında).
    hit = find_note("OLCUM kalem pdf", "^OLCUM kalem pdf", W, H, h)
    if not hit:
        raise RuntimeError("'OLCUM kalem pdf' bulunamadı (HAZIRLIK)")
    ready()
    s.window([("sabit_ac", lambda: tap(*hit), 2.8)])
    close_note_search(H)
    xml = dump()
    # Bölme: başlık alanının altından ek çubuğunun ("Tam ekran") üstüne
    # ("Sayfa 1 / 1" etiketi her zaman gelmiyor).
    # Tablet editörünün üst çubuğunda da "Tam ekran" var: ek çubuğu = EN ALTTAKİ.
    bar = sorted(nodes(xml, "^Tam ekran$"), key=lambda n: -n[2])
    boxes = edit_boxes(xml)
    body = boxes[1] if len(boxes) > 1 else None
    if not bar or not body:
        raise RuntimeError("sabit bölme / gövde bulunamadı")
    top, bot, px = boxes[0][3], bar[0][3][1], W // 2
    ready()
    s.window([("sabit_kay", lambda: swipe(px, int(bot - (bot - top) * .2), px, int(top + (bot - top) * .2), 200), 0.9)
              for _ in range(3)])
    bx, by = (body[0] + body[2]) // 2, min(body[1] + 60, (body[1] + body[3]) // 2)
    kb2 = kb_button(xml)
    tap(bx, by); time.sleep(2.0)
    xml2_after = dump(allow_empty=True)
    kb2_closed = kb_button(xml2_after) or kb2
    ensure_ime(kb2_closed or kb2, (bx, by))
    open_kb2 = (lambda: tap(*kb2_closed)) if kb2_closed else (lambda: tap(bx, by))
    s.window([("sabit_kb", (lambda: key("KEYCODE_BACK")) if i % 2 == 0 else open_kb2,
               1.4 if i % 2 == 0 else 1.6) for i in range(4)])
    back_note(); time.sleep(1.0)
    if _in_editor(dump(allow_empty=True)):
        key("KEYCODE_BACK"); time.sleep(0.8)
    ready()
    clear_search(h)
    list_top(W, H)  # sonraki koşu aynı yerden başlasın

    for phase in (phase_sablon, phase_bicim, phase_kalem, phase_duzen):
        try:
            phase(s, W, H, plus, h)
        except (RuntimeError, IndexError) as e:
            if isinstance(e, NotReady):
                raise
            print(f"evre atlandı ({phase.__name__}): {e}", flush=True)
            # 2026-11-15: evre kendi BACK'lerini bastı; fazladan BACK uygulamadan
            # çıkarıp koşuyu düşürüyordu. Hazır değilse kalan evreler atlanır.
            try:
                ready()
            except NotReady as ne:
                print(f"kalan evreler atlandı (uygulama önde değil): {ne}", flush=True)
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
    W_cur, H_cur = screen_size()
    deleted = False
    for _ in range(6):
        xml = ui_dump()
        if not _in_editor(xml):
            break
        best = None
        for m in re.finditer(r'<node [^>]*>', xml):
            nd = m.group(0)
            b = re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', nd)
            if not b:
                continue
            x0, y0, x1, y1 = map(int, b.groups())
            if y0 < 200:
                continue
            if (x1 - x0) > W_cur * 0.92 or (y1 - y0) > H_cur * 0.55:
                continue
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
        print(f"  trim_typed: best={(t[:40], (x0, y0, x1, y1))}", flush=True)
        keep = t[:junk.start()].rstrip()
        n = len(t) - len(keep)
        tap((x0 + x1) // 2, max(y0 + 10, y1 - 20)); time.sleep(0.6)
        key("KEYCODE_MOVE_END")
        for i in range(0, n, 50):
            sh("input keyevent " + " ".join(["67"] * min(50, n - i)))
        deleted = True
        time.sleep(1.0)
        if not _in_editor(dump(allow_empty=True)):
            break
    if deleted and (not best or not best[0].strip()) and _in_editor(dump(allow_empty=True)):
        tap(fx, fy); time.sleep(0.6)
        key("KEYCODE_MOVE_END"); text("Kitap"); time.sleep(0.6)
    if deleted and _in_editor(dump(allow_empty=True)):
        tap(fx, fy)
        time.sleep(3.5)  # kEditorSaveDelay 2 sn: kayıt kb penceresine taşmasın


def list_top(W, H):
    """Ana ekran listesini başa al."""
    for _ in range(6):
        swipe(W // 2, int(H * .3), W // 2, int(H * .85), 120); time.sleep(0.3)
    time.sleep(1.2)  # fırlatma durmadan dokunmak dokunuşu yutar (tablet: '+' ilk dokunuşta açılmıyordu)


# l10n fromTemplate: eskiden "Şablondan", 2026-11 itibarıyla "Hazır şablonlar" (add_catalog.dart:204) —
# T13 `sablon` evresinin atlanma KÖK NEDENİ buydu (regex yalnız "Şablondan" arıyordu).
TPL = "^(Hazır şablonlar|Şablondan|From template|Ready templates)"


def phase_sablon(s, W, H, plus, h):
    """P63: "+" → Şablonlar → levha → Planlama çipi → kapat (koordinatlar
    pencere dışında bulunur)."""
    # Kök neden (run_g2/g3/g4 "'+' menüsünde Şablondan yok"): panel
    # `SingleChildScrollView(reverse: true)` (quick_add_fab.dart) ve gruplar
    # TERSTEN dizili → Şablon grubu panelin en ÜSTÜNDE, telefonda ekranın üstünde
    # kalıyor; uiautomator görünmeyeni dökmüyor. Eski kaydırma "Metin notu"na
    # doğru ~90 px çekiyordu (yetmez). Başa çıkmak için parmak panelin üst
    # kısmından AŞAĞI uzun çekilir (taşan panel ekranı doldurur → H*0,2 içinde);
    # tavanda durur, iki kez çekmek zararsız. Ölçüm penceresi aynı yolu izler.
    # Önceki evreden kalan fırlatma/menü İLK dokunuşu yutabilir (tablet, 2026-11-18: "+" iki koşudan
    # birinde açılmıyordu) → panel açılana ("Metin notu"/şablon düğmesi dökümde) dek en çok 3 dokunuş.
    for _ in range(3):
        tap(plus[0][1], plus[0][2]); time.sleep(1.3)
        xml = dump()
        if nodes(xml, TPL) or nodes(xml, "^Metin notu"):
            break
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
        if nodes(xml, "^(Kapat|Menüyü düzenle)$"):   # panel açıksa kapat (kapalıyken BACK uygulamadan çıkar)
            key("KEYCODE_BACK"); time.sleep(1.0)
        raise RuntimeError("'+' menüsünde 'Hazır şablonlar' yok (kaydırınca da)")
    tap(tpl[0][1], tpl[0][2]); time.sleep(1.8)
    chip = nodes(dump(), "^Planlama")
    key("KEYCODE_BACK"); time.sleep(1.0)          # şablon levhası
    close_add_panel()                              # "+" paneli (yeni derlemede levhayla birlikte kapanabiliyor)
    if not chip:
        raise RuntimeError("şablon levhasında 'Planlama' çipi yok")
    ready()
    s.window([("sablon", lambda: tap(plus[0][1], plus[0][2]), 1.0)]
             + ([("sablon", lambda: swipe(*roll), 0.8)] * 2 if roll else [])
             + [("sablon", lambda: tap(tpl[0][1], tpl[0][2]), 1.8),
              ("sablon", lambda: tap(chip[0][1], chip[0][2]), 1.2),
              ("sablon", lambda: key("KEYCODE_BACK"), 1.2)])
    time.sleep(0.6)
    close_add_panel()
    ready()


def phase_bicim(s, W, H, plus, h):
    """P63: çizgili listede madde → Biçim → çizgi tepsisi aç/kapa ×3 → tür
    seç ×3. Tepsi düğmelerinin erişilebilirlik adları çeviriden gelir."""
    hit = find_note("OLCUM cizgi", "^OLCUM cizgi", W, H, h)
    if not hit:
        raise RuntimeError("'OLCUM cizgi' bulunamadı (hazırlık başarısız? koşu başındaki 'hazırlık:' satırı)")
    tap(*hit); time.sleep(2.5)
    close_note_search(H)
    boxes = edit_boxes(dump())
    if len(boxes) < 3:
        raise RuntimeError("çizgili listede madde alanı yok")
    it = boxes[2]
    tap((it[0] + it[2]) // 2, (it[1] + it[3]) // 2); time.sleep(1.6)
    fmt = nodes(dump(), "^Biçim$")
    if not fmt:
        raise RuntimeError("Biçim düğmesi yok")
    tap(fmt[0][1], fmt[0][2]); time.sleep(1.2)
    xm = dump()
    menu = nodes(xm, "^Alt çizgi$")
    if not menu:
        print("  bicim tanı (alt yarı):", [(n[0][:22], n[1], n[2]) for n in nodes(xm) if n[0] and n[2] > H * .5][:16], flush=True)
        shot("bicim_tani", 0.3)
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
    # klavye/biçim çubuğu/tepsi açıkken geri tuşu önce onları kapatır: editör araç çubuğu
    # ("Notta ara") kaybolana dek (en çok 5) geri; ana ekranda DURUR (fazlası uygulamadan çıkar).
    for _ in range(5):
        if not nodes(dump(), "^Notta ara$"):
            break
        key("KEYCODE_BACK"); time.sleep(0.9)
    time.sleep(1.0)
    ready()
    clear_search(h)
    list_top(W, H)


def phase_kalem(s, W, H, plus, h):
    """P63 G4: kalem kipi aç → 10 çizgi → kapsül aç/kapa ×3 (geri tuşu kapsülü
    hapa indirir). Çizgiler sonra geri alınır (not büyümesin); "Kalemle yaz"
    alt çubukta, hap düğmesi ("Kalem tepsisini aç") çizimden sonra bulunur."""
    m = h["card_menu"]
    tap(m[1] - 170, m[2] + 150); time.sleep(2.5)
    xk = dump()
    pen = nodes(xk, "^Kalemle yaz")
    if not pen:
        print("  kalem tanı:", labels_in(xk), [(n[0][:22], n[1], n[2]) for n in nodes(xk) if n[0]][:10], flush=True)
        shot("kalem_tani", 0.25)
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
        # kart etiketi TÜM kartı kapsar (merkez); tablet 2 sütun: kart ilk ekranın altına taşabiliyor →
        # pencere geniş (300 … H-150); eski pencere (500 … H-400) kartı hiç yakalamayıp 12 kaydırmayla geçiyordu
        if hit and 300 < hit[0][2] < H - 150:
            return hit
        if hit:
            print(f"  find_in_list: '{pat}' y={hit[0][2]} pencere dışı; kaydırılıyor", flush=True)
        swipe(W // 2, int(H * .75), W // 2, int(H * .35), 300); time.sleep(1.0)
    print(f"  find_in_list: '{pat}' bulunamadı; etiket sayısı {labels_in(ui_dump())}", flush=True)
    shot("find_in_list_yok", 0.25)
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


def phase_duzen(s, W, H, plus, h):
    """P63 G5: not ⋮ ("Not menüsü", üstte) → "Ekranı düzenle" → alt çubuktaki
    ilk 3 çerçeveye (anlam adı "Gizle") ikişer kez dokun → "Bitti". Kayıt
    değişmez (gizle + göster)."""
    m = h["card_menu"]
    tap(m[1] - 170, m[2] + 150); time.sleep(2.5)
    more = [n for n in nodes(dump(), "^Not menüsü$") if n[2] < H * .2]
    if not more:
        key("KEYCODE_BACK"); time.sleep(1.0)
        raise RuntimeError("not ⋮ yok")
    tap(more[0][1], more[0][2]); time.sleep(1.2)
    # "Ekranı düzenle" artık menü levhasının BAŞLIĞINDAKİ ⚙ ("Ayarlar") açılır menüsünde
    # ("Menüyü düzenle · Ekranı düzenle · Ayarlar"); eskiden alt satırdaydı → T13 `duzen` hiç koşmuyordu.
    gear = nodes(dump(), "^Ayarlar$")
    if gear:
        tap(gear[0][1], gear[0][2]); time.sleep(1.2)
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
    if not done and is_tablet():
        # Tablette "Düzenleme modu" üst bandı (Geri al · ↕ · Bitti) semantik ağaçta YOK (KT-bulgusu:
        # TalkBack "Bitti"ye ulaşamaz); görüntüde sağ üstte → 1600 px genişlikte (1507, 120).
        k = W / 1600
        done = [("Bitti", int(1507 * k), int(120 * k), (0, 0, 0, 0))]
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
    ap.add_argument("--hazirlik", action="store_true", help="tablette de ensure_cizgi (yedek yükleme) çalışsın")
    ap.add_argument("--yon", choices=["yatay", "dikey", "mevcut"], default=None)
    o = ap.parse_args()
    la = o.etiket_a or os.path.splitext(os.path.basename(o.a))[0]
    lb = o.etiket_b or os.path.splitext(os.path.basename(o.b))[0]
    os.makedirs(DOCS, exist_ok=True)
    runs = {"A": [], "B": []}
    temps = []
    tablet = is_tablet()
    sfx = "_tablet" if tablet else ""
    yon = o.yon or ("dikey" if tablet else "mevcut")
    if yon != "mevcut":
        sh("wm user-rotation lock " + {"yatay": "1", "dikey": "0"}[yon])
        time.sleep(1.5)
    la += f"_{yon}" if tablet else ""
    lb += f"_{yon}" if tablet else ""
    hist_path = os.path.join(DOCS, f"gecmis{sfx}.csv")
    golden_path = os.path.join(DOCS, f"altin_taban{sfx}.json")
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

    def check_landscape(apk):
        """TP-F (2026-11-19): profil APK'sı varsayılan DİKEY kilitli (manifest
        `olcumYon`); `--yon yatay` kilidi uygulamayı döndürmez, ölçüm sessizce dikeyde
        koşardı. Uygulama açıkken ekran hâlâ dikeyse dur."""
        install(apk)
        sh(f"am start -n {ACT}"); time.sleep(3.0)
        w, h = screen_size()
        sh(f"am force-stop {OPKG}")
        if w < h:
            raise SystemExit(f"{os.path.basename(apk)}: uygulama dikey kilitli ({w}x{h}) — "
                             "yatay ölçüm için NOTLAR_OLCUM_YON=landscape ile derle (TP-F)")

    try:
        if yon == "yatay":
            check_landscape(o.a)
            check_landscape(o.b)
        if tablet and not o.hazirlik:
            # Tablet ana ekranı semantiksiz (home_locate notu): "OLCUM cizgi" varlığı listede aranamaz;
            # yedek bir kez elle yüklenir (docs/perf/README tablet bölümü). Zorlamak: --hazirlik.
            install(o.a)
        elif cool_enough():
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
        if yon != "mevcut":
            sh("wm user-rotation free")
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
    record(hist_path, o.commit, la, am, t)
    record(hist_path, o.commit, lb, median_of(runs["B"]), t)
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
