import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/local_file.dart';

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
    this.arrow = false,
  });

  /// 1 tabanlı sayfa numarası.
  final int page;

  /// ARGB değeri.
  final int color;

  /// Sayfa genişliğinin oranı olarak çizgi kalınlığı.
  final double width;

  /// Düzleştirilmiş nokta listesi: [x1, y1, x2, y2, ...], her biri 0–1.
  final List<double> points;

  /// **OK** mu? true ise çizgi serbest bir el yazısı değil, iki uçlu bir
  /// oktur: ilk nokta kuyruk, SON nokta uçtur ve ucuna dolu bir başlık
  /// çizilir (kullanıcı isteği 2026-08-08: "bir de ok işareti çekme
  /// istiyorum" — "şuraya bak" demenin en kısa yolu, elle çizilen ok hep
  /// eğri çıkıyordu).
  ///
  /// Neden [InkPen] gibi renge gömülmedi: kalem türü SAYDAMLIKTAN okunuyor
  /// (bkz. ink_pen.dart) ama ok, kalemin bir türü değil — her kalemle ve her
  /// renkle çizilebilir. Alan yalnız TRUE iken kayda yazılır: eski çizimlerin
  /// şeması büyümez.
  final bool arrow;

  factory InkStroke.fromMap(Map<String, dynamic> map) => InkStroke(
    page: (map['p'] as num?)?.toInt() ?? 1,
    color: (map['c'] as num?)?.toInt() ?? 0xFF000000,
    width: (map['w'] as num?)?.toDouble() ?? 0.004,
    points: [
      for (final v in (map['d'] as List?) ?? const []) (v as num).toDouble(),
    ],
    arrow: map['a'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    'p': page,
    'c': color,
    'w': width,
    'd': points,
    if (arrow) 'a': true,
  };
}

/// PDF/slayt sayfasının üzerine bırakılan tek bir **not balonu**.
///
/// Kullanıcı belgenin istediği noktasına dokunup balon bırakır ve içine yazar:
/// "burayı düzelt", "bu tabloyu sun", "kaynak?" gibi. Balon çizim değildir —
/// metindir; açılıp kapanır (kapalıyken yalnız küçük bir tutamaç görünür ki
/// sayfa okunmaya devam etsin), istenildiği kadar eklenebilir ve sürüklenerek
/// taşınabilir.
///
/// Çizim ([InkStroke]) ile aynı ilkeler: PDF dosyasına GÖMÜLMEZ, ekin
/// `bubbles` alanında sayfa oranlı (0–1) konumla saklanır ve not ile birlikte
/// Firestore'a gider — her açılışta yeniden düzenlenebilir, silinebilir,
/// cihazlar arasında senkronlanır.
class PageBubble {
  const PageBubble({
    required this.id,
    required this.page,
    required this.x,
    required this.y,
    this.title = '',
    this.text = '',
    this.color = 0xFFFFC107,
    this.collapsed = false,
    this.starred = false,
    this.urgent = false,
    this.rects = const [],
  });

  /// Kalıcı kimlik: balon taşınıp düzenlendiğinde liste yeniden kurulur,
  /// hangi balonun hangisi olduğu buradan bilinir.
  final String id;

  /// 1 tabanlı sayfa/slayt numarası.
  final int page;

  /// Balonun UCUNUN (işaret ettiği noktanın) sayfa oranındaki konumu: 0–1.
  /// Oran olduğu için yakınlaştırma, ekran boyutu ya da cihaz değişse de
  /// balon aynı yere düşer.
  final double x;
  final double y;

  /// KISA başlık (en çok [maxTitle] karakter). Doluysa balon KAPALIYKEN
  /// yuvarlak nokta yerine başlığı yazan küçük bir etiket görünür — sayfaya
  /// bakınca balonu açmadan ne dediği anlaşılır (kullanıcı isteği 2026-08-08).
  final String title;

  /// Başlığın karakter sınırı. Uzun başlık sayfayı kapatır; 12 karakter
  /// "Fatura", "Kaynak?", "Düzelt" gibi bir etikete yeter.
  static const maxTitle = 12;

  final String text;

  /// Balon rengi (ARGB). Konu ayırmak için: sarı "not", kırmızı "düzelt"...
  final int color;

  /// Kapalıysa yalnız küçük tutamaç görünür; dokununca açılır.
  final bool collapsed;

  /// Yıldızlı balon: toplu listede en üste çıkar ve süzülebilir. "Bunu
  /// unutma" demenin en ucuz yolu — renk konu ayırır, yıldız ÖNEM ayırır.
  final bool starred;

  /// ACİL balon: kapalı hâli yanıp söner, gözden kaçmaz. Yıldız "sonra
  /// bakılacak", ünlem "şimdi bakılacak" demektir.
  final bool urgent;

  /// Balonun bağlı olduğu METNİN sayfa üzerindeki dikdörtgenleri (vurgu).
  /// Boş = serbest balon (sayfanın boş bir yerine bırakılmış).
  ///
  /// Vurgu ile balon AYRI iki şey DEĞİL (kullanıcı isteği: "balonu vurguyla
  /// birleştirme olmalı, vurguya tıklayınca balon açılmalı"): metin seçilip
  /// vurgulandığında bir balon oluşur, dikdörtgenleri burada durur ve balonun
  /// rengiyle boyanır. Vurguya dokunmak o balonu açar. Tek veri modeli olduğu
  /// için toplu liste, arama, senkron ve paylaşım da tek yoldan çalışır.
  ///
  /// Koordinatlar sayfa boyutunun ORANI (0–1), sol-üst köşe orijinli — çizim
  /// ([InkStroke]) ile aynı uzay, yani yakınlaştırma ve cihaz değişse de vurgu
  /// metnin üstünde kalır.
  final List<PageBubbleRect> rects;

  /// Bu balon bir METİN vurgusu mu (yoksa serbest balon mu)?
  bool get isHighlight => rects.isNotEmpty;

  PageBubble copyWith({
    int? page,
    double? x,
    double? y,
    String? title,
    String? text,
    int? color,
    bool? collapsed,
    bool? starred,
    bool? urgent,
    List<PageBubbleRect>? rects,
  }) => PageBubble(
    id: id,
    page: page ?? this.page,
    x: x ?? this.x,
    y: y ?? this.y,
    title: title ?? this.title,
    text: text ?? this.text,
    color: color ?? this.color,
    collapsed: collapsed ?? this.collapsed,
    starred: starred ?? this.starred,
    urgent: urgent ?? this.urgent,
    rects: rects ?? this.rects,
  );

  factory PageBubble.fromMap(Map<String, dynamic> map) => PageBubble(
    id: map['i'] as String? ?? '',
    page: (map['p'] as num?)?.toInt() ?? 1,
    x: (map['x'] as num?)?.toDouble() ?? 0.5,
    y: (map['y'] as num?)?.toDouble() ?? 0.5,
    title: map['h'] as String? ?? '',
    text: map['t'] as String? ?? '',
    color: (map['c'] as num?)?.toInt() ?? 0xFFFFC107,
    collapsed: map['k'] as bool? ?? false,
    starred: map['s'] as bool? ?? false,
    urgent: map['u'] as bool? ?? false,
    rects: [
      for (final e in (map['r'] as List?) ?? const [])
        PageBubbleRect.fromList((e as List).cast<num>()),
    ],
  );

  Map<String, dynamic> toMap() => {
    'i': id,
    'p': page,
    'x': x,
    'y': y,
    't': text,
    'c': color,
    // Yalnız DOLU/true iken yazılır: eski ekin şemasına gereksiz alan eklemez.
    if (title.isNotEmpty) 'h': title,
    if (collapsed) 'k': true,
    if (starred) 's': true,
    if (urgent) 'u': true,
    if (rects.isNotEmpty) 'r': [for (final r in rects) r.toList()],
  };
}

/// Vurgunun tek bir SATIRINI kaplayan dikdörtgen; sayfa oranı (0–1),
/// sol-üst köşe orijinli.
///
/// Neden `Rect` değil kendi tipimiz: bu kayıt Firestore'a gidiyor ve dört
/// sayılık düz DİZİ olarak yazılıyor (`[l, t, r, b]`) — sayfa başına onlarca
/// satır olabildiği için alan adlı harita gereksiz yere büyütürdü.
class PageBubbleRect {
  const PageBubbleRect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  factory PageBubbleRect.fromList(List<num> v) => v.length < 4
      ? const PageBubbleRect(0, 0, 0, 0)
      : PageBubbleRect(
          v[0].toDouble(),
          v[1].toDouble(),
          v[2].toDouble(),
          v[3].toDouble(),
        );

  List<double> toList() => [left, top, right, bottom];
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
        arrow: s.arrow,
      ),
    );
  }
  return out;
}

/// Akıştan gelen ek listesini yerel düzenle birleştirir.
///
/// Ek LİSTESİ (hangi ekler var, hangileri yüklendi) sunucudan gelir; her ekin
/// DÜZENİ (konum/boyut/hiza/şeritte mi) editör açıkken YERELDİR. İkisi
/// ayrılmazsa yazma ile anlık görüntü arasındaki yarışta kullanıcının az önce
/// verdiği konum/boyut bir kare için geri döner ve o kare içinde tetiklenen bir
/// kayıtla kalıcılaşır ("boyutu kaydedilmemiş oluyor").
List<Attachment> mergeAttachmentLayout({
  required List<Attachment> local,
  required List<Attachment> incoming,
}) {
  if (local.isEmpty) return incoming;
  final byId = {for (final a in local) a.id: a};
  return [
    for (final remote in incoming)
      if (byId[remote.id] case final mine?)
        remote.withLayoutOf(mine)
      else
        remote,
  ];
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
    this.asFile = false,
    this.ink = const [],
    this.bubbles = const [],
    this.pageIds = const [],
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

  /// Yalnız GÖRSEL ve VİDEO ekler için: true ise ek sayfada yüzmez, alt
  /// taraftaki ek şeridinde PDF/ses gibi bir DOSYA eki olarak durur.
  ///
  /// Her görsel tuvale düşüyordu; kullanıcının bir görseli "yazının arasına
  /// koymadan sadece iliştirmek" istediği durumda (kaynak belge, fiş, ekran
  /// görüntüsü) metnin yerleşimini bozuyor, taşınıp küçültülmesi gerekiyordu.
  /// Görsel olmayan eklerde yok sayılır — onlar zaten hep şerittedir.
  final bool asFile;

  /// PDF üzerine elle yapılan çizimler (sayfa üstü katman). Boş = çizim yok.
  final List<InkStroke> ink;

  /// PDF/slayt sayfalarının üzerine bırakılan not balonları (bkz.
  /// [PageBubble]). Boş = balon yok.
  final List<PageBubble> bubbles;

  /// PDF/sunum ekinde sayfa SIRASINA karşılık gelen kalıcı sayfa kimlikleri:
  /// dizi indeksi = sayfa sırası (0 tabanlı), değer = o sayfanın kimliği.
  /// Boş = kimlik henüz atanmamış; kimlik `p<sayfaNo>` olarak TÜRETİLİR
  /// (bkz. `page_notes.dart` / [pageIdFor]).
  ///
  /// Neden var: sayfa notları doğrudan sayfa NUMARASINA bağlansaydı, PDF
  /// düzenleme (sayfa silme/ekleme/sıralama) gelir gelmez bütün notlar bir
  /// sayfa kayardı — 3. sayfanın notu 2. sayfanın altında belirirdi. Kimlik
  /// sayfayla birlikte taşınır: sayfa düzeni değişince YALNIZ bu liste
  /// yeniden yazılır, `Note.pageNotes` anahtarlarına dokunulmaz.
  final List<String> pageIds;
  final DateTime? createdAt;

  bool get isUploaded => downloadUrl.isNotEmpty;

  /// Ek SAYFADA yüzüyor mu? Görseller gibi videolar da serbest tuvale
  /// yerleşir ve olduğu yerde oynatılır (2026-08-06 isteği); PDF/ses/sunum
  /// hiçbir zaman yüzmez.
  bool get floatsOnPage =>
      (kind == AttachmentKind.image || kind == AttachmentKind.video) &&
      !asFile;

  /// [uploaded] yüklemesinin ürettiği DEPO alanlarını bu ekin üzerine geçirir;
  /// düzen alanları (konum/boyut/hiza/çizim) bu ekten korunur.
  ///
  /// Yükleme saniyeler sürer ve kullanıcı o sırada görseli taşıyıp
  /// boyutlandırabilir; yüklemenin başladığı andaki kopya olduğu gibi yazılsa
  /// bu düzen sessizce geri alınırdı (bkz. `NotesRepository.patchAttachment`).
  Attachment withUploadOf(Attachment uploaded) => copyWith(
    storagePath: uploaded.storagePath,
    downloadUrl: uploaded.downloadUrl,
    localPath: uploaded.localPath,
    sizeBytes: uploaded.sizeBytes,
    fileName: uploaded.fileName,
    mimeType: uploaded.mimeType,
    width: uploaded.width,
    height: uploaded.height,
  );

  /// [remote]'un depo/yükleme durumunu alıp bu ekin YEREL düzenini korur.
  ///
  /// Editör açıkken gelen her Firestore anlık görüntüsü ekleri olduğu gibi
  /// benimsiyordu; yazma ile anlık görüntü arasındaki yarışta (ya da başka bir
  /// cihazın eski kopyası geldiğinde) kullanıcının az önce verdiği konum/boyut
  /// bir kare için geri dönüyor ve o hâliyle yeniden kaydedilebiliyordu.
  Attachment withLayoutOf(Attachment local) => copyWith(
    displayWidth: local.displayWidth,
    align: local.align,
    x: local.x,
    y: local.y,
    pageY: local.pageY,
    asFile: local.asFile,
  );

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
    bool? asFile,
    List<InkStroke>? ink,
    List<PageBubble>? bubbles,
    List<String>? pageIds,
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
    asFile: asFile ?? this.asFile,
    ink: ink ?? this.ink,
    bubbles: bubbles ?? this.bubbles,
    pageIds: pageIds ?? this.pageIds,
    createdAt: createdAt,
  );

  /// [noteId] verilirse yerel yol cihazda TÜRETİLİR (bkz.
  /// [derivedAttachmentPath]); belgedeki `localPath` yalnız eski kayıtlar
  /// için yedek olarak okunur — yeni yazımlar bu alanı hiç içermez.
  factory Attachment.fromMap(Map<String, dynamic> map, {String? noteId}) =>
      Attachment(
        id: map['id'] as String? ?? '',
        kind: AttachmentKind.fromId(map['kind'] as String?),
        fileName: map['fileName'] as String? ?? '',
        mimeType: map['mimeType'] as String? ?? '',
        storagePath: map['storagePath'] as String? ?? '',
        downloadUrl: map['downloadUrl'] as String? ?? '',
        localPath: _resolveLocalPath(map, noteId),
        sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
        width: (map['width'] as num?)?.toInt(),
        height: (map['height'] as num?)?.toInt(),
        displayWidth: (map['displayWidth'] as num?)?.toDouble(),
        align: map['align'] as String? ?? 'center',
        x: (map['x'] as num?)?.toDouble(),
        y: (map['y'] as num?)?.toDouble(),
        pageY: (map['pageY'] as num?)?.toDouble(),
        asFile: map['asFile'] as bool? ?? false,
        ink: [
          for (final e in (map['ink'] as List?) ?? const [])
            InkStroke.fromMap(Map<String, dynamic>.from(e as Map)),
        ],
        bubbles: [
          for (final e in (map['bubbles'] as List?) ?? const [])
            PageBubble.fromMap(Map<String, dynamic>.from(e as Map)),
        ],
        pageIds: [
          for (final e in (map['pageIds'] as List?) ?? const []) e.toString(),
        ],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      );

  /// Cihazdaki dosyanın var olup olmadığına bakılmaksızın beklenen yerel yol;
  /// eski belgelerdeki `localPath` alanı yalnız türetilemediğinde kullanılır
  /// (türetilen yol bu cihaz için her zaman doğrudur, senkronlanan yol ise
  /// başka bir cihazın yolu olabilir).
  static String _resolveLocalPath(Map<String, dynamic> map, String? noteId) {
    if (noteId != null) {
      final derived = derivedAttachmentPath(
        noteId: noteId,
        attachmentId: map['id'] as String? ?? '',
        fileName: map['fileName'] as String? ?? '',
      );
      if (derived.isNotEmpty) return derived;
    }
    return map['localPath'] as String? ?? '';
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'kind': kind.id,
    'fileName': fileName,
    'mimeType': mimeType,
    'storagePath': storagePath,
    'downloadUrl': downloadUrl,
    // localPath BİLEREK YAZILMIYOR: mutlak cihaz yolu (Windows'ta kullanıcı
    // adı içerir) buluta senkronlanıyordu, başka cihazda anlamsızdı ve dosya
    // sistemi işlemlerini yanlış yola yönlendirebiliyordu. Yol artık okuma
    // sırasında türetiliyor (bkz. _resolveLocalPath).
    'sizeBytes': sizeBytes,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
    if (displayWidth != null) 'displayWidth': displayWidth,
    'align': align,
    if (x != null) 'x': x,
    if (y != null) 'y': y,
    if (pageY != null) 'pageY': pageY,
    // Yalnız true iken yazılır: eski notların şemasına yeni bir alan eklemez.
    if (asFile) 'asFile': true,
    if (ink.isNotEmpty) 'ink': [for (final s in ink) s.toMap()],
    // Çizimle aynı kural: yalnız doluysa yazılır, balonsuz ekin şeması büyümez.
    if (bubbles.isNotEmpty) 'bubbles': [for (final b in bubbles) b.toMap()],
    // Yalnız atanmışsa yazılır: kimlik atanmamış ekte alan hiç oluşmaz
    // (türetilen `p<sayfaNo>` zaten aynı sonucu verir) ve eski notların
    // şeması büyümez.
    if (pageIds.isNotEmpty) 'pageIds': pageIds,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
