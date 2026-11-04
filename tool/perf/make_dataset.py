"""Ölçüm veri seti: Keep Takeout biçiminde 240 not + 4 adlı stres notu.

Çıktılar (PERF_OUT ya da geçici klasör):
  keep_olcum.zip  — 140 metin (5'i 300-600 satır), 70 liste (5'i 90-150 madde), 30 görselli (40 foto)
  olcum_ozel.zip  — "OLCUM uzun liste" (120 madde), "OLCUM uzun metin" (500 satır),
                    "OLCUM gorselli" (2 foto), "OLCUM kisa metin" (6 satır)
Telefona: adb push <zip> /sdcard/Download/ → uygulamada Ayarlar → Senkronizasyon →
"Başka uygulamadan içe aktar" (ya da perf.open_import("<zip>")).
"""
import io, json, os, random, sys, zipfile, time
from PIL import Image, ImageDraw, ImageFilter

random.seed(int(os.environ.get("OLCUM_SEED", 42)))  # başka tohum = kopya sayılmayan ikinci set
OUT = os.path.join(os.environ.get("PERF_OUT") or __import__("tempfile").gettempdir(), "keep_olcum.zip")

WORDS = ("bugün yarın toplantı rapor hasta kontrol tahlil ilaç doz randevu market süt ekmek "
         "yumurta peynir proje sunum taslak fikir kitap makale okuma özet not hatırlatma ödeme "
         "fatura kira araba servis lastik tatil bilet otel plan hafta sonu spor koşu yürüyüş "
         "yemek tarif fırın sebze meyve çay kahve telefon mesaj e-posta dosya klasör yedek "
         "güncelleme sürüm hata düzeltme deneme ölçüm sonuç grafik tablo liste madde başlık").split()
LABELS = ["İş", "Ev", "Alışveriş", "Fikirler", "Okul", "Sağlık"]
COLORS = ["DEFAULT"] * 6 + ["RED", "ORANGE", "YELLOW", "GREEN", "TEAL", "BLUE", "GRAY", "PURPLE", "PINK", "BROWN"]


def sentence(n=None):
    n = n or random.randint(4, 14)
    w = [random.choice(WORDS) for _ in range(n)]
    s = " ".join(w)
    r = random.random()
    if r < 0.12:
        i = random.randrange(len(w))
        s = s.replace(w[i], f"**{w[i]}**", 1)
    elif r < 0.2:
        i = random.randrange(len(w))
        s = s.replace(w[i], f"_{w[i]}_", 1)
    return s[0].upper() + s[1:] + "."


def body(lines):
    out = []
    for _ in range(lines):
        out.append(sentence() if random.random() > 0.1 else "")
    return "\n".join(out)


def photo(i, w=2400, h=1800):
    im = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(im)
    c1 = [random.randint(30, 220) for _ in range(3)]
    c2 = [random.randint(30, 220) for _ in range(3)]
    for y in range(0, h, 6):
        t = y / h
        d.rectangle([0, y, w, y + 6], fill=tuple(int(a + (b - a) * t) for a, b in zip(c1, c2)))
    for _ in range(40):
        x, y = random.randrange(w), random.randrange(h)
        r = random.randint(40, 400)
        d.ellipse([x - r, y - r, x + r, y + r], fill=tuple(random.randint(0, 255) for _ in range(3)))
    im = im.filter(ImageFilter.GaussianBlur(3))
    # foto benzeri gren: JPEG boyutu gerçekçi olsun
    noise = Image.effect_noise((w, h), 28).convert("RGB")
    im = Image.blend(im, noise, 0.12)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=85)
    return buf.getvalue()


def main():
    now_us = int(time.time() * 1e6)
    notes = []
    k = 0

    def base(title):
        nonlocal k
        k += 1
        return {
            "color": random.choice(COLORS),
            "isTrashed": False,
            "isPinned": False,
            "isArchived": False,
            "title": title,
            "userEditedTimestampUsec": now_us - k * 3_600_000_000,
            "createdTimestampUsec": now_us - k * 3_600_000_000,
            "labels": [{"name": random.choice(LABELS)}] if random.random() < 0.4 else [],
        }

    # metin notları
    for i in range(140):
        if i < 60:
            lines = random.randint(1, 3)
        elif i < 110:
            lines = random.randint(5, 25)
        elif i < 135:
            lines = random.randint(40, 120)
        else:
            lines = random.randint(300, 600)
        n = base("" if random.random() < 0.15 else sentence(random.randint(2, 5)).rstrip("."))
        n["textContent"] = body(lines)
        notes.append((n, []))
    # listeler
    for i in range(70):
        if i < 50:
            cnt = random.randint(3, 12)
        elif i < 65:
            cnt = random.randint(20, 40)
        else:
            cnt = random.randint(90, 150)
        n = base(sentence(random.randint(1, 3)).rstrip("."))
        n["listContent"] = [{"text": sentence(random.randint(2, 7)).rstrip("."), "isChecked": random.random() < 0.4} for _ in range(cnt)]
        notes.append((n, []))
    # görselli notlar
    imgs = []
    for i in range(30):
        n = base(sentence(random.randint(1, 4)).rstrip("."))
        n["textContent"] = body(random.randint(0, 6))
        files = []
        for j in range(1 if i % 3 else 2):
            name = f"foto_{i}_{j}.jpg"
            files.append(name)
            imgs.append(name)
        n["attachments"] = [{"filePath": f, "mimetype": "image/jpeg"} for f in files]
        notes.append((n, files))
    random.shuffle(notes)
    for n, _ in notes[:6]:
        n["isPinned"] = True

    with zipfile.ZipFile(OUT, "w", zipfile.ZIP_STORED) as z:
        for idx, (n, files) in enumerate(notes):
            z.writestr(f"Takeout/Keep/not_{idx:03d}.json", json.dumps(n, ensure_ascii=False))
            for f in files:
                z.writestr(f"Takeout/Keep/{f}", photo(hash(f) % 1000))
    print(OUT, os.path.getsize(OUT) // 1024, "KB", len(notes), "not,", len(imgs), "görsel")


def main_ozel():
    random.seed(7)
    now = int(time.time() * 1e6)

    def base(t, k):
        return {"color": "DEFAULT", "isTrashed": False, "isPinned": False, "isArchived": False, "title": t,
                "userEditedTimestampUsec": now + k, "createdTimestampUsec": now + k, "labels": []}

    notes = []
    n = base("OLCUM uzun liste", 1)
    n["listContent"] = [{"text": sentence(random.randint(3, 8)).rstrip("."), "isChecked": i % 3 == 0} for i in range(120)]
    notes.append((n, []))
    n = base("OLCUM uzun metin", 2)
    n["textContent"] = body(500)
    notes.append((n, []))
    n = base("OLCUM gorselli", 3)
    n["textContent"] = body(8)
    n["attachments"] = [{"filePath": "olcum_a.jpg", "mimetype": "image/jpeg"}, {"filePath": "olcum_b.jpg", "mimetype": "image/jpeg"}]
    notes.append((n, ["olcum_a.jpg", "olcum_b.jpg"]))
    n = base("OLCUM kisa metin", 4)
    n["textContent"] = body(6)
    notes.append((n, []))
    out = os.path.join(os.path.dirname(OUT), "olcum_ozel.zip")
    with zipfile.ZipFile(out, "w") as z:
        for i, (n, files) in enumerate(notes):
            z.writestr(f"Takeout/Keep/olcum_{i}.json", json.dumps(n, ensure_ascii=False))
            for f in files:
                z.writestr(f"Takeout/Keep/{f}", photo(i))
    print(out)


def main_boyut():
    """F24.1 eşik ölçümü: "OLCUM boyut N" gövdesi N KB metin."""
    random.seed(11)
    now = int(time.time() * 1e6)
    out = os.path.join(os.path.dirname(OUT), "olcum_boyut.zip")
    with zipfile.ZipFile(out, "w") as z:
        for k in (1, 2, 3, 4, 5, 8, 20, 35):
            t = ""
            while len(t) < k * 1000:
                t += body(5) + chr(10)
            n = {"color": "DEFAULT", "isTrashed": False, "isPinned": False, "isArchived": False,
                 "title": f"OLCUM boyut {k}", "textContent": t[:k * 1000],
                 "userEditedTimestampUsec": now + k, "createdTimestampUsec": now + k, "labels": []}
            z.writestr(f"Takeout/Keep/boyut_{k}.json", json.dumps(n, ensure_ascii=False))
    print(out)


if __name__ == "__main__":
    if sys.argv[1:] == ["boyut"]:
        main_boyut()
        sys.exit()
    main()
    main_ozel()
