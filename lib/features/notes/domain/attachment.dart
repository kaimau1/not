import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentKind {
  image('image'),
  pdf('pdf'),
  audio('audio');

  const AttachmentKind(this.id);

  final String id;

  static AttachmentKind fromId(String? id) => AttachmentKind.values.firstWhere(
    (k) => k.id == id,
    orElse: () => AttachmentKind.image,
  );
}

/// Bir nota bağlı dosyanın (görsel/PDF) metadata'sı.
/// Dosyanın kendisi Firebase Storage'da tutulur; yükleme tamamlanana kadar
/// [downloadUrl] boş kalır ve [localPath] üzerinden gösterilir.
class Attachment {
  const Attachment({
    required this.id,
    required this.kind,
    required this.fileName,
    required this.mimeType,
    this.storagePath = '',
    this.downloadUrl = '',
    this.localPath = '',
    this.sizeBytes = 0,
    this.width,
    this.height,
    this.createdAt,
  });

  final String id;
  final AttachmentKind kind;
  final String fileName;
  final String mimeType;
  final String storagePath;
  final String downloadUrl;

  /// Yükleme bitene kadar kullanılan cihaz içi kopya. Firestore'a yazılır ki
  /// aynı cihazda uygulama yeniden açıldığında kuyruk kaldığı yerden sürsün;
  /// diğer cihazlarda dosya mevcut olmayacağı için yalnızca yer tutucu görünür.
  final String localPath;
  final int sizeBytes;
  final int? width;
  final int? height;
  final DateTime? createdAt;

  bool get isUploaded => downloadUrl.isNotEmpty;

  Attachment copyWith({
    String? storagePath,
    String? downloadUrl,
    String? localPath,
  }) => Attachment(
    id: id,
    kind: kind,
    fileName: fileName,
    mimeType: mimeType,
    storagePath: storagePath ?? this.storagePath,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    localPath: localPath ?? this.localPath,
    sizeBytes: sizeBytes,
    width: width,
    height: height,
    createdAt: createdAt,
  );

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
    id: map['id'] as String? ?? '',
    kind: AttachmentKind.fromId(map['kind'] as String?),
    fileName: map['fileName'] as String? ?? '',
    mimeType: map['mimeType'] as String? ?? '',
    storagePath: map['storagePath'] as String? ?? '',
    downloadUrl: map['downloadUrl'] as String? ?? '',
    localPath: map['localPath'] as String? ?? '',
    sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
    width: (map['width'] as num?)?.toInt(),
    height: (map['height'] as num?)?.toInt(),
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind.id,
    'fileName': fileName,
    'mimeType': mimeType,
    'storagePath': storagePath,
    'downloadUrl': downloadUrl,
    'localPath': localPath,
    'sizeBytes': sizeBytes,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
