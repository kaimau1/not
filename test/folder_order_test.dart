import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/folders/data/folder_order.dart';
import 'package:notlar/features/folders/domain/note_folder.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// Klasör sırası ve klasörler arası yana çekiş (kullanıcı isteği
/// 2026-09-26: "sağ sol kaydırmada klasörler arası geçiş ve klasör
/// sıralaması ayarlama").
void main() {
  NoteFolder folder(String id, String name, {int? order, DateTime? created}) =>
      NoteFolder(
        id: id,
        name: name,
        ownerId: 'me',
        order: order,
        createdAt: created,
      );

  final folders = [
    folder('a', 'Zeytin', order: 1, created: DateTime(2026, 1, 3)),
    folder('b', 'armut', order: 0, created: DateTime(2026)),
    folder('c', 'Muz', created: DateTime(2026, 1, 2)),
  ];

  List<String> ids(List<NoteFolder> list) => [for (final f in list) f.id];

  group('sortFolders', () {
    test('ada göre büyük/küçük harf duyarsız', () {
      expect(ids(sortFolders(folders, FolderSort.name)), ['b', 'c', 'a']);
    });

    test('elle: sırası olmayan sona, kendi aralarında ada göre', () {
      expect(ids(sortFolders(folders, FolderSort.manual)), ['b', 'a', 'c']);
    });

    test('en yeni önce; tarihi gelmemiş (yeni açılmış) en başta', () {
      expect(ids(sortFolders(folders, FolderSort.newest)), ['a', 'c', 'b']);
      final fresh = [...folders, folder('d', 'Yeni')];
      expect(ids(sortFolders(fresh, FolderSort.newest)).first, 'd');
    });

    test('not sayısına göre; eşitlikte ada göre', () {
      expect(
        ids(
          sortFolders(
            folders,
            FolderSort.noteCount,
            counts: const {'a': 2, 'c': 2, 'b': 5},
          ),
        ),
        ['b', 'c', 'a'],
      );
    });
  });

  group('nextHomeSwipeStop', () {
    const notes = [
      Note(id: '1', type: NoteType.text, title: 'A', pinned: true),
      Note(id: '2', type: NoteType.text, title: 'B', folderId: 'f1'),
      Note(id: '3', type: NoteType.text, title: 'C', tags: ['iş']),
    ];

    HomeSwipeStop? next(
      SwipeMode mode, {
      String? folderId,
      NoteFilter filter = NoteFilter.all,
      String? tag,
      int direction = 1,
    }) => nextHomeSwipeStop(
      mode: mode,
      notes: notes,
      folderIds: const ['f1', 'f2'],
      folderId: folderId,
      filter: filter,
      tag: tag,
      direction: direction,
    );

    test('klasör kipi: Tümü → f1 → f2 → Tümü', () {
      expect(next(SwipeMode.folders), (
        folderId: 'f1',
        filter: NoteFilter.all,
        tag: null,
      ));
      expect(next(SwipeMode.folders, folderId: 'f1'), (
        folderId: 'f2',
        filter: NoteFilter.all,
        tag: null,
      ));
      expect(next(SwipeMode.folders, folderId: 'f2'), (
        folderId: null,
        filter: NoteFilter.all,
        tag: null,
      ));
    });

    test('klasör kipi geri: Tümü → son klasör', () {
      expect(next(SwipeMode.folders, direction: -1)?.folderId, 'f2');
    });

    test('klasör kipinde açık süzgeç Tümü sayılır ve sıfırlanır', () {
      expect(next(SwipeMode.folders, filter: NoteFilter.pinned), (
        folderId: 'f1',
        filter: NoteFilter.all,
        tag: null,
      ));
    });

    test('klasör yoksa klasör kipinde gezilecek yer yok', () {
      expect(
        nextHomeSwipeStop(
          mode: SwipeMode.folders,
          notes: notes,
          folderIds: const [],
          folderId: null,
          filter: NoteFilter.all,
          tag: null,
          direction: 1,
        ),
        isNull,
      );
    });

    test('süzgeç kipi klasörü korur, duraklar klasörün notlarından', () {
      // f1'de yalnız B var: Tümü ve Metin durak; Sabitli (A) f1'de değil.
      expect(next(SwipeMode.filters, folderId: 'f1'), (
        folderId: 'f1',
        filter: NoteFilter.text,
        tag: null,
      ));
    });

    test('ikisi birden: klasörlerden sonra süzgeçler ve etiketler', () {
      expect(next(SwipeMode.both, folderId: 'f2'), (
        folderId: null,
        filter: NoteFilter.text,
        tag: null,
      ));
      // Son durak etiket; ondan sonra başa (Tümü) sarar.
      expect(next(SwipeMode.both, tag: 'iş'), (
        folderId: null,
        filter: NoteFilter.all,
        tag: null,
      ));
    });

    test('kapalı kip hiçbir yere gitmez', () {
      expect(next(SwipeMode.off), isNull);
    });
  });
}
