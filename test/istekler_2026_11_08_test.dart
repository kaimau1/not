import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notlar/core/personalize.dart';
import 'package:notlar/core/utils/spell_fix.dart';
import 'package:notlar/features/gmail/data/gmail_api.dart';
import 'package:notlar/features/gmail/presentation/gmail_screen.dart';
import 'package:notlar/features/notes/domain/note_item.dart';
import 'package:notlar/core/utils/spell_engine.dart';
import 'package:notlar/features/notes/presentation/editor/note_package.dart';

/// 2026-11-08 istek listesi: yazım düzelt, Gmail görsel/bağlantı, not paketi,
/// hızlı satıra sonradan eklenen düğmeler.
void main() {
  group('Türkçe yazım düzelt', () {
    test('sık hatalar, -yo, soru eki', () {
      expect(fixTurkishWord('herşey'), 'her şey');
      expect(fixTurkishWord('Yanlız'), 'Yalnız');
      expect(fixTurkishWord('geliyo'), 'geliyor');
      expect(fixTurkishWord('gelirmisin'), 'gelir misin');
      expect(fixTurkishWord('kitap'), 'kitap');
      expect(fixTurkishWord('NATO'), 'NATO');
    });

    test('biten kelime + cümle başı büyük harf', () {
      final e = spellFixAt('ali geldi. herşey ', 18)!;
      expect(
        'ali geldi. herşey '.replaceRange(e.start, e.end, e.text),
        'ali geldi. Her şey ',
      );
      // Satır başı (i → İ).
      final f = spellFixAt('iyi ', 4)!;
      expect('iyi '.replaceRange(f.start, f.end, f.text), 'İyi ');
    });

    test('noktalamadan önceki boşluk silinir', () {
      const t = 'Elma ,';
      final e = spellFixAt(t, t.length)!;
      expect(t.replaceRange(e.start, e.end, e.text), 'Elma,');
    });

    test('bağlantıya/sayıya yapışık kelimeye dokunulmaz', () {
      expect(spellFixAt('a.com/herşey ', 13), isNull);
    });

    test('satır sonu: baş harf + nokta (3+ kelime)', () {
      expect(finalizeLine('bugün markete gittim'), 'Bugün markete gittim.');
      expect(finalizeLine('süt'), 'Süt');
      expect(finalizeLine('Bitti!'), 'Bitti!');
    });

    test('cihaz önerisi yalnız yakınsa', () {
      expect(SpellEngine.acceptSuggestion('kalmel', 'kalem'), isTrue);
      expect(SpellEngine.acceptSuggestion('kalem', 'Kalem'), isFalse);
      expect(SpellEngine.acceptSuggestion('kalem', 'masa'), isFalse);
    });
  });

  group('Gmail', () {
    test('görseller (izleme pikseli hariç) ve bağlantılar', () {
      const html =
          '<p>Merhaba <a href="https://x.com/a?b=1&amp;c=2">Siparişin</a></p>'
          '<img src="https://img.com/1.png" width="300">'
          '<img src="https://t.com/p.gif" width="1" height="1">'
          '<img src="cid:abc">';
      expect(htmlImageUrls(html), ['https://img.com/1.png']);
      expect(htmlLinks(html).single.label, 'Siparişin');
      expect(htmlLinks(html).single.url, 'https://x.com/a?b=1&c=2');
    });

    test('düz adres ve <a> yazısı tıklanır parçaya bölünür', () {
      final spans = linkifyMail(
        'Siparişin hazır: https://k.com/s. Bak',
        [(label: 'Siparişin', url: 'https://x.com')],
        linkStyle: const TextStyle(),
        onOpen: (_) {},
      );
      final linked = [
        for (final s in spans.cast<TextSpan>())
          if (s.recognizer != null) s.text,
      ];
      expect(linked, ['Siparişin', 'https://k.com/s']);
      expect(spans.cast<TextSpan>().map((s) => s.text).join(),
          'Siparişin hazır: https://k.com/s. Bak');
    });
  });

  group('Not paketi', () {
    test('uzun paragraf ipucu verir', () {
      expect(suggestsPackage('kısa yazı'), isFalse);
      expect(suggestsPackage(List.filled(20, 'satır').join('\n')), isTrue);
      expect(suggestsPackage('a' * 1000), isTrue);
    });

    test('ad çakışınca numaralanır', () {
      expect(packageName('Toplantı notları\nikinci', {}), 'Toplantı notları');
      expect(
        packageName('Toplantı notları', {'Toplantı notları'}),
        'Toplantı notları (2)',
      );
      final pkg = newNotePackage('içerik', {});
      expect(isNotePackage(pkg), isTrue);
    });

    test('madde paketi kayda yazılır ve okunur', () {
      const item = NoteItem(id: '1', text: 'a', package: 'p1');
      expect(item.toMap()['package'], 'p1');
      expect(NoteItem.fromMap(item.toMap()).package, 'p1');
      expect(const NoteItem(id: '2', text: 'b').toMap().containsKey('package'),
          isFalse);
    });
  });

  test('hızlı satıra eklenebilen düğmeler varsayılan gizli, açılınca kalır',
      () {
    final id = UiItem.quickRow('italic');
    const prefs = UiPrefs();
    expect(prefs.shows(id), isFalse);
    final on = prefs.withVisible(id, true);
    expect(on.shows(id), isTrue);
    expect(UiPrefs.fromJson(on.toJson()).shows(id), isTrue);
    expect(on.withVisible(id, false).shows(id), isFalse);
    // Varsayılan görünür öğe eskisi gibi.
    expect(prefs.shows(UiItem.quickRow('bold')), isTrue);
  });
}
