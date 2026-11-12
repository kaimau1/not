// Renk rolleri bekçisi (DENEYIM_PLANI F73.1, K-D1, §2.2): `tertiary` yapay
// zekâ kimliğidir. `lib/` içinde yalnız `features/ai/`, `AiIcon` dosyası ve
// tema dosyalarında serbest; bugünkü öteki kullanımlar aşağıda sayısıyla ve
// gerekçesiyle izinli. Sayı yalnız DÜŞER — yeni kullanım ekleme, rolüne uygun
// rengi seç (eylem: primary · zaman/dikkat: secondary · yıkıcı: error · geri
// kalan: nötr).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _pattern = RegExp(r'tertiaryContainer|\.tertiary\b');

const _free = [
  'lib/features/ai/',
  'lib/features/auth/presentation/account_required.dart', // AiIcon
  'lib/app/theme/',
];

/// dosya → (izinli sayı, gerekçe). 2026-11-12 sayımı.
const _allowed = <String, (int, String)>{
  'lib/features/auth/presentation/account_sheet.dart': (1, 'misafir hesap durumu simgesi'),
  'lib/features/auth/presentation/guest_backup_card.dart': (2, 'misafir yedek uyarısı kartı'),
  'lib/features/auth/presentation/login_screen.dart': (1, 'giriş ekranı misafir kartı'),
  'lib/features/calendar/presentation/calendar_screen.dart': (1, 'görev türü rengi (takvim lejantı)'),
  'lib/features/calendar/presentation/calendar_views.dart': (1, 'görev türü rengi (takvim)'),
  'lib/features/calendar/presentation/tasks_screen.dart': (1, 'yıldızlı görev — sabah bakılacak (secondary olmalı)'),
  'lib/features/folders/presentation/folder_sheets.dart': (2, 'renksiz klasör vurgusu'),
  'lib/features/folders/presentation/folder_tile.dart': (1, 'renksiz klasör vurgusu'),
  'lib/features/friends/presentation/friends_screen.dart': (1, 'arkadaş avatar paleti (ayırt etme)'),
  'lib/features/friends/presentation/home_invites.dart': (2, 'davet şeridi'),
  'lib/features/gmail/presentation/gmail_screen.dart': (4, 'gönderen avatar paleti + önemli/yıldız'),
  'lib/features/inbox/presentation/shared_hub_screen.dart': (1, 'paylaşılan merkez simgesi'),
  'lib/features/notes/presentation/dashboard_screen.dart': (1, 'P19 alanı (pano gövdesi)'),
  'lib/features/notes/presentation/dashboard_widgets.dart': (1, 'pano rozeti'),
  'lib/features/notes/presentation/editor/attachment_strip.dart': (2, 'editör — P36/P20 alanı'),
  'lib/features/notes/presentation/editor/items_editor_row.dart': (2, 'editör — P36/P20 alanı'),
  'lib/features/notes/presentation/editor/note_editor_parts.dart': (1, 'editör — P36/P20 alanı'),
  'lib/features/notes/presentation/editor/note_editor_screen.dart': (1, 'editör — P36/P20 alanı'),
  'lib/features/notes/presentation/editor/note_presence.dart': (1, 'birlikte düzenleme varlık rozeti'),
  'lib/features/notes/presentation/listening_visuals.dart': (2, 'AI dinleme kipi (AI kimliği)'),
  'lib/features/notes/presentation/note_card.dart': (2, 'kart — P35 alanı'),
  'lib/features/notes/presentation/note_card_media.dart': (3, 'kart ek türü rengi — P35 alanı'),
  'lib/features/notes/presentation/viewers/ink_layer.dart': (1, 'mürekkep katmanı rozeti'),
  'lib/features/settings/presentation/personalize_screen.dart': (1, 'kişiselleştirme önizlemesi'),
};

void main() {
  test('tertiary yalnız AI kimliğinde (izin listesi yalnız düşer)', () {
    final counts = <String, int>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final path = f.path.replaceAll('\\', '/');
      if (path.contains('/l10n/generated/')) continue;
      if (_free.any(path.startsWith)) continue;
      var n = 0;
      for (final line in f.readAsLinesSync()) {
        if (line.trimLeft().startsWith('//')) continue;
        n += _pattern.allMatches(line).length;
      }
      if (n > 0) counts[path] = n;
    }
    final errors = <String>[];
    counts.forEach((path, n) {
      final allowed = _allowed[path]?.$1 ?? 0;
      if (n > allowed) {
        errors.add('$path: $n tertiary (izin $allowed) — AI dışı yerde '
            'tertiary kullanma (DENEYIM §2.2)');
      }
    });
    _allowed.forEach((path, v) {
      final n = counts[path] ?? 0;
      if (n < v.$1) {
        errors.add('$path: $n < izin ${v.$1} — izin listesini $n\'e indir');
      }
    });
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  // F74.5: ana ekranda tek dolu birincil yüzey "+"; yanındaki mikrofon nötr.
  test('ana ekran mikrofonu nötr zeminde (primaryContainer değil)', () {
    final src = File(
      'lib/features/notes/presentation/dashboard_widgets.dart',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    final start = src.indexOf('class _DashVoiceButton');
    final body = src.substring(start, src.indexOf('\n}\n', start));
    expect(body.contains('scheme.surfaceContainerHigh'), isTrue);
    expect(body.contains('primaryContainer'), isFalse);
  });
}
