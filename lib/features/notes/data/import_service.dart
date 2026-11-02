import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:xml/xml.dart';

import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';
import 'attachment_repository.dart';
import 'backup_service.dart' show BackupCancelled, noteDigest;
import 'note_package.dart';
import 'note_share.dart';
import 'notes_repository.dart';

/// **İçe aktarma** (F18.15, 2026-11-02) — başka uygulamadan gelenin ilk
/// engeli: Google Keep (Takeout zip'i), Markdown/düz metin (tek dosya ya da
/// zip) ve Evernote `.enex`. Ayrıştırıcılar saf (birim testli); yazım
/// [ImportService.importAll] ile, tam yedekle aynı çift kayıt atlamasıyla
/// (içerik özeti — bkz. `noteDigest`).
class ImportedNote {
  ImportedNote({
    required this.note,
    this.files = const {},
    this.pinned = false,
    this.archived = false,
    this.trashed = false,
    this.createdAt,
  });

  final Note note;
  final Map<String, Uint8List> files;
  final bool pinned;
  final bool archived;
  final bool trashed;
  final DateTime? createdAt;
}

class ImportResult {
  const ImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
  });
  final int imported;

  /// Zaten var (aynı içerik).
  final int skipped;

  /// Okunamayan/boş kayıt.
  final int failed;
}

enum ImportSource { keep, markdown, enex, unknown }

const _uuid = Uuid();

// ---------------------------------------------------------------- Keep

const _keepColors = {
  'RED': NoteColor.red,
  'ORANGE': NoteColor.peach,
  'YELLOW': NoteColor.amber,
  'GREEN': NoteColor.green,
  'TEAL': NoteColor.sage,
  'BLUE': NoteColor.blue,
  'CERULEAN': NoteColor.blue,
  'GRAY': NoteColor.storm,
  'PURPLE': NoteColor.purple,
  'PINK': NoteColor.blossom,
  'BROWN': NoteColor.clay,
};

/// Arşiv bir Keep Takeout'u mu (not başına JSON, `textContent`/`listContent`).
bool looksLikeKeepTakeout(Archive archive) => archive.files.any(
  (f) =>
      f.isFile &&
      f.name.toLowerCase().endsWith('.json') &&
      f.name.toLowerCase().contains('keep'),
);

/// Keep Takeout zip'i → notlar. Her `.json` bir not; ekleri aynı klasörde.
/// [failed] okunamayan kayıt sayısını toplar.
List<ImportedNote> parseKeepTakeout(Archive archive, {List<int>? failed}) {
  final out = <ImportedNote>[];
  final byName = {
    for (final f in archive.files)
      if (f.isFile) f.name: f,
  };
  for (final f in archive.files) {
    if (!f.isFile || !f.name.toLowerCase().endsWith('.json')) continue;
    try {
      final decoded = jsonDecode(utf8.decode(f.content, allowMalformed: true));
      if (decoded is! Map) continue;
      final map = Map<String, dynamic>.from(decoded);
      if (!map.containsKey('textContent') && !map.containsKey('listContent')) {
        continue; // Takeout'taki başka JSON (etiket listesi vb.)
      }
      final dir = f.name.contains('/')
          ? f.name.substring(0, f.name.lastIndexOf('/') + 1)
          : '';
      final note = parseKeepNoteJson(
        map,
        readFile: (path) => byName['$dir$path']?.content,
      );
      if (note != null) out.add(note);
    } catch (_) {
      failed?.add(1);
    }
  }
  return out;
}

/// Tek bir Keep notu (saf). [readFile] ekin baytını verir (yoksa null).
ImportedNote? parseKeepNoteJson(
  Map<String, dynamic> map, {
  Uint8List? Function(String path)? readFile,
}) {
  final title = (map['title'] as String? ?? '').trim();
  final text = map['textContent'] as String? ?? '';
  final list = map['listContent'] as List? ?? const [];
  final items = [
    for (final raw in list)
      if (raw is Map)
        NoteItem(
          id: _uuid.v4(),
          text: (raw['text'] as String? ?? '').trim(),
          checked: raw['isChecked'] == true,
        ),
  ];
  final labels = [
    for (final l in (map['labels'] as List? ?? const []))
      if (l is Map && (l['name'] as String? ?? '').trim().isNotEmpty)
        (l['name'] as String).trim(),
  ];
  final files = <String, Uint8List>{};
  final attachments = <Attachment>[];
  for (final raw in (map['attachments'] as List? ?? const [])) {
    if (raw is! Map) continue;
    final path = raw['filePath'] as String? ?? '';
    final mime = raw['mimetype'] as String? ?? '';
    final bytes = path.isEmpty ? null : readFile?.call(path);
    // Keep bazen .jpeg yazıp .jpg koyuyor: uzantısız eşleşme de denenir.
    final data = bytes ?? _altExtension(path, readFile);
    if (data == null) continue;
    final kind = mime.startsWith('audio/')
        ? AttachmentKind.audio
        : AttachmentKind.image;
    final id = _uuid.v4();
    files[id] = data;
    attachments.add(
      Attachment(
        id: id,
        kind: kind,
        fileName: path,
        mimeType: mime.isEmpty ? 'image/jpeg' : mime,
        sizeBytes: data.length,
        createdAt: DateTime.now(),
      ),
    );
  }
  if (title.isEmpty &&
      text.trim().isEmpty &&
      items.every((i) => i.text.isEmpty) &&
      attachments.isEmpty) {
    return null;
  }
  final usec = (map['createdTimestampUsec'] as num?)?.toInt();
  return ImportedNote(
    note: Note(
      id: '',
      type: items.isNotEmpty ? NoteType.checklist : NoteType.text,
      title: title,
      body: items.isNotEmpty ? '' : text.trimRight(),
      items: items,
      tags: labels,
      color: _keepColors[map['color']] ?? NoteColor.none,
      attachments: attachments,
    ),
    files: files,
    pinned: map['isPinned'] == true,
    archived: map['isArchived'] == true,
    trashed: map['isTrashed'] == true,
    createdAt: usec == null || usec <= 0
        ? null
        : DateTime.fromMicrosecondsSinceEpoch(usec),
  );
}

Uint8List? _altExtension(
  String path,
  Uint8List? Function(String path)? readFile,
) {
  if (readFile == null || !path.contains('.')) return null;
  final base = path.substring(0, path.lastIndexOf('.'));
  for (final ext in const ['.jpg', '.jpeg', '.png', '.webp', '.3gp', '.m4a']) {
    final b = readFile('$base$ext');
    if (b != null) return b;
  }
  return null;
}

// ------------------------------------------------------------ Markdown

final _checkbox = RegExp(r'^\s*[-*+]\s+\[( |x|X)\]\s?(.*)$');
final _heading = RegExp(r'^\s{0,3}#{1,6}\s+(.*)$');

/// Markdown / düz metin → not (saf). `# başlık` ilk satırdaysa başlık olur;
/// bütün dolu satırlar `- [ ]` / `- [x]` ise liste notu, değilse metin notu
/// (onay kutulu satırlar metinde `☐`/`☑` olarak kalır). Satır içi
/// `__kalın__` → `**kalın**`, `*italik*` → `_italik_` (uygulamanın
/// işaretleri; `**` ve `_` zaten aynı).
ImportedNote? parseMarkdownNote(String fileName, String text) {
  var lines = const LineSplitter().convert(text.replaceAll('\r\n', '\n'));
  var title = '';
  final first = lines.indexWhere((l) => l.trim().isNotEmpty);
  if (first >= 0) {
    final m = _heading.firstMatch(lines[first]);
    if (m != null) {
      title = m.group(1)!.trim();
      lines = [...lines.sublist(0, first), ...lines.sublist(first + 1)];
    }
  }
  if (title.isEmpty) {
    final dot = fileName.lastIndexOf('.');
    final slash = fileName.lastIndexOf('/');
    final base = fileName.substring(
      slash + 1,
      dot > slash ? dot : fileName.length,
    );
    title = base.trim();
  }
  final filled = [
    for (final l in lines)
      if (l.trim().isNotEmpty) l,
  ];
  final allChecks =
      filled.isNotEmpty && filled.every(_checkbox.hasMatch);
  if (allChecks) {
    return ImportedNote(
      note: Note(
        id: '',
        type: NoteType.checklist,
        title: title,
        items: [
          for (final l in filled)
            NoteItem(
              id: _uuid.v4(),
              text: markdownInline(_checkbox.firstMatch(l)!.group(2)!.trim()),
              checked: _checkbox.firstMatch(l)!.group(1)!.toLowerCase() == 'x',
            ),
        ],
      ),
    );
  }
  final body = [
    for (final l in lines)
      if (_checkbox.firstMatch(l) case final m?)
        '${m.group(1)!.toLowerCase() == 'x' ? '☑' : '☐'} '
            '${markdownInline(m.group(2)!.trim())}'
      else
        markdownInline(l),
  ].join('\n').trim();
  if (body.isEmpty && title.isEmpty) return null;
  return ImportedNote(
    note: Note(id: '', type: NoteType.text, title: title, body: body),
  );
}

/// Satır içi Markdown → uygulamanın işaretleri.
String markdownInline(String s) => s
    .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => '**${m[1]}**')
    .replaceAllMapped(
      RegExp(r'(?<![*\w])\*(?!\*)([^*\n]+?)\*(?![*\w])'),
      (m) => '_${m[1]}_',
    );

/// Zip içindeki `.md`/`.markdown`/`.txt` dosyaları.
List<ImportedNote> parseMarkdownArchive(Archive archive, {List<int>? failed}) {
  final out = <ImportedNote>[];
  for (final f in archive.files) {
    final lower = f.name.toLowerCase();
    if (!f.isFile ||
        !(lower.endsWith('.md') ||
            lower.endsWith('.markdown') ||
            lower.endsWith('.txt'))) {
      continue;
    }
    // macOS'un zip'e koyduğu çöp (__MACOSX/._x.md).
    if (lower.contains('__macosx/')) continue;
    try {
      final note = parseMarkdownNote(
        f.name,
        utf8.decode(f.content, allowMalformed: true),
      );
      if (note != null) out.add(note);
    } catch (_) {
      failed?.add(1);
    }
  }
  return out;
}

// ---------------------------------------------------------------- ENEX

/// Evernote `.enex` → notlar: başlık, ENML içeriği düz metne (onay kutuları
/// `☐`/`☑`), etiketler, oluşturma tarihi. Ekler (`resource`) atlanır.
List<ImportedNote> parseEnex(String xml, {List<int>? failed}) {
  final out = <ImportedNote>[];
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } catch (_) {
    failed?.add(1);
    return out;
  }
  for (final n in doc.findAllElements('note')) {
    try {
      final title = n.getElement('title')?.innerText.trim() ?? '';
      final content = n.getElement('content')?.innerText ?? '';
      final body = enmlToText(content);
      final tags = [
        for (final t in n.findElements('tag'))
          if (t.innerText.trim().isNotEmpty) t.innerText.trim(),
      ];
      if (title.isEmpty && body.isEmpty) continue;
      out.add(
        ImportedNote(
          note: Note(
            id: '',
            type: NoteType.text,
            title: title,
            body: body,
            tags: tags,
          ),
          createdAt: _enexDate(n.getElement('created')?.innerText),
        ),
      );
    } catch (_) {
      failed?.add(1);
    }
  }
  return out;
}

/// ENML (XHTML) → düz metin.
String enmlToText(String enml) {
  if (enml.trim().isEmpty) return '';
  try {
    final doc = XmlDocument.parse(
      enml.replaceFirst(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), ''),
    );
    final buf = StringBuffer();
    void walk(XmlNode node) {
      if (node is XmlText) {
        buf.write(node.value);
        return;
      }
      if (node is! XmlElement) {
        for (final c in node.children) {
          walk(c);
        }
        return;
      }
      final name = node.name.local.toLowerCase();
      if (name == 'en-todo') {
        buf.write(node.getAttribute('checked') == 'true' ? '☑ ' : '☐ ');
        return;
      }
      if (name == 'br') {
        buf.write('\n');
        return;
      }
      final block = const {
        'div',
        'p',
        'li',
        'h1',
        'h2',
        'h3',
        'tr',
      }.contains(name);
      final bold = name == 'b' || name == 'strong';
      final italic = name == 'i' || name == 'em';
      if (bold) buf.write('**');
      if (italic) buf.write('_');
      for (final c in node.children) {
        walk(c);
      }
      if (italic) buf.write('_');
      if (bold) buf.write('**');
      if (block) buf.write('\n');
    }

    walk(doc);
    return buf
        .toString()
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .replaceAll('****', '')
        .trim();
  } catch (_) {
    return enml.replaceAll(RegExp(r'<[^>]+>'), ' ').trim();
  }
}

DateTime? _enexDate(String? raw) {
  // 20240115T093000Z
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})Z$')
      .firstMatch(raw?.trim() ?? '');
  if (m == null) return null;
  return DateTime.utc(
    int.parse(m[1]!),
    int.parse(m[2]!),
    int.parse(m[3]!),
    int.parse(m[4]!),
    int.parse(m[5]!),
    int.parse(m[6]!),
  ).toLocal();
}

// -------------------------------------------------------------- yazım

class ImportService {
  ImportService({required this.notes, required this.attachments});

  final NotesRepository notes;
  final AttachmentRepository? attachments;

  /// [items]ı yazar; var olanla aynı içerikte olan atlanır.
  Future<ImportResult> importAll(
    List<ImportedNote> items, {
    required List<Note> existing,
    int failed = 0,
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final digests = {
      for (final n in existing)
        if (n.deletedAt == null && !n.heavyMissing) noteDigest(n),
    };
    var imported = 0;
    var skipped = 0;
    onProgress?.call(0, items.length);
    for (var i = 0; i < items.length; i++) {
      if (cancelled?.call() ?? false) throw const BackupCancelled();
      final item = items[i];
      final digest = noteDigest(item.note);
      if (digests.contains(digest)) {
        skipped++;
        onProgress?.call(i + 1, items.length);
        continue;
      }
      try {
        final id = await NoteShare.import(
          NotePackage(note: item.note, files: item.files),
          notes: notes,
          attachments: attachments,
        );
        final now = Timestamp.now();
        await notes.updateFieldsAndWait(id, {
          if (item.pinned) 'pinned': true,
          if (item.archived) 'archivedAt': now,
          if (item.trashed) 'deletedAt': now,
          if (item.createdAt != null)
            'createdAt': Timestamp.fromDate(item.createdAt!),
        });
        digests.add(digest);
        imported++;
      } catch (_) {
        failed++;
      }
      onProgress?.call(i + 1, items.length);
    }
    return ImportResult(imported: imported, skipped: skipped, failed: failed);
  }
}
