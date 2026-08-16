/// Liste tipli notlardaki tek bir öğe (checklist veya sıralı liste satırı).
class NoteItem {
  const NoteItem({
    required this.id,
    required this.text,
    this.checked = false,
    this.starred = false,
    this.section = '',
  });

  final String id;
  final String text;

  /// Yalnızca checklist tipinde anlamlıdır; sıralı listede yok sayılır.
  final bool checked;

  /// YILDIZLI madde (kullanıcı isteği 2026-08-16: "madde yıldızlama ve
  /// sıralama"). Notun kendi `starred` alanının madde ölçeğindeki karşılığı:
  /// uzun bir listede "asıl önemli olanlar" işaretlenir, sıralama seçeneği
  /// onları en üste alır.
  ///
  /// Alan yalnız TRUE iken kayda yazılır ([toMap]): eski notların şeması
  /// büyümez ve bu alanı bilmeyen bir sürüm listeyi yazarken yıldızları
  /// silmez (`checked` ile aynı gerekçe değil — o hep yazılıyor çünkü
  /// false'a DÖNMEK anlamlı bir durum; yıldızın yokluğu ile false'u aynı).
  final bool starred;

  /// ARŞİV DEFTERİNDE metin girdisinin hangi ELLE AÇILMIŞ sayfaya ait olduğu
  /// (bkz. `Note.archivePages`). Boş = "Metinler" sayfası. Arşiv dışındaki
  /// notlarda yok sayılır — [Attachment.section] ile aynı kural.
  final String section;

  NoteItem copyWith({
    String? text,
    bool? checked,
    bool? starred,
    String? section,
  }) => NoteItem(
    id: id,
    text: text ?? this.text,
    checked: checked ?? this.checked,
    starred: starred ?? this.starred,
    section: section ?? this.section,
  );

  factory NoteItem.fromMap(Map<String, dynamic> map) => NoteItem(
    id: map['id'] as String? ?? '',
    text: map['text'] as String? ?? '',
    checked: map['checked'] as bool? ?? false,
    starred: map['starred'] as bool? ?? false,
    section: map['section'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'checked': checked,
    if (starred) 'starred': true,
    if (section.isNotEmpty) 'section': section,
  };
}
