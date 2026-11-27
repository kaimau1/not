part of 'rich_text.dart';

/// Seçime biçim uygular ya da zaten uygulanmışsa KALDIRIR (aç/kapa).
///
/// [start]/[end] İŞARETLİ metindeki konumlardır; dönen değer yeni metin ve
/// yeni seçimdir. Seçim, biçim uygulandıktan sonra da AYNI metnin üstünde
/// kalır — kullanıcı arka arkaya kalın + renk verebilir.
///
/// Word mantığı: seçim yokken imleç biçimli bir parçanın içindeyse aynı düğme
/// o parçanın biçimini KALDIRIR; değilse imlece boş bir biçim kutusu açılır
/// (yazmaya devam edilince yazılan biçimli çıkar).
/// [pending] doluysa METİN DEĞİŞMEZ: çağıran, bu biçmi "bir sonraki yazılan
/// metne uygulanacak" olarak saklamalıdır (bkz. WrapTextController.pending…).
/// Eskiden burada metne boş kutu (`~~`, `__`) yazılıyordu; kullanıcı içine bir
/// şey yazmazsa o işaretler notta ham markdown olarak kalıyordu — italik ve
/// altı çizili kutuları gizleme kalıbında olmadığı için EKRANDA da görünüyordu
/// (kullanıcı: "bu tür markdownlar asla görünmemeli"). Kutuyu hiç yazmamak,
/// hem çöpü hem de `__init__` gibi gerçek metni kırpma riskini bitirir.
({String text, int start, int end, RichFormat? pending, int? pendingIndex})
toggleFormat(
  String text,
  int start,
  int end,
  RichFormat format, {
  int? colorIndex,
}) {
  if (start < 0 || end > text.length || end < start) {
    return (
      text: text,
      start: start,
      end: end,
      pending: null,
      pendingIndex: null,
    );
  }
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);

  if (ps == pe) {
    final mark = _markAt(segments, ps);
    if (mark.has(format)) {
      final index = mark.indexOf(format);
      final recolor =
          _takesIndex(format) && colorIndex != null && index != colorIndex;
      final run = _runAround(segments, ps, format, index);
      final updated = _mapRange(
        segments,
        run.start,
        run.end,
        (m) => recolor ? m.applied(format, colorIndex) : m.removed(format),
      );
      final out = _serialize(updated);
      final caret = out.starts[ps.clamp(0, out.starts.length - 1)];
      return (
        text: out.text,
        start: caret,
        end: caret,
        pending: null,
        pendingIndex: null,
      );
    }
    // KÖK NEDEN (kullanıcı: "kelimenin içine tıklayıp işlem yapınca yine
    // markdown üretiliyor"): imleç bir kelimenin ORTASINDAyken boş kutu
    // açmak ham işaret bırakıyordu. `_` ve `~` çözümleyicide kelime içinde
    // SAYILMIYOR (bkz. _formatPattern'daki (?<!\w)/(?!\w) koşulları), yani
    // "merh__aba" hiçbir zaman italiğe dönüşmüyor — kullanıcı notunda ham
    // alt çizgi görüyor. `**` çözümleniyor ama o da kelimeyi "merh****aba"
    // diye ikiye bölüyor.
    //
    // Doğru davranış Word ve Docs'ta olan: imleç kelimenin içindeyse biçim
    // KELİMENİN TAMAMINA uygulanır. Kelime başında/sonunda ya da boşlukta
    // imleç eski davranışta kalır (boş kutu = "biçimli yazmaya başla").
    final plain = [for (final seg in segments) seg.text].join();
    final word = _wordAround(plain, ps);
    if (word != null) {
      final updated = _mapRange(
        segments,
        word.start,
        word.end,
        (m) => m.applied(format, colorIndex),
      );
      final out = _serialize(updated);
      return (
        text: out.text,
        start: out.starts[word.start.clamp(0, out.starts.length - 1)],
        end: out.ends[word.end.clamp(0, out.ends.length - 1)],
        pending: null,
        pendingIndex: null,
      );
    }

    // Biçimsiz imleç (kelime başı/sonu ya da boşluk): metne DOKUNULMAZ, biçim
    // "bekleyen" olarak çağırana bildirilir; bir sonraki yazılan metin doğrudan
    // işaretlerin içine girer.
    return (
      text: text,
      start: start,
      end: end,
      pending: format,
      pendingIndex: colorIndex,
    );
  }

  final remove = _rangeHasFormat(segments, ps, pe, format, colorIndex);
  // KELİME SINIRI (2026-08-07 / 14. tur): italik (`_`) ve altı çizili (`~`)
  // işaretleri kalıpta "iki yanında harf/rakam olmasın" şartı taşıyor. Seçim
  // bir kelimenin ORTASINDAN başlıyor ya da ortasında bitiyorsa yazılan
  // işaret hiç EŞLEŞMEZ ve ekranda HAM alt çizgi/tilde olarak görünür
  // ("mer_haba du_nya"). Uygulama aralığı kelime sınırına genişletir —
  // Word'de de kelime ortasından seçip italik yapmak kelimeyi biçimler.
  var from = ps;
  var to = pe;
  if (!remove && richFormatNeedsWordBoundary(format)) {
    final plain = [for (final seg in segments) seg.text].join();
    while (from > 0 && isRichWordChar(plain[from - 1])) {
      from--;
    }
    while (to < plain.length && isRichWordChar(plain[to])) {
      to++;
    }
  }
  final updated = _mapRange(
    segments,
    from,
    to,
    (m) => remove ? m.removed(format) : m.applied(format, colorIndex),
  );
  final out = _serialize(updated);
  return (
    text: out.text,
    start: out.starts[from.clamp(0, out.starts.length - 1)],
    end: out.ends[to.clamp(0, out.ends.length - 1)],
    pending: null,
    pendingIndex: null,
  );
}

/// Seçimdeki TÜM biçimleri kaldırır (Word'ün "biçimlendirmeyi temizle"si).
({String text, int start, int end}) clearFormat(
  String text,
  int start,
  int end,
) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  var ps = _toPlain(leaves, start);
  var pe = _toPlain(leaves, end);
  // Seçim yoksa imlecin içinde bulunduğu biçimli parça temizlenir.
  if (ps == pe) {
    final range = _plainRunAt(segments, ps);
    ps = range.start;
    pe = range.end;
  }
  if (ps == pe) return (text: text, start: start, end: end);
  final out = _serialize(_mapRange(segments, ps, pe, (_) => RichMark.none));
  return (
    text: out.text,
    start: out.starts[ps.clamp(0, out.starts.length - 1)],
    end: out.ends[pe.clamp(0, out.ends.length - 1)],
  );
}

/// Kelime karakteri: harf, rakam, alt çizgi — Türkçe harfler DAHİL.
///
/// `\w` KULLANILMAZ: Dart'ta unicode bayrağı olmadan `\w` yalnız `[A-Za-z0-9_]`
/// demektir ve "çalışma" gibi bir kelimede "ş"yi kelime karakteri saymaz.
/// Kelime sınırı Türkçe metinde ASCII'ye göre farklı çıkarsa aynı tıklama
/// kelimeden kelimeye başka davranırdı.
final RegExp _wordChar = RegExp(r'[\p{L}\p{N}_]', unicode: true);

/// İmleç bir KELİMENİN İÇİNDEyse o kelimenin aralığı, değilse null.
///
/// "İçinde" = iki yanında da kelime karakteri var. Kelimenin başında ya da
/// sonundaki imleç null döner: orada boş biçim kutusu açmak doğru davranıştır
/// (kullanıcı biçimli yazmaya başlamak istiyordur).
({int start, int end})? _wordAround(String plain, int at) {
  if (at <= 0 || at >= plain.length) return null;
  if (!_wordChar.hasMatch(plain[at - 1]) || !_wordChar.hasMatch(plain[at])) {
    return null;
  }
  var start = at, end = at;
  while (start > 0 && _wordChar.hasMatch(plain[start - 1])) {
    start--;
  }
  while (end < plain.length && _wordChar.hasMatch(plain[end])) {
    end++;
  }
  return (start: start, end: end);
}

/// İmleci içeren, biçimi aynı olan kesintisiz parça (biçimsizse boş aralık).
({int start, int end}) _plainRunAt(List<RichSegment> segments, int plain) {
  var pos = 0;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (plain >= start && plain <= end && !seg.mark.isEmpty) {
      return (start: start, end: end);
    }
  }
  return (start: plain, end: plain);
}

/// Aralığa bir biçimi DOĞRUDAN yazar (aç/kapa değil).
///
/// Boyut ve opaklık kaydırıcıları bunu kullanır: sürüklenen değer neyse o
/// uygulanır. [index] null ise biçim aralıktan KALDIRILIR (kaydırıcı notun
/// kendi değerine dönünce işaret yazmanın anlamı yok).
({String text, int start, int end}) setRangeFormat(
  String text,
  int start,
  int end,
  RichFormat format,
  int? index,
) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);
  if (ps == pe) return (text: text, start: start, end: end);
  final updated = _mapRange(
    segments,
    ps,
    pe,
    (m) => index == null ? m.removed(format) : m.applied(format, index),
  );
  final out = _serialize(updated);
  return (
    text: out.text,
    start: out.starts[ps.clamp(0, out.starts.length - 1)],
    end: out.ends[pe.clamp(0, out.ends.length - 1)],
  );
}

/// Satır başlığı düzeyi (bkz. [setLineHeading]).
enum RichHeading {
  /// Büyük başlık: boy kademesi 7 (×1,6) + kalın.
  h1(7),

  /// Alt başlık: boy kademesi 6 (×1,4) + kalın.
  h2(6),

  /// Düz metin: boy ve kalınlık kaldırılır.
  normal(null);

  const RichHeading(this.sizeStep);

  /// [kRichSizeSteps] içindeki 1 tabanlı kademe; null = notun kendi boyu.
  final int? sizeStep;
}

/// İmlecin (ya da seçimin dokunduğu) SATIR(LAR)I başlık yapar.
///
/// Kullanıcı isteği 2026-09-23 ("başlık ve alt başlık"): yeni bir işaret
/// eklenmedi — başlık, zaten var olan iki biçimin birleşimi: satırın
/// TAMAMINA boy kademesi + kalın. Böylece eski sürümler, kartlar, PDF/Word
/// dışa aktarımı ve arama başlığı hiçbir değişiklik olmadan doğru çizer.
///
/// Seçim yoksa imlecin satırı alınır; boş satırda hiçbir şey yapılmaz (boş
/// işaret çifti yazılmaz). Dönen aralık: seçim vardıysa satırların tamamı,
/// yoksa satırın sonunda duran imleç.
({String text, int start, int end}) setLineHeading(
  String text,
  int start,
  int end,
  RichHeading heading,
) {
  if (start < 0 || end > text.length || end < start) {
    return (text: text, start: start, end: end);
  }
  final lineStart = start == 0 ? 0 : text.lastIndexOf('\n', start - 1) + 1;
  final nl = text.indexOf('\n', end);
  final lineEnd = nl < 0 ? text.length : nl;
  if (lineEnd <= lineStart) return (text: text, start: start, end: end);
  final sized = setRangeFormat(
    text,
    lineStart,
    lineEnd,
    RichFormat.size,
    heading.sizeStep,
  );
  final bolded = setRangeFormat(
    sized.text,
    sized.start,
    sized.end,
    RichFormat.bold,
    heading == RichHeading.normal ? null : 1,
  );
  final collapsed = start == end;
  return (
    text: bolded.text,
    start: collapsed ? bolded.end : bolded.start,
    end: bolded.end,
  );
}

/// İmlecin satırının başlık düzeyi (biçim çubuğundaki vurgu için).
RichHeading lineHeadingAt(String text, int caret) {
  if (caret < 0 || caret > text.length) return RichHeading.normal;
  final lineStart = caret == 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
  final nl = text.indexOf('\n', caret);
  final lineEnd = nl < 0 ? text.length : nl;
  if (lineEnd <= lineStart) return RichHeading.normal;
  final size = rangeFormatIndex(text, lineStart, lineEnd, RichFormat.size);
  for (final h in RichHeading.values) {
    if (h.sizeStep != null && h.sizeStep == size) return h;
  }
  return RichHeading.normal;
}

/// Aralıktaki metnin ortak [format] indeksi (hepsi aynı değilse null).
int? rangeFormatIndex(String text, int start, int end, RichFormat format) {
  if (start < 0 || end > text.length || end < start) return null;
  final leaves = _parse(text);
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final ps = _toPlain(leaves, start);
  final pe = _toPlain(leaves, end);
  int? found;
  var first = true;
  var pos = 0;
  for (final seg in segments) {
    final segStart = pos;
    final segEnd = pos + seg.text.length;
    pos = segEnd;
    if (segEnd <= ps || segStart >= pe) continue;
    final index = seg.mark.indexOf(format);
    if (first) {
      found = index;
      first = false;
    } else if (found != index) {
      return null;
    }
  }
  return found;
}

/// İmleci GÖRÜNMEZ işaretlerin içinden çıkarır.
///
/// İşaretler artık çizilmediği için imlecin onların arasında durması
/// kullanıcıya "imleç kıpırdamıyor" ya da "geri silme çalışmıyor" gibi
/// görünürdü (silinen şey görünmeyen bir yıldızdı). Konum, gerçek bir
/// karakterin sınırına çekilir; [backward] geriye giderken sola, ileri
/// giderken sağa öncelik verir.
///
/// Boş biçim kutusunun (`****`) içi ÖZELDİR: orası çözümlemede düz metin
/// sayıldığı için imleç orada kalır — kullanıcı yazmaya başlayınca yazdığı
/// biçimli çıksın diye.
int snapOutOfMarkers(String text, int offset, {bool backward = false}) {
  if (offset <= 0 || offset >= text.length) return offset;
  if (!_hasMarker(text)) return offset;
  final leaves = _parse(text);
  if (leaves.isEmpty) return offset;
  int? before;
  int? after;
  for (final leaf in leaves) {
    final start = leaf.markedStart;
    final end = start + leaf.text.length;
    if (offset >= start && offset <= end) return offset;
    if (end < offset) before = end;
    if (start > offset) {
      after = start;
      break;
    }
  }
  // Metnin başı ve sonu da geçerli birer sınırdır: baştaki işaretin ortasından
  // geriye giden imleç 0'a, sondakinden ileri giden imleç metnin sonuna gider.
  if (backward) return before ?? 0;
  return after ?? text.length;
}

/// İşaretli metnin GÖRÜNEN parçalarının `[başlangıç, bitiş)` aralıkları —
/// işaretli metindeki konumlarla. İşaret yoksa tek aralık: metnin tamamı.
///
/// Not içi aramanın (bkz. `TextSearchIndex`) eşleşmeyi işaretlerin
/// ARASINDAN geçerek bulabilmesi için: "**sü**t" ekranda "süt" okunur.
List<(int, int)> visibleRuns(String marked) {
  if (!_hasMarker(marked)) return [(0, marked.length)];
  return [
    for (final leaf in _parse(marked))
      (leaf.markedStart, leaf.markedStart + leaf.text.length),
  ];
}

/// [index] konumundaki karakter GÖRÜNMEZ bir işaretin parçası mı?
bool isMarkerOffset(String text, int index) {
  if (index < 0 || index >= text.length) return false;
  if (!_hasMarker(text)) return false;
  for (final leaf in _parse(text)) {
    if (index >= leaf.markedStart &&
        index < leaf.markedStart + leaf.text.length) {
      return false;
    }
  }
  return true;
}

/// Görünmez işaretin üstünde geri silme: işaret yerine imlecin solundaki
/// GERÇEK karakteri siler.
///
/// KÖK NEDEN (v1.0.182): işaretler görünmez çizildiğinden imleç biçimli
/// metnin sonunda aslında kapanış işaretinin ARDINDA duruyordu; geri silme
/// önce o işaretleri tek tek siliyor, ilk silmede biçim bozulduğu için
/// kalanlar bir anda EKRANDA BELİRİYORDU ("işaretler geldi, tek tek
/// siliniyor"). Artık silme metnin kendisine iner ve biçim korunur; son harf
/// de silinince boş kalan işaret çifti kendiliğinden düşer.
({String text, int caret})? deleteThroughMarkers(String text, int caret) {
  if (caret <= 0 || caret > text.length) return null;
  final leaves = _parse(text);
  if (leaves.isEmpty) return null;
  final segments = [
    for (final leaf in leaves) RichSegment(leaf.text, leaf.mark),
  ];
  final plainCaret = _toPlain(leaves, caret);
  if (plainCaret <= 0) {
    // Silinecek gerçek karakter yok (imleç metnin başındaki işaretlerin
    // içinde): metne dokunma, imleci başa al.
    final out = _serialize(segments);
    return (text: out.text, caret: out.starts.first);
  }
  final updated = <RichSegment>[];
  var pos = 0;
  for (final seg in segments) {
    final start = pos;
    final end = pos + seg.text.length;
    pos = end;
    if (plainCaret - 1 < start || plainCaret - 1 >= end) {
      updated.add(seg);
      continue;
    }
    final at = plainCaret - 1 - start;
    updated.add(
      RichSegment(
        seg.text.substring(0, at) + seg.text.substring(at + 1),
        seg.mark,
      ),
    );
  }
  final out = _serialize(updated);
  final index = (plainCaret - 1).clamp(0, out.ends.length - 1);
  return (text: out.text, caret: out.ends[index]);
}

/// İmlecin İKİ YANINDA kalan boş işaret çiftlerini siler.
///
/// KÖK NEDEN (v1.0.185): biçimli bir kelimenin son harfi silinince geriye
/// iç içe geçmiş BOŞ işaretler kalıyor (`%%1:**_` + `_**%%`). Bunların içi
/// boş olduğu için hiçbiri biçim olarak eşleşmiyor ve düz metin gibi
/// ÇİZİLİYORLAR — kullanıcı sildikçe yeni işaretler beliriyormuş gibi
/// görünüyordu. Silmeden sonra imlecin iki yanı eşleşen açılış/kapanış
/// işaretiyse çift kaldırılır; içteki gidince dıştaki yan yana geldiği için
/// döngü hepsini toplar.
///
/// Yalnız İMLECİN YANINA bakar: metnin başka yerindeki `__` gibi diziler
/// (kullanıcının yazdığı olabilir) korunur.
({String text, int caret}) collapseEmptyMarkersAt(String text, int caret) {
  var out = text;
  var at = caret.clamp(0, text.length);
  var changed = true;
  while (changed) {
    changed = false;
    for (final format in RichFormat.values) {
      final close = format.marker;
      if (!out.startsWith(close, at)) continue;
      // Açılış işareti: düz (`**`) ya da kademe önekli (`%%3:`).
      final head = out.substring(0, at);
      var openStart = -1;
      if (head.endsWith(close)) {
        openStart = at - close.length;
      } else {
        final prefixed = RegExp(
          '${RegExp.escape(close)}(\\d:)\$',
        ).firstMatch(head);
        if (prefixed != null) openStart = prefixed.start;
      }
      if (openStart < 0) continue;
      out = out.replaceRange(at, at + close.length, '');
      out = out.replaceRange(openStart, at, '');
      at = openStart;
      changed = true;
      break;
    }
  }
  return (text: out, caret: at);
}

/// Biçim kapsamı için metin uzayı seçimi (düz metinde sınırlar bulunur).
enum RichScopeKind { word, line, all }

int _plainToLogicalLeaves(
  List<_Leaf> leaves,
  int plainOffset, {
  bool preferEnd = false,
}) {
  if (leaves.isEmpty) return 0;
  final plainLen = leaves.fold<int>(0, (sum, l) => sum + l.text.length);
  final target = plainOffset.clamp(0, plainLen);
  var plainCursor = 0;
  for (final leaf in leaves) {
    final nextPlain = plainCursor + leaf.text.length;
    if (target < plainCursor) return leaf.markedStart;
    if (target == plainCursor && !preferEnd) return leaf.markedStart;
    if (target < nextPlain) return leaf.markedStart + (target - plainCursor);
    if (target == nextPlain && preferEnd) {
      return leaf.markedStart + leaf.text.length;
    }
    plainCursor = nextPlain;
  }
  final last = leaves.last;
  return last.markedStart + last.text.length;
}

/// [markedText] içindeki [markedOffset] konumunu DÜZ metin uzayına çevirir.
int logicalToPlainOffset(String markedText, int markedOffset) {
  final leaves = _parse(markedText);
  if (leaves.isEmpty) return 0;
  return _toPlain(leaves, markedOffset.clamp(0, markedText.length));
}

/// DÜZ metindeki [plainOffset] konumunu [markedText] içindeki işaretli konuma
/// çevirir.
///
/// [preferEnd] `true` iken iki yaprak sınırında ya da bir biçim kutusunun
/// sağ ucunda kapanış işaretinden ÖNCEKİ (biçimli metnin içindeki) konumu
/// döndürür — seçim sonu ve biçim içi imleç koruması için kullanılır.
int plainToLogicalOffset(
  String markedText,
  int plainOffset, {
  bool preferEnd = false,
}) => _plainToLogicalLeaves(_parse(markedText), plainOffset, preferEnd: preferEnd);

/// [markedText] içindeki [markedCaret] konumunu DÜZ metne indirgeyip [kind]
/// kapsamını ([word]/[line]/[all]) çözer ve işaretli aralığı döndürür.
///
/// KÖK NEDEN: eskiden kapsam seçimi ham işaretli metinde `isRichWordChar`
/// arıyordu; `_` italik işaretiyle çarpışıyor, `%%k:` / `##k:` ise sınırı
/// bölüyordu. Düz metin uzayı işaretlerden tamamen bağımsızdır.
({int start, int end, int plainCaret})? richScopeRange(
  String markedText,
  int markedCaret,
  RichScopeKind kind,
) {
  if (markedText.isEmpty) return null;
  final leaves = _parse(markedText);
  if (leaves.isEmpty) return null;
  final plain = [for (final l in leaves) l.text].join();
  if (plain.isEmpty) return null;
  final caret = _toPlain(
    leaves,
    markedCaret.clamp(0, markedText.length),
  ).clamp(0, plain.length);

  var ps = caret;
  var pe = caret;
  switch (kind) {
    case RichScopeKind.word:
      final leftWord = ps > 0 && isRichWordChar(plain[ps - 1]);
      final rightWord = pe < plain.length && isRichWordChar(plain[pe]);
      if (!leftWord && !rightWord) return null;
      while (ps > 0 && isRichWordChar(plain[ps - 1])) {
        ps--;
      }
      while (pe < plain.length && isRichWordChar(plain[pe])) {
        pe++;
      }
    case RichScopeKind.line:
      ps = caret == 0 ? 0 : plain.lastIndexOf('\n', caret - 1) + 1;
      final next = plain.indexOf('\n', caret);
      pe = next < 0 ? plain.length : next;
    case RichScopeKind.all:
      return (start: 0, end: markedText.length, plainCaret: caret);
  }
  if (pe <= ps) return null;
  var start = _plainToLogicalLeaves(leaves, ps);
  var end = _plainToLogicalLeaves(leaves, pe, preferEnd: true);
  // İşaretlenen aralıkta kısmen kesilen iç biçimler varsa dengeli sınırla.
  ({int start, int end}) balance(String sub, int base, int s, int e) {
    var rs = s;
    var re = e;
    for (final m in _formatPattern.allMatches(sub)) {
      final content = _contentOf(m);
      if (content == null || content.isEmpty) continue;
      final ms = base + m.start;
      final me = base + m.end;
      if (ms >= rs && ms < re && me > re) re = me;
      if (ms < rs && me > rs && me < re) rs = ms;
      final format = _formatOf(m);
      final openLen = _openLength(format, _colorOf(m));
      final inner = balance(content, ms + openLen, rs, re);
      rs = inner.start;
      re = inner.end;
    }
    return (start: rs, end: re);
  }

  final balanced = balance(markedText, 0, start, end);
  start = balanced.start;
  end = balanced.end;
  return (start: start, end: end, plainCaret: caret);
}
