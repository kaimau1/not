import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/search_fold.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/notes_providers.dart';

/// F1.8 — Türkçe ı/I ve aksan duyarsız arama.
void main() {
  bool hit(String text, String query) =>
      foldForSearch(text).contains(foldForSearch(query));

  test('ılık / ILIK', () {
    expect(hit('ILIK SU', 'ılık'), isTrue);
    expect(hit('ılık su', 'ILIK'), isTrue);
  });

  test('alışveriş / alisveris', () {
    expect(hit('Alışveriş listesi', 'alisveris'), isTrue);
    expect(hit('alisveris', 'ALIŞVERİŞ'), isTrue);
  });

  test('İstanbul / istanbul', () {
    expect(hit('İSTANBUL', 'istanbul'), isTrue);
    expect(hit('istanbul', 'İstanbul'), isTrue);
  });

  test('ğ ü ö ç â î û', () {
    expect(hit('Çiğdem Gül Ömür', 'cigdem gul omur'), isTrue);
    expect(hit('kâğıt', 'kagit'), isTrue);
  });

  test('uzunluk korunur (vurgu indeksleri)', () {
    const text = 'İĞNE ıŞık ÇÖÜ';
    expect(foldForSearch(text).length, text.length);
  });

  test('not süzgeci katlanmış sorguyla eşleşir', () {
    const note = Note(
      id: 'n',
      type: NoteType.text,
      title: 'ILIK SU',
      body: 'Alışveriş',
    );
    expect(noteMatchesQuery(note, foldForSearch('ılık')), isTrue);
    expect(noteMatchesQuery(note, foldForSearch('alisveris')), isTrue);
    expect(noteMatchesQuery(note, foldForSearch('yok')), isFalse);
  });
}
