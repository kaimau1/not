import 'list_mode.dart';

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
    this.category = '',
    this.quantity,
    this.unit = '',
    this.price,
    this.doneDays = const [],
    this.priority = ItemPriority.none,
    this.dueDate,
    this.extras = const {},
  });

  /// **NOT PAKETİ** (kullanıcı isteği 2026-11-08): aynı kimliği taşıyan ardışık
  /// maddeler (ya da tek uzun madde) kapalıyken tek bir çerçeveli satırda
  /// toplanır; dokununca açılır, dışarı dokununca daralır. '' = paket yok.
  final String package;

  /// Otomatik veya kullanıcı atanmış grup/reyon anahtarı (ör. `'produce'`,
  /// `'breakfast'`). Boş iken [toMap] yazmaz.
  final String category;

  /// Sayısal miktar (ör. `2`, `1.5`). Null/<=0 iken [toMap] yazmaz.
  final double? quantity;

  /// Miktar birimi (ör. `'kg'`, `'lt'`, `'adet'`). Boş iken [toMap] yazmaz.
  final String unit;

  /// Birim veya satır fiyatı (₺). Null/<=0 iken [toMap] yazmaz.
  final double? price;

  /// Rutin / alışkanlık tamamlanan günler kümesi: sıralı, tekrarsız
  /// `YYYY-MM-DD` anahtarları (en çok [maxDoneDays] gün).
  ///
  /// **Tek gerçek kaynak**: [streakCount], [bestStreak] ve [lastCompletedAt]
  /// yalnızca bu kümeden deterministik hesaplanır; ayrı sayaç saklanmaz.
  final List<String> doneDays;

  /// Madde önceliği (`none` varsayılan; varsayılan iken [toMap] yazmaz).
  final ItemPriority priority;

  /// Hedef tarih/saat (proje görevleri, erteleme). Null iken [toMap] yazmaz.
  final DateTime? dueDate;

  /// Bu sürümün TANIMADIĞI anahtarlar — [toMap] AYNEN geri yazar, eski
  /// istemci yeni sürümün madde alanlarını silemez (F1.5).
  final Map<String, dynamic> extras;

  /// [doneDays] içinde tutulacak en fazla gün sayısı.
  static const maxDoneDays = 90;

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
    'category',
    'quantity',
    'unit',
    'price',
    'doneDays',
    'priority',
    'dueDate',
  };

  /// Eski `extras` şemasından okuma sırasında kanonik alanlara taşınan
  /// anahtarlar — yeniden yazarken çift yazım oluşmasın diye `extras`'tan
  /// temizlenir.
  static const legacyMigratedExtraKeys = <String>{
    'q',
    'u',
    'p',
    'g',
    'hd',
    'hc',
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

  // ── Rutin seri hesapları (tek gerçek kaynak: [doneDays]) ─────────────────

  /// [dayKey] (`YYYY-MM-DD`) tarihinde tamamlandı mı?
  bool isDoneOn(String dayKey) => doneDays.contains(dayKey);

  /// [today] dahil ya da dünden başlayarak ardışık gün serisi.
  int streakCountAt(DateTime today) {
    if (doneDays.isEmpty) return 0;
    final set = doneDays.toSet();
    final t = DateTime(today.year, today.month, today.day);
    var cursor = set.contains(isoDayKeyOf(t))
        ? t
        : t.subtract(const Duration(days: 1));
    var streak = 0;
    while (set.contains(isoDayKeyOf(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Bugüne göre ardışık gün serisi ([doneDays] üzerinden hesaplanır).
  int get streakCount => streakCountAt(DateTime.now());

  /// Kayıtlı en uzun ardışık gün serisi.
  int get bestStreak {
    if (doneDays.isEmpty) return 0;
    var best = 1;
    var cur = 1;
    DateTime? prev;
    for (final s in doneDays) {
      final d = parseIsoDayKeyLocal(s);
      if (d == null) continue;
      if (prev != null && d.difference(prev).inDays == 1) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 1;
      }
      prev = d;
    }
    return best;
  }

  /// [doneDays] içindeki en son tamamlanma günü (yoksa null).
  DateTime? get lastCompletedAt {
    for (var i = doneDays.length - 1; i >= 0; i--) {
      final parsed = parseIsoDayKeyLocal(doneDays[i]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  /// [dayKey] gününü [doneDays] kümesinde açıp kapatır ve [checked] alanını
  /// [todayKey] (verilmezse [dayKey]) ile uyumlu günceller.
  NoteItem toggledDoneDay(String dayKey, {String? todayKey}) {
    final next = {...doneDays};
    if (!next.add(dayKey)) next.remove(dayKey);
    final normalized = normalizeDoneDays(next);
    final refKey = todayKey ?? dayKey;
    return copyWith(
      doneDays: normalized,
      checked: normalized.contains(refKey),
    );
  }

  /// Sıralı, tekrarsız ve en çok [maxDoneDays] günlük tarih kümesi.
  static List<String> normalizeDoneDays(Iterable<String> raw) {
    final set = <String>{
      for (final d in raw)
        if (d.trim().isNotEmpty) d.trim(),
    };
    if (set.isEmpty) return const [];
    final sorted = set.toList()..sort();
    return sorted.length > maxDoneDays
        ? sorted.sublist(sorted.length - maxDoneDays)
        : sorted;
  }

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
    String? category,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    double? price,
    bool clearPrice = false,
    List<String>? doneDays,
    ItemPriority? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    Map<String, dynamic>? extras,
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
    category: category ?? this.category,
    quantity: clearQuantity ? null : (quantity ?? this.quantity),
    unit: unit ?? this.unit,
    price: clearPrice ? null : (price ?? this.price),
    doneDays: doneDays ?? this.doneDays,
    priority: priority ?? this.priority,
    dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    extras: extras ?? this.extras,
  );

  static DateTime? _parseDueDate(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is String) return DateTime.tryParse(raw);
    try {
      final dynamic ts = raw;
      final dynamic d = ts.toDate();
      if (d is DateTime) return d;
    } catch (_) {
      // Bilinmeyen tarih türü yok sayılır.
    }
    return null;
  }

  factory NoteItem.fromMap(Map<String, dynamic> map) {
    final rawQty = map['quantity'] ?? map['q'];
    final quantity = rawQty is num && rawQty > 0 ? rawQty.toDouble() : null;
    final rawUnit = map['unit'] is String && (map['unit'] as String).isNotEmpty
        ? map['unit'] as String
        : (map['u'] is String ? map['u'] as String : '');
    final rawPrice = map['price'] ?? map['p'];
    final price = rawPrice is num && rawPrice > 0 ? rawPrice.toDouble() : null;

    var category = (map['category'] as String? ?? '').trim();
    if (category.isEmpty) {
      final legacyAisle = map['g'];
      if (legacyAisle is num) {
        category = aisleCategoryKey(legacyAisle.toInt()) ?? '';
      } else if (map['hc'] is String && (map['hc'] as String).trim().isNotEmpty) {
        category = (map['hc'] as String).trim();
      }
    }

    final mergedDays = <String>[];
    for (final src in [map['doneDays'], map['hd']]) {
      if (src is List) {
        for (final d in src) {
          if (d is String && d.isNotEmpty) mergedDays.add(d);
        }
      }
    }
    final doneDays = normalizeDoneDays(mergedDays);

    return NoteItem(
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
      category: category,
      quantity: quantity,
      unit: rawUnit.trim(),
      price: price,
      doneDays: doneDays,
      priority: ItemPriority.fromId(map['priority'] as String?),
      dueDate: _parseDueDate(map['dueDate']),
      extras: {
        for (final e in map.entries)
          if (!knownKeys.contains(e.key) &&
              !legacyMigratedExtraKeys.contains(e.key))
            e.key: e.value,
      },
    );
  }

  Map<String, dynamic> toMap() => {
    for (final e in extras.entries)
      if (!legacyMigratedExtraKeys.contains(e.key)) e.key: e.value,
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
    if (category.isNotEmpty) 'category': category,
    if (quantity != null && quantity! > 0) 'quantity': quantity,
    if (unit.isNotEmpty) 'unit': unit,
    if (price != null && price! > 0) 'price': price,
    if (doneDays.isNotEmpty) 'doneDays': doneDays,
    if (priority != ItemPriority.none) 'priority': priority.id,
    if (dueDate != null) 'dueDate': dueDate!.millisecondsSinceEpoch,
  };
}

/// Sıralı listede [index]teki maddenin numarası: ara başlıklar sayılmaz ve
/// her başlıktan sonra numara 1'den başlar (bölüm bölüm liste). Başlığın
/// kendisi için null.
///
/// İŞARETLİ MADDE NUMARA ALMAZ (kullanıcı bulgusu 2026-11-16: "maddeli not
/// numaralıya çevrildiğinde işaretliler de numaralandırılıyor"): işaretli
/// madde için null (yerinde ✓ çizilir) ve sonrakilerin sayımına girmez.
int? itemOrderNumber(List<NoteItem> items, int index) {
  final item = items[index];
  if (item.header || item.checked) return null;
  var n = 1;
  for (var i = index - 1; i >= 0; i--) {
    if (items[i].header) break;
    if (!items[i].checked) n++;
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

/// İki madde `extras` haritasının sığ eşitliği (hızlı yol: ikisi de boşsa
/// ya da aynı nesneyse anında true). HAFIZA kural 5 için üç noktada ortak.
bool sameNoteItemExtras(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (identical(a, b) || (a.isEmpty && b.isEmpty)) return true;
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!b.containsKey(e.key) || b[e.key] != e.value) return false;
  }
  return true;
}

/// İki `doneDays` listesinin eleman eşitliği.
bool sameNoteItemDoneDays(List<String> a, List<String> b) {
  if (identical(a, b) || (a.isEmpty && b.isEmpty)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Yeni yapısal [NoteItem] alanlarının eşitliği (HAFIZA kural 5: üç noktada
/// tek ortak denetim).
bool sameNoteItemStructuredFields(NoteItem a, NoteItem b) =>
    a.category == b.category &&
    a.quantity == b.quantity &&
    a.unit == b.unit &&
    a.price == b.price &&
    a.priority == b.priority &&
    a.dueDate == b.dueDate &&
    sameNoteItemDoneDays(a.doneDays, b.doneDays);
