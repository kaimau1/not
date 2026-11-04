import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../settings/settings_providers.dart';
import '../domain/attachment.dart';
import '../domain/note.dart';
import '../domain/note_item.dart';
import 'card_preview.dart';

/// **ANINDA İÇERİK** (F25.2, telefonda ölçüldü 2026-11-04: ilk kareden sonra
/// ~1 sn iskelet + 480 ms donuk ana iş parçacığı, Firestore'un ilk yayını).
///
/// Arka plana geçişte ana ekranın ilk [kHomeSnapshotNotes] kartının KISALTILMIŞ
/// kopyası tercihlere yazılır; açılışta Firestore gelene kadar bunlar çizilir.
///
/// **KISALTILMIŞ NOT ASLA DIŞARI ÇIKMAZ:** editöre gidip tam notun üstüne
/// yazılmasın diye bu notlar yalnız dashboard'un `loading` dalında,
/// dokunuşa kapalı çizilir (`SliverIgnorePointer`). Depo akışına
/// (`notesStreamProvider`) GİRMEZ: hatırlatıcı/yükleme kuyruğu eksik listeyi
/// "silinmiş" sanırdı.
///
/// Gizlilik: gizli klasörler listede zaten yok (`filteredNotesProvider`); kilitli
/// ve parola notunun içeriği yazılmaz. Tek anahtar + uid: başka hesap görmez,
/// sonraki hesabın ilk arka plana geçişi üstüne yazar.
const kHomeSnapshotNotes = 30;

const _prefKey = 'home_snapshot';

/// Kart satır sayısı için madde adedi korunur, metni yalnız görünecek
/// kadarında tutulur; [_maxItems] üstü yazılmaz (kart sayacı bir an eksik).
const _shownItems = 8;
const _maxItems = 200;

const _tsKey = r'$ts';

Note _shorten(Note note) {
  final hideContent = note.locked || isCredentialPreview(note);
  List<NoteItem> items(List<NoteItem> list) => [
    for (final (i, item) in list.take(_maxItems).indexed)
      item.copyWith(
        text: hideContent
            ? ''
            : i < _shownItems
            ? previewSlice(item.text, maxChars: kPreviewItemChars)
            : '·',
      ),
  ];
  return note.copyWith(
    body: hideContent ? '' : previewSlice(note.body),
    items: items(note.items),
    pageNotes: hideContent
        ? const {}
        : {
            for (final e in note.pageNotes.entries.take(_shownItems))
              e.key: previewSlice(e.value, maxChars: kPreviewItemChars),
          },
    // Küçük resim yeter: çizim ve balon ağır, kartta da yok.
    attachments: [
      for (final Attachment a in note.attachments.take(_shownItems))
        a.copyWith(ink: const [], bubbles: const [], text: ''),
    ],
    textPages: const [],
  );
}

bool isCredentialPreview(Note note) =>
    CardPreview.of(note, hideSensitive: false).credential;

/// [notes] (ana ekran sırasıyla) → saklanacak JSON.
String encodeHomeSnapshot(String uid, List<Note> notes) {
  final list = <Map<String, dynamic>>[];
  // Sabitliler listede tarih sırasında ama ekranda EN ÜSTTE: özete girmezlerse
  // gerçek liste gelince bütün kartları aşağı iterlerdi.
  final ordered = [
    for (final n in notes)
      if (n.pinned) n,
    for (final n in notes)
      if (!n.pinned) n,
  ];
  for (final note in ordered.take(kHomeSnapshotNotes)) {
    list.add({
      'id': note.id,
      'localOnly': note.localOnly,
      // `toMap` güncelleme zamanını sunucu damgası yazar; sıra bozulmasın.
      'map': _shorten(note).toMap()
        ..['updatedAt'] = note.updatedAt == null
            ? null
            : Timestamp.fromDate(note.updatedAt!),
    });
  }
  return jsonEncode({'uid': uid, 'notes': list}, toEncodable: _encodable);
}

/// Çözülemeyen (eski/bozuk) özet boş sayılır: en kötü iskelet görünür.
List<Note> decodeHomeSnapshot(String uid, String raw) {
  try {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['uid'] != uid) return const [];
    return [
      for (final e in data['notes'] as List)
        Note.fromMap(
          e['id'] as String,
          _revive(e['map']) as Map<String, dynamic>,
          localOnly: e['localOnly'] as bool? ?? false,
          heavyLoaded: true,
        ),
    ];
  } catch (_) {
    return const [];
  }
}

Object? _encodable(Object? v) => switch (v) {
  Timestamp t => {_tsKey: t.millisecondsSinceEpoch},
  // Sunucu damgası (`FieldValue`) ve Firestore'a özgü diğerleri: kartta yok.
  _ => null,
};

Object? _revive(Object? v) => switch (v) {
  Map<String, dynamic> m when m.length == 1 && m[_tsKey] is int =>
    Timestamp.fromMillisecondsSinceEpoch(m[_tsKey] as int),
  Map<String, dynamic> m => {
    for (final e in m.entries) e.key: _revive(e.value),
  },
  List<dynamic> l => [for (final e in l) _revive(e)],
  _ => v,
};

/// Açılışta bir kez okunan özet; Firestore gelince bir daha çizilmez.
final homeSnapshotProvider = Provider<List<Note>>((ref) {
  final uid = ref.watch(currentUidProvider);
  final raw = ref.read(sharedPreferencesProvider).getString(_prefKey);
  if (uid == null || raw == null) return const [];
  return decodeHomeSnapshot(uid, raw);
});

/// Arka plana geçişte: yalnız bu ekranın varsayılan (süzgeçsiz) hâli saklanır.
Future<void> saveHomeSnapshot(WidgetRef ref, List<Note> notes) async {
  final uid = ref.read(currentUidProvider);
  if (uid == null) return;
  await ref
      .read(sharedPreferencesProvider)
      .setString(_prefKey, encodeHomeSnapshot(uid, notes));
}
