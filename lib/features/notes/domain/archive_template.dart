import '../../../core/utils/rich_text.dart';

/// Defterde yeni sayfa açarken seçilen HAZIR DÜZEN (kullanıcı isteği
/// 2026-09-23: "defterde sayfa şablonları — günlük, fatura, toplantı").
enum ArchiveTemplate { blank, journal, meeting, expense, todo, reading }

/// Şablonun tek satırı: metni ve başlık düzeyi.
typedef TemplateLine = ({String text, RichHeading heading});

/// Satırlardan sayfanın YAZISINI kurar: başlık satırları boy + kalın
/// işaretleriyle (bkz. [setLineHeading]) — yeni bir biçim türü yok, sayfa
/// açıldıktan sonra kullanıcı başlığı biçim çubuğundan değiştirebilir.
String buildTemplateText(List<TemplateLine> lines) {
  var text = lines.map((l) => l.text).join('\n');
  // Satırlar SONDAN başa işlenir: bir satıra işaret eklemek sonraki
  // satırların konumunu kaydırır, öncekilerinkini kaydırmaz.
  final offsets = <int>[];
  var pos = 0;
  for (final line in lines) {
    offsets.add(pos);
    pos += line.text.length + 1;
  }
  for (var i = lines.length - 1; i >= 0; i--) {
    final line = lines[i];
    if (line.heading == RichHeading.normal || line.text.isEmpty) continue;
    text = setLineHeading(text, offsets[i], offsets[i], line.heading).text;
  }
  return text;
}
