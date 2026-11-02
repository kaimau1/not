import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../folders/data/folders_repository.dart';
import '../../folders/domain/note_folder.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import 'attachment_repository.dart';
import 'note_package.dart';
import 'note_share.dart';
import 'notes_repository.dart';

/// **Tam yedek** (F18.4, 2026-11-02) — bütün notları HER ŞEYİYLE (ekler,
/// çizim, balon, PDF işaretleri, sayfalar, görünüm) ve klasörleri tek bir ZIP
/// dosyasında taşır; geri yükleme çift kayıt açmaz.
///
/// Eski "Yedeği dışa aktar (JSON)" yalnız metni taşıyordu ve geri yükleme her
/// kaydı YENİ not açtığı için iki kez yüklenen yedek notları çoğaltıyordu.
/// O JSON hâlâ okunur ([restoreLegacyJson]).
///
/// Biçim (`.notyedek`, içi ZIP):
/// * `yedek.json` — `{app, kind: 'full-backup', v, exportedAt, folders, notes}`;
///   her not girdisi [encodeNoteJson] (not paketiyle AYNI içerik biçimi) +
///   hesaba özgü alanlar (klasör, sabit, yıldız, kilit, arşiv, tarih,
///   hatırlatıcı, yerel) + içerik özeti.
/// * `dosyalar/<notKimliği>/<ekKimliği>` — ek baytları.
///
/// Arayüzden BAĞIMSIZ (F18.5): misafir notlarını Google hesabına taşıma da
/// aynı dışa/içe aktarmayı kullanır.
class BackupService {
  BackupService({required this.notes, required this.attachments, this.folders});

  final NotesRepository notes;
  final AttachmentRepository? attachments;
  final FoldersRepository? folders;

  static const fileExtension = '.notyedek';
  static const formatVersion = 1;
  static const _jsonEntry = 'yedek.json';
  static const _filesDir = 'dosyalar/';

  /// Yedeğe baytlarıyla girebilecek en büyük ek (paketle aynı tavan).
  static const maxFileBytes = NoteShare.maxPackagedFileBytes;

  /// Notları ve klasörleri [sink]e yazar; yazılan not sayısını döner.
  ///
  /// [allNotes] listeden gelen (HAFİF olabilir) notlardır — her biri
  /// [NotesRepository.hydrate] ile tamamlanır. Ekler TEK TEK okunup hemen
  /// yazılır: bütün yedek bellekte birikmez ([sink] dosyaya akıtıyorsa).
  /// [cancelled] true dönerse yarıda bırakılır ve [BackupCancelled] atılır.
  Future<int> export(
    BackupSink sink, {
    required List<Note> allNotes,
    List<NoteFolder> folderList = const [],
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final live = [
      for (final n in allNotes)
        if (n.deletedAt == null) n,
    ];
    final entries = <Map<String, dynamic>>[];
    var done = 0;
    onProgress?.call(0, live.length);
    for (final light in live) {
      if (cancelled?.call() ?? false) throw const BackupCancelled();
      final note = light.heavyMissing ? await notes.hydrate(light) : light;
      final repo = attachments;
      if (repo != null) {
        for (final a in note.attachments) {
          if (a.kind == AttachmentKind.text || a.isWebVideo) continue;
          if (a.sizeBytes > maxFileBytes) continue;
          if (cancelled?.call() ?? false) throw const BackupCancelled();
          try {
            final bytes = await repo.readBytes(a);
            if (bytes != null) sink.add('$_filesDir${note.id}/${a.id}', bytes);
          } catch (_) {
            // Okunamayan ek yedeği düşürmez: kaydı yine yazılır, geri
            // yüklemede baytsız ek atlanır (paket kuralı).
          }
        }
      }
      entries.add(encodeBackupEntry(note));
      done++;
      onProgress?.call(done, live.length);
    }
    final json = utf8.encode(
      jsonEncode({
        'app': 'notlar',
        'kind': 'full-backup',
        'v': formatVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'folders': [for (final f in folderList) _encodeFolder(f)],
        'notes': entries,
      }),
    );
    sink.add(_jsonEntry, json);
    await sink.close();
    return entries.length;
  }

  /// [archive]daki yedeği geri yükler. Var olan notla AYNI kimlikteki ya da
  /// aynı içerik özetini taşıyan kayıt atlanır — yedek iki kez yüklense de
  /// notlar çoğalmaz.
  Future<RestoreResult> restore(
    Archive archive, {
    required List<Note> existing,
    List<NoteFolder> existingFolders = const [],
    void Function(int done, int total)? onProgress,
    bool Function()? cancelled,
    bool allowLocalOnly = true,
  }) async {
    final jsonFile = archive.find(_jsonEntry);
    if (jsonFile == null) throw const FormatException('Yedek verisi yok');
    final decoded = jsonDecode(utf8.decode(jsonFile.content));
    if (decoded is! Map || decoded['kind'] != 'full-backup') {
      throw const FormatException('Tam yedek değil');
    }
    final version = (decoded['v'] as num?)?.toInt() ?? 0;
    if (version > formatVersion) {
      throw FormatException('Yedek sürümü desteklenmiyor: $version');
    }

    // Klasörler AD ile eşlenir: kimlik başka hesapta anlamsız; aynı adlı
    // klasör varsa o kullanılır (ikinci yükleme klasörü de çoğaltmasın).
    final folderMap = <String, String>{};
    final byName = {
      for (final f in existingFolders) f.name.trim().toLowerCase(): f.id,
    };
    final rawFolders = decoded['folders'] as List? ?? const [];
    for (final raw in rawFolders) {
      if (raw is! Map) continue;
      final id = raw['id']?.toString() ?? '';
      final name = (raw['name'] as String? ?? '').trim();
      if (id.isEmpty || name.isEmpty) continue;
      final known = byName[name.toLowerCase()];
      if (known != null) {
        folderMap[id] = known;
        continue;
      }
      final repo = folders;
      if (repo == null) continue;
      final created = await repo.createFolder(
        name,
        icon: raw['icon'] as String? ?? NoteFolder.defaultIcon,
        hidden: raw['hidden'] as bool? ?? false,
        color: (raw['color'] as num?)?.toInt(),
      );
      folderMap[id] = created;
      byName[name.toLowerCase()] = created;
    }

    final ids = {for (final n in existing) n.id};
    final digests = {
      for (final n in existing)
        if (n.deletedAt == null && !n.heavyMissing) noteDigest(n),
    };
    // Önceki geri yüklemelerin kaynak kimliği (`restoredFrom`) de tanınır.
    final restoredFrom = {
      for (final n in existing)
        if (n.extras['restoredFrom'] is String) n.extras['restoredFrom'],
    };

    final raws = decoded['notes'] as List? ?? const [];
    var restored = 0;
    var skipped = 0;
    onProgress?.call(0, raws.length);
    for (var i = 0; i < raws.length; i++) {
      if (cancelled?.call() ?? false) throw const BackupCancelled();
      final raw = raws[i];
      if (raw is! Map) {
        skipped++;
        continue;
      }
      final map = Map<String, dynamic>.from(raw);
      final sourceId = map['id']?.toString() ?? '';
      final digest = map['digest']?.toString() ?? '';
      if (ids.contains(sourceId) ||
          restoredFrom.contains(sourceId) ||
          (digest.isNotEmpty && digests.contains(digest))) {
        skipped++;
        onProgress?.call(i + 1, raws.length);
        continue;
      }
      final note = decodeNoteJson(
        Map<String, dynamic>.from(map['note'] as Map? ?? const {}),
      );
      final files = <String, Uint8List>{};
      for (final a in note.attachments) {
        final f = archive.find('$_filesDir$sourceId/${a.id}');
        if (f != null) files[a.id] = f.content;
      }
      final id = await NoteShare.import(
        NotePackage(note: note, files: files),
        notes: notes,
        attachments: attachments,
      );
      Timestamp? ts(String key) {
        final v = map[key] as String?;
        final parsed = v == null ? null : DateTime.tryParse(v);
        return parsed == null ? null : Timestamp.fromDate(parsed);
      }

      final reminder = ts('reminderAt');
      final folderId = folderMap[map['folderId']];
      await notes.updateFieldsAndWait(id, {
        'pinned': map['pinned'] == true,
        'starred': map['starred'] == true,
        'locked': map['locked'] == true,
        'folderId': ?folderId,
        if (ts('createdAt') != null) 'createdAt': ts('createdAt'),
        if (ts('archivedAt') != null) 'archivedAt': ts('archivedAt'),
        // Geçmişte kalmış hatırlatıcı geri kurulmaz.
        if (reminder != null && reminder.toDate().isAfter(DateTime.now()))
          'reminderAt': reminder,
        if (sourceId.isNotEmpty) 'restoredFrom': sourceId,
      });
      if (allowLocalOnly && map['localOnly'] == true && notes.local != null) {
        final created = await notes.watchNote(id).firstWhere((n) => n != null);
        await notes.setLocalOnly(
          created!,
          localOnly: true,
          attachments: attachments,
        );
      }
      ids.add(id);
      if (digest.isNotEmpty) digests.add(digest);
      if (sourceId.isNotEmpty) restoredFrom.add(sourceId);
      restored++;
      onProgress?.call(i + 1, raws.length);
    }
    return RestoreResult(restored: restored, skipped: skipped);
  }

  /// Eski "Yedeği dışa aktar (JSON)" dosyası (yalnız metin). Çift kayıt
  /// atlama burada da çalışır (kimlik + içerik özeti).
  Future<RestoreResult> restoreLegacyJson(
    Map<String, dynamic> decoded, {
    required List<Note> existing,
  }) async {
    final rawNotes = decoded['notes'];
    if (rawNotes is! List) throw const FormatException();
    final restoredFrom = {
      for (final n in existing)
        if (n.extras['restoredFrom'] is String) n.extras['restoredFrom'],
      for (final n in existing) n.id,
    };
    final digests = {
      for (final n in existing)
        if (n.deletedAt == null && !n.heavyMissing) noteDigest(n),
    };
    var count = 0;
    var skipped = 0;
    for (final raw in rawNotes) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      final sourceId = map['id']?.toString() ?? '';
      final title = map['title'] as String? ?? '';
      final body = map['body'] as String? ?? '';
      final itemTexts = [
        for (final i in (map['items'] as List<dynamic>? ?? const []))
          if (i is Map) i['text'] as String? ?? '',
      ];
      if (title.trim().isEmpty && body.trim().isEmpty && itemTexts.isEmpty) {
        continue;
      }
      final digest = _digestOf(
        type: map['type'] as String? ?? '',
        title: title,
        body: body,
        items: itemTexts,
      );
      if (restoredFrom.contains(sourceId) || digests.contains(digest)) {
        skipped++;
        continue;
      }
      final note = decodeNoteJson({
        'type': map['type'],
        'title': title,
        'body': body,
        'items': [
          for (final i in (map['items'] as List<dynamic>? ?? const []))
            if (i is Map)
              {
                'id': const Uuid().v4(),
                'text': i['text'] as String? ?? '',
                'checked': i['checked'] as bool? ?? false,
              },
        ],
        'tags': map['tags'],
        'color': map['color'],
        'frameColor': map['frameColor'],
        'customColor': map['customColor'],
        'customFrameColor': map['customFrameColor'],
      });
      final id = await NoteShare.import(
        NotePackage(note: note, files: const {}),
        notes: notes,
        attachments: null,
      );
      Timestamp? ts(String key) {
        final v = map[key] as String?;
        final parsed = v == null ? null : DateTime.tryParse(v);
        return parsed == null ? null : Timestamp.fromDate(parsed);
      }

      final reminder = ts('reminderAt');
      await notes.updateFieldsAndWait(id, {
        'pinned': map['pinned'] as bool? ?? false,
        'starred': map['starred'] as bool? ?? false,
        'locked': map['locked'] as bool? ?? false,
        if (ts('createdAt') != null) 'createdAt': ts('createdAt'),
        if (ts('archivedAt') != null) 'archivedAt': ts('archivedAt'),
        if (reminder != null && reminder.toDate().isAfter(DateTime.now()))
          'reminderAt': reminder,
        if (sourceId.isNotEmpty) 'restoredFrom': sourceId,
      });
      if (sourceId.isNotEmpty) restoredFrom.add(sourceId);
      digests.add(digest);
      count++;
    }
    return RestoreResult(restored: count, skipped: skipped);
  }

  /// Bu hesabın notlarını [target] hesaba TAŞIR (F18.5): misafir, zaten var
  /// olan bir Google hesabına girerken notlarını yanına alır. Önce bellekte
  /// tam yedek kurulur ([prepareMigration] — oturum değişmeden ÖNCE, misafir
  /// kimliğiyle okunur), giriş sonrası [target]e geri yüklenir; çift kayıt
  /// atlaması burada da geçerli (aynı notu iki kez taşımak çoğaltmaz).
  Future<Uint8List> prepareMigration({
    required List<Note> allNotes,
    List<NoteFolder> folderList = const [],
  }) async {
    final sink = MemoryBackupSink();
    await export(sink, allNotes: allNotes, folderList: folderList);
    return sink.bytes!;
  }

  static Future<RestoreResult> completeMigration(
    Uint8List backup,
    BackupService target, {
    required List<Note> existing,
    List<NoteFolder> existingFolders = const [],
  }) => target.restore(
    ZipDecoder().decodeBytes(backup),
    existing: existing,
    existingFolders: existingFolders,
  );

  static Map<String, dynamic> _encodeFolder(NoteFolder f) => {
    'id': f.id,
    'name': f.name,
    'icon': f.icon,
    if (f.hidden) 'hidden': true,
    if (f.color != null) 'color': f.color,
  };
}

/// Notun yedek girdisi (saf → birim testli).
Map<String, dynamic> encodeBackupEntry(Note note) => {
  'id': note.id,
  'digest': noteDigest(note),
  if (note.folderId != null) 'folderId': note.folderId,
  if (note.pinned) 'pinned': true,
  if (note.starred) 'starred': true,
  if (note.locked) 'locked': true,
  if (note.localOnly) 'localOnly': true,
  'createdAt': ?note.createdAt?.toIso8601String(),
  'updatedAt': ?note.updatedAt?.toIso8601String(),
  'archivedAt': ?note.archivedAt?.toIso8601String(),
  'reminderAt': ?note.reminderAt?.toIso8601String(),
  'note': encodeNoteJson(note),
};

/// Notun İÇERİK özeti: tür + başlık + gövde + madde metinleri. Kimlik,
/// tarih ve görünüm girmez — başka hesaba geri yüklenmiş aynı not da
/// tanınsın.
String noteDigest(Note note) => _digestOf(
  type: note.type.id,
  title: note.title,
  body: note.body,
  items: [for (final i in note.items) i.text],
);

String _digestOf({
  required String type,
  required String title,
  required String body,
  required List<String> items,
}) {
  final text = [type, title.trim(), body.trim(), ...items].join('\u0000');
  return sha1.convert(utf8.encode(text)).toString();
}

/// Yedek baytlarını alan hedef: dosyaya akıtan (cihaz) ya da bellekte biriken
/// (web, test).
abstract class BackupSink {
  void add(String name, List<int> bytes);
  Future<void> close();
}

/// Bellekte ZIP kurar ([bytes] `close`tan sonra dolar).
class MemoryBackupSink implements BackupSink {
  final _archive = Archive();
  Uint8List? bytes;

  @override
  void add(String name, List<int> data) =>
      _archive.addFile(ArchiveFile(name, data.length, data));

  @override
  Future<void> close() async {
    bytes = Uint8List.fromList(ZipEncoder().encode(_archive));
  }
}

class RestoreResult {
  const RestoreResult({required this.restored, required this.skipped});
  final int restored;
  final int skipped;
}

class BackupCancelled implements Exception {
  const BackupCancelled();
}

/// Baytların tam yedek mi, eski JSON mu olduğunu ayırır.
enum BackupFormat { full, legacyJson, unknown }

BackupFormat sniffBackup(Uint8List head) {
  if (head.length >= 2 && head[0] == 0x50 && head[1] == 0x4B) {
    return BackupFormat.full; // "PK" — ZIP
  }
  for (final b in head) {
    if (b == 0x20 ||
        b == 0x0A ||
        b == 0x0D ||
        b == 0x09 ||
        b == 0xEF ||
        b == 0xBB ||
        b == 0xBF) {
      continue;
    }
    return b == 0x7B ? BackupFormat.legacyJson : BackupFormat.unknown;
  }
  return BackupFormat.unknown;
}
