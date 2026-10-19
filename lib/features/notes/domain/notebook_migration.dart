import '../../../core/utils/rich_text.dart';
import 'attachment.dart';
import 'note.dart';
import 'note_item.dart';
import 'note_type.dart';

/// **DEFTER → SAYFALI NOT** (F3.5, 2026-10-19).
///
/// Eskiden defter (`NoteType.archive`) ayrı bir editördü: adlı sayfalar,
/// sayfaya bağlı serbest yazı + başlıklı metin blokları + ekler, kâğıt
/// deseni. Artık normal notun "Defter" görünümüdür ([Note.paged]): sayfalar
/// [Note.textPages], ekler `Attachment.section` = sayfa kimliğiyle sayfaya
/// bağlı, kâğıt deseni [Note.archivePaper]da kalır.
///
/// Çeviri SAF ve kayıpsızdır (içerik açısından):
///  * Her defter sayfası bir not sayfası olur; ilki ('' — Genel) ilk sayfa.
///  * Sayfa ADI sayfanın ilk satırına ALT BAŞLIK olarak yazılır (Genel'in
///    kullanıcı vermediği "Genel" adı yazılmaz).
///  * Serbest yazı, ardından başlıklı/bağlı bloklar (başlık kalın satır,
///    altında metni) sayfanın gövdesine.
///  * Ekler kendi sayfasına (öksüz bölümdekiler ilk sayfaya — defterdeki
///    kuralın aynısı).
///
/// Sayfa kimlikleri [pageId] ile üretilir (sıra numarası verilir; testler
/// belirleyici kimlik geçer).
Note notebookToPagedNote(Note note, {required String Function(int) pageId}) {
  if (note.type != NoteType.archive) return note;
  final names = ['', ...note.archivePages];
  final ids = [for (var i = 0; i < names.length; i++) i == 0 ? '' : pageId(i)];

  bool onPage(String section, int page) => page == 0
      ? (section.isEmpty || !note.archivePages.contains(section))
      : section == names[page];

  final bodies = <String>[];
  for (var i = 0; i < names.length; i++) {
    final parts = <String>[];
    final name = i == 0 ? note.archiveGeneralName.trim() : names[i].trim();
    if (name.isNotEmpty) {
      parts.add(setLineHeading(name, 0, 0, RichHeading.h2).text);
    }
    NoteItem? writing;
    for (final item in note.items) {
      if (item.title.isEmpty &&
          item.attachmentId.isEmpty &&
          onPage(item.section, i)) {
        writing = item;
        break;
      }
    }
    if (writing != null && writing.text.trim().isNotEmpty) {
      parts.add(writing.text.trimRight());
    }
    for (final item in note.items) {
      if (identical(item, writing) || !onPage(item.section, i)) continue;
      final title = item.title.trim();
      final text = item.text.trimRight();
      if (title.isEmpty && text.trim().isEmpty) continue;
      parts.add(
        [
          if (title.isNotEmpty)
            setRangeFormat(title, 0, title.length, RichFormat.bold, 1).text,
          if (text.trim().isNotEmpty) text,
        ].join('\n'),
      );
    }
    bodies.add(parts.join('\n\n'));
  }

  int pageOf(String section) {
    for (var i = 1; i < names.length; i++) {
      if (onPage(section, i)) return i;
    }
    return 0;
  }

  final attachments = <Attachment>[
    for (final a in note.attachments)
      a.copyWith(section: ids[pageOf(a.section)]),
  ];

  // Tek sayfalı defter tek sayfalı not olur (sayfa çubuğu yine görünür —
  // Defter görünümünde sayfa eklemek tek dokunuş).
  final multi = names.length > 1;
  return note.copyWith(
    type: NoteType.text,
    paged: true,
    body: bodies.first,
    items: const [],
    attachments: attachments,
    archivePages: const [],
    archiveGeneralName: '',
    activePage: '',
    textPages: multi
        ? [
            const NoteTextPage(id: ''),
            for (var i = 1; i < names.length; i++)
              NoteTextPage(id: ids[i], body: bodies[i]),
          ]
        : const [],
  );
}
