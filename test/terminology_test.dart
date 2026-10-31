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
