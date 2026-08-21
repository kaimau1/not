import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:uuid/uuid.dart';

import '../domain/note.dart';
import '../domain/note_type.dart';

/// Notların **JSON yedeği**: dışa aktarma (kodlama) ve geri yükleme (çözme).
///
/// Ayarlar ekranındaki iki düğmenin içine gömülüydü; buraya çıkarıldı çünkü
/// (a) widget'a gömülü mantık test edilemiyordu, (b) anonim hesaptan Google'a
/// geçerken "önce yerel yedek al → giriş yap → geri yükle" akışı aynı mantığı
/// ekrandan bağımsız çağırmak zorunda (KALANLAR: hesap çakışması maddesi).
///
/// **Ekler yedeğe GİRMEZ** (yalnız adı/türü/Storage yolu yazılır): yedek
/// dosyası e-postayla elden ele dolaşıyor, `downloadUrl` içindeki `?token=`
/// ise Storage kurallarını atlayan süresiz bir anahtar olurdu.
class NoteBackup {
  const NoteBackup._();

  /// Yedek dosyasının `app` damgası — başka bir uygulamanın JSON'u yanlışlıkla
  /// geri yüklenmesin.
  static const appTag = 'notlar';

  /// Dışa aktarılacak dosya adı (`notlar-yedek-2026-08-21.json`).
  static String fileName(DateTime at) =>
      'notlar-yedek-${at.year}-${_two(at.month)}-${_two(at.day)}.json';

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Notları okunabilir (girintili) JSON'a çevirir.
  static String encode(List<Note> notes, {DateTime? at}) =>
      const JsonEncoder.withIndent('  ').convert({
        'app': appTag,
        'exportedAt': (at ?? DateTime.now()).toIso8601String(),
        'noteCount': notes.length,
        'notes': [for (final n in notes) noteToMap(n)],
      });

  static Map<String, dynamic> noteToMap(Note n) => {
    'id': n.id,
    'type': n.type.id,
    'title': n.title,
    'body': n.body,
    'items': [
      for (final i in n.items) {'text': i.text, 'checked': i.checked},
    ],
    'tags': n.tags,
    'color': n.color.id,
    'frameColor': n.frameColor.id,
    'folderId': n.folderId,
    'pinned': n.pinned,
    'starred': n.starred,
    'locked': n.locked,
    'createdAt': n.createdAt?.toIso8601String(),
    'updatedAt': n.updatedAt?.toIso8601String(),
    'archivedAt': n.archivedAt?.toIso8601String(),
    'reminderAt': n.reminderAt?.toIso8601String(),
    'attachments': [
      // BİLEREK storagePath, downloadUrl DEĞİL (gerekçe sınıf belgesinde).
      for (final a in n.attachments)
        {'fileName': a.fileName, 'kind': a.kind.name, 'path': a.storagePath},
    ],
  };

  /// Yedek JSON'unu geri yüklenebilir kayıtlara çevirir.
  ///
  /// Biçim bozuksa [FormatException] atar. Boş kayıtlar (başlıksız, gövdesiz,
  /// maddesiz) atlanır — geri yüklemede boş not üretmenin anlamı yok.
  ///
  /// [now]: geçmişte kalmış hatırlatıcıların elenmesinde kullanılan "şimdi"
  /// (testlerde sabitlenebilsin diye parametre).
  static List<RestoredNote> decode(String source, {DateTime? now}) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) throw const FormatException();
    final rawNotes = decoded['notes'];
    if (rawNotes is! List) throw const FormatException();
    const uuid = Uuid();
    final at = now ?? DateTime.now();
    final out = <RestoredNote>[];
    for (final raw in rawNotes) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      final title = map['title'] as String? ?? '';
      final body = map['body'] as String? ?? '';
      final items = [
        for (final i in (map['items'] as List<dynamic>? ?? const []))
          if (i is Map)
            {
              // Yeni kimlik: madde kimlikleri hesap içinde benzersiz olmalı ve
              // geri yükleme her kaydı YENİ not olarak açıyor.
              'id': uuid.v4(),
              'text': i['text'] as String? ?? '',
              'checked': i['checked'] as bool? ?? false,
            },
      ];
      if (title.trim().isEmpty && body.trim().isEmpty && items.isEmpty) {
        continue;
      }
      Timestamp? ts(String key) {
        final value = map[key] as String?;
        final parsed = value == null ? null : DateTime.tryParse(value);
        return parsed == null ? null : Timestamp.fromDate(parsed);
      }

      final reminder = ts('reminderAt');
      out.add(
        RestoredNote(
          type: NoteType.fromId(map['type'] as String?),
          // Yedekteki alanların OLABİLDİĞİNCE çoğu geri yazılır: eskiden yalnız
          // title/body/items/tags/pinned dönüyordu, yani kilitli notlar
          // KİLİTSİZ (içerik açıkta!), arşivdekiler ana duvara, renk/
          // hatırlatıcı/tarih kayıp geliyordu. Klasör geri yüklenmez (id başka
          // hesapta anlamsız).
          fields: {
            'title': title,
            'body': body,
            'items': items,
            'tags': [
              for (final t in (map['tags'] as List<dynamic>? ?? const []))
                t.toString(),
            ],
            'pinned': map['pinned'] as bool? ?? false,
            'starred': map['starred'] as bool? ?? false,
            'locked': map['locked'] as bool? ?? false,
            if (map['color'] is String) 'color': map['color'],
            if (map['frameColor'] is String) 'frameColor': map['frameColor'],
            if (ts('createdAt') != null) 'createdAt': ts('createdAt'),
            if (ts('archivedAt') != null) 'archivedAt': ts('archivedAt'),
            // Geçmişte kalmış hatırlatıcı geri kurulmaz (bildirim zaten
            // planlanmaz, "Geçmiş" listesini şişirir).
            if (reminder != null && reminder.toDate().isAfter(at))
              'reminderAt': reminder,
          },
        ),
      );
    }
    return out;
  }
}

/// Yedekten okunmuş tek not: hangi türde açılacağı + açıldıktan sonra
/// yazılacak alanlar. Her kayıt YENİ not olarak oluşturulur — mevcut notlara
/// dokunulmaz, id çakışması/veri ezme riski yoktur.
class RestoredNote {
  const RestoredNote({required this.type, required this.fields});

  final NoteType type;
  final Map<String, dynamic> fields;
}
