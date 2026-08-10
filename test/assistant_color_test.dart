import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/ai/data/assistant_service.dart';
import 'package:notlar/features/notes/domain/note.dart';

/// KÖK NEDEN (kullanıcı 2026-08-09, ekran görüntüsüyle): "kırmızı çerçeve yap"
/// denince asistan isteği NOTUN İÇİNE madde olarak yazıyordu — notun kendi
/// alanlarını değiştirecek bir aracı yoktu. Araç eklendi; renk argümanı model
/// ne yazarsa yazsın (Türkçe, İngilizce, büyük harf) çözülmeli.
void main() {
  test('renk adı Türkçe de İngilizce de tanınır', () {
    expect(AssistantService.parseColor('kırmızı'), NoteColor.red);
    expect(AssistantService.parseColor('kirmizi'), NoteColor.red);
    expect(AssistantService.parseColor('RED'), NoteColor.red);
    expect(AssistantService.parseColor('  Mavi '), NoteColor.blue);
    expect(AssistantService.parseColor('none'), NoteColor.none);
    expect(AssistantService.parseColor('yok'), NoteColor.none);
  });

  test('tanınmayan değer null döner (yanlış renk yazılmaz)', () {
    expect(AssistantService.parseColor('turkuaz'), isNull);
    expect(AssistantService.parseColor(''), isNull);
    expect(AssistantService.parseColor(null), isNull);
    expect(AssistantService.parseColor(3), isNull);
  });
}
