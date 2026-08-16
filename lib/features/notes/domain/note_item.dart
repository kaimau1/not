/// Liste tipli notlardaki tek bir öğe (checklist veya sıralı liste satırı).
class NoteItem {
  const NoteItem({
    required this.id,
    required this.text,
    this.checked = false,
    this.starred = false,
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

  NoteItem copyWith({String? text, bool? checked, bool? starred}) => NoteItem(
    id: id,
    text: text ?? this.text,
    checked: checked ?? this.checked,
    starred: starred ?? this.starred,
  );

  factory NoteItem.fromMap(Map<String, dynamic> map) => NoteItem(
    id: map['id'] as String? ?? '',
    text: map['text'] as String? ?? '',
    checked: map['checked'] as bool? ?? false,
    starred: map['starred'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'checked': checked,
    if (starred) 'starred': true,
  };
}
