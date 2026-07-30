import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentKind {
  image('image'),
  pdf('pdf'),
  audio('audio'),
  slide('slide'),
  /// Görüntülü not. YALNIZCA CİHAZDA kalır — Storage'a hiç yüklenmez
  /// (bkz. UploadQueue), bu yüzden cihazlar arasında senkronlanmaz.
  video('video');

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

/// Görsel kırpılınca üstündeki çizimleri YENİ çerçeveye taşır.
///
/// Noktalar görselin oranı (0–1) olarak tutulduğundan kırpma onları geçersiz
/// kılar: kırpma yapılıp çizimler olduğu gibi bırakılırsa çizgi görselin
/// bambaşka bir yerine kayar. [left]/[top]/[right]/[bottom] kırpma
/// dikdörtgeni, yine 0–1. Tümüyle dışarıda kalan çizgi düşer; kalınlık da
/// oransal olduğu için aynı oranda büyütülür.
List<InkStroke> cropInk(
  List<InkStroke> strokes, {
  required double left,
  required double top,
  required double right,
  required double bottom,
}) {
  final w = right - left;
  final h = bottom - top;
  if (w <= 0 || h <= 0) return const [];
  final out = <InkStroke>[];
  for (final s in strokes) {
    final points = <double>[];
    var anyInside = false;
    for (var i = 0; i + 1 < s.points.length; i += 2) {
      final x = (s.points[i] - left) / w;
      final y = (s.points[i + 1] - top) / h;
      if (x >= 0 && x <= 1 && y >= 0 && y <= 1) anyInside = true;
      points..add(x)..add(y);
    }
    // Hiçbir noktası yeni çerçeveye düşmeyen çizgi atılır; kısmen taşan çizgi
    // korunur (çizim katmanı zaten kırpar) — yoksa kenardaki bir imza
    // tek nokta yüzünden tümüyle silinirdi.
    if (!anyInside) continue;
    out.add(
      InkStroke(
        page: s.page,
        color: s.color,
        // Kalınlık görsel GENİŞLİĞİNİN oranı; çerçeve daraldıkça oran büyür.
        width: s.width / w,
        points: points,
      ),
    );
  }
  return out;
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

  /// [fileName]/[mimeType]/[width]/[height]/[sizeBytes] yalnız KIRPMA yolunda
  /// değişir (dosyanın kendisi yeniden yazılır); onun dışında ek oluşturulduğu
  /// gibi kalır.
  Attachment copyWith({
    String? fileName,
    String? mimeType,
    String? storagePath,
    String? downloadUrl,
    String? localPath,
    int? sizeBytes,
    int? width,
    int? height,
    double? displayWidth,
    String? align,
    double? x,
    double? y,
    double? pageY,
    List<InkStroke>? ink,
  }) => Attachment(
    id: id,
    kind: kind,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    storagePath: storagePath ?? this.storagePath,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    localPath: localPath ?? this.localPath,
    sizeBytes: sizeBytes ?? this.sizeBytes,
    width: width ?? this.width,
    height: height ?? this.height,
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
