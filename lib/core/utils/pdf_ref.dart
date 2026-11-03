/// Notun içindeki PDF SAYFA/SATIR REFERANSLARI ("📖 s.12 · 5. satır").
///
/// Kullanıcı isteği 2026-11-03: "PDF'de seçili yere basılı tutunca metin
/// seçimi gelir ve bir Not al butonu olur; o buton sayfa sayısını ve satırı
/// kaydeder — aynı YouTube'da dakika kaydetmek gibi. Okuma modu gibi düşün:
/// hem okurken hem not almak çok kolay ve pratik olmalı."
///
/// Video zaman damgası gibi (bkz. `video_time.dart`) referans metnin İÇİNDE
/// düz yazı olarak durur — kopyalama, dışa aktarma, arama hep onu görür; notta
/// bağlantı gibi çizilir ve dokununca belge o sayfaya döner. Kitap simgesi
/// (📖) referansı sıradan "s.12" yazısından ayırır: kullanıcının kendi
/// yazdığı "s.12" bağlantıya dönmez.
library;

/// Referansın başındaki işaret.
const String kPdfRefMark = '📖';

/// Metindeki bir referans: `[start, end)` aralığı, sayfa (1 tabanlı) ve
/// varsa satır.
typedef PdfPageRef = ({int start, int end, int page, int? line});

/// Türkçe "📖 s.12 · 5. satır", İngilizce "📖 p.12 · line 5"; satır kısmı
/// isteğe bağlı. İki dil de her arayüz dilinde tanınır (not başka dilde
/// yazılmış olabilir).
final RegExp _refPattern = RegExp(
  '$kPdfRefMark '
  r'[sp]\.(\d{1,5})(?: · (?:(\d{1,4})\. satır|line (\d{1,4})))?',
);

/// Metindeki bütün referanslar, soldan sağa.
List<PdfPageRef> findPdfPageRefs(String text) {
  if (!text.contains(kPdfRefMark)) return const [];
  return [
    for (final m in _refPattern.allMatches(text))
      (
        start: m.start,
        end: m.end,
        page: int.parse(m.group(1)!),
        line: int.tryParse(m.group(2) ?? m.group(3) ?? ''),
      ),
  ];
}

/// [offset] konumundaki referans (imleç referansın İÇİNDE ya da tam
/// sınırında); yoksa null.
PdfPageRef? pdfPageRefAt(String text, int offset) {
  for (final r in findPdfPageRefs(text)) {
    if (offset >= r.start && offset <= r.end) return r;
    if (r.start > offset) break;
  }
  return null;
}

/// Referans yazısı: [turkish] ise "📖 s.12 · 5. satır", değilse
/// "📖 p.12 · line 5". Satır bilinmiyorsa (taranmış sayfa, metinsiz seçim)
/// yalnız sayfa.
String formatPdfRef({required int page, int? line, required bool turkish}) {
  final head = '$kPdfRefMark ${turkish ? 's' : 'p'}.$page';
  if (line == null || line < 1) return head;
  return turkish ? '$head · $line. satır' : '$head · line $line';
}

/// Seçilen yazının nota girecek alıntısı: tek satıra indirilir, uzunsa
/// kelime sınırında kısaltılır (not alıntıyla dolmasın — tamamı belgede).
String pdfQuoteSnippet(String text, {int max = 280}) {
  final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (flat.length <= max) return flat;
  var cut = flat.lastIndexOf(' ', max);
  if (cut < max * 0.6) cut = max;
  return '${flat.substring(0, cut).trimRight()}…';
}

/// Nota yazılan tam satır: referans + (varsa) tırnak içinde alıntı.
String pdfNoteLine({
  required int page,
  int? line,
  String quote = '',
  required bool turkish,
}) {
  final ref = formatPdfRef(page: page, line: line, turkish: turkish);
  final snippet = pdfQuoteSnippet(quote);
  return snippet.isEmpty ? ref : '$ref “$snippet”';
}

/// Sayfadaki bir metin parçasının kutusu — PDF koordinatı (y YUKARI artar:
/// `top > bottom`).
typedef PdfTextBand = ({double left, double top, double right, double bottom});

/// [target] (seçimin İLK satırı) sayfanın kaçıncı satırında — 1 tabanlı.
///
/// Satırlar metin parçalarından çıkarılır: dikeyde örtüşen parçalar tek
/// satırdır. Yalnız seçimle AYNI SÜTUNDAKİ parçalar sayılır (yatayda
/// örtüşenler) — iki sütunlu bir makalede sağ sütundaki seçim sol sütunun
/// satırlarını saymasın. Hiç parça yoksa null.
int? pdfLineNumber(List<PdfTextBand> fragments, PdfTextBand target) {
  final targetHeight = target.top - target.bottom;
  if (targetHeight <= 0) return null;
  final column = [
    for (final f in fragments)
      if (f.top > f.bottom &&
          f.right >= f.left &&
          f.left < target.right &&
          f.right > target.left)
        f,
  ];
  if (column.isEmpty) return null;
  double center(PdfTextBand b) => (b.top + b.bottom) / 2;
  column.sort((a, b) => center(b).compareTo(center(a)));
  final lines = <({double top, double bottom})>[];
  for (final f in column) {
    final c = center(f);
    if (lines.isNotEmpty) {
      final last = lines.last;
      if (c <= last.top && c >= last.bottom) {
        lines[lines.length - 1] = (
          top: f.top > last.top ? f.top : last.top,
          bottom: f.bottom < last.bottom ? f.bottom : last.bottom,
        );
        continue;
      }
    }
    lines.add((top: f.top, bottom: f.bottom));
  }
  final targetCenter = (target.top + target.bottom) / 2;
  var above = 0;
  for (final l in lines) {
    // Hedefin kendi satırı (merkezi hedefin içinde) sayılmaz.
    if (targetCenter <= l.top && targetCenter >= l.bottom) continue;
    if ((l.top + l.bottom) / 2 > targetCenter) above++;
  }
  return above + 1;
}
