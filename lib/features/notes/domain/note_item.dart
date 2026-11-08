/// Liste tipli notlardaki tek bir öğe (checklist veya sıralı liste satırı).
class NoteItem {
  const NoteItem({
    required this.id,
    required this.text,
    this.checked = false,
    this.starred = false,
    this.section = '',
    this.title = '',
    this.attachmentId = '',
    this.divider = '',
    this.header = false,
    this.align = '',
    this.package = '',
    this.extras = const {},
  });

  /// **NOT PAKETİ** (kullanıcı isteği 2026-11-08): aynı kimliği taşıyan ardışık
  /// maddeler (ya da tek uzun madde) kapalıyken tek bir çerçeveli satırda
  /// toplanır; dokununca açılır, dışarı dokununca daralır. '' = paket yok.
  final String package;

  /// Bu sürümün TANIMADIĞI anahtarlar — [toMap] AYNEN geri yazar, eski
  /// istemci yeni sürümün madde alanlarını silemez (F1.5).
  final Map<String, dynamic> extras;

  static const knownKeys = <String>{
    'id',
    'text',
    'checked',
    'starred',
    'section',
    'title',
    'attachmentId',
    'divider',
    'header',
    'align',
    'package',
  };

  /// Ara başlık hizası (bkz. [align]).
  static const alignCenter = 'center';
  static const alignEnd = 'end';

  /// Madde ALTI ayırıcı çizgi türleri (bkz. [divider]).
  static const dividerSolid = 'solid';
  static const dividerDashed = 'dashed';
  static const dividerDotted = 'dotted';

  /// Çift çizgi ve dalgalı çizgi (2026-10-23). Bu türleri tanımayan eski
  /// sürüm düz çizgi çizer.
  static const dividerDouble = 'double';
  static const dividerWavy = 'wavy';

  final String id;
  final String text;

  /// Yalnızca checklist tipinde anlamlıdır; sıralı listede yok sayılır.
  final bool checked;

  /// YILDIZLI madde (kullanıcı isteği 2026-08-16: "madde yıldızlama ve
  /// sıralama"). Notun kendi `starred` alanının madde ölçeğindeki karşılığı:
  /// uzun bir listede "asıl önemli olanlar" işaretlenir, sıralama seçeneği
  /// onları en üste alır.
  ///
  /// Alan yalnız TRUE iken kayda yazılır ([toMap]): eski notların şeması
  /// büyümez ve bu alanı bilmeyen bir sürüm listeyi yazarken yıldızları
  /// silmez (`checked` ile aynı gerekçe değil — o hep yazılıyor çünkü
  /// false'a DÖNMEK anlamlı bir durum; yıldızın yokluğu ile false'u aynı).
  final bool starred;

  /// ARŞİV DEFTERİNDE metin girdisinin hangi ELLE AÇILMIŞ sayfaya ait olduğu
  /// (bkz. `Note.archivePages`). Boş = "Metinler" sayfası. Arşiv dışındaki
  /// notlarda yok sayılır — [Attachment.section] ile aynı kural.
  final String section;

  /// ARŞİV DEFTERİNDE girdinin BAŞLIĞI (kullanıcı isteği 2026-08-16:
  /// "hepsinin başlığı ayarlanabilmeli"). Boşsa girdi metninin ilk satırı
  /// başlık gibi gösterilir. Arşiv dışındaki notlarda yok sayılır.
  final String title;

  /// ARŞİV DEFTERİNDE girdinin BAĞLI olduğu ekin kimliği (kullanıcı isteği
  /// 2026-08-16: "metinler görsel veya belge ile bağlanabilmeli"). Boş = bağ
  /// yok. Bağlı ek silinirse kimlik yetim kalır; okuyan taraf ek listesinde
  /// bulamazsa bağı yok sayar — kimliği temizlemek için ayrıca yazım
  /// gerekmesin diye.
  final String attachmentId;

  /// Maddenin ALTINA çizilen ayırıcı çizgi (kullanıcı isteği 2026-10-20:
  /// "satır aralarına çizgi çekme, kesikli çizgi çekme"): '' yok,
  /// [dividerSolid] / [dividerDashed] / [dividerDotted]. Tanınmayan değer
  /// düz çizgi gibi çizilir. Yalnız doluyken kayda yazılır.
  final String divider;

  /// **ARA BAŞLIK** (kullanıcı isteği 2026-11-05: "madde modunda ara başlık
  /// ekleyebilme"): satır madde değil, altındaki maddeleri gruplayan başlık —
  /// kutucuğu/numarası yok, işaretlenmez, kalın ve büyük çizilir, ilerleme
  /// sayısına girmez. Yalnız TRUE iken kayda yazılır; alanı tanımayan eski
  /// sürüm satırı düz madde olarak görür ve `extras`ta aynen geri yazar.
  final bool header;

  /// Ara başlığın HİZASI (kullanıcı isteği 2026-11-05: "ara başlığa basılı
  /// tutarak sola, ortaya, sağa hizalayabilelim"): '' = sola (varsayılan),
  /// [alignCenter] / [alignEnd]. Yalnız doluyken kayda yazılır; alanı
  /// tanımayan eski sürüm sola hizalı çizer.
  final String align;

  NoteItem copyWith({
    String? text,
    bool? checked,
    bool? starred,
    String? section,
    String? title,
    String? attachmentId,
    String? divider,
    bool? header,
    String? align,
    String? package,
  }) => NoteItem(
    id: id,
    text: text ?? this.text,
    checked: checked ?? this.checked,
    starred: starred ?? this.starred,
    section: section ?? this.section,
    title: title ?? this.title,
    attachmentId: attachmentId ?? this.attachmentId,
    divider: divider ?? this.divider,
    header: header ?? this.header,
    align: align ?? this.align,
    package: package ?? this.package,
    extras: extras,
  );

  factory NoteItem.fromMap(Map<String, dynamic> map) => NoteItem(
    id: map['id'] as String? ?? '',
    text: map['text'] as String? ?? '',
    checked: map['checked'] as bool? ?? false,
    starred: map['starred'] as bool? ?? false,
    section: map['section'] as String? ?? '',
    title: map['title'] as String? ?? '',
    attachmentId: map['attachmentId'] as String? ?? '',
    divider: map['divider'] as String? ?? '',
    header: map['header'] as bool? ?? false,
    align: map['align'] as String? ?? '',
    package: map['package'] as String? ?? '',
    extras: {
      for (final e in map.entries)
        if (!knownKeys.contains(e.key)) e.key: e.value,
    },
  );

  Map<String, dynamic> toMap() => {
    ...extras,
    'id': id,
    'text': text,
    'checked': checked,
    if (starred) 'starred': true,
    if (section.isNotEmpty) 'section': section,
    if (title.isNotEmpty) 'title': title,
    if (attachmentId.isNotEmpty) 'attachmentId': attachmentId,
    if (divider.isNotEmpty) 'divider': divider,
    if (header) 'header': true,
    if (align.isNotEmpty) 'align': align,
    if (package.isNotEmpty) 'package': package,
  };
}

/// Sıralı listede [index]teki maddenin numarası: ara başlıklar sayılmaz ve
/// her başlıktan sonra numara 1'den başlar (bölüm bölüm liste). Başlığın
/// kendisi için null.
int? itemOrderNumber(List<NoteItem> items, int index) {
  if (items[index].header) return null;
  var n = 1;
  for (var i = index - 1; i >= 0; i--) {
    if (items[i].header) break;
    n++;
  }
  return n;
}

/// Madde altı ayırıcının BİÇİMİ: tür + isteğe bağlı renk ve kalınlık
/// (kullanıcı isteği 2026-10-23: "çizgi rengi ve özelliklerini ayarlama").
///
/// [NoteItem.divider] dizesinin içinde saklanır — ayrı alan açılmadı:
/// karşılaştırma, satır önbelleği anahtarı, birleştirme ve kopyalama zaten
/// bu dizeye bakıyor, yeni alan hepsine tek tek eklenmek zorunda kalırdı.
/// Biçim: `tür` (varsayılan renk/kalınlık) ya da `tür|c:AARRGGBB|w:1.5`.
/// Eski sürüm tanımadığı dizeyi düz çizgi olarak çizer (veri kaybolmaz).
class ItemDivider {
  const ItemDivider(this.kind, {this.color, this.weight = 1});

  /// [NoteItem.dividerSolid] / dashed / dotted / double / wavy.
  final String kind;

  /// ARGB; null = temanın vurgu rengi.
  final int? color;

  /// Kalınlık çarpanı (0,5–3; 1 = varsayılan).
  final double weight;

  static const minWeight = 0.5;
  static const maxWeight = 3.0;

  static const kinds = [
    NoteItem.dividerSolid,
    NoteItem.dividerDashed,
    NoteItem.dividerDotted,
    NoteItem.dividerDouble,
    NoteItem.dividerWavy,
  ];

  /// Boş dizede null.
  static ItemDivider? parse(String raw) {
    if (raw.isEmpty) return null;
    final parts = raw.split('|');
    int? color;
    var weight = 1.0;
    for (final part in parts.skip(1)) {
      if (part.startsWith('c:')) {
        color = int.tryParse(part.substring(2), radix: 16);
      } else if (part.startsWith('w:')) {
        weight = (double.tryParse(part.substring(2)) ?? 1)
            .clamp(minWeight, maxWeight)
            .toDouble();
      }
    }
    return ItemDivider(parts.first, color: color, weight: weight);
  }

  String encode() {
    final buffer = StringBuffer(kind);
    final c = color;
    if (c != null) {
      buffer.write('|c:${c.toRadixString(16).padLeft(8, '0').toUpperCase()}');
    }
    if ((weight - 1).abs() > 0.01) {
      buffer.write('|w:${weight.toStringAsFixed(2)}');
    }
    return buffer.toString();
  }

  ItemDivider copyWith({
    String? kind,
    int? color,
    bool clearColor = false,
    double? weight,
  }) => ItemDivider(
    kind ?? this.kind,
    color: clearColor ? null : (color ?? this.color),
    weight: weight ?? this.weight,
  );
}
