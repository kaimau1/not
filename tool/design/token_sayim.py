"""Tasarım belirteci sayımı (DENEYIM_PLANI F72.3).

`lib/` içinde elle yazılmış görsel değerleri sayar: köşe, yazı boyutu, süre,
eğri, simge boyutu, saydamlık, yazı ağırlığı. Amaç iki şey:
  1. Kanıt: "kaç farklı değer var" sorusunun tek komutla cevabı.
  2. Mandal: `test/design_tokens_guard_test.dart` aynı desenleri sayar; sayı
     `test/design_tokens/budget.json`daki değeri AŞAMAZ (yalnız düşer).

Kullanım (depo kökünden):
    python tool/design/token_sayim.py            # özet
    python tool/design/token_sayim.py --json     # budget.json biçimi
    python tool/design/token_sayim.py radius     # o türün dosya:satır dökümü

Belirteçlerin kendi tanım dosyaları ve üretilen çeviri dosyaları sayılmaz.
"""

import collections
import json
import os
import re
import sys

ROOT = 'lib'
SKIP_DIRS = ('l10n',)
# Belirteçlerin TANIMLANDIĞI dosyalar: buradaki sayılar değer değil tanım.
SKIP_FILES = (
    'lib/app/theme/app_tokens.dart',
    'lib/app/theme/app_theme.dart',
    'lib/app/theme/app_palette.dart',
    'lib/app/theme/note_colors.dart',
    'lib/app/theme/note_themes.dart',
    'lib/app/theme/fixed_colors.dart',
)

PATTERNS = {
    'radius': r'(?:BorderRadius\.circular|Radius\.circular)\(\s*([0-9.]+)\s*\)',
    'fontSize': r'fontSize:\s*([0-9.]+)',
    'duration': r'Duration\(milliseconds:\s*([0-9]+)\)',
    'curve': r'Curves\.(\w+)',
    'iconSize': r'(?:\bsize:|iconSize:)\s*([0-9.]+)',
    'alpha': r'withValues\(alpha:\s*([0-9.]+)\)',
    'fontWeight': r'FontWeight\.(w\d+|bold)',
    'haptic': r'HapticFeedback\.(\w+)',
}


def dart_files():
    for d, _, fs in os.walk(ROOT):
        if any(s in d.replace(os.sep, '/').split('/') for s in SKIP_DIRS):
            continue
        for f in fs:
            if not f.endswith('.dart'):
                continue
            p = os.path.join(d, f).replace(os.sep, '/')
            if p in SKIP_FILES:
                continue
            yield p


def count():
    values = {k: collections.Counter() for k in PATTERNS}
    hits = {k: [] for k in PATTERNS}
    for p in dart_files():
        with open(p, encoding='utf-8') as fh:
            for i, line in enumerate(fh, 1):
                # Yorum satırı değer değildir.
                if line.lstrip().startswith('//'):
                    continue
                for k, pt in PATTERNS.items():
                    for m in re.finditer(pt, line):
                        values[k][m.group(1)] += 1
                        hits[k].append(f'{p}:{i}: {line.strip()[:110]}')
    return values, hits


def main():
    # Windows konsolu Türkçe harfleri bozmasın.
    sys.stdout.reconfigure(encoding='utf-8')
    values, hits = count()
    args = sys.argv[1:]
    if args and args[0] == '--json':
        print(json.dumps({k: sum(v.values()) for k, v in values.items()}, indent=2))
        return
    if args and args[0] in PATTERNS:
        print('\n'.join(hits[args[0]]))
        return
    for k, v in values.items():
        top = ', '.join(f'{a}×{b}' for a, b in v.most_common(14))
        print(f'{k}: {sum(v.values())} kullanım, {len(v)} farklı değer')
        print(f'   {top}')


if __name__ == '__main__':
    main()
