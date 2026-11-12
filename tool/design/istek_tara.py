"""Bir dosyadaki 'kullanıcı isteği / bulgusu / kararı' yorumlarını döker.

DENEYIM_PLANI protokol 0: bir bileşenin GÖRÜNÜŞÜNÜ ya da YERİNİ değiştirmeden
önce o dosyada kullanıcının daha önce ne istediğine bak. Koddaki bu yorumlar
aylarca süren geri bildirim turlarının kaydıdır; birini tersine çeviren
değişiklik "iyileştirme" değil, geri gidiştir.

Kullanım (depo kökünden):
    python tool/design/istek_tara.py lib/features/notes/presentation/note_card.dart
    python tool/design/istek_tara.py lib/features/calendar/presentation/*.dart
"""

import re
import sys

PATTERN = re.compile(r'kullanıcı (isteği|bulgusu|kararı)', re.I)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    for path in sys.argv[1:]:
        try:
            with open(path, encoding='utf-8') as fh:
                lines = fh.read().split('\n')
        except OSError:
            print(f'YOK {path}')
            continue
        name = path.replace('\\', '/').split('/')[-1]
        for i, line in enumerate(lines):
            if not PATTERN.search(line):
                continue
            text = ' '.join(x.strip().lstrip('/').strip() for x in lines[i:i + 3])
            print(f'{name}:{i + 1}: {text[:240]}')


if __name__ == '__main__':
    main()
