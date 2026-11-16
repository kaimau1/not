/// **SESLE BİTİR** (kullanıcı isteği 2026-11-16: "hızlı not ve akıllı liste
/// 'bitti'yi anlamalı, dinlemeyi bitirip notu oluşturmalı").
///
/// Konuşmanın SONUNDA söylenen bitiş sözü ("bitti", "bu kadar", "done")
/// dinlemeyi bitirir. Yalnız en sondaki söz sayılır: "bitti" ortada geçerse
/// (tanıyıcı cümleyi sürdürdükçe) bir şey olmaz.
const doneWords = <String>[
  'bu kadar',
  'liste bitti',
  'not bitti',
  'bitti',
  "that's all",
  'that is all',
  'finished',
  'done',
];

/// [text] bir bitiş sözüyle bitiyorsa o söz (ve sondaki noktalama)
/// atılmış metni döner; bitmiyorsa null.
String? stripDoneWord(String text) {
  final trimmed = text.trimRight().replaceFirst(RegExp(r'[\s.,!?;:…]+$'), '');
  final lower = _lower(trimmed);
  for (final w in doneWords) {
    if (lower == w) return '';
    if (lower.endsWith(' $w')) {
      return trimmed.substring(0, trimmed.length - w.length).trimRight();
    }
  }
  return null;
}

/// Türkçe büyük İ/I doğru küçülsün ("BİTTİ" → "bitti"); harf sayısı aynı
/// kalır (kesme konumları [stripDoneWord]'da geçerli).
String _lower(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
