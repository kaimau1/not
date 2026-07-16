import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.color = NoteColor.none,
    this.pinned = false,
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
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
  final NoteColor color;
  final bool pinned;
  final double orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final AiSummary? aiSummary;

  bool get isEmpty =>
      title.trim().isEmpty &&
      body.trim().isEmpty &&
      items.every((i) => i.text.trim().isEmpty) &&
      attachments.isEmpty;

  /// AI'ya gönderilecek düz metin temsili.
  String toPlainText() {
    final buffer = StringBuffer();
    if (title.trim().isNotEmpty) buffer.writeln(title.trim());
    switch (type) {
      case NoteType.text:
        buffer.writeln(body);
      case NoteType.checklist:
        for (final item in items) {
          buffer.writeln('- [${item.checked ? 'x' : ' '}] ${item.text}');
        }
      case NoteType.ordered:
        for (var i = 0; i < items.length; i++) {
          buffer.writeln('${i + 1}. ${items[i].text}');
        }
    }
    return buffer.toString().trim();
  }

  Note copyWith({
    String? title,
    String? body,
    List<NoteItem>? items,
    List<Attachment>? attachments,
    NoteColor? color,
    bool? pinned,
    double? orderIndex,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    AiSummary? aiSummary,
  }) =>
      Note(
        id: id,
        type: type,
        title: title ?? this.title,
        body: body ?? this.body,
        items: items ?? this.items,
        attachments: attachments ?? this.attachments,
        color: color ?? this.color,
        pinned: pinned ?? this.pinned,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt,
        updatedAt: updatedAt,
        deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
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
      color: NoteColor.fromId(map['color'] as String?),
      pinned: map['pinned'] as bool? ?? false,
      orderIndex: (map['orderIndex'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      deletedAt: (map['deletedAt'] as Timestamp?)?.toDate(),
      aiSummary: map['aiSummary'] is Map
          ? AiSummary.fromMap(Map<String, dynamic>.from(map['aiSummary'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': type.id,
        'title': title,
        'body': body,
        'items': [for (final i in items) i.toMap()],
        'attachments': [for (final a in attachments) a.toMap()],
        'color': color.id,
        'pinned': pinned,
        'orderIndex': orderIndex,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
        'aiSummary': aiSummary?.toMap(),
      };
}
