import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **TASARIM BELİRTECİ MANDALI** (DENEYIM_PLANI F72.3). `lib/` içinde elle
/// yazılmış görsel değerleri (köşe, punto, süre, eğri, simge, saydamlık,
/// ağırlık, titreşim) sayar — `tool/design/token_sayim.py` ile AYNI desenler,
/// aynı atlamalar (yorum satırı, belirteç tanım dosyaları, `l10n/`).
///
/// Bütçe `test/design_tokens/budget.json`; yalnız DÜŞER:
///  * sayı > bütçe → yeni elle değer eklenmiş: `AppRadius` / `AppText` /
///    `AppMotion` / `AppIconSize` / `AppAlpha` / `AppWeight` kullan.
///  * sayı < bütçe → biri göç etmiş: bütçeyi yeni sayıya indir.
const _patterns = {
  'radius': r'(?:BorderRadius\.circular|Radius\.circular)\(\s*([0-9.]+)\s*\)',
  'fontSize': r'fontSize:\s*([0-9.]+)',
  'duration': r'Duration\(milliseconds:\s*([0-9]+)\)',
  'curve': r'Curves\.(\w+)',
  'iconSize': r'(?:\bsize:|iconSize:)\s*([0-9.]+)',
  'alpha': r'withValues\(alpha:\s*([0-9.]+)\)',
  'fontWeight': r'FontWeight\.(w\d+|bold)',
  'haptic': r'HapticFeedback\.(\w+)',
};

const _skipFiles = {
  'lib/app/theme/app_tokens.dart',
  'lib/app/theme/app_theme.dart',
  'lib/app/theme/app_palette.dart',
  'lib/app/theme/note_colors.dart',
  'lib/app/theme/note_themes.dart',
  'lib/app/theme/fixed_colors.dart',
  'lib/core/haptics.dart', // AppHaptics: titreşimin tek kaynağı (F77.2)
};

Map<String, int> countTokens(String root) {
  final counts = {for (final k in _patterns.keys) k: 0};
  final regs = {for (final e in _patterns.entries) e.key: RegExp(e.value)};
  for (final f in Directory(root).listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final p = f.path.replaceAll(r'\', '/');
    if (p.split('/').contains('l10n') || _skipFiles.contains(p)) continue;
    for (final line in f.readAsLinesSync()) {
      if (line.trimLeft().startsWith('//')) continue;
      for (final e in regs.entries) {
        counts[e.key] = counts[e.key]! + e.value.allMatches(line).length;
      }
    }
  }
  return counts;
}

void main() {
  test('elle yazılmış tasarım değerleri bütçeyi aşmaz, bütçe yalnız düşer', () {
    final budget = (jsonDecode(
      File('test/design_tokens/budget.json').readAsStringSync(),
    ) as Map<String, dynamic>).cast<String, int>();
    final now = countTokens('lib');
    expect(budget.keys.toSet(), _patterns.keys.toSet());

    final errors = <String>[];
    for (final k in _patterns.keys) {
      final n = now[k]!, b = budget[k]!;
      if (n > b) {
        errors.add(
          '$k: $n > bütçe $b — yeni elle değer: AppRadius/AppText/AppMotion/'
          'AppIconSize/AppAlpha/AppWeight kullan '
          '(döküm: python tool/design/token_sayim.py $k)',
        );
      } else if (n < b) {
        errors.add('$k: $n < bütçe $b — bütçeyi $n\'e indir (yalnız düşer)');
      }
    }
    expect(errors, isEmpty, reason: errors.join('\n'));
  });

  test('sayaç elle değeri yakalar, yorum satırını saymaz (bozma denemesi)', () {
    final dir = Directory.systemTemp.createTempSync('tokens');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/a.dart').writeAsStringSync(
      'final r = BorderRadius.circular(12);\n'
      '// fontSize: 14 yorumda\n'
      'const s = TextStyle(fontSize: 13, fontWeight: FontWeight.w700);\n',
    );
    final c = countTokens(dir.path);
    expect(c['radius'], 1);
    expect(c['fontSize'], 1);
    expect(c['fontWeight'], 1);
    expect(c['duration'], 0);
  });
}
