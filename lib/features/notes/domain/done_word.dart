/// **SESLE BİTİR** (kullanıcı isteği 2026-11-16: "hızlı not ve akıllı liste
/// 'bitti'yi anlamalı, dinlemeyi bitirip notu oluşturmalı").
///
/// Konuşmanın SONUNDA söylenen bitiş sözü ("bitti", "bu kadar", "done")
/// dinlemeyi bitirir. Yalnız en sondaki söz sayılır: "bitti" ortada geçerse
/// (tanıyıcı cümleyi sürdürdükçe) bir şey olmaz.
///
/// **H1 (17K §4.1):** "süt bitti" gibi cümlelerde yalın "bitti"/"done"/
/// "finished" sözü konuşmanın devamıdır. [parseDoneWord] bunları `bare: true`
/// olarak işaretler: ses oturumunda yalnızca kendinden önce ~0,7 sn sessizlik
/// varsa bitiş sayılır; çok kelimeli açık komutlar ("liste bitti", "bu kadar",
/// "not bitti") ve tek başına söylenen "bitti" her zaman bitiş sayılır.
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

const _bareDoneWords = {'bitti', 'finished', 'done'};

/// [text] bir bitiş sözüyle bitiyorsa o söz atılmış [rest] metnini ve bunun
/// bağlama duyarlı yalın tek söz olup olmadığını ([bare]) döner; bitmiyorsa
/// null.
({String rest, bool bare})? parseDoneWord(String text) {
  final trimmed = text.trimRight().replaceFirst(RegExp(r'[\s.,!?;:…]+$'), '');
  final lower = _lower(trimmed);
  for (final w in doneWords) {
    if (lower == w) return (rest: '', bare: false);
    if (lower.endsWith(' $w')) {
      final rest = trimmed.substring(0, trimmed.length - w.length).trimRight();
      return (rest: rest, bare: rest.isNotEmpty && _bareDoneWords.contains(w));
    }
  }
  return null;
}

/// [text] bir bitiş sözüyle bitiyorsa o söz (ve sondaki noktalama)
/// atılmış metni döner; bitmiyorsa null.
String? stripDoneWord(String text) => parseDoneWord(text)?.rest;

/// Türkçe büyük İ/I doğru küçülsün ("BİTTİ" → "bitti"); harf sayısı aynı
/// kalır (kesme konumları [parseDoneWord]'da geçerli).
String _lower(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
