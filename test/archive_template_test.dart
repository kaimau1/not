import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/archive_template.dart';

/// Şablon yazısı: satırlar aynen, başlık satırları boy + kalın işaretli.
void main() {
  test('başlık satırları işaretlenir, düz satırlar ve metin korunur', () {
    final text = buildTemplateText(const [
      (text: 'Toplantı', heading: RichHeading.h1),
      (text: '23 Eylül', heading: RichHeading.normal),
      (text: 'Gündem', heading: RichHeading.h2),
      (text: '1. ', heading: RichHeading.normal),
    ]);
    expect(stripRichMarkers(text), 'Toplantı\n23 Eylül\nGündem\n1. ');
    final lines = text.split('\n');
    expect(lineHeadingAt(text, 0), RichHeading.h1);
    final second = lines[0].length + 1;
    expect(lineHeadingAt(text, second), RichHeading.normal);
    final third = second + lines[1].length + 1;
    expect(lineHeadingAt(text, third), RichHeading.h2);
  });

  test('boş başlık satırı işaret almaz', () {
    final text = buildTemplateText(const [
      (text: '', heading: RichHeading.h1),
      (text: 'a', heading: RichHeading.normal),
    ]);
    expect(text, '\na');
  });
}
