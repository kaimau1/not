import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentKind {
  image('image'),
  pdf('pdf'),
  audio('audio'),
  slide('slide');

  const AttachmentKind(this.id);

  final String id;

  static AttachmentKind fromId(String? id) => AttachmentKind.values.firstWhere(
    (k) => k.id == id,
    orElse: () => AttachmentKind.image,
  );
}

/// PDF sayfasının üzerine elle çizilen tek bir çizgi. Koordinatlar sayfa
/// boyutunun oranı (0–1) olarak tutulur: yakınlaştırma, ekran boyutu ya da
/// cihaz değişse de çizim aynı yere düşer. PDF dosyasına dokunulmaz; çizim
/// ayrı katman olduğu için sonradan tekrar düzenlenip silinebilir.
class InkStroke {
  const InkStroke({
    required this.page,
    required this.color,
    required this.width,
    required this.points,
  });

  /// 1 tabanlı sayfa numarası.
  final int page;

  /// ARGB değeri.
  final int color;

  /// Sayfa genişliğinin oranı olarak çizgi kalınlığı.
  final double width;

  /// Düzleştirilmiş nokta listesi: [x1, y1, x2, y2, ...], her biri 0–1.
  final List<double> points;

  factory InkStroke.fromMap(Map<String, dynamic> map) => InkStroke(
    page: (map['p'] as num?)?.toInt() ?? 1,
    color: (map['c'] as num?)?.toInt() ?? 0xFF000000,
    width: (map['w'] as num?)?.toDouble() ?? 0.004,
    points: [
      for (final v in (map['d'] as List?) ?? const []) (v as num).toDouble(),
    ],
  );

  Map<String, dynamic> toMap() => {
    'p': page,
    'c': color,
    'w': width,
    'd': points,
  };
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
    this.displayWidth,
    this.align = 'center',
    this.x,
    this.y,
    this.pageY,
    this.ink = const [],
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

  /// Görselin notta gösterileceği genişlik: içerik genişliğinin oranı (0–1).
  /// null = varsayılan (tam genişlik). Kullanıcı elle küçültüp büyütür.
  final double? displayWidth;

  /// Görselin nottaki yatay hizası: 'left' | 'center' | 'right'. Satır içi
  /// (eski) diziliş için; serbest tuval modunda [x]/[y] kullanılır.
  final String align;

  /// Serbest tuvalde görselin sol-üst köşesinin konumu: tuval genişlik/
  /// yüksekliğinin oranı (0–1). null = konum atanmamış (eski/yeni görsel);
  /// bu durumda otomatik sıralı yerleşim uygulanır. Kullanıcı sürükleyince
  /// yazılır. [displayWidth] ile birlikte "boyut ve yer serbest" (madde 5).
  final double? x;
  final double? y;

  /// Metin notunda TAM SAYFA serbest yerleşim: görselin üst kenarının sayfa
  /// içeriğinin tepesinden uzaklığı (dp). Sabit oranlı küçük tuvalin aksine
  /// sayfa yüksekliği metinle değişir; oran yerine mutlak dp saklanır ki metin
  /// uzayınca görsel yerinden oynamasın. null = eski görsel — [y] oranından
  /// bir kez çevrilir. Yatay konum [x] (genişlik oranı) ile ortak.
  final double? pageY;

  /// PDF üzerine elle yapılan çizimler (sayfa üstü katman). Boş = çizim yok.
  final List<InkStroke> ink;
  final DateTime? createdAt;

  bool get isUploaded => downloadUrl.isNotEmpty;

  Attachment copyWith({
    String? storagePath,
    String? downloadUrl,
    String? localPath,
    double? displayWidth,
    String? align,
    double? x,
    double? y,
    double? pageY,
    List<InkStroke>? ink,
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
    displayWidth: displayWidth ?? this.displayWidth,
    align: align ?? this.align,
    x: x ?? this.x,
    y: y ?? this.y,
    pageY: pageY ?? this.pageY,
    ink: ink ?? this.ink,
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
    displayWidth: (map['displayWidth'] as num?)?.toDouble(),
    align: map['align'] as String? ?? 'center',
    x: (map['x'] as num?)?.toDouble(),
    y: (map['y'] as num?)?.toDouble(),
    pageY: (map['pageY'] as num?)?.toDouble(),
    ink: [
      for (final e in (map['ink'] as List?) ?? const [])
        InkStroke.fromMap(Map<String, dynamic>.from(e as Map)),
    ],
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
    if (displayWidth != null) 'displayWidth': displayWidth,
    'align': align,
    if (x != null) 'x': x,
    if (y != null) 'y': y,
    if (pageY != null) 'pageY': pageY,
    if (ink.isNotEmpty) 'ink': [for (final s in ink) s.toMap()],
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
