import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/antalia/antalia_text.dart';

/// Antalia metin normalleştiricisinin Dart portu, tarayıcı portunun
/// diferansiyel örnekleriyle (beklenen = orijinal Python `to_model_text`
/// çıktısı) birebir eşleşmeli. Sözlükler örneklerde geçen kelimelere
/// indirgenmiş alt kümedir (tam sözlük ~2,6 MB, uygulama indirir).
void main() {
  final data = jsonDecode(
    File('test/fixtures/antalia_text_cases.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final dicts = data['dicts'] as Map<String, dynamic>;

  setUpAll(() {
    AntaliaText.setData(
      foreign: (dicts['foreign'] as Map).cast<String, String>(),
      parts: (dicts['parts'] as Map).cast<String, String>(),
      known: (dicts['known'] as List).cast<String>(),
      englishI: (dicts['englishI'] as List).cast<String>(),
    );
  });
  tearDownAll(AntaliaText.setData);

  group('toModelText = Python', () {
    final cases = data['cases'] as List;
    for (var i = 0; i < cases.length; i++) {
      final c = cases[i] as Map<String, dynamic>;
      final input = c['input'] as String;
      test('[$i] ${input.length > 48 ? input.substring(0, 48) : input}', () {
        expect(AntaliaText.toModelText(input), c['expected']);
      });
    }
  });

  test('sözlük yokken de sayılar okunur', () {
    AntaliaText.setData();
    expect(
      AntaliaText.toModelText('Saat 14:30, 1.250,75 TL.'),
      'saat on dört otuz, bin iki yüz elli lira yetmiş beş kuruş.',
    );
  });

  test('encode: <bos> harfler <eos>, tablo dışı harf atılır', () {
    final ids = AntaliaText.encode('ab ç');
    expect(ids.first, AntaliaText.bos);
    expect(ids.last, AntaliaText.eos);
    expect(ids.length, 6);
    expect(AntaliaText.symbols.length, 47); // config.json n_symbols
  });

  test('splitModelText: ilk parça kısa, sonrakiler 250', () {
    final text = List.filled(12, 'bu bir deneme cümlesidir.').join(' ');
    final parts = AntaliaText.splitModelText(text);
    expect(parts.first.length, lessThanOrEqualTo(80));
    expect(parts.skip(1).every((p) => p.length <= 250), isTrue);
    expect(parts.join(' '), text);
  });

  test('capLength: noktasız uzun satır virgülden bölünür', () {
    final long = List.filled(30, 'elma, armut').join(' ');
    final parts = AntaliaText.capLength(long);
    expect(parts.every((p) => p.length <= 250), isTrue);
    expect(parts.join(' '), long);
  });
}
