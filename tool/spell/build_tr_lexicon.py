#!/usr/bin/env python3
"""Türkçe kök sözlüğü üretici (yazım denetimi, kullanıcı isteği 2026-11-26).

Kaynak: Zemberek-NLP sözlüğü (Apache License 2.0, (c) Ahmet A. Akın,
Mehmet D. Akın) — master-dictionary.dict. Çıktı:
assets/spell/tr_lexicon.txt, her satır `kelime<TAB>bayraklar`, Dart'ın
String.compareTo sırasıyla (UTF-16 kod birimi; Türkçe harfler BMP'de olduğu
için kod noktası sırasıyla aynı) sıralı, tekrarsız.

Bayraklar:
  n  ad/sıfat kökü (ek alır)
  x  ek almayan sözcük (zarf, bağlaç, ünlem, adıl…; yalnız birebir)
  v  fiil kökü (mastar eki -mak/-mek atılmış)
  s  tek heceli ve sonu yumuşar (Voicing: "kap" → "kabı")
  h  yumuşamaz (NoVoicing: "adalet" → "adaleti")
  d  ikizleşir (Doubling: "hak" → "hakkı")
  f  ince ünlüyle ek alır (InverseHarmony: "saat" → "saati")
  l  son ünlü düşer (LastVowelDrop: "ağız" → "ağzı")

Kullanım:
  python3 tool/spell/build_tr_lexicon.py [--src DİZİN]
--src verilmezse dosyalar GitHub'dan indirilir; özetleri (sha256) aşağıdaki
SOURCES ile karşılaştırılır — kaynak değiştiyse betik durur (bilerek
güncellemek için yeni özeti yaz).
"""
import argparse
import hashlib
import os
import re
import sys
import urllib.request

BASE = ('https://raw.githubusercontent.com/ahmetaa/zemberek-nlp/master/'
        'morphology/src/main/resources/tr/')
# non-tdk.dict BİLEREK yok: TDK dışı yazımları da içeriyor ("herşey",
# "orjinal", "döküman") — yaygın yanlışlar "doğru" sayılmasın.
SOURCES = {
    'master-dictionary.dict':
        '56d294b674d0e22287a3b0b4384fd621d39dd0e4f51795bf05c0bd1aaacbad04',
}
# Ek almayan (yalnız birebir bilinen) sözcük türleri: zarf, bağlaç, ünlem,
# adıl, belirteç, ilgeç, soru, ikileme. Ek çözücü bunlara ek eklemez
# ("yinede", "hemde" bilinmesin).
CLOSED = {'Adv', 'Conj', 'Interj', 'Pron', 'Det', 'Postp', 'Ques', 'Dup'}
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'assets', 'spell', 'tr_lexicon.txt')

VOWELS = set('aeıioöuüâîû')
LETTERS = re.compile(r'^[a-zçğıöşüâîû]+$')


def tr_lower(s):
    return s.replace('I', 'ı').replace('İ', 'i').lower()


def plain(s):
    return s.replace('â', 'a').replace('î', 'i').replace('û', 'u')


def syllables(w):
    return sum(1 for c in w if c in VOWELS)


def read(name, src):
    if src:
        with open(os.path.join(src, name), 'rb') as f:
            data = f.read()
    else:
        with urllib.request.urlopen(BASE + name, timeout=60) as r:
            data = r.read()
    digest = hashlib.sha256(data).hexdigest()
    expected = SOURCES[name]
    if expected != digest:
        print(f'UYARI {name}: sha256 {digest} (beklenen {expected})',
              file=sys.stderr)
        if os.environ.get('TR_LEXICON_ACCEPT') != '1':
            sys.exit('Kaynak değişmiş: bilerek güncelliyorsan '
                     'TR_LEXICON_ACCEPT=1 ile koş ve SOURCES özetini yaz.')
    return data.decode('utf-8')


def parse(text, out):
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        meta = ''
        if '[' in line:
            word, meta = line.split('[', 1)
            meta = meta.rstrip(']')
        else:
            word = line
        word = word.strip()
        if ' ' in word or not word:
            continue
        pos = ''
        attrs = set()
        for part in meta.split(';'):
            part = part.strip()
            if part.startswith('P:'):
                pos = part[2:].strip()
            elif part.startswith('A:'):
                attrs |= {a.strip() for a in part[2:].split(',')}
        if pos in ('Punc', 'Num'):
            continue
        if word[0].isupper():
            continue  # özel ad (bu dosyalarda yok; olursa dışarıda)
        w = tr_lower(word)
        if not LETTERS.match(w):
            continue
        flags = set()
        if pos == 'Verb' or (not pos and len(w) > 4 and w[-3:] in ('mak', 'mek')):
            w = w[:-3]
            flags.add('v')
        elif pos in CLOSED or 'NoSuffix' in attrs:
            flags.add('x')
        else:
            flags.add('n')
        if len(w) < 2:
            continue
        # Ses olayı bayrakları yalnız AD girdisinden: fiil "et-" yumuşar
        # ("ediyor"), ad "et" yumuşamaz ("eti") — birleşince "eti" yanlış
        # sayılıyordu. Fiil yumuşaması ek çözücüde ayrı (git/et/tat/güt).
        if 'v' in flags:
            attrs = set()
        if 'Voicing' in attrs and syllables(w) == 1:
            flags.add('s')
        if 'NoVoicing' in attrs:
            flags.add('h')
        if 'Doubling' in attrs:
            flags.add('d')
        if 'InverseHarmony' in attrs:
            flags.add('f')
        if 'LastVowelDrop' in attrs:
            flags.add('l')
        for form in {w, plain(w)}:
            out.setdefault(form, set()).update(flags)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', help='kaynak .dict dosyalarının dizini')
    args = ap.parse_args()
    words = {}
    for name in SOURCES:
        parse(read(name, args.src), words)
    order = 'nxvshdfl'
    lines = [
        f'{w}\t{"".join(c for c in order if c in f)}'
        for w, f in sorted(words.items(), key=lambda kv: kv[0])
    ]
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(lines) + '\n')
    verbs = sum(1 for f in words.values() if 'v' in f)
    print(f'{len(words)} kelime ({verbs} fiil kökü) → {OUT}')


if __name__ == '__main__':
    main()
