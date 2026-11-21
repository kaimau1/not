import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../folders/domain/note_folder.dart';
import '../domain/note.dart';
import '../domain/note_type.dart';

/// Kolay, açık ve taşınabilir **Markdown (.zip)** dışa aktarma (PLAN §1.4/6).
///
/// Her etkin not (çöptekiler hariç) klasör adına göre dizinlere yerleştirilen
/// standart UTF-8 `.md` dosyalarına dönüştürülür: YAML ön bilgisi (başlık,
/// tür, etiketler, sabitleme, tarihler) + okunaklı Markdown gövde/liste.
/// Kendi `.notyedek` biçimine bağlı kalmadan Obsidian, Notion, Git vb. her
/// araçta doğrudan açılabilir.

String markdownExportFileName([DateTime? now]) {
  final t = now ?? DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  return 'notlar-markdown-${t.year}-${two(t.month)}-${two(t.day)}.zip';
}

/// Dosya veya klasör adını işletim sistemleri arası güvenli biçime çevirir.
String sanitizeMarkdownName(String raw, {String fallback = 'not'}) {
  final cleaned = raw
      .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'^\.+|\.+$'), '');
  if (cleaned.isEmpty) return fallback;
  return cleaned.length > 64 ? cleaned.substring(0, 64).trim() : cleaned;
}

String _yamlQuote(String s) {
  final escaped = s
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', ' ')
      .replaceAll('\r', '');
  return '"$escaped"';
}

/// Tek bir notu YAML ön bilgili standart Markdown metnine dönüştürür.
String noteToMarkdown(
  Note note, {
  String untitled = 'Adsız not',
  String pagePrefix = 'Sayfa',
  String attachmentsHeading = 'Ekler',
}) {
  final title = note.displayTitle.trim().isEmpty
      ? untitled
      : note.displayTitle.trim();
  final buf = StringBuffer()
    ..writeln('---')
    ..writeln('title: ${_yamlQuote(title)}')
    ..writeln('type: ${note.type.id}');
  final tags = [
    for (final t in note.tags)
      if (t.trim().isNotEmpty) t.trim(),
  ];
  if (tags.isNotEmpty) {
    buf.writeln('tags: [${tags.map(_yamlQuote).join(', ')}]');
  }
  if (note.pinned) buf.writeln('pinned: true');
  if (note.archivedAt != null) buf.writeln('archived: true');
  if (note.createdAt != null) {
    buf.writeln('created: ${note.createdAt!.toUtc().toIso8601String()}');
  }
  if (note.updatedAt != null) {
    buf.writeln('updated: ${note.updatedAt!.toUtc().toIso8601String()}');
  }
  buf
    ..writeln('---')
    ..writeln()
    ..writeln('# $title');

  switch (note.type) {
    case NoteType.checklist:
      if (note.items.isNotEmpty) {
        buf.writeln();
        for (final item in note.items) {
          final text = item.text.trim();
          if (item.header) {
            if (text.isNotEmpty) buf.writeln('\n## $text\n');
            continue;
          }
          if (text.isEmpty) continue;
          final mark = item.checked ? 'x' : ' ';
          buf.writeln('- [$mark] $text');
        }
      }
      if (note.body.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln(note.body.trim());
      }
    case NoteType.ordered:
      if (note.items.isNotEmpty) {
        buf.writeln();
        var n = 1;
        for (final item in note.items) {
          final text = item.text.trim();
          if (item.header) {
            if (text.isNotEmpty) {
              buf.writeln('\n## $text\n');
              n = 1;
            }
            continue;
          }
          if (text.isEmpty) continue;
          buf.writeln('${n++}. $text');
        }
      }
      if (note.body.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln(note.body.trim());
      }
    case NoteType.pdf:
    case NoteType.slides:
      if (note.body.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln(note.body.trim());
      }
      if (note.pageNotes.isNotEmpty) {
        final pages = note.pageNotes.keys.toList()
          ..sort((a, b) {
            final ai = int.tryParse(a.split(':').last);
            final bi = int.tryParse(b.split(':').last);
            if (ai != null && bi != null && ai != bi) return ai.compareTo(bi);
            return a.compareTo(b);
          });
        for (final p in pages) {
          final content = note.pageNotes[p]?.trim() ?? '';
          if (content.isEmpty) continue;
          final label = p.contains(':') ? p.split(':').last : p;
          buf
            ..writeln()
            ..writeln('## $pagePrefix $label')
            ..writeln()
            ..writeln(content);
        }
      }
    case NoteType.archive:
      if (note.body.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln(note.body.trim());
      }
      if (note.items.isNotEmpty) {
        buf.writeln();
        for (final item in note.items) {
          final text = item.text.trim();
          if (text.isEmpty) continue;
          if (item.section.trim().isNotEmpty) {
            buf.writeln('- **${item.section.trim()}**: $text');
          } else {
            buf.writeln('- $text');
          }
        }
      }
    case NoteType.text:
      if (note.body.trim().isNotEmpty) {
        buf
          ..writeln()
          ..writeln(note.body.trim());
      }
  }

  if (note.attachments.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## $attachmentsHeading')
      ..writeln();
    for (final a in note.attachments) {
      final label = a.fileName.trim().isEmpty ? a.id : a.fileName.trim();
      buf.writeln('- `$label` (${a.kind.id})');
    }
  }

  return buf.toString();
}

/// Etkin notları klasör yapısında `.md` dosyalarına çevirip standart `.zip`
/// baytları üretir (çöptekiler atlanır).
({Uint8List bytes, int exportedCount}) buildMarkdownZip(
  Iterable<Note> notes, {
  Iterable<NoteFolder> folders = const [],
  String archiveFolderName = 'Arşiv',
  String untitled = 'Adsız not',
  String pagePrefix = 'Sayfa',
  String attachmentsHeading = 'Ekler',
}) {
  final folderNames = <String, String>{
    for (final f in folders)
      f.id: sanitizeMarkdownName(f.name, fallback: 'Klasör'),
  };
  final archive = Archive();
  final usedPaths = <String>{};
  var count = 0;

  for (final note in notes) {
    if (note.deletedAt != null) continue;
    final dirParts = <String>[];
    if (note.archivedAt != null) {
      dirParts.add(sanitizeMarkdownName(archiveFolderName, fallback: 'Arşiv'));
    } else if (note.folderId != null && folderNames.containsKey(note.folderId)) {
      dirParts.add(folderNames[note.folderId]!);
    }
    final baseName = sanitizeMarkdownName(
      note.displayTitle,
      fallback: sanitizeMarkdownName(untitled),
    );
    final prefix = dirParts.isEmpty ? '' : '${dirParts.join('/')}/';
    var candidate = '$prefix$baseName.md';
    var suffix = 2;
    while (!usedPaths.add(candidate.toLowerCase())) {
      candidate = '$prefix$baseName-$suffix.md';
      suffix++;
    }
    final md = noteToMarkdown(
      note,
      untitled: untitled,
      pagePrefix: pagePrefix,
      attachmentsHeading: attachmentsHeading,
    );
    final data = utf8.encode(md);
    archive.addFile(ArchiveFile(candidate, data.length, data));
    count++;
  }

  final encoded = ZipEncoder().encode(archive);
  return (bytes: Uint8List.fromList(encoded), exportedCount: count);
}
