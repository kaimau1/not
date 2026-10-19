import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// Ana ekranı yana çekince gezilen duraklar (bkz. [nextSwipeStop]).
///
/// Kullanıcı bulgusu 2026-09-23: "ana ekranda sağa sola kaydırmada mantık
/// hatası var". Eski kural dokuz süzgecin hepsini (boş olanlar dahil)
/// geziyor, seçili klasörü siliyor ve birleşik süzgeçte listenin başına
/// fırlatıyordu.
void main() {
  const notes = [
    Note(id: 'a', type: NoteType.text, title: 'A', pinned: true),
    Note(id: 'b', type: NoteType.checklist, title: 'B', tags: ['iş']),
    Note(id: 'c', type: NoteType.text, title: 'C', tags: ['ev', 'iş']),
  ];

  SwipeStop? next(NoteFilter filter, {String? tag, int direction = 1}) =>
      nextSwipeStop(
        notes: notes,
        filter: filter,
        tag: tag,
        direction: direction,
      );

  test('boş süzgeçler atlanır: Tümü → Metin → Madde → Sabitli', () {
    expect(next(NoteFilter.all), (filter: NoteFilter.text, tag: null));
    expect(next(NoteFilter.text), (filter: NoteFilter.checklist, tag: null));
    // Sıralı liste yok → atlanır.
    expect(next(NoteFilter.checklist), (filter: NoteFilter.pinned, tag: null));
  });

  test('süzgeçlerden sonra etiketler, sonra başa dönülür', () {
    // Sabitli'den sonra yıldızlı/hatırlatıcılı/kilitli yok; "diğerleri"
    // (klasörsüz ve etiketsiz) var: A.
    expect(next(NoteFilter.pinned), (filter: NoteFilter.others, tag: null));
    expect(next(NoteFilter.others), (filter: NoteFilter.all, tag: 'ev'));
    expect(next(NoteFilter.all, tag: 'ev'), (filter: NoteFilter.all, tag: 'iş'));
    expect(next(NoteFilter.all, tag: 'iş'), (filter: NoteFilter.all, tag: null));
  });

  test('geri çekiş önceki durağa gider (baştan sona sarar)', () {
    expect(
      next(NoteFilter.all, direction: -1),
      (filter: NoteFilter.all, tag: 'iş'),
    );
    expect(
      next(NoteFilter.checklist, direction: -1),
      (filter: NoteFilter.text, tag: null),
    );
  });

  test('birleşik süzgeç (sabitli + etiket) etiketin durağından sürer', () {
    // Eskiden bu hâl hiçbir durağa uymuyor ve çekiş listenin başına
    // fırlatıyordu.
    expect(
      next(NoteFilter.pinned, tag: 'ev'),
      (filter: NoteFilter.all, tag: 'iş'),
    );
  });

  test('açık olan süzgeç boş olsa da durak sayılır', () {
    // Kilitli not yok ama kullanıcı o süzgeçte: bir sonraki durak Sabitli
    // değil, sıradaki dolu süzgeç — ve geri çekiş Kilitli'nin öncesine döner.
    expect(next(NoteFilter.locked), (filter: NoteFilter.others, tag: null));
    expect(
      next(NoteFilter.locked, direction: -1),
      (filter: NoteFilter.pinned, tag: null),
    );
  });

  test('gezilecek yer yoksa null', () {
    expect(
      nextSwipeStop(
        notes: const [],
        filter: NoteFilter.all,
        tag: null,
        direction: 1,
      ),
      isNull,
    );
  });
}
