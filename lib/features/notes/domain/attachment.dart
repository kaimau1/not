import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

import '../../../core/utils/local_file.dart';

enum AttachmentKind {
  image('image'),
  pdf('pdf'),
  audio('audio'),
  slide('slide'),

  /// Görüntülü not. YALNIZCA CİHAZDA kalır — Storage'a hiç yüklenmez
  /// (bkz. UploadQueue), bu yüzden cihazlar arasında senkronlanmaz.
  video('video'),

  /// **METİN EKİ** (.txt) — ses/video/görselin TRANSKRİPTİ (kullanıcı isteği
  /// 2026-10-17: "transkriptini metin dosyası olarak ek olarak nota ekleme
  /// ve okuyabilme"). İçerik kaydın kendisinde ([Attachment.text]) durur ve
  /// notla birlikte senkronlanır: dosya yüklenmez, her cihaz anında okur,
  /// arama ve dışa aktarma metni doğrudan alır. Paylaşırken/dışa aktarırken
  /// `.txt` dosyası olarak çıkar (bkz. `AttachmentRepository.readBytes`).
  text('text'),

  /// **BU SÜRÜMÜN TANIMADIĞI TÜR** (F1.5, 2026-10-19). Daha yeni bir
  /// sürümün eklediği tür eskiden sessizce `image`e düşüyordu; eski istemci
  /// notu kaydedince ek `kind: image` + metinsiz geri yazılıp BOZULUYORDU.
  /// Artık asıl kimlik [Attachment.rawKind]'da saklanır ve [Attachment.toMap]
  /// onu AYNEN geri yazar; arayüz "uygulamayı güncelle" kutusu gösterir,
  /// ek açılmaz/düzenlenmez/yüklenmez. Kayda hiç bu kimlikle yazılmaz.
  unknown('');

  const AttachmentKind(this.id);

  final String id;

  /// Eksik/boş kimlik eski kayıtlarda görsel demekti (tür alanı sonradan
  /// geldi) — `image` kalır. Dolu ama tanınmayan kimlik [unknown] olur.
  static AttachmentKind fromId(String? id) {
    if (id == null || id.isEmpty) return AttachmentKind.image;
    for (final k in AttachmentKind.values) {
      if (k != AttachmentKind.unknown && k.id == id) return k;
    }
    return AttachmentKind.unknown;
  }
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
    this.pressures,
  });

  /// 1 tabanlı sayfa numarası.
  final int page;

  /// ARGB değeri.
  final int color;

  /// Sayfa genişliğinin oranı olarak çizgi kalınlığı.
  final double width;

  /// Düzleştirilmiş nokta listesi: [x1, y1, x2, y2, ...], her biri 0–1.
  /// Kayıttan okunan çizgide `Float32List` (F7.2: kutulu double'ın ~1/5'i;
  /// float32 yuvarlaması 0–1 aralığında ~1e-8, ekranda görünmez). Çizim
  /// SÜRERKEN büyüyen çizgi büyüyebilir liste kalır ([InkController]).
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

  /// **KALEM BASINCI** (kullanıcı isteği 2026-10-23: "Samsung Notes'tan geri
  /// kalmamalıyız"): basınç algılayan kalemle çizilen çizgide nokta başına
  /// bir değer (0–1); kalınlık noktada `width × basınç eğrisi` olur
  /// ([inkPressureFactor]). Parmakla/fareyle çizgide null — şema büyümez.
  /// Uzunluk [points]in YARISI değilse (eski istemci noktaları kırptı)
  /// yok sayılır ([hasPressure]).
  final List<double>? pressures;

  /// Basınç listesi noktalarla eşleşiyor mu (çizim buna göre değişken kalın).
  bool get hasPressure {
    final p = pressures;
    return p != null && p.isNotEmpty && p.length * 2 == points.length;
  }

  factory InkStroke.fromMap(Map<String, dynamic> map) => InkStroke(
    page: (map['p'] as num?)?.toInt() ?? 1,
    color: (map['c'] as num?)?.toInt() ?? 0xFF000000,
    width: (map['w'] as num?)?.toDouble() ?? 0.004,
    points: _points(map['d'] as List?),
    arrow: map['a'] as bool? ?? false,
    pressures: map['q'] is List ? _points(map['q'] as List?) : null,
  );

  /// Aynı çizginin yeni nokta listesiyle kopyası (kırp/yerleştir/döndür):
  /// basınç nokta başına olduğundan dönüşümlerden aynen geçer.
  InkStroke copyWith({int? page, double? width, List<double>? points}) =>
      InkStroke(
        page: page ?? this.page,
        color: color,
        width: width ?? this.width,
        points: points ?? this.points,
        arrow: arrow,
        pressures: pressures,
      );

  static List<double> _points(List? raw) {
    if (raw == null || raw.isEmpty) return Float32List(0);
    if (raw is Float32List) return raw;
    final out = Float32List(raw.length);
    for (var i = 0; i < raw.length; i++) {
      out[i] = (raw[i] as num).toDouble();
    }
    return out;
  }

  Map<String, dynamic> toMap() => {
    'p': page,
    'c': color,
    'w': width,
    // Kopyasız düz liste görünümü: Firestore kodlayıcısı `Float32List`i
    // tipli dizi (float[]) olarak yollar, sunucu kabul etmez.
    'd': points is Float32List ? UnmodifiableListView(points) : points,
    if (arrow) 'a': true,
    if (hasPressure)
      'q': pressures is Float32List
          ? UnmodifiableListView(pressures!)
          : pressures,
  };
}

/// Basınçtan kalınlık çarpanı: hafif dokunuş ince (×0,35), sert basış kalın
/// (×1,4); orta basınç (~0,5) seçilen kalınlığa yakın düşer.
double inkPressureFactor(double pressure) =>
    0.35 + 1.05 * pressure.clamp(0.0, 1.0);

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
    this.arrow = true,
    this.plain = false,
    this.size = 1,
    this.bold = false,
    this.italic = false,
    this.fill = 0,
    this.align = 0,
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

  /// Balonu vurguladığı metne bağlayan OK çizilsin mi?
  ///
  /// Kullanıcı isteği (2026-08-09): "ok işaretini kaldırma seçeneği olmalı."
  /// Sık sık vurgu yapılan bir sayfada oklar birbirini kesip belgeyi okunmaz
  /// hâle getirebiliyor; balon başına kapatılabilir. Varsayılan AÇIK — eski
  /// kayıtlarda alan yok ve okun kaybolması sürpriz olurdu.
  final bool arrow;

  /// **AÇIK METİN ALANI** — Paint'in metin aracı gibi.
  ///
  /// Kullanıcı isteği 2026-08-16: "balon moduna ek özellik olarak açık metin
  /// alanı paintteki gibi". Normal balon sayfada küçük bir tutamaç olarak
  /// durur ve yazısı ancak dokununca açılır — yerine bir şey YAZMAK
  /// (bir çizime etiket koymak, bir fotoğrafın üstüne tarih düşmek) için
  /// fazladan bir adım demek. `plain` balonun yazısı sayfanın üstünde
  /// DOĞRUDAN, tutamaçsız çizilir; dokunulunca yine aynı kart açılır.
  ///
  /// Veri modeli aynı kalır (renk, taşıma, silme, senkron, paylaşım, toplu
  /// liste hepsi olduğu gibi çalışır) — değişen yalnız ÇİZİM biçimi.
  final bool plain;

  /// **Açık metin alanının YAZI BOYU ÇARPANI** (1 = varsayılan boy).
  ///
  /// Kullanıcı isteği 2026-08-18: "açık metin balonu Paint'teki gibi boyutu
  /// ayarlanabilir olmalı". Sayfanın köşesindeki tutamaç sürüklenerek
  /// büyütülüp küçültülür; değer nota yazıldığı için cihazlar arasında ve
  /// paylaşılan PDF'te de aynı kalır.
  ///
  /// Çarpan (mutlak punto değil): yazı ekran uzayında çiziliyor, çarpan
  /// yakınlaştırmadan bağımsız olarak "iki kat büyük" demeyi sürdürür.
  /// [minSize]–[maxSize] arasına kıstırılır.
  final double size;

  /// **AÇIK METİN ALANININ BİÇİMİ** (kullanıcı isteği: "metin kutusunu
  /// geliştirme").
  ///
  /// Kutu şimdiye dek yalnız RENK ve BOY veriyordu. Paint'in metin aracının
  /// karşılığı olarak konmuştu ama iki eksiği vardı:
  /// * Fotoğraf ya da taranmış bir sayfanın üstünde yazı, zemin karışık
  ///   olduğunda dış hatla bile zor okunuyordu — **dolgu** ([fill]) yazının
  ///   arkasına düz bir zemin koyar, yazı her belgede okunur olur.
  /// * Bir başlık ya da uyarı vurgulanamıyordu — **kalın/italik** ([bold],
  ///   [italic]) ve çok satırlı yazıda **hizalama** ([align]) eklendi.
  ///
  /// Hepsi eski kayıtlarda YOK ve varsayılanları eski davranışı verir
  /// (kalın değil, italik değil, dolgusuz, sola dayalı) — eski notlar
  /// olduğu gibi çizilmeye devam eder.
  final bool bold;
  final bool italic;

  /// Yazının arkasındaki dolgu rengi (ARGB); 0 = dolgu yok.
  final int fill;

  /// Çok satırlı yazının hizası: 0 sola, 1 ortaya, 2 sağa. Sayı olarak
  /// tutulur — alan adı kısa kalsın ve etki alanı `dart:ui`ye bağlanmasın
  /// (çizim tarafı `TextAlign`e çevirir).
  final int align;

  /// Açık metin alanının en küçük/en büyük yazı boyu çarpanı. Alt sınır
  /// okunaklılık, üst sınır sayfayı tümüyle kapatan bir yazı için.
  static const double minSize = 0.5;
  static const double maxSize = 5;

  /// Çarpanın ekrandaki karşılığı: 16 px taban.
  static const double baseFontSize = 16;

  /// TUTAMACIN (normal balon) boyut çarpanı sınırları — kullanıcı isteği
  /// 2026-10-16: "balonların boyutu ayarlanabilir olsun". Aynı [size] alanı:
  /// açık metinde yazının puntosu, normal balonda tutamacın kendisi büyür.
  /// Eski kayıtlarda 1 (varsayılan boy) — eski balonlar aynen çizilir.
  static const double minPinSize = 0.6;
  static const double maxPinSize = 2.5;

  /// "Küçült / Büyüt" düğmelerinin adımları.
  static const sizeSteps = <double>[0.6, 0.75, 1, 1.25, 1.5, 2, 2.5];

  /// [current]'tan bir adım küçük ([direction] < 0) ya da büyük boy.
  /// Açık metin kendi sınırlarını ([minSize]–[maxSize]) korur ve adımları
  /// aşan boyda (köşe tutamacıyla büyütülmüş) %25 yürür.
  static double stepSize(double current, int direction, {bool plain = false}) {
    final lo = plain ? minSize : minPinSize;
    final hi = plain ? maxSize : maxPinSize;
    double next;
    if (direction > 0) {
      next = sizeSteps.firstWhere(
        (s) => s > current + 0.01,
        orElse: () => current * 1.25,
      );
    } else {
      next = sizeSteps.lastWhere(
        (s) => s < current - 0.01,
        orElse: () => current / 1.25,
      );
    }
    return next.clamp(lo, hi).toDouble();
  }

  double get fontSize => baseFontSize * size;

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
    bool? arrow,
    bool? plain,
    double? size,
    bool? bold,
    bool? italic,
    int? fill,
    int? align,
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
    plain: plain ?? this.plain,
    arrow: arrow ?? this.arrow,
    size: (size ?? this.size).clamp(minSize, maxSize),
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    fill: fill ?? this.fill,
    align: align ?? this.align,
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
    rects: _rectsFromMap(map),
    // Alan YOKSA ok çizilir: eski kayıtlarda ok vardı, okuma onu düşürmemeli.
    arrow: map['a'] as bool? ?? true,
    plain: map['n'] as bool? ?? false,
    // Alan yoksa varsayılan boy: eski kayıtlar olduğu gibi çizilir.
    size: ((map['z'] as num?)?.toDouble() ?? 1).clamp(minSize, maxSize),
    bold: map['b'] as bool? ?? false,
    italic: map['e'] as bool? ?? false,
    fill: (map['f'] as num?)?.toInt() ?? 0,
    align: (map['g'] as num?)?.toInt() ?? 0,
  );

  /// Vurgu dikdörtgenlerini kayıttan okur.
  ///
  /// **KÖK NEDEN (kullanıcı bulgusu 2026-08-08: "metin seçip üzerine balon
  /// koyunca o balon kaydolmuyor, geri gidince kayboluyor").** Dikdörtgenler
  /// `[[l,t,r,b], [l,t,r,b]]` yani DİZİ İÇİNDE DİZİ olarak yazılıyordu;
  /// **Firestore iç içe dizi kabul etmez** ve o notun yazımı tümüyle
  /// reddediliyordu. Yani yalnız vurgu değil, vurgu eklendikten sonraki her
  /// değişiklik de kaydedilmiyordu. Artık DÜZ liste yazılıyor
  /// (`[l,t,r,b,l,t,r,b,...]` — çizimdeki [InkStroke.points] ile aynı kural).
  ///
  /// Okuma İKİ biçimi de anlar: elde eski biçimde kalmış bir kayıt (paket
  /// dosyası, yerel anlık görüntü) sessizce kaybolmasın.
  static List<PageBubbleRect> _rectsFromMap(Map<String, dynamic> map) {
    final raw = map['r'] as List?;
    if (raw == null || raw.isEmpty) return const [];
    if (raw.first is List) {
      return [
        for (final e in raw) PageBubbleRect.fromList((e as List).cast<num>()),
      ];
    }
    final flat = [for (final v in raw) (v as num).toDouble()];
    return [
      for (var i = 0; i + 3 < flat.length; i += 4)
        PageBubbleRect(flat[i], flat[i + 1], flat[i + 2], flat[i + 3]),
    ];
  }

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
    // Yalnız KAPATILDIYSA yazılır (varsayılan açık — bkz. [arrow]).
    if (!arrow) 'a': false,
    if (plain) 'n': true,
    // Yalnız DEĞİŞTİRİLDİYSE yazılır (varsayılan 1).
    if (size != 1) 'z': size,
    if (bold) 'b': true,
    if (italic) 'e': true,
    if (fill != 0) 'f': fill,
    if (align != 0) 'g': align,
    // DÜZ liste: Firestore iç içe dizi kabul etmiyor (bkz. [_rectsFromMap]).
    if (rects.isNotEmpty)
      'r': [
        for (final r in rects) ...[r.left, r.top, r.right, r.bottom],
      ],
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
      points
        ..add(x)
        ..add(y);
    }
    // Hiçbir noktası yeni çerçeveye düşmeyen çizgi atılır; kısmen taşan çizgi
    // korunur (çizim katmanı zaten kırpar) — yoksa kenardaki bir imza
    // tek nokta yüzünden tümüyle silinirdi.
    if (!anyInside) continue;
    // Kalınlık görsel GENİŞLİĞİNİN oranı; çerçeve daraldıkça oran büyür.
    out.add(s.copyWith(width: s.width / w, points: points));
  }
  return out;
}

/// [cropInk]'in TERSİ: görselin oranlı uzayındaki çizimleri, görselin
/// [frame] dikdörtgeninde durduğu bir SAYFANIN uzayına taşır.
///
/// Görsel balonlu görünüme alınınca A4 bir PDF sayfasına ortalanarak
/// yerleşir (bkz. `ScanPdf.imageFrameOnPage`); üstüne çizilmiş imza/ok
/// olduğu yerde kalmalı. Kalınlık sayfa GENİŞLİĞİNİN oranı olduğundan
/// çerçevenin genişliğiyle küçülür.
List<InkStroke> placeInk(
  List<InkStroke> strokes,
  PageBubbleRect frame, {
  int page = 1,
}) {
  final w = frame.right - frame.left;
  final h = frame.bottom - frame.top;
  return [
    for (final s in strokes)
      s.copyWith(
        page: page,
        width: s.width * w,
        points: [
          for (var i = 0; i + 1 < s.points.length; i += 2) ...[
            frame.left + s.points[i] * w,
            frame.top + s.points[i + 1] * h,
          ],
        ],
      ),
  ];
}

/// [placeInk]'in balon karşılığı: konum ve vurgu dikdörtgenleri sayfaya.
List<PageBubble> placeBubbles(
  List<PageBubble> bubbles,
  PageBubbleRect frame, {
  int page = 1,
}) {
  final w = frame.right - frame.left;
  final h = frame.bottom - frame.top;
  return [
    for (final b in bubbles)
      b.copyWith(
        page: page,
        x: frame.left + b.x * w,
        y: frame.top + b.y * h,
        rects: [
          for (final r in b.rects)
            PageBubbleRect(
              frame.left + r.left * w,
              frame.top + r.top * h,
              frame.left + r.right * w,
              frame.top + r.bottom * h,
            ),
        ],
      ),
  ];
}

/// [placeBubbles]'ın TERSİ: sayfada [frame] dikdörtgeninde duran görselin
/// balonlarını görselin kendi oranlı uzayına geri taşır (yalnız [page]
/// sayfasındakiler). Görselden türetilmiş balonlu belge klasik görünümde
/// gizliyken balonlar sabit görselin üstünde bu yoldan çizilir.
List<PageBubble> unplaceBubbles(
  List<PageBubble> bubbles,
  PageBubbleRect frame, {
  int page = 1,
}) {
  final w = frame.right - frame.left;
  final h = frame.bottom - frame.top;
  if (w <= 0 || h <= 0) return const [];
  return [
    for (final b in bubbles)
      if (b.page == page)
        b.copyWith(
          x: (b.x - frame.left) / w,
          y: (b.y - frame.top) / h,
          rects: [
            for (final r in b.rects)
              PageBubbleRect(
                (r.left - frame.left) / w,
                (r.top - frame.top) / h,
                (r.right - frame.left) / w,
                (r.bottom - frame.top) / h,
              ),
          ],
        ),
  ];
}

/// Görsel 90°'nin katlarıyla döndürülünce üstündeki çizimleri de döndürür.
///
/// [cropInk] ile aynı gerekçe: noktalar görselin ORANI (0–1) olarak tutuluyor,
/// görsel dönüp çizgiler olduğu gibi kalırsa imza/işaret görselin bambaşka bir
/// yerine düşer.
///
/// Saat yönünde çeyrek tur: `(x, y) → (1 - y, x)`. Tur sayısı 4'e göre
/// indirgenir; negatif değer (sola döndürme) pozitife çevrilir, böylece tek
/// bir dönüşüm art arda uygulanarak 180° ve 270° de çıkar. Kalınlık görsel
/// genişliğinin oranı olduğundan tek sayıda turda en/boy yer değiştirir ve
/// oran da o ölçüde değişir — ama [InkStroke.width] görselin dar kenarına
/// göre değil genişliğine göre ölçeklendiğinden burada düzeltme YAPILMAZ:
/// kırpmadan farklı olarak döndürme görselin alanını değiştirmez, çizgi
/// kalınlığındaki fark gözle ayırt edilemeyecek kadar küçüktür.
List<InkStroke> rotateInk(List<InkStroke> strokes, int quarterTurns) {
  var turns = quarterTurns % 4;
  if (turns < 0) turns += 4;
  if (turns == 0 || strokes.isEmpty) return strokes;
  var current = strokes;
  for (var turn = 0; turn < turns; turn++) {
    current = [
      for (final s in current)
        s.copyWith(
          points: [
            for (var i = 0; i + 1 < s.points.length; i += 2) ...[
              1 - s.points[i + 1],
              s.points[i],
            ],
          ],
        ),
    ];
  }
  return current;
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

/// Ağır belge İLK kez geldiğinde (F3.13) editörün ek listesi (F5.6).
///
/// Normalde [incoming] olduğu gibi benimsenir: yereldeki hafif kopyanın ağır
/// alanları boş, birleştirme onları ağır veriye tercih ederdi. Ama açılıştan
/// sonraki ilk yüzlerce ms'de eklenen/taşınan ve henüz KAYDEDİLMEMİŞ
/// ([localPending]) ek değişikliği o zaman siliniyordu. Bekleyen yerel
/// değişiklik varsa liste YERELDİR; ağır alanlar (çizim, balon, PDF
/// işaretleri) ek kimliğiyle gelen kopyadan işlenir.
List<Attachment> hydrateAttachments({
  required List<Attachment> local,
  required List<Attachment> incoming,
  required bool localPending,
}) {
  if (!localPending) return incoming;
  final heavy = {for (final a in incoming) a.id: a};
  return [
    for (final a in local)
      if (heavy[a.id] case final h?)
        a.copyWith(ink: h.ink, bubbles: h.bubbles, pdfMarks: h.pdfMarks)
      else
        a,
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
    this.driveId = '',
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
    this.onPage = false,
    this.pdfPage = 1,
    this.pdfTurns = 0,
    this.pdfMarks = const [],
    this.section = '',
    this.ink = const [],
    this.bubbles = const [],
    this.pageIds = const [],
    this.webUrl = '',
    this.pinHeight = 0,
    this.sourceId = '',
    this.bubblesHidden = false,
    this.text = '',
    this.transcriptOf = '',
    this.sourceDigest = '',
    this.caption = '',
    this.wave = const [],
    this.createdAt,
    this.rawKind = '',
    this.extras = const {},
  });

  /// Kayıttaki `kind` kimliği AYNEN — yalnız [AttachmentKind.unknown] iken
  /// anlamlı; [toMap] tanınmayan türü bununla geri yazar (F1.5).
  final String rawKind;

  /// Bu sürümün TANIMADIĞI anahtarlar (daha yeni sürümün eklediği alanlar).
  /// [fromMap] saklar, [toMap] AYNEN geri yazar: eski istemci yeni alanı
  /// silemez (F1.5). Bilinen anahtarlar [knownKeys]'de.
  final Map<String, dynamic> extras;

  /// [toMap]'in yazabildiği bütün anahtarlar (+ eski kayıtlardaki
  /// `localPath`). Yeni alan eklenince BURAYA da eklenmeli; test
  /// (`forward_compat_test`) toMap çıktısının bu kümede kaldığını doğrular.
  static const knownKeys = <String>{
    'id',
    'kind',
    'fileName',
    'mimeType',
    'storagePath',
    'downloadUrl',
    'driveId',
    'localPath',
    'sizeBytes',
    'width',
    'height',
    'displayWidth',
    'align',
    'x',
    'y',
    'pageY',
    'asFile',
    'onPage',
    'pdfPage',
    'pdfTurns',
    'pdfMarks',
    'section',
    'ink',
    'bubbles',
    'pageIds',
    'webUrl',
    'pinHeight',
    'sourceId',
    'bubblesHidden',
    'text',
    'transcriptOf',
    'sourceDigest',
    'caption',
    'wave',
    'createdAt',
  };

  /// **GÖRSEL AÇIKLAMASI** (kullanıcı isteği 2026-10-28: "görüntü açıklaması
  /// kısmı da güzel"): görselin hemen altında duran kısa yazı. Notun metni
  /// değil, görselin parçası — görsel taşınınca/silinince onunla gider.
  /// Aramada ve dışa aktarmada görselin yerine geçer. Yalnız doluyken yazılır.
  final String caption;

  /// Açıklamanın karakter tavanı (iki-üç satırlık altyazı; uzun yazı notun
  /// gövdesine aittir).
  static const maxCaptionChars = 280;

  /// **SES DALGASI** (kullanıcı isteği 2026-10-28: sesli not dalga formuyla):
  /// kayıt sırasında ölçülen genliklerin [waveBars] çubuğa indirgenmiş hâli,
  /// her biri 0–100. Oynatıcı bunu çizer — dosyayı çözmeden, her cihazda
  /// aynı. Boşsa (eski kayıt, dışarıdan eklenen dosya) ekin kimliğinden
  /// türetilen kararlı bir desen çizilir ([displayWave]).
  final List<int> wave;

  /// Saklanan dalganın çubuk sayısı (kayda ~100 bayt).
  static const waveBars = 48;

  /// Çizilecek dalga: kayıtlıysa o, değilse kimlikten türeyen yumuşak desen
  /// (her açılışta aynı — rastgele değil).
  List<int> get displayWave {
    if (wave.isNotEmpty) return wave;
    var seed = 0;
    for (final c in id.codeUnits) {
      seed = (seed * 31 + c) & 0x7fffffff;
    }
    return [
      for (var i = 0; i < waveBars; i++)
        () {
          seed = (seed * 1103515245 + 12345) & 0x7fffffff;
          // Konuşma gibi: ortası dolgun, uçları alçak, arada dalgalanma.
          final envelope = 0.45 + 0.55 * (1 - ((i / waveBars) * 2 - 1).abs());
          return (20 + (seed % 70) * envelope).round().clamp(8, 100);
        }(),
    ];
  }

  /// Ölçülen genlik dizisini (her biri 0–1) [waveBars] çubuğa indirger:
  /// her çubuk kendi dilimindeki EN YÜKSEK değer (kısa heceler kaybolmasın).
  static List<int> compactWave(List<double> levels) {
    if (levels.isEmpty) return const [];
    final out = <int>[];
    for (var i = 0; i < waveBars; i++) {
      final from = (i * levels.length / waveBars).floor();
      final to = (((i + 1) * levels.length) / waveBars).ceil().clamp(
        from + 1,
        levels.length,
      );
      var peak = 0.0;
      for (var j = from; j < to && j < levels.length; j++) {
        if (levels[j] > peak) peak = levels[j];
      }
      out.add((peak.clamp(0.0, 1.0) * 100).round());
    }
    return out;
  }

  /// Bu sürümün işleyemediği (daha yeni sürümde eklenmiş) ek mi?
  bool get isUnsupported => kind == AttachmentKind.unknown;

  /// TÜRETİLMİŞ belgenin üretildiği kaynak içeriğin özeti (yalnız metin →
  /// balonlu belgede; bkz. [digestOf]). Metin sonradan düzenlenince özet
  /// tutmaz ve belge balonluya geçişte yeniden dizilir. Boş = bilinmiyor.
  final String sourceDigest;

  /// Metnin kısa, kararlı özeti (SHA-1'in ilk 16 hanesi).
  static String digestOf(String text) =>
      sha1.convert(utf8.encode(text)).toString().substring(0, 16);

  /// METİN EKİNİN içeriği (yalnız [AttachmentKind.text]); öbür türlerde boş.
  /// Firestore belge sınırı (1 MiB) yüzünden [maxTextChars]'ta kesilir.
  final String text;

  /// Metin eki hangi ekin TRANSKRİPTİ (ses/video/görsel kimliği; boş =
  /// bağımsız metin eki). `sourceId`den AYRI alan: o, görselden türetilen
  /// balonlu belgeyi klasik görünümde GİZLER (bkz. `Note.hidesDerivedDocument`)
  /// — transkript ise her görünümde şeritte durmalı.
  final String transcriptOf;

  /// Metin ekinin karakter tavanı (~120 bin karakter ≈ 1 saatlik konuşma).
  /// Not belgesi tek parça yazıldığından daha büyüğü belgeyi 1 MiB sınırına
  /// yaklaştırır ve her kayıtta gereksiz yere ağdan gider.
  static const maxTextChars = 120000;

  /// Dosyası buluta YÜKLENMEYEN tür mü? Görüntülü not yalnız cihazda kalır;
  /// metin eki içeriğini kaydın kendisinde taşır ([text]) — yüklenecek dosya
  /// yok, kuyruk ikisini de atlar.
  bool get skipsUpload =>
      kind == AttachmentKind.video ||
      kind == AttachmentKind.text ||
      kind == AttachmentKind.unknown;

  /// Belgenin BALONLARI gizli mi (kullanıcı isteği 2026-10-16: "balonları
  /// göster/gizle olsun; balonludan üste sabitlemeye alınınca da balonlar
  /// görülsün ama göster/gizlesi olsun"). Yalnız GÖRÜNÜM tercihi: balonlar
  /// silinmez, toplu listede ve paylaşımda durur. Belge başına saklanır
  /// (bir belgede gizlemek ötekileri etkilemez) ve senkronlanır.
  final bool bubblesHidden;

  final String id;
  final AttachmentKind kind;
  final String fileName;
  final String mimeType;
  final String storagePath;
  final String downloadUrl;

  /// **GOOGLE DRIVE** kopyasının dosya kimliği (kullanıcının Drive'ındaki
  /// uygulama klasörü — bkz. `drive_store.dart`). Boş = Drive'da yok.
  ///
  /// Kullanıcı isteği 2026-10-15: "eklerin ve görsellerin senkronizasyonu
  /// Google Drive'a bağlansın, oradaki kota kullanılsın". Drive dosyası
  /// özeldir — herkese açık bir adresi yok; öbür cihaz onu kendi Google
  /// yetkisiyle İNDİRİP yerel kopyaya yazar ve her ekran zaten önce yerel
  /// kopyaya baktığı için oradan çizer. Bu yüzden [downloadUrl]'a
  /// (Storage'ın herkese açık jetonlu adresi) dokunulmaz, ayrı alan.
  final String driveId;

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

  // ── PDF SAYFAYA GÖMÜLÜNCE (kullanıcı isteği 2026-09-06: "PDF'yi sayfaya
  // entegre etme, aynı görsel gibi sayfaya yerleşir ancak sayfa
  // değiştirilebilir") ────────────────────────────────────────────────────
  // Görselin `asFile`ı burada TERSİNE çalışıyor: görsel varsayılan olarak
  // sayfada yüzer, PDF ise varsayılan olarak şeritte durur. Yeni bir alan
  // gerekiyordu, çünkü `asFile: false` var olan bütün PDF eklerinde zaten
  // yazılı — anlamını değiştirmek her eski notun PDF'ini bir anda sayfanın
  // ortasına taşırdı.

  /// PDF / metin / ses eki sayfada mı duruyor? (Görsel/videoda yok sayılır —
  /// onların yeri [asFile] ile belirlenir; bkz. [stripByDefault].)
  final bool onPage;

  /// Sayfada gösterilen PDF sayfası (1 tabanlı). Notla birlikte senkronlanır:
  /// belge kaldığı sayfadan açılır, öbür cihazda da aynı sayfa görünür.
  final int pdfPage;

  /// Sayfadaki PDF kutusunun görüntü döndürmesi (90°'nin katı, 0–3).
  /// Yalnız GÖRÜNTÜyü döndürür; PDF dosyasına dokunulmaz (sayfaları kalıcı
  /// döndürmek için sayfa yöneticisi var, bkz. `pdf_pages_screen.dart`).
  final int pdfTurns;

  /// Yer imi konan PDF sayfaları (1 tabanlı, artan). Uzun belgede "kaldığım
  /// yerler" listesi.
  final List<int> pdfMarks;

  /// ARŞİV DEFTERİNDE ekin hangi ELLE AÇILMIŞ sayfaya konduğu
  /// (bkz. `Note.archivePages`). Boş = sayfa seçilmemiş; ek o zaman türüne
  /// göre kendiliğinden dolan sayfada (Görseller / Videolar / Belgeler)
  /// görünür. Arşiv dışındaki notlarda yok sayılır.
  final String section;

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

  /// WEB VİDEOSU (YouTube) bağlantısı — yalnız [AttachmentKind.video]'da.
  /// Dosya yoktur: video gömülü oynatıcıda akar, not ile birlikte buluta
  /// gider (yalnız bağlantı) ve her cihazda oynar. Neden `downloadUrl`
  /// değil: o alan "Storage'a yüklendi" anlamı taşıyor ([isUploaded]) ve
  /// görsel önbelleği/silme yolları onu Storage adresi sanardı.
  final String webUrl;

  /// **ÜSTE SABİTLİ** medya (kullanıcı isteği 2026-10-11: "üstte video/resim,
  /// altta not"): 0'dan büyükse görsel/video sayfada yüzmez, notun ÜSTÜNDE
  /// sabit bir bölmede durur ve metin altında kayar. Değer bölmenin
  /// yüksekliği (dp) — ayraç sürüklenerek değişir. 0 = hiç sabitlenmedi.
  ///
  /// NEGATİF = sabit DEĞİL ama son bölme yüksekliği hatırlanıyor (kullanıcı
  /// bulgusu 2026-10-11: "geri serbestleştirince boyut sıfırlanıyor, eski
  /// boyut hatırlanmalı"). Sabitlemeden çıkmak işareti çevirir; sayfadaki
  /// konum/genişlik (x, pageY, displayWidth) sabitlerken hiç silinmediği
  /// için medya eski yerine eski boyutuyla döner.
  final double pinHeight;

  /// Bu belge hangi GÖRSELDEN üretildi (boş = sıradan ek).
  ///
  /// Kullanıcı isteği 2026-10-16: sabit / yüzen / balonlu geçişi bütün
  /// eklerde olmalı. Balon bir belge SAYFASINDA yaşadığı için görsel
  /// balonluya alınınca tek sayfalık bir PDF'e çevrilir (yakalama levhasının
  /// "balonlu" kipiyle aynı yol). Görsel klasiğe dönünce bu belge GİZLENİR
  /// (görselin kendisi sayfasına döner); yeniden balonluya alınınca AYNI
  /// belge — balonları ve çizimleriyle — geri gelir, ikinci kopya üretilmez.
  /// Kaynak görsel silinirse belge sıradan bir ek gibi görünür.
  final String sourceId;

  final DateTime? createdAt;

  bool get isUploaded => downloadUrl.isNotEmpty;

  /// Google Drive'da kopyası var mı (bkz. [driveId]).
  bool get isInDrive => driveId.isNotEmpty;

  /// Bulutta (Storage YA DA Drive) bir kopyası var mı — başka cihaz ona
  /// ulaşabilir mi.
  bool get isSynced =>
      isUploaded || isInDrive || kind == AttachmentKind.text;

  /// YouTube (web) videosu mu — dosyası yok, gömülü oynatıcıda açılır.
  bool get isWebVideo => kind == AttachmentKind.video && webUrl.isNotEmpty;

  /// Bir sonraki sabitlemede kullanılacak, HATIRLANAN bölme yüksekliği
  /// (hiç sabitlenmediyse null).
  double? get rememberedPinHeight => pinHeight == 0 ? null : pinHeight.abs();

  /// Notun üstündeki sabit bölmede mi (bkz. [pinHeight]).
  ///
  /// PDF de sabitlenir (kullanıcı isteği 2026-10-16: "PDF'lerde üste
  /// sabitleme yapamıyorum"): bölmede sayfa çevrilebilen belge kutusu durur,
  /// not altında yazılır. Balonlu görünümden farkı: belge notun KENDİSİ
  /// olmaz, not metin notu kalır.
  ///
  /// METİN ve SES de sabitlenir (kullanıcı isteği 2026-10-17: "txt dosyaları
  /// da ekrana gömme, yukarı sabitleme ve balonlu geçiş; bu geçiş olabilecek
  /// TÜM türler için çalışmalı"): bölmede metin okunur ya da ses çalar, not
  /// altında yazılır. Sunum da sabitlenir (2026-10-17, bkz. `SlidePageBox`).
  bool get isPinnedTop =>
      pinHeight > 0 &&
      (kind == AttachmentKind.image ||
          kind == AttachmentKind.video ||
          kind == AttachmentKind.pdf ||
          kind == AttachmentKind.text ||
          kind == AttachmentKind.audio ||
          kind == AttachmentKind.slide);

  /// Varsayılan yeri ALT ŞERİT olan türler: sayfaya [onPage] ile gömülürler
  /// (görsel/video ise varsayılan olarak sayfadadır, şeride [asFile] ile
  /// iner). SUNUM da 2026-10-17'den beri gömülür ve sabitlenir (bkz.
  /// `SlidePageBox`; kullanıcı isteği: "sunum gibi diğer tipteki dosyalarda
  /// gömülü, Sabit, Balonlu seçeneklerinin hepsi olmalı").
  bool get stripByDefault =>
      kind == AttachmentKind.pdf ||
      kind == AttachmentKind.text ||
      kind == AttachmentKind.audio ||
      kind == AttachmentKind.slide;

  /// Ek sayfanın DIŞINDA mı (şeritte ya da yalnız bölmede)?
  bool get offPage => stripByDefault ? !onPage : asFile;

  /// Eki sayfaya koyan ([on]) ya da şeride indiren kopya — türün kendi
  /// alanıyla ([onPage] / [asFile]).
  Attachment placedOnPage(bool on) =>
      stripByDefault ? copyWith(onPage: on) : copyWith(asFile: !on);

  /// Ek SAYFADA yüzüyor mu? Görseller gibi videolar da serbest tuvale
  /// yerleşir ve olduğu yerde oynatılır (2026-08-06 isteği); PDF, metin ve
  /// ses sayfaya gömülünce ([onPage]) yüzer; sunum hiçbir zaman yüzmez.
  bool get floatsOnPage =>
      ((kind == AttachmentKind.image || kind == AttachmentKind.video) &&
          !asFile &&
          !isPinnedTop) ||
      (stripByDefault && onPage && !isPinnedTop);

  /// [uploaded] yüklemesinin ürettiği DEPO alanlarını bu ekin üzerine geçirir;
  /// düzen alanları (konum/boyut/hiza/çizim) bu ekten korunur.
  ///
  /// Yükleme saniyeler sürer ve kullanıcı o sırada görseli taşıyıp
  /// boyutlandırabilir; yüklemenin başladığı andaki kopya olduğu gibi yazılsa
  /// bu düzen sessizce geri alınırdı (bkz. `NotesRepository.patchAttachment`).
  Attachment withUploadOf(Attachment uploaded) => copyWith(
    storagePath: uploaded.storagePath,
    downloadUrl: uploaded.downloadUrl,
    driveId: uploaded.driveId,
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
    onPage: local.onPage,
    pdfPage: local.pdfPage,
    pdfTurns: local.pdfTurns,
    pdfMarks: local.pdfMarks,
    pinHeight: local.pinHeight,
    bubblesHidden: local.bubblesHidden,
    // Açıklama yazılırken gelen eski yankı harfleri geri almasın.
    caption: local.caption,
  );

  /// [fileName]/[mimeType]/[width]/[height]/[sizeBytes] yalnız KIRPMA yolunda
  /// değişir (dosyanın kendisi yeniden yazılır); onun dışında ek oluşturulduğu
  /// gibi kalır.
  Attachment copyWith({
    String? fileName,
    String? mimeType,
    String? storagePath,
    String? downloadUrl,
    String? driveId,
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
    bool? onPage,
    int? pdfPage,
    int? pdfTurns,
    List<int>? pdfMarks,
    String? section,
    List<InkStroke>? ink,
    List<PageBubble>? bubbles,
    List<String>? pageIds,
    String? webUrl,
    double? pinHeight,
    String? sourceId,
    bool? bubblesHidden,
    String? text,
    String? transcriptOf,
    String? sourceDigest,
    String? caption,
    List<int>? wave,
  }) => Attachment(
    id: id,
    kind: kind,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    storagePath: storagePath ?? this.storagePath,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    driveId: driveId ?? this.driveId,
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
    onPage: onPage ?? this.onPage,
    pdfPage: pdfPage ?? this.pdfPage,
    pdfTurns: pdfTurns ?? this.pdfTurns,
    pdfMarks: pdfMarks ?? this.pdfMarks,
    section: section ?? this.section,
    ink: ink ?? this.ink,
    bubbles: bubbles ?? this.bubbles,
    pageIds: pageIds ?? this.pageIds,
    webUrl: webUrl ?? this.webUrl,
    pinHeight: pinHeight ?? this.pinHeight,
    sourceId: sourceId ?? this.sourceId,
    bubblesHidden: bubblesHidden ?? this.bubblesHidden,
    text: text ?? this.text,
    transcriptOf: transcriptOf ?? this.transcriptOf,
    sourceDigest: sourceDigest ?? this.sourceDigest,
    caption: caption ?? this.caption,
    wave: wave ?? this.wave,
    createdAt: createdAt,
    rawKind: rawKind,
    extras: extras,
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
        driveId: map['driveId'] as String? ?? '',
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
        onPage: map['onPage'] as bool? ?? false,
        pdfPage: (map['pdfPage'] as num?)?.toInt() ?? 1,
        pdfTurns: (map['pdfTurns'] as num?)?.toInt() ?? 0,
        pdfMarks: [
          for (final e in (map['pdfMarks'] as List?) ?? const [])
            (e as num).toInt(),
        ],
        section: map['section'] as String? ?? '',
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
        webUrl: map['webUrl'] as String? ?? '',
        pinHeight: (map['pinHeight'] as num?)?.toDouble() ?? 0,
        sourceId: map['sourceId'] as String? ?? '',
        bubblesHidden: map['bubblesHidden'] as bool? ?? false,
        text: map['text'] as String? ?? '',
        transcriptOf: map['transcriptOf'] as String? ?? '',
        sourceDigest: map['sourceDigest'] as String? ?? '',
        caption: map['caption'] as String? ?? '',
        wave: [
          for (final e in (map['wave'] as List?) ?? const [])
            if (e is num) e.toInt().clamp(0, 100),
        ],
        createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
        rawKind: map['kind'] as String? ?? '',
        extras: {
          for (final e in map.entries)
            if (!knownKeys.contains(e.key)) e.key: e.value,
        },
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
    // ÖNCE tanınmayan alanlar: bilinen anahtarlar her zaman üstüne yazar.
    ...extras,
    'id': id,
    'kind': kind == AttachmentKind.unknown ? rawKind : kind.id,
    'fileName': fileName,
    'mimeType': mimeType,
    'storagePath': storagePath,
    // `blob:` adresi yalnız bu tarayıcı sekmesinde geçerli (web'de Drive'dan
    // indirilen ek — bkz. resolveWebDriveAttachment): buluta yazılmaz.
    'downloadUrl': downloadUrl.startsWith('blob:') ? '' : downloadUrl,
    // Yalnız doluysa: Drive'sız eklerin şeması büyümez.
    if (driveId.isNotEmpty) 'driveId': driveId,
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
    // PDF sayfaya gömülüyse: aynı kural — varsayılan değerler yazılmaz.
    if (onPage) 'onPage': true,
    if (pdfPage > 1) 'pdfPage': pdfPage,
    if (pdfTurns != 0) 'pdfTurns': pdfTurns,
    if (pdfMarks.isNotEmpty) 'pdfMarks': pdfMarks,
    // Yalnız doluysa yazılır (arşiv defteri dışında hiç oluşmaz).
    if (section.isNotEmpty) 'section': section,
    if (ink.isNotEmpty) 'ink': [for (final s in ink) s.toMap()],
    // Çizimle aynı kural: yalnız doluysa yazılır, balonsuz ekin şeması büyümez.
    if (bubbles.isNotEmpty) 'bubbles': [for (final b in bubbles) b.toMap()],
    // Yalnız atanmışsa yazılır: kimlik atanmamış ekte alan hiç oluşmaz
    // (türetilen `p<sayfaNo>` zaten aynı sonucu verir) ve eski notların
    // şeması büyümez.
    if (pageIds.isNotEmpty) 'pageIds': pageIds,
    // Yalnız doluysa: dosyalı eklerin şeması büyümez.
    if (webUrl.isNotEmpty) 'webUrl': webUrl,
    if (pinHeight != 0) 'pinHeight': pinHeight,
    // Yalnız doluysa: türetilmemiş eklerin şeması büyümez. (Ekler dizi
    // olarak TÜMDEN yazılır — merge tuzağı yok.)
    if (sourceId.isNotEmpty) 'sourceId': sourceId,
    // Yalnız gizliyken yazılır (ekler dizi olarak TÜMDEN yazılır — gösterince
    // alanın düşmesi yeterli, merge tuzağı yok).
    if (bubblesHidden) 'bubblesHidden': true,
    // Metin eki: içerik ve kaynağı yalnız doluyken (öbür türlerde alan yok).
    if (text.isNotEmpty) 'text': text,
    if (transcriptOf.isNotEmpty) 'transcriptOf': transcriptOf,
    if (sourceDigest.isNotEmpty) 'sourceDigest': sourceDigest,
    // Açıklama ve dalga yalnız doluyken (ekler dizi olarak TÜMDEN yazılır —
    // silinen açıklamanın alanı düşer, merge tuzağı yok).
    if (caption.isNotEmpty) 'caption': caption,
    if (wave.isNotEmpty) 'wave': wave,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}
