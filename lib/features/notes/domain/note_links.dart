import 'note.dart';

/// **Not bağlantıları** (F18.16, 2026-11-02).
///
/// Bağlantı, ek gömmenin ([NoteTagLink]) AYNI kalıbıdır: metinde
/// "📎 Başlık" yazısı, notta `tagLinks` kaydı. Fark yalnız kimlikte: ek
/// yerine `note:<notKimliği>`. Böylece
///  * bağ KİMLİKLE kurulur — hedefin başlığı değişse de bağ kalır;
///  * eski sürüm aynı satırı düz metin "📎 Başlık" olarak görür, eki
///    bulamadığı bağı zaten yok sayar (bkz. [NoteTagLink.attachmentId]);
///  * paylaşım/dışa aktarma metninde başlık okunur biçimde gider.
const String kNoteLinkPrefix = 'note:';

/// Bağ bir NOT bağlantısıysa hedef notun kimliği.
String? linkedNoteId(NoteTagLink link) =>
    link.attachmentId.startsWith(kNoteLinkPrefix)
    ? link.attachmentId.substring(kNoteLinkPrefix.length)
    : null;

/// [label] etiketinin gittiği not (yoksa null).
String? noteLinkTarget(Note note, String label) {
  for (final l in note.tagLinks) {
    if (l.label != label) continue;
    final id = linkedNoteId(l);
    if (id != null && id.isNotEmpty) return id;
  }
  return null;
}

/// Bu notun bağlandığı notlar (sırayla, tekrarsız).
List<String> outgoingNoteLinks(Note note) {
  final out = <String>[];
  for (final l in note.tagLinks) {
    final id = linkedNoteId(l);
    if (id != null && id.isNotEmpty && !out.contains(id)) out.add(id);
  }
  return out;
}

/// **Geri bağlantılar**: [noteId]ye bağlanan notlar (istemcide türetilir —
/// ayrı bir alan yazılmaz). Çöptekiler ve notun kendisi sayılmaz.
List<Note> backlinksTo(String noteId, Iterable<Note> notes) => [
  for (final n in notes)
    if (n.id != noteId &&
        n.deletedAt == null &&
        n.tagLinks.any((l) => linkedNoteId(l) == noteId))
      n,
];
