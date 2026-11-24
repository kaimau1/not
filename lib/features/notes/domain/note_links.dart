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

/// **Web bağlantısı gömme** (kullanıcı 2026-11-24): aynı kalıp, kimlik
/// `url:<adres>`. Eski sürüm eki bulamadığı bağı yok sayar, yazı düz kalır.
const String kUrlLinkPrefix = 'url:';

/// Bağ bir WEB bağlantısıysa adresi.
String? linkedUrl(NoteTagLink link) =>
    link.attachmentId.startsWith(kUrlLinkPrefix)
    ? link.attachmentId.substring(kUrlLinkPrefix.length)
    : null;

/// [label] etiketinin gittiği web adresi (yoksa null).
String? urlLinkTarget(Note note, String label) {
  for (final l in note.tagLinks) {
    if (l.label != label) continue;
    final u = linkedUrl(l);
    if (u != null && u.isNotEmpty) return u;
  }
  return null;
}

/// Bağın gideceği yer hâlâ var mı (ek silinmişse etiket çip sayılmaz).
bool tagLinkAlive(Note note, NoteTagLink link) =>
    linkedNoteId(link) != null ||
    linkedUrl(link) != null ||
    note.attachments.any((a) => a.id == link.attachmentId);

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
