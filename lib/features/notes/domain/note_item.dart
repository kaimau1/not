/// Liste tipli notlardaki tek bir öğe (checklist veya sıralı liste satırı).
class NoteItem {
  const NoteItem({required this.id, required this.text, this.checked = false});

  final String id;
  final String text;

  /// Yalnızca checklist tipinde anlamlıdır; sıralı listede yok sayılır.
  final bool checked;

  NoteItem copyWith({String? text, bool? checked}) => NoteItem(
    id: id,
    text: text ?? this.text,
    checked: checked ?? this.checked,
  );

  factory NoteItem.fromMap(Map<String, dynamic> map) => NoteItem(
    id: map['id'] as String? ?? '',
    text: map['text'] as String? ?? '',
    checked: map['checked'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {'id': id, 'text': text, 'checked': checked};
}
