import '../../../core/utils/rich_text.dart';
import 'note.dart';

/// Bir notun sayısal özeti: kelime, karakter, madde, ek ve tahmini okuma
/// süresi.
///
/// NEDEN: uzun bir notun ne kadar uzun olduğu yalnız kaydırarak anlaşılıyordu.
/// Sayılar notun kendisinden türetilir, hiçbir yere yazılmaz.
class NoteStats {
  const NoteStats({
    required this.words,
    required this.characters,
    required this.items,
    required this.checkedItems,
    required this.attachments,
  });

  final int words;
  final int characters;
  final int items;
  final int checkedItems;
  final int attachments;

  /// Ortalama okuma hızı dakikada ~200 kelime. Bir kelimeden azsa 0 döner ki
  /// boş notta "~1 dk okuma" yazmasın.
  int get readMinutes => words == 0 ? 0 : (words / 200).ceil();

  /// Biçim işaretleri (`**kalın**`, `%%2:renk%%`) SAYILMAZ: kullanıcı gördüğü
  /// metnin uzunluğunu sorar, kaynak işaretlerin değil.
  factory NoteStats.of(Note note) {
    final buffer = StringBuffer()
      ..writeln(stripRichMarkers(note.title))
      ..writeln(stripRichMarkers(note.body));
    for (final item in note.items) {
      buffer.writeln(stripRichMarkers(item.text));
    }
    for (final page in note.pageNotes.values) {
      buffer.writeln(stripRichMarkers(page));
    }
    final text = buffer.toString();
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .length;
    return NoteStats(
      words: words,
      // Boşluklar ve satır sonları dışarıda: "kaç karakter yazdım" sorusunun
      // beklenen cevabı görünür harf sayısıdır.
      characters: text.replaceAll(RegExp(r'\s'), '').length,
      items: note.items.where((i) => i.text.trim().isNotEmpty).length,
      checkedItems: note.items
          .where((i) => i.checked && i.text.trim().isNotEmpty)
          .length,
      attachments: note.attachments.length,
    );
  }
}
