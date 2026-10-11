import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import '../domain/note_type.dart';

/// **Not paketi** — bir notu HER ŞEYİYLE başka bir Not kullanıcısına
/// göndermenin biçimi.
///
/// Düz metin paylaşımı (`Paylaş → metin`) notun yalnız gövdesini taşır: ekler,
/// PDF sayfa notları, çizimler, balonlar, renkler ve yazı tipi kaybolur; karşı
/// taraf notu "aynı şekilde" açamaz. Paket bunların tamamını taşır.
///
/// Biçim: tek bir ZIP dosyası (uzantı `.notpaket`).
/// * `not.json` — notun bütün alanları (bkz. [encodeNoteJson]).
/// * `dosyalar/<ekKimliği>` — her ekin ham baytları (PDF, sunum, görsel, ses).
///
/// Neden ZIP: ekler ikili veridir; base64'le JSON'a gömmek dosyayı ~%33
/// büyütür ve 20 MB'lık bir PDF'i tek satırlık bir dizeye çevirir (bellek
/// sıçraması + okunamaz dosya). `archive` paketi zaten bağımlılıkta (sunum
/// okuyucu kullanıyor), yeni bağımlılık gerekmiyor.
///
/// Neden Firestore `toMap()` değil: o harita `Timestamp` ve
/// `FieldValue.serverTimestamp()` taşır — ikisi de JSON'a çevrilemez ve
/// sunucuya özeldir. Paket biçimi bilinçli olarak AYRI ve sürümlüdür
/// ([formatVersion]): notun iç şeması değişince paket okuyucusu eski
/// paketleri okumayı sürdürebilsin.
class NotePackage {
  const NotePackage({required this.note, required this.files});

  /// Paketten çözülen not — kimlik/tarih alanları YOKTUR (içe aktaran cihaz
  /// kendi kimliğini üretir; bkz. [decodeNoteJson]).
  final Note note;

  /// Ek kimliği → ham dosya baytları. Paket bozuksa eksik kalabilir; içe
  /// aktarma baytı olmayan eki atlar.
  final Map<String, Uint8List> files;

  /// Paket biçim sürümü. Okuyucu bilmediği bir sürümü reddeder.
  static const formatVersion = 1;

  /// Paketin dosya uzantısı. Paylaşım hedefindeki uygulama bunu görünce
  /// "not paketi" olduğunu anlar (bkz. `share_intake.dart`).
  static const fileExtension = '.notpaket';

  static const _jsonEntry = 'not.json';
  static const _filesDir = 'dosyalar/';
}

/// Notu paket JSON'una çevirir (saf fonksiyon → birim testli).
///
/// [Note.id], klasör ve sıralama gibi CİHAZA ÖZEL alanlar bilerek dışarıda
/// bırakılır: karşı tarafta o kimlikler başka bir notu gösterir ya da hiçbir
/// şeyi göstermez. Taşınan her şey notun İÇERİĞİ ve GÖRÜNÜMÜdür.
Map<String, dynamic> encodeNoteJson(Note note) => {
  'v': NotePackage.formatVersion,
  'type': note.type.id,
  'title': note.title,
  'body': note.body,
  'items': [for (final item in note.items) item.toMap()],
  if (note.pageNotes.isNotEmpty) 'pageNotes': note.pageNotes,
  'attachments': [for (final a in note.attachments) _encodeAttachment(a)],
  'tags': note.tags,
  'color': note.color.id,
  'frameColor': note.frameColor.id,
  'fontFamily': note.fontFamily,
  'fontScale': note.fontScale,
  'textOpacity': note.textOpacity,
  'titleFontFamily': note.titleFontFamily,
  'titleFontScale': note.titleFontScale,
  'titleTextOpacity': note.titleTextOpacity,
  'backgroundImageId': note.backgroundImageId,
  'backgroundOpacity': note.backgroundOpacity,
  if (note.textPages.isNotEmpty)
    'textPages': [for (final p in note.textPages) p.toMap()],
  if (note.activePage.isNotEmpty) 'activePage': note.activePage,
};

/// Ekin DÜZEN ve KATMAN alanları. Depo alanları (storagePath, downloadUrl,
/// localPath) YAZILMAZ: onlar gönderenin hesabına/cihazına aittir, alıcıda
/// hiçbir işe yaramaz ve kişisel bilgi sızdırır (kullanıcı kimliği yolun
/// içindedir).
Map<String, dynamic> _encodeAttachment(Attachment a) => {
  'id': a.id,
  'kind': a.kind.id,
  'fileName': a.fileName,
  'mimeType': a.mimeType,
  'sizeBytes': a.sizeBytes,
  if (a.width != null) 'width': a.width,
  if (a.height != null) 'height': a.height,
  if (a.displayWidth != null) 'displayWidth': a.displayWidth,
  'align': a.align,
  if (a.x != null) 'x': a.x,
  if (a.y != null) 'y': a.y,
  if (a.pageY != null) 'pageY': a.pageY,
  if (a.asFile) 'asFile': true,
  // Sayfalı notta görselin hangi sayfada olduğu (bkz. Note.textPages).
  if (a.section.isNotEmpty) 'section': a.section,
  if (a.ink.isNotEmpty) 'ink': [for (final s in a.ink) s.toMap()],
  // PDF/slayt üzerindeki not balonları da paketle gider: kullanıcı isteği
  // "PDF üzerindeki balonlar girmiş olsun, yani her şeyiyle paylaşılmış olacak".
  if (a.bubbles.isNotEmpty) 'bubbles': [for (final b in a.bubbles) b.toMap()],
  if (a.pageIds.isNotEmpty) 'pageIds': a.pageIds,
  // YouTube eki dosyasızdır: bağlantının kendisi ektir (kişisel veri yok).
  if (a.webUrl.isNotEmpty) 'webUrl': a.webUrl,
  if (a.pinHeight != 0) 'pinHeight': a.pinHeight,
};

/// Paket JSON'unu nota çevirir. Kimlik boş bırakılır: içe aktaran taraf notu
/// kendi deposunda oluşturur ve kimliği oradan alır.
///
/// Bilinmeyen bir biçim sürümü [FormatException] atar — sessizce yarım bir
/// not oluşturmaktansa "bu paketi açamıyorum" demek doğrudur.
Note decodeNoteJson(Map<String, dynamic> map) {
  final version = (map['v'] as num?)?.toInt() ?? 0;
  if (version > NotePackage.formatVersion) {
    throw FormatException('Paket sürümü desteklenmiyor: $version');
  }
  return Note(
    id: '',
    type: NoteType.fromId(map['type'] as String?),
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    items: [
      for (final raw in (map['items'] as List? ?? const []))
        NoteItem.fromMap(Map<String, dynamic>.from(raw as Map)),
    ],
    pageNotes: {
      for (final e in (map['pageNotes'] as Map? ?? const {}).entries)
        e.key.toString(): e.value?.toString() ?? '',
    },
    attachments: [
      for (final raw in (map['attachments'] as List? ?? const []))
        _decodeAttachment(Map<String, dynamic>.from(raw as Map)),
    ],
    tags: [for (final t in (map['tags'] as List? ?? const [])) t.toString()],
    color: NoteColor.fromId(map['color'] as String?),
    frameColor: NoteColor.fromId(map['frameColor'] as String?),
    fontFamily: map['fontFamily'] as String?,
    fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1,
    textOpacity: (map['textOpacity'] as num?)?.toDouble() ?? 1,
    titleFontFamily: map['titleFontFamily'] as String?,
    titleFontScale: (map['titleFontScale'] as num?)?.toDouble() ?? 1,
    titleTextOpacity: (map['titleTextOpacity'] as num?)?.toDouble() ?? 1,
    backgroundImageId: map['backgroundImageId'] as String?,
    backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.35,
    textPages: [
      for (final raw in (map['textPages'] as List? ?? const []))
        NoteTextPage.fromMap(Map<String, dynamic>.from(raw as Map)),
    ],
    activePage: map['activePage'] as String? ?? '',
  );
}

Attachment _decodeAttachment(Map<String, dynamic> map) => Attachment(
  id: map['id'] as String? ?? '',
  kind: AttachmentKind.fromId(map['kind'] as String?),
  fileName: map['fileName'] as String? ?? '',
  mimeType: map['mimeType'] as String? ?? '',
  sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
  width: (map['width'] as num?)?.toInt(),
  height: (map['height'] as num?)?.toInt(),
  displayWidth: (map['displayWidth'] as num?)?.toDouble(),
  align: map['align'] as String? ?? 'center',
  x: (map['x'] as num?)?.toDouble(),
  y: (map['y'] as num?)?.toDouble(),
  pageY: (map['pageY'] as num?)?.toDouble(),
  asFile: map['asFile'] as bool? ?? false,
  section: map['section'] as String? ?? '',
  ink: [
    for (final raw in (map['ink'] as List? ?? const []))
      InkStroke.fromMap(Map<String, dynamic>.from(raw as Map)),
  ],
  bubbles: [
    for (final raw in (map['bubbles'] as List? ?? const []))
      PageBubble.fromMap(Map<String, dynamic>.from(raw as Map)),
  ],
  pageIds: [
    for (final raw in (map['pageIds'] as List? ?? const [])) raw.toString(),
  ],
  webUrl: map['webUrl'] as String? ?? '',
  pinHeight: (map['pinHeight'] as num?)?.toDouble() ?? 0,
);

/// Notu ve ek baytlarını tek bir `.notpaket` (ZIP) dosyasına yazar.
///
/// [files] anahtarı ek KİMLİĞİdir; baytı olmayan ek (bulutta duran ama
/// indirilememiş dosya) pakete metadata'sıyla girer, alıcıda yer tutucu
/// olarak görünür — notun geri kalanı yine açılır.
Uint8List buildNotePackage(Note note, Map<String, Uint8List> files) {
  final archive = Archive();
  final json = utf8.encode(jsonEncode(encodeNoteJson(note)));
  archive.addFile(ArchiveFile(NotePackage._jsonEntry, json.length, json));
  for (final entry in files.entries) {
    archive.addFile(
      ArchiveFile(
        '${NotePackage._filesDir}${entry.key}',
        entry.value.length,
        entry.value,
      ),
    );
  }
  // ZipEncoder her zaman bayt döndürür; boş arşiv bile geçerli bir ZIP'tir.
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// `.notpaket` baytlarını çözer. Dosya ZIP değilse, `not.json` içermiyorsa ya
/// da JSON bozuksa [FormatException] atar — çağıran kullanıcıya "bu dosya bir
/// not paketi değil" diyebilsin.
NotePackage readNotePackage(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (e) {
    throw FormatException('Paket açılamadı: $e');
  }
  Map<String, dynamic>? json;
  final files = <String, Uint8List>{};
  for (final file in archive.files) {
    if (!file.isFile) continue;
    if (file.name == NotePackage._jsonEntry) {
      final decoded = jsonDecode(utf8.decode(file.content as List<int>));
      if (decoded is Map) json = Map<String, dynamic>.from(decoded);
      continue;
    }
    if (file.name.startsWith(NotePackage._filesDir)) {
      files[file.name.substring(NotePackage._filesDir.length)] =
          Uint8List.fromList(file.content as List<int>);
    }
  }
  if (json == null) {
    throw const FormatException('Pakette not verisi yok');
  }
  return NotePackage(note: decodeNoteJson(json), files: files);
}

/// Paketin dosya adı: notun başlığından türetilir, dosya sisteminde sorun
/// çıkaran karakterler ayıklanır. Başlıksız notta genel bir ad kullanılır.
String notePackageFileName(Note note, {required String fallback}) {
  final raw = note.displayTitle.trim().isEmpty
      ? fallback
      : note.displayTitle.trim();
  var name = raw.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1F]'), ' ').trim();
  name = name.replaceAll(RegExp(r'\s+'), ' ');
  if (name.length > 60) name = name.substring(0, 60).trim();
  if (name.isEmpty) name = fallback;
  return '$name${NotePackage.fileExtension}';
}
