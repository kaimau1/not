/// Not tipleri: düz metin, alışveriş/kontrol listesi, sıralı (numaralı) liste.
enum NoteType {
  text('text'),
  checklist('checklist'),
  ordered('ordered');

  const NoteType(this.id);

  final String id;

  static NoteType fromId(String? id) => NoteType.values.firstWhere(
        (t) => t.id == id,
        orElse: () => NoteType.text,
      );
}
