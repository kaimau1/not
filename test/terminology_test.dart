import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// **TERİM SÖZLÜĞÜ** (F14.1, bkz. `TERIMLER.md`): Türkçe metinlerde tek ad,
/// tek hitap. Yeni bir metin yasaklı yazımı geri getirirse burada kırılır.
void main() {
  final arb = jsonDecode(
    File('lib/l10n/app_tr.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  final texts = {
    for (final e in arb.entries)
      // Yer tutucular ({size}…) metin değil.
      if (!e.key.startsWith('@') && e.value is String)
        e.key: (e.value as String).replaceAll(RegExp(r'\{\w+\}'), ''),
  };

  List<String> offenders(RegExp pattern) => [
    for (final e in texts.entries)
      if (pattern.hasMatch(e.value)) '${e.key}: ${e.value}',
  ];

  test('"Yapay zekâ" tek yazım (şapkalı, cümle düzeninde)', () {
    expect(offenders(RegExp('[Yy]apay [Zz]eka|Yapay Zekâ')), isEmpty);
  });

  test('liste satırı "madde" — "öğe" yok', () {
    expect(offenders(RegExp('öğe', caseSensitive: false)), isEmpty);
  });

  test('hep "sen" — "siz" hitabı ve -ın/-in emri yok', () {
    // Çoğul emir: dokunun, seçin, yazın, açın, gizleyin, basın…
    // `\b` ASCII'dir ("yazının"daki "ı"yı sınır sayar) — harf sınırı
    // Unicode bakışla.
    RegExp word(String alternatives) =>
        RegExp('(?<!\\p{L})($alternatives)(?!\\p{L})', unicode: true);
    final imperative = word(
      'dokunun|seçin|yazın|açın|kapatın|gizleyin|gösterin|basın|'
      'değiştirin|deneyin|ekleyin|bekleyin|girin|silin|kaydedin|'
      'konuşun|tutun|sürükleyin|kullanın|bakın|tıklayın|Lütfen',
    );
    expect(offenders(imperative), isEmpty);
    expect(offenders(word('siz|sizin|size|sizi')), isEmpty);
    expect(
      offenders(RegExp(r'\w+(ebilirsiniz|abilirsiniz|nızda|nizde)\b')),
      isEmpty,
    );
  });

  test('F42.5: cümlede "yapay zekâ", "AI" yalnız kısa yerde', () {
    // "AI sesli not" terimin adı (TERİMLER), cümlede de öyle kalır.
    final ai = RegExp(r'(?<!\p{L})AI(?!\p{L})', unicode: true);
    expect(
      [
        for (final e in texts.entries)
          if (e.value.length >= 60 &&
              ai.hasMatch(e.value.replaceAll('AI sesli not', '')))
            '${e.key}: ${e.value}',
      ],
      isEmpty,
    );
  });

  test('F42.3: lib/ içinde sabit Türkçe kullanıcı metni yok', () {
    // Bilinçli istisna: setup_required_screen Firebase'siz derlemede geliştirici
    // ekranı, l10n'dan önce ve son kullanıcıya hiç görünmez.
    final hardcoded = RegExp(
      r'''(?:\bText\(\s*|\b(?:label|tooltip|title|hintText|labelText|subtitle|'''
      r'''helperText|message|semanticLabel)\s*:\s*|showMessage\(\s*|'''
      r'''_showSnack\(\s*|_snack\(\s*|GeminiException\(\s*)(?:const\s+)?'''
      r'''(['"])(?:(?!\1).)*[çğıöşüÇĞİÖŞÜ](?:(?!\1).)*\1''',
    );
    final found = <String>[];
    for (final f in Directory('lib').listSync(recursive: true)) {
      final path = f.path.replaceAll('\\', '/');
      if (f is! File ||
          !path.endsWith('.dart') ||
          path.contains('l10n/generated') ||
          path.endsWith('setup_required_screen.dart')) {
        continue;
      }
      for (final m in hardcoded.allMatches(f.readAsStringSync())) {
        found.add('$path: ${m[0]}');
      }
    }
    expect(found, isEmpty);
  });

  test('ses ve kopya ailesi tek adla; eski "arşiv defteri" yok', () {
    expect(
      offenders(
        RegExp(
          'Sesle yazdır|Sesli yazdır|sesli yazdırma|Sesli oku\\b|'
          'Kopya gönder|[Aa]rşiv defter|Belge gibi not al',
        ),
      ),
      isEmpty,
    );
  });
}
