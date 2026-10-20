import 'note.dart';
import 'note_item.dart';

/// **NOT SÜRÜM GEÇMİŞİ** (F4.2, 2026-10-19).
///
/// AI "notu değiştir", ortak not ve otomatik kayıt varken "dünkü hâline dön"
/// güvencesi yoktu (yalnız 4 sn'lik geri al). SEYREK anlık görüntüler
/// `notes/{id}/versions/{otomatik}` altında tutulur:
///  * not bir oturumda ilk kez DEĞİŞTİĞİNDE açıldığı hâli ('open'),
///  * uzun düzenlemede en çok [kVersionInterval]'da bir ('auto'),
///  * AI notu değiştirmeden ÖNCEKİ hâli ('ai'), geri dönmeden önceki hâli
///    ('restore').
/// Yalnız METİN (başlık, gövde, maddeler, sayfalar) saklanır — ekler ve
/// çizimler sürümlenmez (boyut; ekler zaten silinmeden çöpte bekler).
/// Not başına en çok [kMaxVersions] sürüm kalır.
const kVersionInterval = Duration(minutes: 30);
const kMaxVersions = 30;
const kVersionsCollection = 'versions';

class NoteVersion {
  const NoteVersion({
    required this.id,
    required this.at,
    required this.reason,
    required this.by,
    required this.title,
    required this.body,
    required this.items,
    required this.textPages,
  });

  final String id;
  final DateTime at;

  /// 'open' | 'auto' | 'ai' | 'restore'.
  final String reason;

  /// Yazan kullanıcının uid'i (ortak notta kim olduğunu söylemek için).
  final String by;
  final String title;
  final String body;
  final List<NoteItem> items;
  final List<NoteTextPage> textPages;

  /// Önizleme: ilk dolu satır.
  String get preview {
    for (final text in [
      title,
      body,
      for (final i in items) i.text,
      for (final p in textPages) p.body,
    ]) {
      final line = text.trim().split('\n').first.trim();
      if (line.isNotEmpty) return line;
    }
    return '';
  }

  static NoteVersion fromMap(
    String id,
    Map<String, dynamic> map,
    DateTime at,
  ) => NoteVersion(
    id: id,
    at: at,
    reason: map['reason'] as String? ?? 'auto',
    by: map['by'] as String? ?? '',
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    items: [
      for (final raw in (map['items'] as List<dynamic>? ?? const []))
        NoteItem.fromMap(Map<String, dynamic>.from(raw as Map)),
    ],
    textPages: [
      for (final raw in (map['textPages'] as List<dynamic>? ?? const []))
        NoteTextPage.fromMap(Map<String, dynamic>.from(raw as Map)),
    ],
  );

  /// Sürümü nota uygular: yalnız metin alanları, gerisi (ekler, renk,
  /// etiketler…) notun bugünkü hâlinde kalır.
  Note applyTo(Note note) => note.copyWith(
    title: title,
    body: body,
    items: items,
    textPages: textPages,
  );
}

/// Bir notun sürümlenen alanları (Firestore biçimi). Notun TAMAMI
/// (`toMap`, ekler dahil) kurulmaz — her kayıtta çağrılıyor (F6.2).
Map<String, dynamic> versionPayload(Note note, {required String reason}) => {
  'reason': reason,
  'title': note.title,
  'body': note.body,
  'items': [for (final i in note.items) i.toMap()],
  'textPages': [for (final p in note.textPages) p.toMap()],
};
