"""Indirilebilir yazi tiplerinin (PL10) kaynak tablosunu uretir.

google_fonts paketinin (pubspec.lock surumu) `GoogleFontsFile(sha256, uzunluk)`
kayitlarindan 400/500 kesimlerini okur; adres `fonts.gstatic.com/s/a/<sha256>.ttf`
(paketin kendi kurali). Cikti: lib/core/utils/font_sources.dart.
Kullanim: python tool/gen_font_sources.py <google_fonts-paket-dizini>
"""
import pathlib
import re
import sys

pkg = pathlib.Path(sys.argv[1]) / "lib/src/google_fonts_parts"
FAMILIES = {  # katalog adi -> paket yontem adi
    "Open Sans": "openSans", "Lato": "lato", "Source Sans 3": "sourceSans3",
    "Work Sans": "workSans", "Rubik": "rubik", "Nunito": "nunito",
    "Montserrat": "montserrat", "Poppins": "poppins", "Merriweather": "merriweather",
    "PT Serif": "ptSerif", "EB Garamond": "ebGaramond",
    "Playfair Display": "playfairDisplay", "JetBrains Mono": "jetBrainsMono",
    "Patrick Hand": "patrickHand",
}
src = "".join(p.read_text(encoding="utf8") for p in sorted(pkg.glob("part_*.dart")))
out = []
for name, method in FAMILIES.items():
    m = re.search(
        r"static TextStyle %s\(\{.*?\n  \}\) \{(.*?)\n    return googleFontsTextStyle" % method,
        src, re.S)
    body = m.group(1)
    rows = []
    for w, h, n in re.findall(
        r"fontWeight: FontWeight\.w(\d+),\s*fontStyle: FontStyle\.normal,\s*\): GoogleFontsFile\(\s*'([0-9a-f]{64})',\s*(\d+),",
        body,
    ):
        if w in ("400", "500"):
            rows.append((w, h, n))
    out.append((name, rows))
lines = [
    "// URETILDI: python tool/gen_font_sources.py <google_fonts-8.2.0>. Elle duzenleme.",
    "// Her kayit: agirlik, SHA-256 (adres = fonts.gstatic.com/s/a/<sha>.ttf), uzunluk.",
    "",
    "typedef FontSource = ({int weight, String sha256, int length});",
    "",
    "const Map<String, List<FontSource>> kDownloadableFontSources = {",
]
for name, rows in out:
    assert rows and rows[0][0] == "400", name
    lines.append(f"  '{name}': [")
    for w, h, n in rows:
        lines.append(f"    (weight: {w}, sha256: '{h}', length: {n}),")
    lines.append("  ],")
lines.append("};")
pathlib.Path("lib/core/utils/font_sources.dart").write_text("\n".join(lines) + "\n", encoding="utf8")
