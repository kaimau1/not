import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/pdf_text.dart';

/// Temizlik sesli okumanın işe yarar olup olmamasını belirliyor: temizlenmemiş
/// PDF metni "Sayfa 12 bölü 47" diye okunur ve dinlenmez.
void main() {
  test('Satır sonu tirelemesi birleştirilir', () {
    expect(
      PdfText.cleanForSpeechSync('kelime-\nnin sonu'),
      'kelimenin sonu',
    );
  });

  test('Yalnız sayfa numarası olan satırlar atılır', () {
    const raw = 'Giriş metni\n12\n- 13 -\n14 / 47\nDevam metni';
    expect(PdfText.cleanForSpeechSync(raw), 'Giriş metni\nDevam metni');
  });

  test('Her sayfada tekrarlayan üstbilgi atılır', () {
    const header = 'Yıllık Rapor 2026';
    final raw = [
      header,
      'Birinci sayfa içeriği',
      header,
      'İkinci sayfa içeriği',
      header,
      'Üçüncü sayfa içeriği',
    ].join('\n');
    final cleaned = PdfText.cleanForSpeechSync(raw);
    expect(cleaned.contains(header), isFalse);
    expect(cleaned.contains('Birinci sayfa içeriği'), isTrue);
    expect(cleaned.contains('Üçüncü sayfa içeriği'), isTrue);
  });

  test('İki kez geçen uzun cümle KORUNUR (üstbilgi değil)', () {
    // 3 tekrar eşiği: gerçek içerik iki kez geçebilir, silinmemeli.
    const line = 'Bu cümle içerikte iki kez geçiyor.';
    final cleaned = PdfText.cleanForSpeechSync('$line\nAra metin\n$line');
    expect(line.allMatches(cleaned).length, 2);
  });

  test('Boş girdi boş döner', () {
    expect(PdfText.cleanForSpeechSync('   \n\n  '), '');
  });
}
