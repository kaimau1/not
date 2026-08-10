import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/note_card.dart';

/// Ana ekran ızgarası kartları ÇİZMEDEN ÖNCE sütunlara dağıtıyor; dağıtım
/// [estimateNoteCardHeight] ile yapılıyor (bkz. dashboard_screen.dart →
/// `_balancedColumns`). Tahminin kesin olması gerekmiyor ama SIRALAMASI
/// doğru olmalı: daha çok içerik taşıyan kart daha uzun sayılmalı, yoksa
/// sütunlar ters dengelenir ve kullanıcının bildirdiği "sağ sütunda kalan
/// boşluk" geri gelir.
void main() {
  const width = 190.0; // iki sütunlu düzende bir hücre

  Note note({
    String title = '',
    String body = '',
    List<NoteItem> items = const [],
    NoteType type = NoteType.text,
  }) => Note(
    id: 'n',
    type: type,
    title: title,
    body: body,
    items: items,
  );

  test('boş not en kısa, içerik eklendikçe uzar', () {
    final empty = estimateNoteCardHeight(note(), width);
    final titled = estimateNoteCardHeight(note(title: 'Başlık'), width);
    final withBody = estimateNoteCardHeight(
      note(title: 'Başlık', body: 'Kısa bir gövde'),
      width,
    );
    expect(empty, greaterThan(0));
    expect(titled, greaterThan(empty));
    expect(withBody, greaterThan(titled));
  });

  test('uzun gövde kısa gövdeden uzun sayılır', () {
    final short = estimateNoteCardHeight(note(body: 'tek satır'), width);
    final long = estimateNoteCardHeight(note(body: 'x' * 400), width);
    expect(long, greaterThan(short));
  });

  test('madde sayısı arttıkça uzar ama tavanda durur', () {
    List<NoteItem> items(int n) => [
      for (var i = 0; i < n; i++) NoteItem(id: '$i', text: 'madde $i'),
    ];
    final two = estimateNoteCardHeight(
      note(type: NoteType.checklist, items: items(2)),
      width,
    );
    final six = estimateNoteCardHeight(
      note(type: NoteType.checklist, items: items(6)),
      width,
    );
    final many = estimateNoteCardHeight(
      note(type: NoteType.checklist, items: items(40)),
      width,
    );
    expect(six, greaterThan(two));
    // Kartta en çok 6 madde + "+N öğe daha" satırı çiziliyor: 40 maddelik not
    // 6 maddelikten yalnız o tek satır kadar uzun olmalı.
    expect(many - six, lessThan(30));
  });
}
