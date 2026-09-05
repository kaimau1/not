import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folder_activity.dart';
import 'package:notlar/features/folders/data/folder_chat_repository.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';

/// **PAYLAŞILAN KLASÖRÜN OKUNMAMIŞ SAYACI** (kullanıcı isteği 2026-09-04:
/// "ana sayfada basit bir işaretçi olmalı, o klasör simgesinin sağ üstünde
/// 1, 2 gibi rakam").
///
/// Kural iki cümle: **son bakıştan sonra** olan ve **başkasının yaptığı**
/// hareket sayılır. İkisinden biri unutulursa rozet ya hiç sönmez ya da
/// kendi düzenlemem kendi telefonuma bildirim düşürür.
void main() {
  final since = DateTime(2026, 9, 4, 12);
  Note note(String id, {required DateTime at, String by = 'other'}) => Note(
    id: id,
    type: NoteType.text,
    updatedAt: at,
    updatedBy: by,
  );
  FolderMessage message(String id, {required DateTime at, String from = 'other'}) =>
      FolderMessage(
        id: id,
        senderId: from,
        senderName: 'Karşı taraf',
        text: 'selam',
        createdAt: at,
      );

  test('son bakıştan SONRA gelen not ve mesaj sayılır', () {
    final count = countFolderUnread(
      notes: [note('a', at: since.add(const Duration(minutes: 1)))],
      messages: [message('m', at: since.add(const Duration(minutes: 2)))],
      since: since,
      me: 'me',
    );
    expect(count, 2);
  });

  test('son bakıştan ÖNCEKİ hareket sayılmaz', () {
    final count = countFolderUnread(
      notes: [note('a', at: since.subtract(const Duration(hours: 1)))],
      messages: [message('m', at: since.subtract(const Duration(hours: 1)))],
      since: since,
      me: 'me',
    );
    expect(count, 0);
  });

  test('KENDİ yazdığım sayılmaz (kendi telefonuma bildirim düşmesin)', () {
    final count = countFolderUnread(
      notes: [note('a', at: since.add(const Duration(minutes: 1)), by: 'me')],
      messages: [
        message('m', at: since.add(const Duration(minutes: 2)), from: 'me'),
      ],
      since: since,
      me: 'me',
    );
    expect(count, 0);
  });

  test('ESKİ kayıtta yazar bilinmiyor (boş) — sayılır', () {
    // Kayıp bildirim, yanlış sessizlikten iyidir: `updatedBy` alanı
    // eklenmeden önce yazılmış notlar bilinmeyen sayılır.
    final count = countFolderUnread(
      notes: [note('a', at: since.add(const Duration(minutes: 1)), by: '')],
      messages: const [],
      since: since,
      me: 'me',
    );
    expect(count, 1);
  });

  test('zamansız (henüz sunucuya ulaşmamış) hareket sayılmaz', () {
    final count = countFolderUnread(
      notes: [Note(id: 'a', type: NoteType.text, updatedBy: 'other')],
      messages: [
        const FolderMessage(
          id: 'm',
          senderId: 'other',
          senderName: 'X',
          text: 'y',
        ),
      ],
      since: since,
      me: 'me',
    );
    expect(count, 0);
  });
}
