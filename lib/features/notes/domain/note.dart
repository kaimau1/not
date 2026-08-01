import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/rich_text.dart';
import 'attachment.dart';
import 'note_item.dart';
import 'note_type.dart';

/// Renk belirteci — tema tarafında gerçek renklere çözülür.
enum NoteColor {
  none('default'),
  red('red'),
  amber('amber'),
  green('green'),
  blue('blue'),
  purple('purple');

  const NoteColor(this.id);

  final String id;

  static NoteColor fromId(String? id) => NoteColor.values.firstWhere(
    (c) => c.id == id,
    orElse: () => NoteColor.none,
  );
}

class AiSummary {
  const AiSummary({required this.text, required this.model, this.createdAt});

  final String text;
  final String model;
  final DateTime? createdAt;

  factory AiSummary.fromMap(Map<String, dynamic> map) => AiSummary(
    text: map['text'] as String? ?? '',
    model: map['model'] as String? ?? '',
    createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
  );

  Map<String, dynamic> toMap() => {
    'text': text,
    'model': model,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
  };
}

/// Bir not — tüm içerik tek Firestore dokümanında tutulur (atomik ve
/// offline dostu). İkili veriler (görsel/PDF) Storage'dadır.
class Note {
  const Note({
    required this.id,
    required this.type,
    this.title = '',
    this.body = '',
    this.items = const [],
    this.attachments = const [],
    this.tags = const [],
    this.folderId,
    this.color = NoteColor.none,
    this.frameColor = NoteColor.none,
    this.pinned = false,
    this.starred = false,
    this.locked = false,
    this.fontFamily,
    this.fontScale = 1,
    this.textOpacity = 1,
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.archivedAt,
    this.reminderAt,
    this.aiSummary,
  });

  final String id;
  final NoteType type;
  final String title;

  /// Yalnızca [NoteType.text] için kullanılır.
  final String body;

  /// Yalnızca liste tiplerinde kullanılır; sıra = dizi indeksi.
  final List<NoteItem> items;
  final List<Attachment> attachments;

  /// Serbest etiketler ("iş", "ev"...). '#' işareti olmadan saklanır.
  final List<String> tags;

  /// Notun bağlı olduğu klasörün id'si (null = klasörsüz). Klasörler
  /// users/{uid}/folders koleksiyonunda tutulur.
  final String? folderId;
  final NoteColor color;

  /// Kartın/edit ekranının çevresine çizilen renkli çerçeve. [NoteColor.none]
  /// = çerçeve yok (yalnız ince varsayılan kenarlık). Zemin renginden
  /// ([color]) bağımsızdır: renkli zemin + farklı renkli çerçeve olabilir.
  final NoteColor frameColor;
  final bool pinned;

  /// Yıldızlı (favori) not: filtre çubuğundaki "Yıldızlı" süzgeciyle
  /// kolayca bulunur.
  final bool starred;

  /// Kilitli not: kart içeriği gizlenir, açmak biyometrik doğrulama ister;
  /// arama yalnızca başlıkta yapılır ve AI bağlamlarına dahil edilmez.
  final bool locked;

  /// Notun kendi yazı tipi: null = uygulama varsayılanı, 'serif' = kitap,
  /// 'monospace' = daktilo. Sistemde HER ZAMAN bulunan genel aileler seçildi;
  /// indirilen bir yazı tipi çevrimdışı açılan notta eksik kalırdı.
  final String? fontFamily;

  /// Notun kendi yazı boyutu çarpanı (1 = varsayılan). Ayarlardaki genel
  /// ölçekten AYRIDIR: bu tek nota özeldir (uzun bir belgeyi küçültmek,
  /// alışveriş listesini büyütmek).
  final double fontScale;

  /// Not metninin opaklığı (0.3–1). 1 = tam koyu. Soluk yazı, tamamlanmış ya
  /// da arka plana itilmek istenen notları renk değiştirmeden geri plana
  /// alır. Taban 0.3'tür: daha soluğunda kullanıcı yazdığını göremez ve
  /// ayarı geri bulamaz.
  final double textOpacity;
  final double orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  /// Arşivlenen notlar dashboard'da görünmez; Arşiv ekranından erişilir.
  final DateTime? archivedAt;

  /// Doluysa bu tarihte yerel bildirim planlanır.
  final DateTime? reminderAt;
  final AiSummary? aiSummary;

  bool get isEmpty =>
      title.trim().isEmpty &&
      body.trim().isEmpty &&
      items.every((i) => i.text.trim().isEmpty) &&
      attachments.isEmpty;

  /// AI'ya gönderilecek düz metin temsili. Satır içi biçim işaretleri
  /// (`**kalın**` gibi) SÖKÜLÜR: modele, sesli okumaya ve paylaşıma giden
  /// metinde işaretlerin işi yok (bkz. rich_text.dart).
  String toPlainText() {
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) buffer.writeln(title.trim());
    switch (type) {
      case NoteType.text:
        if (body.trim().isNotEmpty) buffer.writeln(body);
        // Karışık içerik: metin notuna eklenen checklist maddeleri de dahil.
        for (final item in items) {
          if (item.text.trim().isEmpty) continue;
          buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
        }
      case NoteType.checklist:
        for (final item in items) {
          buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
        }
      case NoteType.ordered:
        for (var i = 0; i < items.length; i++) {
          buffer.writeln('${i + 1}. ${items[i].text}');
        }
    }
    return stripRichMarkers(buffer.toString().trim());
  }

  /// AI ile "geliştir/düzelt" için notun İÇERİĞİ — başlık ve liste işaretleri
  /// (`- [ ]`, `[x]`, numara) OLMADAN, her satır bir öğe/paragraf. Round-trip'te
  /// (not → metin → AI → not) başlığın öğeye, onay kutusu/numara işaretlerinin
  /// öğe metnine sızmasını engeller — bu yüzden başlık+işaret taşıyan
  /// [toPlainText]'ten ayrı tutulur.
  /// [skipChecked] true ise işaretli (tamamlanmış) maddeler İÇERİĞE KATILMAZ —
  /// AI düzeltme/çevirisine yalnız işaretsiz maddeler gider; tamamlananlar
  /// değiştirilmeden yerinde korunur ("işaretlilere karışma" isteği).
  ///
  /// Satır içi biçim işaretleri burada da sökülür: AI'ya işaretli metin
  /// gitseydi dönen metinde işaretler bozulur ya da çoğalırdı.
  String toContentText({bool skipChecked = false}) {
    bool include(NoteItem item) =>
        item.text.trim().isNotEmpty && !(skipChecked && item.checked);
    return stripRichMarkers(switch (type) {
      NoteType.text => [
        if (body.trim().isNotEmpty) body.trim(),
        // Karışık içerik: metin notundaki checklist maddeleri de içeriğe girer.
        for (final item in items)
          if (include(item)) item.text.trim(),
      ].join('\n'),
      NoteType.checklist || NoteType.ordered => [
        for (final item in items)
          if (include(item)) item.text.trim(),
      ].join('\n'),
    });
  }

  Note copyWith({
    NoteType? type,
    String? title,
    String? body,
    List<NoteItem>? items,
    List<Attachment>? attachments,
    List<String>? tags,
    String? folderId,
    bool clearFolderId = false,
    NoteColor? color,
    NoteColor? frameColor,
    bool? pinned,
    bool? starred,
    bool? locked,
    String? fontFamily,
    bool clearFontFamily = false,
    double? fontScale,
    double? textOpacity,
    double? orderIndex,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? reminderAt,
    bool clearReminderAt = false,
    AiSummary? aiSummary,
  }) => Note(
    id: id,
    type: type ?? this.type,
    title: title ?? this.title,
    body: body ?? this.body,
    items: items ?? this.items,
    attachments: attachments ?? this.attachments,
    tags: tags ?? this.tags,
    folderId: clearFolderId ? null : (folderId ?? this.folderId),
    color: color ?? this.color,
    frameColor: frameColor ?? this.frameColor,
    pinned: pinned ?? this.pinned,
    starred: starred ?? this.starred,
    locked: locked ?? this.locked,
    fontFamily: clearFontFamily ? null : (fontFamily ?? this.fontFamily),
    fontScale: fontScale ?? this.fontScale,
    textOpacity: textOpacity ?? this.textOpacity,
    orderIndex: orderIndex ?? this.orderIndex,
    createdAt: createdAt,
    updatedAt: updatedAt,
    deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
    reminderAt: clearReminderAt ? null : (reminderAt ?? this.reminderAt),
    aiSummary: aiSummary ?? this.aiSummary,
  );

  factory Note.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? const <String, dynamic>{};
    return Note(
      id: doc.id,
      type: NoteType.fromId(map['type'] as String?),
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      items: [
        for (final raw in (map['items'] as List<dynamic>? ?? const []))
          NoteItem.fromMap(Map<String, dynamic>.from(raw as Map)),
      ],
      attachments: [
        for (final raw in (map['attachments'] as List<dynamic>? ?? const []))
          Attachment.fromMap(Map<String, dynamic>.from(raw as Map)),
      ],
      tags: [
        for (final tag in (map['tags'] as List<dynamic>? ?? const []))
          tag.toString(),
      ],
      folderId: map['folderId'] as String?,
      color: NoteColor.fromId(map['color'] as String?),
      frameColor: NoteColor.fromId(map['frameColor'] as String?),
      pinned: map['pinned'] as bool? ?? false,
      starred: map['starred'] as bool? ?? false,
      locked: map['locked'] as bool? ?? false,
      fontFamily: map['fontFamily'] as String?,
      fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1,
      textOpacity: (map['textOpacity'] as num?)?.toDouble() ?? 1,
      orderIndex: (map['orderIndex'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      archivedAt: (map['archivedAt'] as Timestamp?)?.toDate(),
      reminderAt: (map['reminderAt'] as Timestamp?)?.toDate(),
      aiSummary: map['aiSummary'] is Map
          ? AiSummary.fromMap(
              Map<String, dynamic>.from(map['aiSummary'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type.id,
    'title': title,
    'body': body,
    'items': [for (final i in items) i.toMap()],
    'attachments': [for (final a in attachments) a.toMap()],
    'tags': tags,
    'folderId': folderId,
    'color': color.id,
    'frameColor': frameColor.id,
    'pinned': pinned,
    'starred': starred,
    'locked': locked,
    // Varsayılandan farklıysa yazılır: eski notların şeması büyümez.
    if (fontFamily != null) 'fontFamily': fontFamily,
    if (fontScale != 1) 'fontScale': fontScale,
    if (textOpacity != 1) 'textOpacity': textOpacity,
    'orderIndex': orderIndex,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
    'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
    'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
    'aiSummary': aiSummary?.toMap(),
  };
}
