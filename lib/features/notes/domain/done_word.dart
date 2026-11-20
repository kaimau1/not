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

/// YALIN bitiş sözleri: içerikte de geçer ("süt bitti" = süt kalmadı, "rapor
/// bitti"). Konuşmada tek başına kesin bitiş sayılmaz (H1, bkz.
/// [matchDoneWord]); öbürleri ("bu kadar", "liste bitti") hep bitiştir.
const _bareDoneWords = {'bitti', 'finished', 'done'};

/// [text] bir bitiş sözüyle bitiyorsa o söz (ve sondaki noktalama)
/// atılmış metni döner; bitmiyorsa null.
String? stripDoneWord(String text) => matchDoneWord(text)?.rest;

/// [stripDoneWord] + sözün türü. [bare]: yalın söz ("bitti") ve önünde
/// içerik var — konuşma sürerse içeriğin parçasıdır ("süt bitti, ekmek…").
/// Ses tanıma noktalama vermediği için "süt ekmek bitti" ile "süt bitti"
/// metinden ayrılamaz; karar konuşmanın ZAMANINDAN verilir (QuickEntryBar:
/// önünde duraklama varsa ya da ardından konuşma gelmezse bitiş).
({String rest, bool bare})? matchDoneWord(String text) {
  final trimmed = text.trimRight().replaceFirst(RegExp(r'[\s.,!?;:…]+$'), '');
  final lower = _lower(trimmed);
  for (final w in doneWords) {
    if (lower == w) return (rest: '', bare: false);
    if (lower.endsWith(' $w')) {
      return (
        rest: trimmed.substring(0, trimmed.length - w.length).trimRight(),
        bare: _bareDoneWords.contains(w),
      );
    }
  }
  return null;
}

/// Türkçe büyük İ/I doğru küçülsün ("BİTTİ" → "bitti"); harf sayısı aynı
/// kalır (kesme konumları [stripDoneWord]'da geçerli).
String _lower(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
