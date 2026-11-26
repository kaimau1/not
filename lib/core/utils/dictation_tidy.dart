/// **CİHAZ İÇİ DİKTE TEMİZLİĞİ** (kullanıcı isteği 2026-11-26: "sesle
/// konuşmamızda Claude / Antigravity yazıyı çok güzel düzelterek yapıyor,
/// bu seviyeye çıkabilir miyiz"). Saf Dart, ağ yok, model yok.
///
/// O uygulamalar konuşmayı sunucudaki büyük bir modelle yazıya döküp bir dil
/// modeliyle düzeltiyor; burada yapılabilen, cihaz tanıyıcısının çıktısını
/// kurallarla toparlamak:
///
/// * dolgu sesleri ("ııı", "eee", "hmm") atılır;
/// * noktalamanın önündeki boşluk silinir, ardına (harf geliyorsa) boşluk
///   konur ("3,5" ve "10:30" bozulmaz);
/// * soru ekiyle ("mı/mi/mu/mü", "musun", "miyiz" …) biten satıra "?" eklenir;
/// * cümle başı (metnin başı, `.!?` ya da satır sonundan sonrası) büyür;
/// * [item] (liste maddesi) satır sonundaki tek nokta atılır — Android 13+
///   otomatik noktalaması maddeye "Ekmek." yazmasın.
///
/// Her olayda HAM metinden baştan hesaplanır (bkz. `applyVoiceCommands`):
/// aynı girdi hep aynı çıktıyı verir, tanıyıcının sonraki düzeltmesiyle
/// çelişmez. Ortadaki özel adların büyük harfine dokunulmaz.
library;

/// [text]'i temizler. [before]: metnin YAZILACAĞI yerin öncesi (cümle başı
/// mı karar için); boşsa metin cümle başıdır.
String tidyDictation(String text, {String before = '', bool item = false}) {
  if (text.trim().isEmpty) return text;
  final lines = text.split('\n');
  final out = <String>[];
  for (var i = 0; i < lines.length; i++) {
    var line = _dropFillers(lines[i]);
    line = _spacePunctuation(line);
    if (item) line = _dropTrailingPeriod(line);
    line = _questionMark(line);
    final start = i == 0 ? _startsSentence(before) : true;
    if (start) line = _capitalize(line);
    line = _capitalizeAfterStops(line);
    out.add(line);
  }
  return out.join('\n');
}

/// Dolgu sesi mi ("ııı", "ıı", "eee", "eeh", "hmm", "mmm", "ıhh").
bool isDictationFiller(String token) {
  final w = token
      .replaceAll(RegExp(r'[^\p{L}]', unicode: true), '')
      .replaceAll('I', 'ı')
      .toLowerCase();
  if (w.isEmpty) return false;
  return _filler.hasMatch(w);
}

final _filler = RegExp(r'^(ı{2,}h*|e{3,}h*|ee+h+|ıh+|h+m{2,}|m{3,}|hı+m+)$');

String _dropFillers(String line) {
  if (line.trim().isEmpty) return line;
  final tokens = line.split(' ');
  final kept = <String>[];
  for (final t in tokens) {
    if (t.isNotEmpty && isDictationFiller(t)) continue;
    kept.add(t);
  }
  if (kept.length == tokens.length) return line;
  return kept.join(' ').replaceAll(RegExp(r' {2,}'), ' ').trim();
}

String _spacePunctuation(String line) {
  var s = line.replaceAllMapped(RegExp(r'\s+([,.;:!?…])'), (m) => m[1]!);
  // Ardından harf gelen noktalamaya boşluk ("3,5" / "10:30" / "a.b.c"
  // kısaltmaları korunur: yalnız virgül/noktalı virgül/ünlem/soru ve
  // sözcükten sonra gelen iki nokta).
  s = s.replaceAllMapped(
    RegExp(r'([,;!?])(\p{L})', unicode: true),
    (m) => '${m[1]} ${m[2]}',
  );
  s = s.replaceAll(RegExp(r',{2,}'), ',');
  s = s.replaceAll(RegExp(r'^[,;]\s*'), '');
  return s.replaceAll(RegExp(r' {2,}'), ' ');
}

String _dropTrailingPeriod(String line) {
  final t = line.trimRight();
  if (t.endsWith('.') && !t.endsWith('..')) {
    return t.substring(0, t.length - 1);
  }
  return line;
}

/// Soru eki (+ kişi eki) kelimesi.
final _questionParticle = RegExp(
  r'^(m[ıiuü])(y[ıiuü]m|s[ıiuü]n|y[ıiuü]z|s[ıiuü]n[ıiuü]z|d[ıiuü]r|yd[ıiuü]|ym[ıiuü]ş)?$',
);

String _questionMark(String line) {
  final t = line.trimRight();
  if (t.isEmpty) return line;
  if ('.,;:!?…'.contains(t[t.length - 1])) return line;
  final words = t.split(' ');
  if (words.length < 2) return line;
  final w = words.last.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  if (!_questionParticle.hasMatch(w)) return line;
  return '$t?';
}

bool _startsSentence(String before) {
  final t = before.trimRight();
  if (t.isEmpty) return true;
  if (before.endsWith('\n')) return true;
  return '.!?'.contains(t[t.length - 1]);
}

String _capitalize(String s) {
  final i = s.indexOf(RegExp(r'\p{L}', unicode: true));
  if (i < 0) return s;
  // Baştaki harften önce yalnız boşluk/tırnak/açılan ayraç olabilir.
  if (s.substring(0, i).trim().replaceAll(RegExp('["“(«‘\']'), '').isNotEmpty) {
    return s;
  }
  final c = s[i];
  final upper = switch (c) {
    'i' => 'İ',
    'ı' => 'I',
    _ => c.toUpperCase(),
  };
  return '${s.substring(0, i)}$upper${s.substring(i + 1)}';
}

/// Satır içinde `.!?` + boşluktan sonraki harf büyür ("tamam. yarın" →
/// "tamam. Yarın"). Rakamdan sonraki nokta (sıra sayısı, "3. kat") hariç.
String _capitalizeAfterStops(String line) => line.replaceAllMapped(
  RegExp(r'(^|[^\d])([.!?]) (\p{Ll})', unicode: true),
  (m) {
    final c = m[3]!;
    final up = switch (c) {
      'i' => 'İ',
      'ı' => 'I',
      _ => c.toUpperCase(),
    };
    return '${m[1]}${m[2]} $up';
  },
);
