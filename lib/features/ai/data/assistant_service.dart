import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../notes/data/notes_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_item.dart';
import '../../notes/domain/note_type.dart';

final assistantServiceProvider = Provider<AssistantService>(
  (ref) => AssistantService(ref),
);

/// Asistanın araç çağrılarını (not oluştur/güncelle/sil) gerçek Firestore
/// işlemlerine çevirir.
class AssistantService {
  AssistantService(this._ref);

  final Ref _ref;

  static const _uuid = Uuid();

  /// Modele verilecek not defteri bağlamı (id'li kompakt liste).
  String buildNotesContext(List<Note> notes) {
    final buffer = StringBuffer();
    for (final note in notes.take(80)) {
      final text = note.toPlainText();
      buffer.writeln(
        '- id: ${note.id} | tip: ${note.type.id}'
        '${note.tags.isEmpty ? '' : ' | etiketler: ${note.tags.join(',')}'}'
        '${note.reminderAt != null ? ' | hatırlatıcı: ${note.reminderAt!.toIso8601String()}' : ''}',
      );
      buffer.writeln(
        '  ${text.length > 300 ? '${text.substring(0, 300)}…' : text}'
            .replaceAll('\n', ' / '),
      );
    }
    return buffer.isEmpty ? '(not defteri boş)' : buffer.toString();
  }

  Future<Map<String, dynamic>> execute(
    String name,
    Map<String, dynamic> args,
  ) async {
    final repo = _ref.read(notesRepositoryProvider);
    if (repo == null) {
      return {'status': 'error', 'message': 'Oturum bulunamadı'};
    }
    switch (name) {
      case 'create_note':
        return _createNote(repo, args);
      case 'update_note':
        return _updateNote(repo, args);
      case 'delete_note':
        final noteId = args['noteId'] as String?;
        if (noteId == null || noteId.isEmpty) {
          return {'status': 'error', 'message': 'noteId gerekli'};
        }
        repo.softDelete(noteId);
        return {'status': 'ok', 'message': 'Not çöp kutusuna taşındı'};
      default:
        return {'status': 'error', 'message': 'Bilinmeyen araç: $name'};
    }
  }

  List<String> _stringList(dynamic value) => [
        for (final entry in (value as List<dynamic>? ?? const []))
          entry.toString(),
      ];

  Future<Map<String, dynamic>> _createNote(
    NotesRepository repo,
    Map<String, dynamic> args,
  ) async {
    final type = NoteType.fromId(args['type'] as String?);
    final id = await repo.createNote(type);
    final items = _stringList(args['items']);
    final reminder = args['reminderAt'] is String
        ? DateTime.tryParse(args['reminderAt'] as String)
        : null;
    repo.updateFields(id, {
      'title': args['title'] as String? ?? '',
      if (type == NoteType.text) 'body': args['body'] as String? ?? '',
      if (type != NoteType.text)
        'items': [
          for (final item in items)
            NoteItem(id: _uuid.v4(), text: item).toMap(),
        ],
      'tags': _stringList(args['tags']),
      if (reminder != null) 'reminderAt': Timestamp.fromDate(reminder),
    });
    return {'status': 'ok', 'noteId': id};
  }

  Future<Map<String, dynamic>> _updateNote(
    NotesRepository repo,
    Map<String, dynamic> args,
  ) async {
    final noteId = args['noteId'] as String?;
    if (noteId == null || noteId.isEmpty) {
      return {'status': 'error', 'message': 'noteId gerekli'};
    }
    final fields = <String, dynamic>{};
    if (args['title'] is String) fields['title'] = args['title'];
    if (args['body'] is String) fields['body'] = args['body'];
    if (args['setTags'] is List) fields['tags'] = _stringList(args['setTags']);
    if (args['pinned'] is bool) fields['pinned'] = args['pinned'];
    if (args['archived'] is bool) {
      fields['archivedAt'] =
          (args['archived'] as bool) ? Timestamp.now() : null;
    }
    if (args['clearReminder'] == true) {
      fields['reminderAt'] = null;
    } else if (args['reminderAt'] is String) {
      final reminder = DateTime.tryParse(args['reminderAt'] as String);
      if (reminder != null) fields['reminderAt'] = Timestamp.fromDate(reminder);
    }

    final addItems = _stringList(args['addItems']);
    if (addItems.isNotEmpty) {
      // Mevcut öğeleri koruyarak sona ekle.
      final current = await repo.watchNote(noteId).first;
      if (current != null) {
        fields['items'] = [
          for (final item in current.items) item.toMap(),
          for (final text in addItems)
            NoteItem(id: _uuid.v4(), text: text).toMap(),
        ];
      }
    }

    if (fields.isEmpty) {
      return {'status': 'error', 'message': 'Güncellenecek alan yok'};
    }
    repo.updateFields(noteId, fields);
    return {'status': 'ok', 'noteId': noteId};
  }
}
