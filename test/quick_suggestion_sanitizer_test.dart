import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/data/quick_entry_memory.dart';
import 'package:notlar/features/notes/domain/list_mode.dart';
import 'package:notlar/features/notes/domain/quick_suggestion_sanitizer.dart';
import 'package:notlar/features/notes/domain/smart_list.dart';

void main() {
  group('QuickSuggestionSanitizer', () {
    test('rich_text işaretlerini temizler ve kirli kod/uzun cümleleri reddeder', () {
      expect(QuickSuggestionSanitizer.cleanItem('##3:Süt##'), 'Süt');
      expect(QuickSuggestionSanitizer.cleanItem('**Domates** (2 kg)'), 'Domates');
      expect(
        QuickSuggestionSanitizer.cleanItem('%%yellow:Beyaz peynir%%'),
        'Beyaz peynir',
      );
      expect(
        QuickSuggestionSanitizer.cleanItem(
          'Bu beş kelimeden çok daha uzun bir cümledir',
        ),
        isNull,
      );
      expect(
        QuickSuggestionSanitizer.cleanItem('https://example.com/urun'),
        isNull,
      );
      expect(
        QuickSuggestionSanitizer.cleanItem('final x = map[0];'),
        isNull,
      );
      expect(QuickSuggestionSanitizer.cleanItem('12345'), isNull);
    });

    test('alışveriş modunda fiil/görev cümlelerini ayıklar, market ürünlerini geçirir', () {
      final filtered = QuickSuggestionSanitizer.filterSuggestions(
        [
          '##3:Süt##',
          'Proje dosyasını kontrol et',
          'Faturayı öde',
          'Domates',
          'Zeytinyağı',
          'https://test.com',
        ],
        mode: ListMode.shopping,
        kind: SmartListKind.shopping,
        locale: 'tr',
      );
      expect(filtered, ['Süt', 'Domates', 'Zeytinyağı']);
    });

    test('sanitizeMemory mevcut kirli hafızayı temizler ve sayaçları birleştirir', () {
      const dirty = QuickEntryMemory(
        kinds: {
          'smart:market': {
            '##3:sut##': ('##3:Süt##', 2),
            'sut': ('Süt', 3),
            'uzun': ('Bu çok uzun bir görev cümlesi eklenmiş', 4),
            'kod': ('foo::bar()', 5),
          },
        },
      );
      final clean = QuickSuggestionSanitizer.sanitizeMemory(dirty);
      expect(clean.kinds['smart:market']?.length, 1);
      expect(clean.kinds['smart:market']?['sut'], ('Süt', 5));
    });
  });
}
