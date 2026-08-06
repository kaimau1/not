// 2026-08-06 genel kullanım denetiminin düzeltmelerini kilitleyen testler:
// hatırlatıcılı boş not, temiz pano seçimi, unicode kelime sınırı, yinele.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/utils/rich_text.dart';
import 'package:notlar/features/notes/domain/note.dart';
import 'package:notlar/features/notes/domain/note_type.dart';
import 'package:notlar/features/notes/presentation/editor/note_undo.dart';
import 'package:notlar/features/notes/presentation/editor/text_wrap.dart';

Note _note({String body = ''}) =>
    Note(id: 'n1', type: NoteType.text, body: body);

void main() {
  group('Note.isEmpty + hatırlatıcı', () {
    test('yalnız hatırlatıcısı olan not BOŞ sayılmaz (silinmez)', () {
      final note = Note(
        id: '1',
        type: NoteType.text,
        reminderAt: DateTime(2026, 8, 7, 9),
      );
      expect(note.isEmpty, isFalse);
    });

    test('hatırlatıcısız boş not boş sayılmaya devam eder', () {
      const note = Note(id: '1', type: NoteType.text);
      expect(note.isEmpty, isTrue);
    });
  });

  group('plainSelection (temiz pano)', () {
    test('biçim işaretleri panoya gitmez', () {
      const text = 'önce **kalın** sonra';
      expect(plainSelection(text, 0, text.length), 'önce kalın sonra');
    });

    test('işaretin ORTASINA düşen uç görünür karaktere hizalanır', () {
      const text = '%%1:renkli%% metin';
      // Uç `%%1:` önekinin içinde: yarım işaret panoya sızmamalı.
      final copied = plainSelection(text, 2, text.length);
      expect(copied.contains('%'), isFalse);
      expect(copied, contains('renkli'));
    });

    test('işaretsiz metinde birebir alt dizi döner', () {
      expect(plainSelection('merhaba', 2, 5), 'rha');
    });
  });

  group('clipboardTextOf (çapa + işaret temizliği)', () {
    test('sarma çapaları kopyalanan metne girmez', () {
      final anchored =
          'satır$kWrapGlueChar$kWrapAnchorChar${kWrapAnchorChar}devam **k**';
      final value = TextEditingValue(
        text: anchored,
        selection: TextSelection(baseOffset: 0, extentOffset: anchored.length),
      );
      final out = clipboardTextOf(value);
      expect(out.contains(kWrapAnchorChar), isFalse);
      expect(out.contains(kWrapGlueChar), isFalse);
      expect(out.contains('**'), isFalse);
      expect(out, contains('satır'));
      expect(out, contains('k'));
    });

    test('seçim yoksa boş döner', () {
      const value = TextEditingValue(text: 'abc');
      expect(clipboardTextOf(value), '');
    });
  });

  group('biçim kalıbı unicode kelime sınırı', () {
    test('Türkçe harfli snake_case italik SANILMAZ', () {
      // Eskiden `\w` ASCII olduğundan `_ortalama_` italik sanılıp
      // alt çizgiler görünmez oluyordu.
      const text = 'yaş_ortalama_x hesabı';
      expect(stripRichMarkers(text), text);
    });

    test('ASCII snake_case korunmaya devam eder', () {
      const text = 'dosya_adi_uzun kaldı';
      expect(stripRichMarkers(text), text);
    });

    test('boşlukla ayrılmış italik hâlâ çalışır', () {
      expect(stripRichMarkers('bu _italik_ olmalı'), 'bu italik olmalı');
    });
  });

  group('NoteUndoStack yinele (redo)', () {
    final t0 = DateTime(2026, 8, 1, 9);

    test('geri alınan durum yinelenebilir', () {
      final stack = NoteUndoStack();
      final a = _note(body: 'a');
      final b = _note(body: 'b');
      stack.push(a, b, now: t0);
      expect(stack.canRedo, isFalse);

      final undone = stack.undo(b);
      expect(undone!.body, 'a');
      expect(stack.canRedo, isTrue);

      final redone = stack.redoStep(undone);
      expect(redone!.body, 'b');
      expect(stack.canRedo, isFalse);
      // Yinelemenin kendisi de geri alınabilir.
      expect(stack.canUndo, isTrue);
      expect(stack.undo(redone)!.body, 'a');
    });

    test('yeni değişiklik yinele zincirini temizler', () {
      final stack = NoteUndoStack();
      final a = _note(body: 'a');
      final b = _note(body: 'b');
      stack.push(a, b, now: t0);
      final undone = stack.undo(b)!;
      expect(stack.canRedo, isTrue);

      // Geri al sonrası YENİ yazım: ileri zincir artık geçersiz.
      stack.push(undone, _note(body: 'c'), now: t0.add(const Duration(seconds: 5)));
      expect(stack.canRedo, isFalse);
    });

    test('boş yığında undo/redo null döner', () {
      final stack = NoteUndoStack();
      expect(stack.undo(_note()), isNull);
      expect(stack.redoStep(_note()), isNull);
    });
  });
}
